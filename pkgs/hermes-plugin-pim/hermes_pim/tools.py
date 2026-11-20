"""Tool schemas the model reads and the handlers that run them against backends."""

import json
from collections.abc import Callable
from dataclasses import asdict
from datetime import date, datetime

from .model import (
    CalendarBackend,
    ContactsBackend,
    EventChange,
    EventDraft,
    MailBackend,
    MailQuery,
    PimError,
)

DEFAULT_LIMIT = 25
MAX_LIMIT = 100
MAX_EVENT_SPAN_DAYS = 366


def _json_tool(function: Callable[[dict], dict]) -> Callable[..., str]:
    def handler(args: dict, **kwargs) -> str:
        try:
            return json.dumps(function(args))
        except PimError as error:
            return json.dumps({"error": str(error)})

    return handler


def _day(args: dict, key: str, required: bool = False) -> str | None:
    value = args.get(key)
    if value is None and not required:
        return None
    try:
        return date.fromisoformat(value).isoformat()
    except (TypeError, ValueError):
        raise PimError(f"{key} must be a date as YYYY-MM-DD, got {value!r}") from None


def _moment(args: dict, key: str, required: bool = False) -> str | None:
    value = args.get(key)
    if value is None and not required:
        return None
    try:
        if isinstance(value, str) and "T" in value:
            return datetime.strptime(value, "%Y-%m-%dT%H:%M").strftime("%Y-%m-%dT%H:%M")
        return date.fromisoformat(value).isoformat()
    except (TypeError, ValueError):
        raise PimError(f"{key} must be YYYY-MM-DD or YYYY-MM-DDTHH:MM, got {value!r}") from None


def _limit(args: dict) -> int:
    limit = int(args.get("limit", DEFAULT_LIMIT))
    if not 1 <= limit <= MAX_LIMIT:
        raise PimError(f"limit must be between 1 and {MAX_LIMIT}")
    return limit


def _schema(name: str, description: str, properties: dict, required: list[str]) -> dict:
    return {
        "name": name,
        "description": description,
        "parameters": {"type": "object", "properties": properties, "required": required},
    }


_DAY = "Date as YYYY-MM-DD."
_MOMENT = (
    "Local time as YYYY-MM-DDTHH:MM, or a date as YYYY-MM-DD for an all-day event."
)
_LIMIT = f"Results per page, 1 to {MAX_LIMIT}. Default {DEFAULT_LIMIT}."


def build_tools(
    mail: MailBackend, calendar: CalendarBackend, contacts: ContactsBackend
) -> list[tuple[dict, Callable[..., str]]]:
    @_json_tool
    def mail_search(args):
        query = MailQuery(
            folder=args.get("folder", "inbox"),
            sender=args.get("sender"),
            subject=args.get("subject"),
            text=args.get("text"),
            after=_day(args, "after"),
            before=_day(args, "before"),
            unread_only=bool(args.get("unread_only", False)),
            limit=_limit(args),
            page=int(args.get("page", 0)),
        )
        return asdict(mail.search(query))

    @_json_tool
    def mail_read(args):
        return asdict(mail.read(args["thread_id"]))

    @_json_tool
    def calendar_events(args):
        first, last = _day(args, "first_day", True), _day(args, "last_day", True)
        span = (date.fromisoformat(last) - date.fromisoformat(first)).days
        if not 0 <= span < MAX_EVENT_SPAN_DAYS:
            raise PimError(
                f"the range must run forward and cover at most {MAX_EVENT_SPAN_DAYS} days"
            )
        events = calendar.events(first, last, args.get("calendar"))
        return {"events": [asdict(event) for event in events]}

    @_json_tool
    def calendar_create(args):
        draft = EventDraft(
            calendar=args.get("calendar"),
            title=args["title"],
            start=_moment(args, "start", True),
            end=_moment(args, "end"),
            location=args.get("location"),
            description=args.get("description"),
        )
        return {"id": calendar.create(draft)}

    @_json_tool
    def calendar_update(args):
        change = EventChange(
            title=args.get("title"),
            start=_moment(args, "start"),
            end=_moment(args, "end"),
            location=args.get("location"),
            description=args.get("description"),
        )
        if all(value is None for value in vars(change).values()):
            raise PimError("give at least one field to change")
        calendar.update(args["event_id"], change)
        return {"id": args["event_id"]}

    @_json_tool
    def calendar_delete(args):
        calendar.delete(args["event_id"])
        return {"deleted": args["event_id"]}

    @_json_tool
    def contacts_search(args):
        found = contacts.search(args["text"], _limit(args))
        return {"contacts": [asdict(contact) for contact in found]}

    return [
        (
            _schema(
                "mail_search",
                "Search mail threads, newest first. Every filter given must match. "
                "Returns thread summaries; read a thread with mail_read.",
                {
                    "folder": {
                        "type": "string",
                        "description": "Folder or label name, or 'all'. Default 'inbox'.",
                    },
                    "sender": {"type": "string", "description": "Sender address."},
                    "subject": {"type": "string", "description": "Text in the subject."},
                    "text": {"type": "string", "description": "Text anywhere in the thread."},
                    "after": {"type": "string", "description": _DAY},
                    "before": {"type": "string", "description": _DAY},
                    "unread_only": {"type": "boolean", "description": "Only unread threads."},
                    "limit": {"type": "integer", "description": _LIMIT},
                    "page": {"type": "integer", "description": "Page number from 0."},
                },
                [],
            ),
            mail_search,
        ),
        (
            _schema(
                "mail_read",
                "Read a whole mail thread, decrypted, with quoted replies removed.",
                {"thread_id": {"type": "string", "description": "Id from mail_search."}},
                ["thread_id"],
            ),
            mail_read,
        ),
        (
            _schema(
                "calendar_events",
                "List calendar events in a range of whole days, both ends included. "
                "Each occurrence of a recurring event appears on its own day.",
                {
                    "first_day": {"type": "string", "description": _DAY},
                    "last_day": {"type": "string", "description": _DAY},
                    "calendar": {
                        "type": "string",
                        "description": "Calendar name. Default: all calendars.",
                    },
                },
                ["first_day", "last_day"],
            ),
            calendar_events,
        ),
        (
            _schema(
                "calendar_create",
                "Create a calendar event. Without an end the event lasts the calendar's "
                "default duration.",
                {
                    "title": {"type": "string", "description": "Event title."},
                    "start": {"type": "string", "description": _MOMENT},
                    "end": {
                        "type": "string",
                        "description": "End, in the same form as start. For an all-day "
                        "event, the last day it runs through.",
                    },
                    "location": {"type": "string", "description": "Where it is."},
                    "description": {"type": "string", "description": "Event notes."},
                    "calendar": {
                        "type": "string",
                        "description": "Calendar name. Default: the first calendar.",
                    },
                },
                ["title", "start"],
            ),
            calendar_create,
        ),
        (
            _schema(
                "calendar_update",
                "Change fields of an existing event; omitted fields stay as they are. "
                "An empty string clears location or description.",
                {
                    "event_id": {"type": "string", "description": "Id from calendar_events."},
                    "title": {"type": "string", "description": "New title."},
                    "start": {
                        "type": "string",
                        "description": _MOMENT + " A date alone moves the event and keeps its time.",
                    },
                    "end": {"type": "string", "description": "New end, in the form of start."},
                    "location": {"type": "string", "description": "New location."},
                    "description": {"type": "string", "description": "New notes."},
                },
                ["event_id"],
            ),
            calendar_update,
        ),
        (
            _schema(
                "calendar_delete",
                "Permanently delete an event.",
                {"event_id": {"type": "string", "description": "Id from calendar_events."}},
                ["event_id"],
            ),
            calendar_delete,
        ),
        (
            _schema(
                "contacts_search",
                "Find contacts by text in the name or an address.",
                {
                    "text": {"type": "string", "description": "Text to match."},
                    "limit": {"type": "integer", "description": _LIMIT},
                },
                ["text"],
            ),
            contacts_search,
        ),
    ]
