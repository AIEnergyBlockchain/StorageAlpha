"""ASGI entrypoint for running the DR Agent FastAPI gateway."""

from services.api import app

__all__ = ["app"]
