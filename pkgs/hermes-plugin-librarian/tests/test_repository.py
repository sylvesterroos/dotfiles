import shutil
import subprocess

import pytest

from hermes_librarian.repository import LibrarianError, parse_reference

from conftest import REPO


def _git(path, *arguments):
    return subprocess.run(
        ["git", *arguments], cwd=path, check=True, capture_output=True, text=True
    ).stdout.strip()


@pytest.mark.parametrize(
    "reference",
    [
        "acme/widget",
        "github.com/acme/widget",
        "https://github.com/acme/widget",
        "https://github.com/acme/widget.git",
        "git@github.com:acme/widget.git",
        "ssh://git@github.com/acme/widget",
    ],
)
def test_parse_reference_accepts_every_form_of_one_github_repository(reference):
    repository = parse_reference(reference)
    assert (repository.host, repository.segments) == ("github.com", ("acme", "widget"))


@pytest.mark.parametrize(
    ("reference", "host", "segments", "url"),
    [
        ("forge.test/acme/widget", "forge.test", ("acme", "widget"), "https://forge.test/acme/widget.git"),
        ("https://gitlab.com/group/sub/project.git", "gitlab.com", ("group", "sub", "project"), "https://gitlab.com/group/sub/project.git"),
        ("https://git.sr.ht/~sircmpwn/scdoc", "git.sr.ht", ("~sircmpwn", "scdoc"), "https://git.sr.ht/~sircmpwn/scdoc"),
        ("ssh://git@forge.test:2222/acme/widget.git", "forge.test", ("acme", "widget"), "ssh://git@forge.test:2222/acme/widget.git"),
        ("git@forge.test:acme/widget.git", "forge.test", ("acme", "widget"), "git@forge.test:acme/widget.git"),
        ("http://localhost:3000/acme/widget", "localhost", ("acme", "widget"), "http://localhost:3000/acme/widget"),
        ("http://bachus/acme/widget/", "bachus", ("acme", "widget"), "http://bachus/acme/widget"),
    ],
)
def test_parse_reference_keeps_the_transport_of_non_github_remotes(reference, host, segments, url):
    repository = parse_reference(reference)
    assert (repository.host, repository.segments, repository.url) == (host, segments, url)


@pytest.mark.parametrize(
    "reference",
    [
        "widget",
        "acme/../widget",
        "gitlab.com/../x/y",
        "",
        "file:///srv/git/widget",
        "ext::sh -c id",
        "-oProxyCommand=id@host.test:a/b",
        "https://github.com/acme/widget/tree/main/src",
        "https://github.com/acme/widget/blob/v1/README.md",
        "ssh://-oProxyCommand=id@host.test/a/b",
    ],
)
def test_parse_reference_rejects_unusable_references(reference):
    with pytest.raises(LibrarianError):
        parse_reference(reference)


@pytest.mark.parametrize(
    "reference",
    [REPO, "ssh://git@forge.test:2222/acme/widget.git", "git@forge.test:acme/widget.git"],
)
def test_checkout_clones_over_the_transport_the_reference_names(remote, library, reference):
    checkout = library.checkout(reference)
    assert checkout.path == library.root / "forge.test" / "acme" / "widget"
    assert (checkout.path / "src" / "app.py").exists()


def test_checkout_clones_once_and_reuses_the_cache(remote, library):
    first = library.checkout(REPO)
    second = library.checkout(REPO)
    assert (first.path / "src" / "app.py").exists()
    assert second.path == first.path
    assert second.warning is None


def test_refresh_brings_the_checkout_up_to_the_remote(remote, library):
    checkout = library.checkout(REPO)
    remote.commit("Add changelog", {"CHANGELOG.md": "v2\n"})
    library.checkout(REPO)
    assert not (checkout.path / "CHANGELOG.md").exists()
    library.checkout(REPO, refresh=True)
    assert (checkout.path / "CHANGELOG.md").exists()


def test_failed_refresh_serves_the_cache_with_a_warning(remote, library):
    checkout = library.checkout(REPO)
    shutil.rmtree(remote.path)
    again = library.checkout(REPO, refresh=True)
    assert again.path == checkout.path
    assert "refresh failed" in again.warning


def test_resolve_defaults_to_the_remote_head(remote, library):
    checkout = library.checkout(REPO)
    assert library.resolve(checkout, None) == remote.git("rev-parse", "HEAD")


def test_resolve_fetches_a_tag_created_after_the_clone(remote, library):
    checkout = library.checkout(REPO)
    sha = remote.commit("Release", {"RELEASE.txt": "2\n"})
    remote.git("tag", "v2")
    assert library.resolve(checkout, "v2") == sha


def test_resolve_rejects_unknown_and_option_like_revisions(remote, library):
    checkout = library.checkout(REPO)
    with pytest.raises(LibrarianError, match="unknown revision"):
        library.resolve(checkout, "v99")
    with pytest.raises(LibrarianError, match="invalid revision"):
        library.resolve(checkout, "--output=x")


def test_read_at_a_tag_leaves_the_cache_on_the_default_branch(remote, library):
    checkout = library.checkout(REPO)
    old = library.read(checkout, library.resolve(checkout, "v1"), "src/app.py", 1, None)
    assert "hello there" in old["content"]
    assert "'hi'" in (checkout.path / "src" / "app.py").read_text()


def test_read_numbers_lines_within_the_requested_range(remote, library):
    checkout = library.checkout(REPO)
    sha = library.resolve(checkout, None)
    excerpt = library.read(checkout, sha, "src/app.py", 2, 2)
    assert excerpt == {
        "total_lines": 2,
        "start_line": 2,
        "end_line": 2,
        "content": "2|    return 'hi'",
    }


def test_read_refuses_directories_and_paths_outside_the_repository(remote, library):
    checkout = library.checkout(REPO)
    sha = library.resolve(checkout, None)
    with pytest.raises(LibrarianError, match="tree"):
        library.read(checkout, sha, "src", 1, None)
    with pytest.raises(LibrarianError, match="relative"):
        library.read(checkout, sha, "../etc/passwd", 1, None)


def test_files_lists_one_level_with_directory_markers(remote, library):
    checkout = library.checkout(REPO)
    sha = library.resolve(checkout, None)
    assert library.files(checkout, sha, "", None) == ["README.md", "src/"]
    assert library.files(checkout, sha, "src", None) == ["app.py"]


def test_files_filters_a_whole_tree_by_glob(remote, library):
    checkout = library.checkout(REPO)
    sha = library.resolve(checkout, None)
    assert library.files(checkout, sha, "", "**/*.py") == ["src/app.py"]
    assert library.files(checkout, sha, "src", "*.md") == []


def test_grep_reports_path_and_line_at_the_requested_revision(remote, library):
    checkout = library.checkout(REPO)
    old = library.resolve(checkout, "v1")
    assert library.grep(checkout, old, "hello there", None, False, True, 0) == [
        "src/app.py:2:    return 'hello there'"
    ]
    assert library.grep(checkout, old, "HELLO", "src/**", True, True, 0) == [
        "src/app.py:1:def hello():",
        "src/app.py:2:    return 'hello there'",
    ]
    assert library.grep(checkout, old, "absent", None, False, True, 0) == []


def test_grep_rejects_an_invalid_pattern(remote, library):
    checkout = library.checkout(REPO)
    sha = library.resolve(checkout, None)
    with pytest.raises(LibrarianError):
        library.grep(checkout, sha, "(", None, False, False, 0)


def test_history_matches_the_commit_body(remote, library):
    checkout = library.checkout(REPO)
    sha = library.resolve(checkout, None)
    commits = library.history(checkout, sha, 10, "noisy", None, None, None, None, None)
    assert [commit["subject"] for commit in commits] == ["Shorten greeting"]
    assert "long greeting noisy" in commits[0]["body"]


def test_history_pickaxe_finds_the_commit_that_removed_a_string(remote, library):
    checkout = library.checkout(REPO)
    sha = library.resolve(checkout, None)
    commits = library.history(checkout, sha, 10, None, "hello there", None, None, None, None)
    assert [commit["subject"] for commit in commits] == ["Shorten greeting", "Add greeting"]


def test_history_limits_to_a_path(remote, library):
    checkout = library.checkout(REPO)
    sha = library.resolve(checkout, None)
    commits = library.history(checkout, sha, 10, None, None, "README.md", None, None, None)
    assert [commit["subject"] for commit in commits] == ["Add greeting"]


def test_show_renders_a_patch_despite_an_external_diff_driver(remote, library, monkeypatch):
    monkeypatch.setenv("GIT_EXTERNAL_DIFF", "false")
    checkout = library.checkout(REPO)
    sha = library.resolve(checkout, None)
    shown = library.show(checkout, sha, "src/app.py")
    assert "Shorten greeting" in shown
    assert "-    return 'hello there'" in shown


def test_cached_lists_each_repository_with_its_commit(remote, library):
    checkout = library.checkout(REPO)
    [entry] = library.cached()
    assert entry["repo"] == "forge.test/acme/widget"
    assert entry["path"] == str(checkout.path)
    assert remote.git("rev-parse", "HEAD").startswith(entry["commit"])


def test_resolve_prefers_the_remote_branch_over_a_stale_local_one(remote, library):
    checkout = library.checkout(REPO)
    (checkout.path / "README.md").write_text("local edit\n")
    sha = remote.commit("Add changelog", {"CHANGELOG.md": "v2\n"})
    refreshed = library.checkout(REPO, refresh=True)
    assert library.resolve(refreshed, "main") == sha


def test_refresh_reports_a_working_tree_it_cannot_fast_forward(remote, library):
    checkout = library.checkout(REPO)
    (checkout.path / "README.md").write_text("local edit\n")
    remote.commit("Add changelog", {"CHANGELOG.md": "v2\n"})
    refreshed = library.checkout(REPO, refresh=True)
    assert "local changes" in refreshed.warning


def test_checkout_follows_the_transport_of_the_latest_reference(remote, library):
    library.checkout(REPO)
    checkout = library.checkout("git@forge.test:acme/widget.git")
    url = _git(checkout.path, "config", "remote.origin.url")
    assert url == "git@forge.test:acme/widget.git"


def test_read_numbers_lines_by_newline_only(remote, library):
    remote.commit("Add form feed", {"form.txt": "a\x0cb\nc\r\nd\n"})
    checkout = library.checkout(REPO, refresh=True)
    sha = library.resolve(checkout, None)
    excerpt = library.read(checkout, sha, "form.txt", 1, None)
    assert excerpt["total_lines"] == 3
    assert excerpt["content"] == "1|a\x0cb\n2|c\n3|d"
