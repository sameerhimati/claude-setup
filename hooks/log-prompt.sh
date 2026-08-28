#!/usr/bin/env bash
# UserPromptSubmit: records typed slash commands, and a truncated prompt for clustering.
# The truncated text is what lets the 30-day audit find recurring asks that no skill covers.
# Local only, gitignored, never leaves the machine. Never blocks.
set -uo pipefail
LOG="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/state/skill-usage.jsonl"
mkdir -p "$(dirname "$LOG")" 2>/dev/null || exit 0
jq -c --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" '
  ((.prompt // "") | sub("^\\s+"; "")) as $t
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
