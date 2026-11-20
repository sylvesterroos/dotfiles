import json

import pytest

from hermes_pim.model import Contact, Event, EventChange, EventDraft, MailQuery, Message, PimError, Thread, ThreadPage
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
        self.created = []
        self.updated = []
        self.deleted = []

    def create(self, draft):
        self.created.append(draft)
        return "cal/e2"

    def update(self, event_id, change):
        self.updated.append((event_id, change))

    def delete(self, event_id):
        if event_id != "cal/e1":
            raise PimError(f"no event {event_id}")
        self.deleted.append(event_id)

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


def test_calendar_create_passes_a_neutral_draft(call, calendar):
    result = call("calendar_create", title="Dentist", start="2027-05-13T12:30", location="Main Street 1")
    assert result == {"id": "cal/e2"}
    assert calendar.created == [EventDraft(None, "Dentist", "2027-05-13T12:30", None, "Main Street 1", None)]


def test_calendar_create_rejects_a_malformed_start(call, calendar):
    assert "YYYY-MM-DDTHH:MM" in call("calendar_create", title="Dentist", start="13-05-2027 12:30")["error"]
    assert calendar.created == []


def test_calendar_update_passes_only_given_fields(call, calendar):
    call("calendar_update", event_id="cal/e1", location="")
    assert calendar.updated == [("cal/e1", EventChange(None, None, None, "", None))]


def test_calendar_update_requires_a_field(call, calendar):
    assert "at least one" in call("calendar_update", event_id="cal/e1")["error"]
    assert calendar.updated == []


def test_calendar_delete_removes_the_event(call, calendar):
    assert call("calendar_delete", event_id="cal/e1") == {"deleted": "cal/e1"}
    assert calendar.deleted == ["cal/e1"]


def test_calendar_delete_reports_an_unknown_event(call):
    assert call("calendar_delete", event_id="gone")["error"] == "no event gone"
