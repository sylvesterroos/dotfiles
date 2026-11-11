import json
import stat
from pathlib import Path

import pytest

from hermes_pim.model import MailQuery, PimError
from hermes_pim.proton import ProtonCalendar, ProtonContacts, ProtonMail, command_runner

FIXTURES = Path(__file__).parent / "fixtures"


def fixture(name):
    return json.loads((FIXTURES / name).read_text())


class RecordingRun:
    def __init__(self, **responses):
        self.responses = responses
        self.calls = []

    def __call__(self, arguments):
        self.calls.append(arguments)
        return self.responses[" ".join(arguments[:3])]


QUERY = MailQuery("inbox", None, None, None, None, None, False, 25, 0)


def test_mail_search_builds_cli_filters():
    run = RecordingRun(**{"mail conversations list": fixture("conversations_list.json")})
    query = MailQuery("all", "a@example.com", "invoice", "tax", "2026-11-01", "2026-11-30", True, 10, 2)
    ProtonMail(run).search(query)
    assert run.calls == [[
        "mail", "conversations", "list", "--folder", "all", "--from", "a@example.com",
        "--subject", "invoice", "--keyword", "tax", "--after", "2026-11-01",
        "--before", "2026-11-30", "--unread", "--page-size", "10", "--page", "2",
    ]]


def test_mail_search_maps_a_thread_summary():
    run = RecordingRun(**{"mail conversations list": fixture("conversations_list.json")})
    page = ProtonMail(run).search(QUERY)
    thread = page.threads[0]
    assert (thread.id, thread.subject, thread.senders, thread.recipients) == (
        "conv1", "Your invoice", ["billing@shop.example"], ["me@pm.example"])
    assert (thread.unread, thread.starred, thread.attachment_count) == (True, True, 1)
    assert thread.date.startswith("2026-11-")
    assert (page.page, page.has_more) == (0, True)


def test_mail_read_maps_messages_and_strips_quotes():
    run = RecordingRun(**{"mail conversations get": fixture("conversations_get.json")})
    thread = ProtonMail(run).read("conv1")
    assert run.calls == [["mail", "conversations", "get", "conv1", "--strip-quotes"]]
    message = thread.messages[0]
    assert (message.sender, message.recipients, message.body, message.attachments) == (
        "billing@shop.example", ["me@pm.example", "cc@example.com"], "Invoice attached.", ["invoice.pdf"])


def test_calendar_events_name_their_calendar():
    run = RecordingRun(**{
        "calendar settings calendars": fixture("calendars_list.json"),
        "calendar events list": fixture("events_list.json"),
    })
    events = ProtonCalendar(run).events("2026-11-10", "2026-11-10", "Personal")
    assert run.calls[1] == ["calendar", "events", "list", "--start", "2026-11-10",
                            "--end", "2026-11-10", "--calendar", "Personal"]
    assert [(e.calendar, e.title, e.location, e.all_day) for e in events] == [
        ("Personal", "Dentist", "Main Street 1", False), ("Holidays", "Holiday", None, True)]
    assert events[0].attendees == ["a@example.com"]


def test_contacts_drop_the_phone_type_prefix():
    run = RecordingRun(**{"contacts list --keyword": fixture("contacts_list.json")})
    [contact] = ProtonContacts(run).search("jane", 5)
    assert run.calls == [["contacts", "list", "--keyword", "jane", "--page-size", "5"]]
    assert (contact.name, contact.emails, contact.phones, contact.organization) == (
        "Jane Roe", ["jane@example.com"], ["+31600000000", "+31611111111"], "Roe Dental")


def executable(tmp_path, script):
    path = tmp_path / "proton"
    path.write_text("#!/bin/sh\n" + script)
    path.chmod(path.stat().st_mode | stat.S_IEXEC)
    return str(path)


def test_runner_passes_json_flags_and_parses_output(tmp_path):
    run = command_runner(executable(tmp_path, 'printf \'{"args": "%s"}\' "$*"'))
    assert run(["mail", "list"]) == {"args": "--output json --no-input mail list"}


def test_runner_reports_the_cli_error(tmp_path):
    run = command_runner(executable(tmp_path, 'echo \'Error: No conversation matching "x".\' >&2; exit 3'))
    with pytest.raises(PimError, match='No conversation matching "x"'):
        run(["mail", "conversations", "get", "x"])
