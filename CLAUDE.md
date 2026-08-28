@AGENTS.md

## Claude Code

### Skills

Skills fire because their `description` matches the request, not because a slash command gets typed.
Do not expect to be routed to a skill by this file; if a skill needs routing help here, its
description is broken.

### Hooks

Hooks are enforcement; this file and skills are advice. Anything that must happen every time without
exception belongs in a hook, not here.

Registered: `block-dangerous.sh` (blocks `rm -rf`, `git reset --hard`, force pushes, `DROP TABLE`),
`protect-secrets.sh` (blocks writes to `.env`, `.pem`, `.key`, `credentials`, `secrets/`),
`log-skill.sh` and `log-prompt.sh` (usage telemetry to `state/skill-usage.jsonl`).

### Memory

Auto memory under `projects/<project>/memory/` is written by Claude. This file is written by the user.
Don't duplicate one into the other, and don't record here what the code or git history already says.

### Sessions

Starting and ending a session are the two moments worth ritualizing. Everything else is ordinary work.
