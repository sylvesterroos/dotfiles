"""A cache of remote git repositories, readable at any revision.

Every repository lives at `<root>/<host>/<owner>/<name>` as a partial clone.
Reads address a revision through git's object database, so the checked-out
state of the cache stays on the remote's default branch.
"""

import fcntl
import os
import re
import subprocess
import time
from collections.abc import Iterator
from contextlib import contextmanager
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path, PurePosixPath

REFRESH_INTERVAL_SECONDS = 300
NETWORK_TIMEOUT_SECONDS = 600
SEARCH_TIMEOUT_SECONDS = 120
LOCAL_TIMEOUT_SECONDS = 60
MAX_READ_LINES = 2000

_SCHEMES = ("https", "http", "ssh", "git")
_USER = r"[A-Za-z0-9_][A-Za-z0-9_.-]*"
_HOST = r"[A-Za-z0-9][A-Za-z0-9.-]*"
_SEGMENT = re.compile(r"[.~]?[A-Za-z0-9_][A-Za-z0-9._-]*")
_AUTHORITY = re.compile(rf"(?:{_USER}@)?({_HOST})(?::[0-9]{{1,5}})?")
_SCP = re.compile(rf"{_USER}@({_HOST}):(?!//)(.+)")
_ENTRY_MARKS = {"blob": "", "tree": "/", "commit": "@"}
_GIT_ENVIRONMENT = {"GIT_TERMINAL_PROMPT": "0", "GIT_PAGER": "cat", "LC_ALL": "C"}


class LibrarianError(Exception):
    pass


@dataclass(frozen=True)
class Repository:
    """Identified by host and path; `url` is the transport the first clone uses."""

    host: str
    segments: tuple[str, ...]
    url: str = field(compare=False)

    @property
    def name(self) -> str:
        return "/".join((self.host, *self.segments))


@dataclass(frozen=True)
class Checkout:
    repository: Repository
    path: Path
    warning: str | None


def parse_reference(reference: str) -> Repository:
    """Accepts `owner/repo` (GitHub), `host/path` for a dotted host, `https|http|ssh|git://` URLs
    and scp-style `user@host:path`. Explicit URLs keep their transport, port and user."""
    text = reference.strip()
    shorthand = False
    if "://" in text:
        scheme, _, rest = text.partition("://")
        authority, _, path = rest.partition("/")
        match = _AUTHORITY.fullmatch(authority)
        if scheme not in _SCHEMES or match is None:
            raise _unusable(reference)
        host, base = match.group(1), f"{scheme}://{authority}/"
    elif match := _SCP.fullmatch(text):
        host, path = match.groups()
        base = text[: text.index(":") + 1]
    else:
        shorthand = True
        first, _, path = text.partition("/")
        host, path = (first, path) if "." in first else ("github.com", text)
        base = f"https://{host}/"
    if not re.fullmatch(_HOST, host):
        raise _unusable(reference)
    path = path.rstrip("/")
    suffix = ".git" if shorthand or path.endswith(".git") else ""
    segments = [segment for segment in path.removesuffix(".git").split("/") if segment]
    if host == "github.com" and len(segments) != 2:
        raise _unusable(reference)
    if len(segments) < 2 or not all(_SEGMENT.fullmatch(segment) for segment in segments):
        raise _unusable(reference)
    return Repository(host, tuple(segments), base + "/".join(segments) + suffix)


def _unusable(reference: str) -> LibrarianError:
    return LibrarianError(
        f"expected owner/repo, host/org/repo, an https/http/ssh/git URL or user@host:path, got {reference!r}"
    )


def relative_path(value: str) -> str:
    path = PurePosixPath(value)
    if path.is_absolute() or ".." in path.parts:
        raise LibrarianError(f"path must be relative to the repository root: {value!r}")
    return "" if str(path) == "." else str(path)


def _run(
    arguments: list[str],
    cwd: Path | None = None,
    timeout: int = LOCAL_TIMEOUT_SECONDS,
    accepted: tuple[int, ...] = (0,),
) -> bytes:
    try:
        result = subprocess.run(
            ["git", *arguments],
            cwd=cwd,
            env={**os.environ, **_GIT_ENVIRONMENT},
            capture_output=True,
            timeout=timeout,
            # Without a controlling terminal ssh and credential helpers fail instead of prompting.
            start_new_session=True,
        )
    except subprocess.TimeoutExpired:
        raise LibrarianError(f"git {arguments[0]} timed out after {timeout}s") from None
    if result.returncode not in accepted:
        stderr = result.stderr.decode("utf-8", "replace").strip()
        raise LibrarianError(f"git {arguments[0]} failed: {stderr}")
    return result.stdout


def _git(
    arguments: list[str],
    cwd: Path | None = None,
    timeout: int = LOCAL_TIMEOUT_SECONDS,
    accepted: tuple[int, ...] = (0,),
) -> str:
    return _run(arguments, cwd, timeout, accepted).decode("utf-8", "replace")


def _lines(text: str) -> list[str]:
    lines = [line.removesuffix("\r") for line in text.split("\n")]
    if lines[-1] == "":
        lines.pop()
    return lines


def _last_fetch(path: Path) -> float:
    git_directory = path / ".git"
    try:
        return (git_directory / "FETCH_HEAD").stat().st_mtime
    except FileNotFoundError:
        return (git_directory / "HEAD").stat().st_mtime


class Library:
    def __init__(self, root: Path):
        self.root = root

    def checkout(self, reference: str, refresh: bool = False) -> Checkout:
        """Clones the repository when absent, otherwise refreshes it when stale or `refresh` is set."""
        repository = parse_reference(reference)
        path = self.root.joinpath(repository.host, *repository.segments)
        with self._locked(repository):
            if not (path / ".git").is_dir():
                path.parent.mkdir(parents=True, exist_ok=True)
                _git(
                    ["clone", "--filter=blob:none", "--quiet", "--", repository.url, str(path)],
                    timeout=NETWORK_TIMEOUT_SECONDS,
                )
                return Checkout(repository, path, None)
            if _git(["config", "remote.origin.url"], path).strip() != repository.url:
                _git(["remote", "set-url", "origin", repository.url], path)
            return Checkout(repository, path, self._refresh(path, refresh))

    def resolve(self, checkout: Checkout, ref: str | None) -> str:
        """Returns the commit a branch, tag or commit name points at; a missing name triggers one tag fetch."""
        if ref is not None and ref.startswith("-"):
            raise LibrarianError(f"invalid revision: {ref!r}")
        candidates = ("origin/HEAD", "HEAD") if ref is None else (f"origin/{ref}", ref)
        sha = self._first_commit(checkout.path, candidates)
        if sha is None:
            with self._locked(checkout.repository):
                _git(
                    ["fetch", "--quiet", "--tags", "origin"],
                    checkout.path,
                    timeout=NETWORK_TIMEOUT_SECONDS,
                )
            sha = self._first_commit(checkout.path, candidates)
        if sha is None:
            raise LibrarianError(f"unknown revision: {ref}")
        return sha

    def cached(self) -> list[dict]:
        entries = []
        for directory, subdirectories, _ in os.walk(self.root):
            if ".git" not in subdirectories:
                continue
            subdirectories.clear()
            path = Path(directory)
            entries.append(
                {
                    "repo": str(path.relative_to(self.root)),
                    "path": str(path),
                    "commit": _git(["rev-parse", "--short=12", "HEAD"], path).strip(),
                    "fetched": datetime.fromtimestamp(_last_fetch(path))
                    .astimezone()
                    .isoformat(timespec="seconds"),
                }
            )
        return sorted(entries, key=lambda entry: entry["repo"])

    def read(self, checkout: Checkout, sha: str, file: str, start: int, end: int | None) -> dict:
        spec = f"{sha}:{relative_path(file)}"
        kind = _git(["cat-file", "-t", spec], checkout.path).strip()
        if kind != "blob":
            raise LibrarianError(f"{file} is a {kind}; list directories with repo_files")
        data = _run(["cat-file", "blob", spec], checkout.path)
        if b"\0" in data[:8000]:
            raise LibrarianError(f"{file} is a binary file")
        lines = _lines(data.decode("utf-8", "replace"))
        first = max(start, 1)
        last = min(end or len(lines), first + MAX_READ_LINES - 1, len(lines))
        numbered = (f"{number}|{line}" for number, line in enumerate(lines[first - 1 : last], first))
        return {
            "total_lines": len(lines),
            "start_line": first,
            "end_line": last,
            "content": "\n".join(numbered),
        }

    def files(self, checkout: Checkout, sha: str, directory: str, pattern: str | None) -> list[str]:
        """Lists one directory level, or every file under `directory` matching a `**` glob pattern."""
        directory = relative_path(directory)
        tree = f"{sha}:{directory}" if directory else sha
        if pattern is None:
            raw = _git(["ls-tree", "-z", "--format=%(objecttype) %(path)", tree], checkout.path)
            entries = []
            for record in filter(None, raw.split("\0")):
                kind, _, name = record.partition(" ")
                entries.append(name + _ENTRY_MARKS[kind])
            return sorted(entries)
        raw = _git(["ls-tree", "-r", "-z", "--name-only", tree], checkout.path)
        names = filter(None, raw.split("\0"))
        return sorted(name for name in names if PurePosixPath(name).full_match(pattern))

    def grep(
        self,
        checkout: Checkout,
        sha: str,
        pattern: str,
        glob: str | None,
        ignore_case: bool,
        fixed_strings: bool,
        context: int,
    ) -> list[str]:
        arguments = ["grep", "-n", "-I", "--no-color", "-F" if fixed_strings else "-E"]
        if ignore_case:
            arguments.append("-i")
        if context:
            arguments.append(f"-C{context}")
        arguments += ["-e", pattern, sha, "--"]
        if glob:
            arguments.append(f":(glob){glob}")
        output = _git(arguments, checkout.path, timeout=SEARCH_TIMEOUT_SECONDS, accepted=(0, 1))
        return [line.removeprefix(f"{sha}:") for line in _lines(output)]

    def history(
        self,
        checkout: Checkout,
        sha: str,
        limit: int,
        query: str | None,
        pickaxe: str | None,
        path: str | None,
        author: str | None,
        since: str | None,
        until: str | None,
    ) -> list[dict]:
        """Searches commit messages (subject and body) and, with `pickaxe`, the lines each commit adds or removes."""
        arguments = [
            "log",
            "--no-color",
            "--date=short",
            f"--max-count={limit}",
            "--format=%x1e%H%x1f%ad%x1f%an%x1f%s%x1f%b",
        ]
        if query:
            arguments += ["-i", "-E", f"--grep={query}"]
        if pickaxe:
            arguments.append(f"-S{pickaxe}")
        for option, value in (("author", author), ("since", since), ("until", until)):
            if value:
                arguments.append(f"--{option}={value}")
        arguments += [sha, "--"]
        if path:
            arguments.append(relative_path(path))
        output = _git(arguments, checkout.path, timeout=SEARCH_TIMEOUT_SECONDS)
        commits = []
        for record in filter(str.strip, output.split("\x1e")):
            commit, date, name, subject, body = record.split("\x1f", 4)
            commits.append(
                {
                    "commit": commit.strip()[:12],
                    "date": date,
                    "author": name,
                    "subject": subject,
                    "body": body.strip(),
                }
            )
        return commits

    def show(self, checkout: Checkout, sha: str, path: str | None) -> str:
        arguments = [
            "show",
            "--no-ext-diff",
            "--no-color",
            "--stat",
            "--patch",
            "--date=iso",
            "--format=%H%n%an <%ae>%n%ad%n%n%s%n%n%b",
            sha,
            "--",
        ]
        if path:
            arguments.append(relative_path(path))
        return _git(arguments, checkout.path)

    def _first_commit(self, path: Path, candidates: tuple[str, ...]) -> str | None:
        for candidate in candidates:
            output = _git(
                ["rev-parse", "--verify", "--quiet", f"{candidate}^{{commit}}"],
                path,
                accepted=(0, 1),
            ).strip()
            if output:
                return output
        return None

    def _refresh(self, path: Path, force: bool) -> str | None:
        if not force and time.time() - _last_fetch(path) < REFRESH_INTERVAL_SECONDS:
            return None
        try:
            _git(["fetch", "--quiet", "origin"], path, timeout=NETWORK_TIMEOUT_SECONDS)
            branch = _git(["symbolic-ref", "--short", "-q", "HEAD"], path, accepted=(0, 1)).strip()
            if branch:
                if _git(["status", "--porcelain"], path).strip():
                    return "working tree has local changes, so the files on disk are not fast-forwarded"
                _git(["merge", "--ff-only", "--quiet", f"origin/{branch}"], path)
        except LibrarianError as error:
            return f"refresh failed, serving cached state: {error}"
        return None

    @contextmanager
    def _locked(self, repository: Repository) -> Iterator[None]:
        lock_directory = self.root / ".locks"
        lock_directory.mkdir(parents=True, exist_ok=True)
        lock_file = lock_directory / (repository.name.replace("/", "__") + ".lock")
        with open(lock_file, "w") as handle:
            fcntl.flock(handle, fcntl.LOCK_EX)
            yield
