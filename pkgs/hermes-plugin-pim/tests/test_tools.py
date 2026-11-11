import json

import pytest

from hermes_pim.model import Contact, Event, MailQuery, Message, PimError, Thread, ThreadPage
from hermes_pim.tools import build_tools


class FakeMail:
    def __init__(self):
        self.queries = []

    def search(self, query: MailQuery) -> ThreadPage:
        self.queries.append(query)
        return ThreadPage(threads=[], page=query.page, has_more=False)

    def read(self, thread_id: str) -> Thread:
        if thread_id != "t1":
            raise PimError(f"no thread {thread_id}")
        message = Message("m1", "a@example.com", ["me@example.com"], "2026-11-09", "Hi", "Hello")
        return Thread("t1", "Hi", [message])


class FakeCalendar:
    def __init__(self):
        self.ranges = []

    def events(self, first_day, last_day, calendar):
        self.ranges.append((first_day, last_day, calendar))
        return [Event("e1", "Personal", "Dentist", "2026-11-10T14:00:00+01:00",
                      "2026-11-10T15:00:00+01:00", False, None, [])]


class FakeContacts:
    def search(self, text, limit):
        return [Contact("c1", "Jane Roe", ["jane@example.com"], [], None)]


@pytest.fixture
def mail():
    return FakeMail()


@pytest.fixture
def calendar():
    return FakeCalendar()


@pytest.fixture
def call(mail, calendar):
    handlers = {schema["name"]: handler for schema, handler in build_tools(mail, calendar, FakeContacts())}

    def invoke(name, **args):
        return json.loads(handlers[name](args))

    return invoke


def test_mail_search_passes_filters_as_a_neutral_query(call, mail):
    call("mail_search", sender="a@example.com", after="2026-11-01", unread_only=True)
    query = mail.queries[0]
    assert (query.folder, query.sender, query.after, query.unread_only, query.limit) == (
        "inbox", "a@example.com", "2026-11-01", True, 25)


def test_mail_search_rejects_a_malformed_date(call, mail):
    assert "YYYY-MM-DD" in call("mail_search", after="yesterday")["error"]
    assert mail.queries == []


def test_mail_search_rejects_an_oversized_page(call):
    assert "limit" in call("mail_search", limit=1000)["error"]


def test_backend_failures_return_as_error_json(call):
    assert call("mail_read", thread_id="gone")["error"] == "no thread gone"


def test_mail_read_returns_messages(call):
    assert call("mail_read", thread_id="t1")["messages"][0]["body"] == "Hello"


def test_calendar_events_requires_a_forward_range(call, calendar):
    assert "forward" in call("calendar_events", first_day="2026-11-10", last_day="2026-11-01")["error"]
    assert calendar.ranges == []


def test_calendar_events_requires_both_days(call):
    assert "first_day" in call("calendar_events", last_day="2026-11-10")["error"]


def test_calendar_events_returns_events(call, calendar):
    result = call("calendar_events", first_day="2026-11-10", last_day="2026-11-10", calendar="Personal")
    assert result["events"][0]["title"] == "Dentist"
    assert calendar.ranges == [("2026-11-10", "2026-11-10", "Personal")]


def test_contacts_search_returns_contacts(call):
    assert call("contacts_search", text="jane")["contacts"][0]["emails"] == ["jane@example.com"]
