---
description: Python/FastAPI conventions. Scoped to Python repos.
paths:
  - "**/pyproject.toml"
  - "**/requirements.txt"
  - "**/*.py"
---

# Python / FastAPI

- FastAPI + Pydantic v2. Models define the contract — validate at boundaries.
- Async endpoints and async DB access; don't block the event loop.
- Typer for CLIs. DuckDB/SQLite for analytics, Postgres for prod.
- Clear layering (routers / services / models): thin routers, logic in services.
- pytest; integration over unit.
