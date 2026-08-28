---
name: session-kickoff
description: >-
  Starts a work session: reads the last handoff file, reviews git state, and builds a
  prioritized task queue. Use when starting work, opening a project, asking what to work on
  next, picking up where things left off, or asking where things stand.
allowed-tools: Read, Glob, Grep, Bash
---

# Session Kickoff

## Step 1: Gather Context

Read these in order (skip if they don't exist):
1. **session-handoff.md** — previous session's handoff (highest priority, has immediate context)
2. **roadmap.md** — project roadmap for pending items
3. Run `git log --oneline -5` for recent work
4. Run `git status` for uncommitted changes

If session-handoff.md exists, summarize what was done last time and what was recommended next. This is the starting point for planning.

## Step 2: Plan Mode Discussion

**Enter plan mode.** Before committing to any tasks, have a back-and-forth conversation with the user:

1. **Present what you see** — summarize last session's state, open threads, and what seems most important
2. **Ask clarifying questions** — what changed since last session? Any new priorities? Anything blocking?
3. **Propose direction** — suggest what the session should focus on and why
4. **Get alignment** — don't proceed to task definition until the user confirms the direction

This is a conversation, not a checklist. Stay in plan mode until there's clear agreement on what this session is about. Only then move to Step 3.

## Step 3: Define Task Queue

Break the user's input (or handoff recommendations + roadmap items) into discrete tasks. Each task must be:
- Completable in one focused pass
- Independently committable
- Describable in one sentence

Present as:

```
## Session Plan — [date]

### Context from Last Session
[1-2 sentences from session-handoff.md, or "Fresh start — no prior handoff"]

### Tasks
1. **[task]** — [one sentence] → `type/branch-name`
2. **[task]** — [one sentence] → `type/branch-name`
3. **[task]** — [one sentence] → `type/branch-name`

Ready to start #1?
```

## Step 4: Triage Tasks — Delegate or Conversational

For each task in the queue, decide and label:

- **Delegate-able** — independent execution, clear spec, no turn-by-turn judgment from Sameer needed. Examples: implement endpoint, refactor module, write tests, research sweep, codebase audit, find-all-usages.
- **Conversational** — needs Sameer's input mid-task, taste-driven, or *is* the conversation. Examples: /lint, /compile, /think, /learn, writing or editing prose, decision-making, anything where his voice matters turn-by-turn.

Why this matters: delegating conversational work to a subagent loses Sameer's input; running delegate-able work in main thread burns the context window. The triage decides which.

Present the labeled queue back and confirm before executing.

## Step 5: Execute

**Delegate-able tasks:** spawn a subagent with full context (goal, files involved, constraints, why it matters). Main thread is conductor — review the result, ask follow-ups, commit. Independent delegate-able tasks can run in parallel — send a single message with multiple Agent calls.

**Conversational tasks:** run in main thread. State what we're doing → plan briefly → implement → verify (/verify) → review (/review) → commit → report and move on.

Rules:
- Each task gets its own commit, regardless of where it ran
- For parallel subagents: kick them off together, then commit each result as it returns
- For main-thread tasks: never start next until current is committed
- If a task is bigger than expected, suggest splitting
- If scope creeps ("while we're here..."), note it for later, stay focused
- User can say "skip to task N", "add a task", or "delegate this one" at any time
