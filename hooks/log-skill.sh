#!/usr/bin/env bash
# PreToolUse(Skill): records every model-initiated skill invocation.
# Transcripts rotate after ~30 days; this log does not.
# Never blocks and never fails a tool call.
set -uo pipefail
# Eval runs drive real sessions and would otherwise land in the usage log they are
# meant to measure. eval.sh sets this.
[ -n "${CLAUDE_SKILL_EVAL:-}" ] && exit 0
LOG="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/state/skill-usage.jsonl"
mkdir -p "$(dirname "$LOG")" 2>/dev/null || exit 0
jq -c --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" '{
  ts:      $ts,
  source:  "auto",
  skill:   (.tool_input.skill // ""),
  args:    ((.tool_input.args // "")[0:120]),
  session: (.session_id // ""),
  cwd:     (.cwd // "")
}' >> "$LOG" 2>/dev/null || true
exit 0
