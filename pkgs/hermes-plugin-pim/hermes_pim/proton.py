"""Backends that read Proton Mail, Calendar and Contacts through the `proton` command line."""

import json
import subprocess
from collections.abc import Callable
from datetime import datetime

from .model import (
    Contact,
    Event,
    Message,
    MailQuery,
    PimError,
    Thread,
    ThreadPage,
    ThreadSummary,
)

Run = Callable[[list[str]], dict]


def command_runner(executable: str) -> Run:
    def run(arguments: list[str]) -> dict:
        result = subprocess.run(
            [executable, "--output", "json", "--no-input", *arguments],
            capture_output=True,
            text=True,
        )
        if result.returncode != 0:
            raise PimError(result.stderr.strip().removeprefix("Error: "))
        return json.loads(result.stdout)

    return run


def _iso(epoch: int) -> str:
    return datetime.fromtimestamp(epoch).astimezone().isoformat()


def _addresses(people: list[dict]) -> list[str]:
    return [person["Address"] for person in people]


class ProtonMail:
    def __init__(self, run: Run):
        self._run = run

    def search(self, query: MailQuery) -> ThreadPage:
        filters = {
            "--folder": query.folder,
            "--from": query.sender,
            "--subject": query.subject,
            "--keyword": query.text,
            "--after": query.after,
            "--before": query.before,
        }
        arguments = ["mail", "conversations", "list"]
        for flag, value in filters.items():
            if value is not None:
                arguments += [flag, value]
        if query.unread_only:
            arguments.append("--unread")
        arguments += ["--page-size", str(query.limit), "--page", str(query.page)]
        listing = self._run(arguments)
        return ThreadPage(
            threads=[self._summary(item) for item in listing["conversations"]],
            page=listing["page"],
            has_more=listing["has_more"],
        )

    def read(self, thread_id: str) -> Thread:
        thread = self._run(["mail", "conversations", "get", thread_id, "--strip-quotes"])
        return Thread(
            id=thread["conversation"]["id"],
            subject=thread["conversation"]["subject"],
            messages=[self._message(item) for item in thread["messages"]],
        )

    @staticmethod
    def _summary(item: dict) -> ThreadSummary:
        return ThreadSummary(
            id=item["id"],
            subject=item["subject"],
            senders=_addresses(item["senders"]),
            recipients=_addresses(item["recipients"]),
            date=_iso(item["time"]),
            unread=item["num_unread"] > 0,
            starred=STARRED_LABEL in item["labels"],
            attachment_count=item["num_attachments"],
        )

    @staticmethod
    def _message(item: dict) -> Message:
        return Message(
            id=item["id"],
            sender=item["from"]["Address"],
            recipients=_addresses(item["to"] + item["cc"]),
            date=_iso(item["time"]),
            subject=item["subject"],
            body=item["body"],
            attachments=[attachment["name"] for attachment in item["attachments"]],
        )


STARRED_LABEL = "10"


class ProtonCalendar:
    def __init__(self, run: Run):
        self._run = run

    def events(self, first_day: str, last_day: str, calendar: str | None) -> list[Event]:
        names = {item["id"]: item["name"] for item in self._run(
            ["calendar", "settings", "calendars", "list"])["calendars"]}
        arguments = ["calendar", "events", "list", "--start", first_day, "--end", last_day]
        if calendar is not None:
            arguments += ["--calendar", calendar]
        return [
            Event(
                id=item["id"],
                calendar=names[item["calendar_id"]],
                title=item["title"],
                start=item["start"],
                end=item["end"],
                all_day=item["all_day"],
                location=item.get("location") or None,
                attendees=item["attendees"],
            )
            for item in self._run(arguments)["events"]
        ]


class ProtonContacts:
    def __init__(self, run: Run):
        self._run = run

    def search(self, text: str, limit: int) -> list[Contact]:
        listing = self._run(
            ["contacts", "list", "--keyword", text, "--page-size", str(limit)]
        )
        return [
            Contact(
                id=item["id"],
                name=item["name"],
                emails=item["emails"],
                phones=[phone.rpartition(":")[2] for phone in item["phones"]],
                organization=item.get("org"),
            )
            for item in listing["contacts"]
        ]
