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

Populated in a later commit.
