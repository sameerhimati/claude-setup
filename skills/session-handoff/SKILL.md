---
name: session-handoff
description: >-
  Ends a work session and writes a handoff for the next one: what got done, current state,
  blockers, and the next action. Use when wrapping up, asking whether it is safe or good to
  exit, checking everything is committed and pushed, or saying that is enough for today.
---

# Session Handoff

## Steps
1. Run `git log --oneline -10`
2. Run `git status`
3. Run `git branch --show-current`
4. Run build/test command if known
5. Read roadmap.md if it exists
6. Read existing session-handoff.md if it exists (to preserve history context)

## Plan Mode Discussion

**Enter plan mode before writing the handoff.** Have a back-and-forth conversation with the user:

1. **Reflect on the session** — what actually got done vs what was planned? What surprised us?
2. **Surface open questions** — anything unresolved that the next session needs to address?
3. **Discuss next session priorities** — don't just list tasks, discuss what matters most and why. Get the user's input on ordering.
4. **Capture non-obvious context** — decisions made, things that almost broke, context that would take time to rediscover

Only write the handoff file after this conversation. The discussion ensures the handoff captures what actually matters, not just a mechanical dump of git state.

## Write to session-handoff.md

**CRITICAL: If session-handoff.md already exists, OVERWRITE it. Do NOT create session-handoff-2.md or any variant. One file, always updated in place.**

Use the Write tool (or Edit tool if updating specific sections) to write `session-handoff.md` in the project root:

```markdown
# Session Handoff
> Last updated: [date and time]

## Completed This Session
- [x] [from git log — what was done this session]

## Current State
- **Branch:** [current branch]
- **Last commit:** [hash + message]
- **Build:** [passing/failing/unknown]
- **Uncommitted changes:** [yes/no — list files if yes]
- **Blockers:** [any blockers or "none"]

## Next Session Should
1. **Opening gambit:** [specific first move — file to open + exact action. Not "continue the billing work" but "Open src/billing/invoice.ts, finish the proration branch"]
2. [second priority]
3. [additional items from roadmap]

## Context to Remember
- [architectural decisions made and why]
- [gotchas discovered during this session]
- [things that almost broke or were tricky]
- [dependencies or external setup that was done]

## Start Command
`[specific command to resume work, e.g. "cd api && source venv/bin/activate && uvicorn app.main:app --reload"]`
```

## Rules
- Always write to `session-handoff.md` in the project root
- If the file exists, replace its contents entirely — do not append or create duplicates
- "Next Session Should #1" must be a concrete opening gambit (file + action) so the handoff functions as a cold-start prompt at kickoff. Items 2+ can be looser.
- "Context to Remember" is the most valuable section — capture things that would take time to re-discover
- Keep it concise. This is a handoff, not a diary.
