import json

import pytest

from hermes_librarian import tools

from conftest import REPO


@pytest.fixture(autouse=True)
def isolated_library(library, monkeypatch):
    monkeypatch.setattr(tools, "LIBRARY", library)


def test_repo_read_returns_numbered_lines_and_the_commit_read(remote):
    result = json.loads(tools.repo_read({"repo": REPO, "path": "src/app.py", "ref": "v1"}))
    assert result["commit"] == remote.git("rev-parse", "--short=12", "v1")
    assert result["content"].splitlines()[0] == "1|def hello():"


def test_handlers_report_failures_as_error_json(remote):
    result = json.loads(tools.repo_read({"repo": REPO, "path": "missing.py"}))
    assert "does not exist" in result["error"]


def test_repo_checkout_returns_the_cache_path(remote, library):
    result = json.loads(tools.repo_checkout({"repo": REPO}))
    assert result["path"] == str(library.root / "forge.test" / "acme" / "widget")


def test_repo_files_reports_when_a_listing_is_truncated(remote, monkeypatch):
    monkeypatch.setattr(tools, "MAX_LISTED_FILES", 1)
    result = json.loads(tools.repo_files({"repo": REPO, "directory": "", "pattern": "**/*"}))
    assert (result["total"], result["truncated"], len(result["entries"])) == (2, True, 1)


def test_repo_history_clips_long_commit_bodies(remote, monkeypatch):
    monkeypatch.setattr(tools, "MAX_COMMIT_BODY_CHARACTERS", 6)
    result = json.loads(tools.repo_history({"repo": REPO, "query": "noisy"}))
    assert result["commits"][0]["body"] == "Reason"
