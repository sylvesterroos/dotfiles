"""Provider-neutral vocabulary of mail, calendar and contact data and the backend contracts."""

from dataclasses import dataclass, field
from typing import Protocol


class PimError(Exception):
    pass


@dataclass(frozen=True)
class MailQuery:
    folder: str
    sender: str | None
    subject: str | None
    text: str | None
    after: str | None
    before: str | None
    unread_only: bool
    limit: int
    page: int


@dataclass(frozen=True)
class ThreadSummary:
    id: str
    subject: str
    senders: list[str]
    recipients: list[str]
    date: str
    unread: bool
    starred: bool
    attachment_count: int


@dataclass(frozen=True)
class ThreadPage:
    threads: list[ThreadSummary]
    page: int
    has_more: bool


@dataclass(frozen=True)
class Message:
    id: str
    sender: str
    recipients: list[str]
    date: str
    subject: str
    body: str
    attachments: list[str] = field(default_factory=list)


@dataclass(frozen=True)
class Thread:
    id: str
    subject: str
    messages: list[Message]


@dataclass(frozen=True)
class Event:
    id: str
    calendar: str
    title: str
    start: str
    end: str
    all_day: bool
    location: str | None
    attendees: list[str]


@dataclass(frozen=True)
class Contact:
    id: str
    name: str
    emails: list[str]
    phones: list[str]
    organization: str | None


class MailBackend(Protocol):
    def search(self, query: MailQuery) -> ThreadPage: ...

    def read(self, thread_id: str) -> Thread: ...


class CalendarBackend(Protocol):
    def events(self, first_day: str, last_day: str, calendar: str | None) -> list[Event]: ...


class ContactsBackend(Protocol):
    def search(self, text: str, limit: int) -> list[Contact]: ...
