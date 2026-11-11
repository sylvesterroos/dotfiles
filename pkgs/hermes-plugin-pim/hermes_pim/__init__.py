"""Hermes plugin that reads mail, calendar and contacts."""

import shutil

from .proton import ProtonCalendar, ProtonContacts, ProtonMail, command_runner
from .tools import build_tools

PROTON_EXECUTABLE = "proton"


def proton_available() -> bool:
    return shutil.which(PROTON_EXECUTABLE) is not None


def register(ctx):
    run = command_runner(PROTON_EXECUTABLE)
    for schema, handler in build_tools(ProtonMail(run), ProtonCalendar(run), ProtonContacts(run)):
        ctx.register_tool(
            name=schema["name"],
            toolset="pim",
            schema=schema,
            handler=handler,
            check_fn=proton_available,
        )
