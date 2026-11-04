"""Hermes plugin that reads cached remote git repositories at any revision."""

from .tools import TOOLS, git_available


def register(ctx):
    for schema, handler in TOOLS:
        ctx.register_tool(
            name=schema["name"],
            toolset="librarian",
            schema=schema,
            handler=handler,
            check_fn=git_available,
        )
