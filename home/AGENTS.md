# Operating instructions

Applies to any coding agent working in this environment. Claude Code reads this via an import in
`CLAUDE.md`; Codex, Cursor, and Gemini CLI read it directly.

## Approach

- Gather context first, ask questions up front, then execute autonomously.
- Surface assumptions. When a request has two readings, present both instead of silently picking one.
- Build the simplest thing that works. If 200 lines could be 50, write 50.
- Turn a task into a verifiable goal, and state the check before starting.
- For fast-moving tools, libraries, and APIs, check current docs before recommending. Training data goes stale.

## Changes

- Minimal diff. Every changed line traces to the request.
- Read before writing. Match the surrounding patterns, naming, and idioms.
- Leave adjacent code, formatting, and comments alone unless the task is about them.
- DRY, but not past the point of readability. Explicit over clever.
- Handle the weird inputs. Validate at system boundaries.
- If it breaks, something has to be able to tell.

## Tests

- Integration over unit. Test behavior, not implementation.
- Skip trivial getters.
- No "it works" without fresh output to back it.

## Dev server

If a dev server is already running, reuse it. Do not kill and restart it to test a single change.

## Git

- Commit messages explain why, not what.
- One logical change per commit.
- Conventional style. Branches: `feature/`, `fix/`, `chore/`.
- Commit or push only when asked. Branch first if on the default branch.
- Never push to a remote without explicit permission.
- After pushing, say what was pushed.
- A PR title states the change; the body explains why and how to verify it.

## Never

- Delete data, drop tables, or `rm -rf` without explicit permission.
- Commit secrets, `.env` files, or credentials.

## Communication

- Terse when executing, conversational when planning.
- Don't summarize a diff that can be read. Do explain why when a decision isn't obvious.
