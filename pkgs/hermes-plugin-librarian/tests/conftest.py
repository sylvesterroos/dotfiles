import subprocess
from pathlib import Path

import pytest

from hermes_librarian.repository import Library

REPO = "forge.test/acme/widget"


class Remote:
    def __init__(self, path: Path):
        self.path = path

    def git(self, *arguments: str) -> str:
        result = subprocess.run(
            ["git", *arguments], cwd=self.path, check=True, capture_output=True, text=True
        )
        return result.stdout.strip()

    def commit(self, subject: str, files: dict[str, str], body: str = "") -> str:
        for name, content in files.items():
            target = self.path / name
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text(content)
        self.git("add", "-A")
        messages = ["-m", subject] + (["-m", body] if body else [])
        self.git("commit", "--quiet", *messages)
        return self.git("rev-parse", "HEAD")


@pytest.fixture
def remote(tmp_path, monkeypatch) -> Remote:
    remotes = tmp_path / "remotes"
    environment = {
        "GIT_CONFIG_GLOBAL": "/dev/null",
        "GIT_CONFIG_SYSTEM": "/dev/null",
        "GIT_AUTHOR_NAME": "Ada",
        "GIT_AUTHOR_EMAIL": "ada@forge.test",
        "GIT_COMMITTER_NAME": "Ada",
        "GIT_COMMITTER_EMAIL": "ada@forge.test",
        "GIT_CONFIG_COUNT": "3",
        "GIT_CONFIG_KEY_0": f"url.file://{remotes}/.insteadOf",
        "GIT_CONFIG_VALUE_0": "https://forge.test/",
        "GIT_CONFIG_KEY_1": f"url.file://{remotes}/.insteadOf",
        "GIT_CONFIG_VALUE_1": "ssh://git@forge.test:2222/",
        "GIT_CONFIG_KEY_2": f"url.file://{remotes}/.insteadOf",
        "GIT_CONFIG_VALUE_2": "git@forge.test:",
    }
    for name, value in environment.items():
        monkeypatch.setenv(name, value)
    path = remotes / "acme" / "widget.git"
    path.mkdir(parents=True)
    repository = Remote(path)
    repository.git("init", "--quiet", "-b", "main")
    repository.git("config", "uploadpack.allowFilter", "true")
    repository.commit(
        "Add greeting",
        {"README.md": "widget\n", "src/app.py": "def hello():\n    return 'hello there'\n"},
    )
    repository.git("tag", "v1")
    repository.commit(
        "Shorten greeting",
        {"src/app.py": "def hello():\n    return 'hi'\n"},
        body="Reason: users found the long greeting noisy.",
    )
    return repository


@pytest.fixture
def library(tmp_path) -> Library:
    return Library(tmp_path / "cache")
