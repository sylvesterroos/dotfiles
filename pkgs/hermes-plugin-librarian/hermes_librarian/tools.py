"""The librarian tools: schemas the model reads and handlers that run them."""

import json
import shutil
from collections.abc import Callable
from pathlib import Path

from .repository import MAX_READ_LINES, REFRESH_INTERVAL_SECONDS, Library, LibrarianError

LIBRARY = Library(Path.home() / ".cache" / "checkouts")

MAX_LISTED_FILES = 500
DEFAULT_GREP_LINES = 100
MAX_GREP_LINES = 200
DEFAULT_HISTORY_COMMITS = 30
MAX_HISTORY_COMMITS = 200
MAX_COMMIT_BODY_CHARACTERS = 1500
MAX_SHOW_CHARACTERS = 40_000


def git_available() -> bool:
    return shutil.which("git") is not None


def _json_tool(function: Callable[[dict], dict]) -> Callable[..., str]:
    def handler(args: dict, **kwargs) -> str:
        try:
            return json.dumps(function(args))
        except LibrarianError as error:
            return json.dumps({"error": str(error)})

    return handler


def _target(args):
    checkout = LIBRARY.checkout(args["repo"])
    return checkout, LIBRARY.resolve(checkout, args.get("ref"))


def _header(checkout, sha) -> dict:
    header = {"repo": checkout.repository.name, "commit": sha[:12]}
    if checkout.warning:
        header["warning"] = checkout.warning
    return header


def _capped(items: list, limit: int, key: str, total_key: str = "total") -> dict:
    return {total_key: len(items), "truncated": len(items) > limit, key: items[:limit]}


@_json_tool
def repo_checkout(args):
    checkout = LIBRARY.checkout(args["repo"], refresh=args.get("refresh", False))
    sha = LIBRARY.resolve(checkout, None)
    return {**_header(checkout, sha), "path": str(checkout.path)}


@_json_tool
def repo_list(args):
    return {"repositories": LIBRARY.cached()}


@_json_tool
def repo_read(args):
    checkout, sha = _target(args)
    excerpt = LIBRARY.read(
        checkout, sha, args["path"], int(args.get("start_line", 1)), args.get("end_line")
    )
    return {**_header(checkout, sha), "path": args["path"], **excerpt}


@_json_tool
def repo_files(args):
    checkout, sha = _target(args)
    entries = LIBRARY.files(checkout, sha, args.get("directory", ""), args.get("pattern"))
    return {**_header(checkout, sha), **_capped(entries, MAX_LISTED_FILES, "entries")}


@_json_tool
def repo_grep(args):
    checkout, sha = _target(args)
    lines = LIBRARY.grep(
        checkout,
        sha,
        args["pattern"],
        args.get("glob"),
        bool(args.get("ignore_case", False)),
        bool(args.get("fixed_strings", False)),
        int(args.get("context", 0)),
    )
    limit = min(int(args.get("limit", DEFAULT_GREP_LINES)), MAX_GREP_LINES)
    output = _capped(lines, limit, "matches", "total_lines")
    return {**_header(checkout, sha), **output, "matches": "\n".join(output["matches"])}


@_json_tool
def repo_history(args):
    checkout, sha = _target(args)
    limit = min(int(args.get("limit", DEFAULT_HISTORY_COMMITS)), MAX_HISTORY_COMMITS)
    commits = LIBRARY.history(
        checkout,
        sha,
        limit,
        args.get("query"),
        args.get("pickaxe"),
        args.get("path"),
        args.get("author"),
        args.get("since"),
        args.get("until"),
    )
    for commit in commits:
        commit["body"] = commit["body"][:MAX_COMMIT_BODY_CHARACTERS]
    return {**_header(checkout, sha), "limit": limit, "commits": commits}


@_json_tool
def repo_show(args):
    checkout, sha = _target(args)
    text = LIBRARY.show(checkout, sha, args.get("path"))
    return {
        **_header(checkout, sha),
        "truncated": len(text) > MAX_SHOW_CHARACTERS,
        "content": text[:MAX_SHOW_CHARACTERS],
    }


def _schema(name: str, description: str, properties: dict, required: list[str]) -> dict:
    return {
        "name": name,
        "description": description,
        "parameters": {"type": "object", "properties": properties, "required": required},
    }


_REPO = {
    "type": "string",
    "description": "owner/repo (GitHub), host/org/repo, or a git URL on any forge: https://, http://, ssh://, "
    "or user@host:path. Private repositories use your git credentials and ssh agent. Cloned on first use.",
}
_REF = {
    "type": "string",
    "description": "Branch, tag or commit to read. Defaults to the remote's default branch.",
}
_PATH = {"type": "string", "description": "Path relative to the repository root."}

TOOLS = [
    (
        _schema(
            "repo_checkout",
            "Cache a remote git repository and return its local path, so read_file, search_files "
            "and terminal can work on it. Refreshes a stale cache. Reports the commit the cache is at.",
            {
                "repo": _REPO,
                "refresh": {
                    "type": "boolean",
                    "description": f"Fetch from the remote now instead of waiting for the {REFRESH_INTERVAL_SECONDS // 60} minute refresh interval.",
                },
            },
            ["repo"],
        ),
        repo_checkout,
    ),
    (
        _schema(
            "repo_list",
            "List the cached repositories with their local path, current commit and last fetch time.",
            {},
            [],
        ),
        repo_list,
    ),
    (
        _schema(
            "repo_read",
            "Read a file from a remote repository at a branch, tag or commit. Lines are numbered "
            "as `N|text`. Reports the commit read, so claims can cite it.",
            {
                "repo": _REPO,
                "path": _PATH,
                "ref": _REF,
                "start_line": {"type": "integer", "description": "First line to return (1-based)."},
                "end_line": {"type": "integer", "description": f"Last line to return. At most {MAX_READ_LINES} lines are returned."},
            },
            ["repo", "path"],
        ),
        repo_read,
    ),
    (
        _schema(
            "repo_files",
            "List a remote repository's files at a branch, tag or commit. Without `pattern` it lists "
            "one directory level (directories end in `/`). With `pattern` it lists every file under "
            "`directory` matching the glob, e.g. `**/*.py`.",
            {
                "repo": _REPO,
                "ref": _REF,
                "directory": {"type": "string", "description": "Directory to list. Defaults to the repository root."},
                "pattern": {
                    "type": "string",
                    "description": "Glob matched against paths relative to `directory`; `**` spans directories.",
                },
            },
            ["repo"],
        ),
        repo_files,
    ),
    (
        _schema(
            "repo_grep",
            "Search file contents in a remote repository at a branch, tag or commit (extended regex; "
            "use fixed_strings for literals). Results are `path:line:text`, with `-` replacing `:` on "
            "context lines. Searching an old revision of a large repository downloads its files first.",
            {
                "repo": _REPO,
                "pattern": {"type": "string", "description": "Regular expression to search for."},
                "ref": _REF,
                "glob": {"type": "string", "description": "Limit the search to paths matching this glob, e.g. `src/**/*.ts`."},
                "ignore_case": {"type": "boolean"},
                "fixed_strings": {"type": "boolean", "description": "Treat the pattern as a literal string."},
                "context": {"type": "integer", "description": "Lines of context around each match."},
                "limit": {"type": "integer", "description": f"Maximum output lines. Default {DEFAULT_GREP_LINES}, at most {MAX_GREP_LINES}."},
            },
            ["repo", "pattern"],
        ),
        repo_grep,
    ),
    (
        _schema(
            "repo_history",
            "Search a remote repository's commit history, newest first. `query` matches commit "
            "messages including their bodies, where the reason for a change usually sits. `pickaxe` "
            "finds commits that add or remove a string in the code. Combine with `path`, `author`, "
            "`since` and `until` to date a change; read the body of each candidate.",
            {
                "repo": _REPO,
                "ref": _REF,
                "query": {"type": "string", "description": "Case-insensitive regex matched against commit messages."},
                "pickaxe": {"type": "string", "description": "String whose addition or removal in the diff selects a commit."},
                "path": {"type": "string", "description": "Only commits touching this path."},
                "author": {"type": "string"},
                "since": {"type": "string", "description": "Date, e.g. `2026-01-01` or `3 months ago`."},
                "until": {"type": "string"},
                "limit": {"type": "integer", "description": f"Maximum commits. Default {DEFAULT_HISTORY_COMMITS}, at most {MAX_HISTORY_COMMITS}."},
            },
            ["repo"],
        ),
        repo_history,
    ),
    (
        _schema(
            "repo_show",
            "Show one commit of a remote repository: message, diffstat and patch. `ref` takes a "
            "commit, tag or branch. Use `path` to limit the patch to one file or directory.",
            {"repo": _REPO, "ref": _REF, "path": _PATH},
            ["repo", "ref"],
        ),
        repo_show,
    ),
]
