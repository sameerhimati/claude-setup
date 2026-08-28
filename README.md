# claude-setup

Claude Code configuration: instructions, rules, hooks, and skills. The repo is the source of truth;
`~/.claude` links into it.

## Install

```bash
git clone git@github.com:sameerhimati/claude-setup.git ~/Code/claude-setup
cd ~/Code/claude-setup && ./scripts/install.sh
```

Requires `jq`. Run `./scripts/install.sh --dry-run` first to see what it would change.

The installer symlinks `skills/`, `agents/`, `hooks/`, and `rules/` entry by entry, copies `CLAUDE.md`
and `AGENTS.md`, and merges only the hooks block into `settings.json`. Anything already in `~/.claude`
is backed up rather than replaced. Re-running is safe.

`CLAUDE.md` is copied rather than symlinked because Claude Code skips a symlinked
`~/.claude/CLAUDE.md` in Cowork desktop sessions. Re-run the installer after editing it.

## Layout

| Path | Contents |
|---|---|
| `AGENTS.md` | Instructions every harness reads. Claude Code loads it via an import in `CLAUDE.md`. |
| `CLAUDE.md` | That import plus Claude Code specifics. Installed to `~/.claude/CLAUDE.md`. |
| `rules/` | Path-scoped rules, loaded only when Claude touches matching files. |
| `skills/` | Skills. `in-progress/` is not installed. |
| `hooks/` | Shell hooks. Registered in `settings.template.json`. |
| `evals/` | Trigger tests, one JSONL per skill. |
| `mcp/` | Stack-to-MCP mappings. Placeholders only, never keys. |
| `scripts/` | `install.sh`, `sync.sh`, `eval.sh`. |

## Hooks

| Hook | Event | Does |
|---|---|---|
| `block-dangerous.sh` | PreToolUse(Bash) | Blocks recursive force deletes, hard resets, force pushes, and dropped tables |
| `protect-secrets.sh` | PreToolUse(Edit/Write) | Blocks writes to `.env`, `.pem`, `.key`, `credentials`, `secrets/` |
| `log-skill.sh` | PreToolUse(Skill) | Appends model-invoked skill calls to `state/skill-usage.jsonl` |
| `log-prompt.sh` | UserPromptSubmit | Appends typed slash commands and truncated prompts to the same log |

The usage log is local, gitignored, and does not rotate. Session transcripts are pruned after about
30 days, so it is the only durable record of which skills actually fire.

## Skills

| Skill | Fires when |
|---|---|
| `session-kickoff` | Starting work, picking up where things left off |
| `session-handoff` | Wrapping up, "good to exit?", checking everything is committed |
| `claude-api` | Writing or debugging Claude API code, prompt caching, model choice |
| `deslop` | Prose reads machine-written, "sound more like me", "less like ChatGPT" |
| `office-hours` | Pressure-testing an idea before building it |
| `oss` | Making a repo public, checking it for secrets first |
| `writing-skills` | Writing or fixing a skill, or a skill that will not trigger |

A skill exists only if the model would not already do the thing. Twenty-two skills were measured
against eleven months of usage; the ones that had never fired all described default behavior — run
tests, search, debug, plan. They were removed rather than rewritten.

```bash
./scripts/eval.sh              # every skill
./scripts/eval.sh deslop       # one
./scripts/eval.sh --list       # cases, no model calls
```

Each skill has cases in `evals/<name>.jsonl`, at least one negative. Costs tokens: one short turn per
case, exploration tools blocked so the run stops at the routing decision.

## Measurement

Three layers, after [WikiSkill](https://arxiv.org/abs/2608.27454).

| Layer | Where | Read by |
|---|---|---|
| What happened | `~/.claude/state/skill-usage.jsonl` | the audit |
| What was learned | `wiki/patterns/*.md` | the audit only |
| What runs | `skills/*/SKILL.md` | every session |

The wiki is local, gitignored, and never installed. Nothing read while working should come from it:
in the paper's ablation, giving the working agent the knowledge base scored *below* giving it
nothing, while giving it only to the skill-editing pass scored well above both. `install.sh` refuses
to install a skill that references `wiki/`.

```bash
./scripts/audit.sh --stats     # what fired, what didn't
./scripts/audit.sh             # ...then propose changes
./scripts/wiki.sh add "title"  # record a pattern
```

The audit proposes and never edits. Apply one change at a time, then
`./scripts/wiki.sh log <skill> kept|reverted "<note>"`.
