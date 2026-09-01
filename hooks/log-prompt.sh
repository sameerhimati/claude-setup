#!/usr/bin/env bash
# UserPromptSubmit: records typed slash commands, and a truncated prompt for clustering.
# The truncated text is what lets the 30-day audit find recurring asks that no skill covers.
# Local only, gitignored, never leaves the machine. Never blocks.
set -uo pipefail
# Eval runs drive real sessions and would otherwise land in the usage log they are
# meant to measure. eval.sh sets this.
[ -n "${CLAUDE_SKILL_EVAL:-}" ] && exit 0
LOG="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/state/skill-usage.jsonl"
mkdir -p "$(dirname "$LOG")" 2>/dev/null || exit 0
jq -c --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" '
  ((.prompt // "") | sub("^\\s+"; "")) as $t
  # The harness delivers task notifications, system reminders and command echoes through the
  # same event as a typed prompt. Logged, they read as demand the user never expressed, and
  # the audit clusters them into skills nobody asked for.
  | if ($t | test("^(<task-notification|<system-reminder|<command-name|<local-command|\\[SYSTEM NOTIFICATION)"))
    then empty else . end
  | (if ($t | test("^/[a-zA-Z0-9]"))
     then ($t | sub("^/"; "") | sub("\\s[\\s\\S]*$"; ""))
     else "" end) as $cmd
  | {
      ts:      $ts,
      source:  (if $cmd == "" then "prompt" else "typed" end),
      skill:   $cmd,
      session: (.session_id // ""),
      cwd:     (.cwd // ""),
      text:    ($t[0:200])
    }' >> "$LOG" 2>/dev/null || true
exit 0
