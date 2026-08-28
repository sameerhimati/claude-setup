#!/usr/bin/env bash
# Tests whether skills actually fire. Reads evals/<skill>.jsonl, runs each prompt
# through a fresh headless session, and reports which skill the model reached for.
#
#   ./scripts/eval.sh                 every skill with an eval file
#   ./scripts/eval.sh deslop oss      named skills only
#   ./scripts/eval.sh --list          show cases without running them
#
# Each line of evals/<skill>.jsonl is:
#   {"prompt": "...", "expect": "deslop"}   must fire this skill
#   {"prompt": "...", "expect": null}       must fire nothing (negative case)
#
# Costs real tokens. One short turn per case, tools restricted to Skill so the
# run stops at the routing decision instead of doing the work.
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EVALS="$REPO/evals"
TIMEOUT="${EVAL_TIMEOUT:-90}"
# Keeps eval sessions out of the usage log the audit reads.
export CLAUDE_SKILL_EVAL=1
LIST_ONLY=0
[ "${1:-}" = "--list" ] && { LIST_ONLY=1; shift; }

command -v jq >/dev/null || { echo "error: jq is required"; exit 1; }
command -v claude >/dev/null || { echo "error: claude CLI not on PATH"; exit 1; }

# macOS ships neither timeout nor gtimeout. Use one if present, otherwise run bare.
# A plain string, not an array: bash 3.2 errors on an empty array under `set -u`.
TO=""
if command -v timeout >/dev/null;    then TO="timeout $TIMEOUT"
elif command -v gtimeout >/dev/null; then TO="gtimeout $TIMEOUT"
fi

if [ "$#" -gt 0 ]; then
  files=(); for s in "$@"; do files+=("$EVALS/$s.jsonl"); done
else
  files=("$EVALS"/*.jsonl)
fi

pass=0; fail=0; failures=()

# Tools blocked so the model cannot go exploring instead of deciding. With Bash and
# Read available it spends its turns hunting for the file and never reaches a skill,
# which measures the sandbox rather than the description. `--allowedTools` does not
# restrict; `--disallowedTools` does.
BLOCKED="Bash Read Glob Grep Edit Write WebFetch WebSearch Task TodoWrite NotebookEdit"

# Runs one prompt, prints the skill the model invoked, or empty for none.
# `error_max_turns` is the normal outcome and is not a failure: the run is stopped
# at the routing decision on purpose, before any work happens.
fired_skill() {
  local prompt="$1"
  claude -p "$prompt" \
    --output-format stream-json --verbose \
    --max-turns 2 \
    --disallowedTools "$BLOCKED" \
    --permission-mode bypassPermissions < /dev/null 2>/dev/null \
  | sed $'s/\x1b\][^\x07]*\x07//g' | grep '^{' \
  | jq -rs '[ .[]
      | (.message.content // [])[]?
      | select(type == "object" and .type == "tool_use" and .name == "Skill")
      | .input.skill ] | first // ""'
}

for f in "${files[@]}"; do
  [ -f "$f" ] || { echo "skip: no eval file $(basename "$f")"; continue; }
  skill="$(basename "$f" .jsonl)"
  echo "── $skill"
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    prompt="$(jq -r '.prompt' <<<"$line")"
    expect="$(jq -r 'if .expect == null then "" else .expect end' <<<"$line")"
    label="$(cut -c1-58 <<<"$prompt")"

    if [ "$LIST_ONLY" = 1 ]; then
      printf '   %-8s %s\n' "${expect:-none}" "$label"
      continue
    fi

    # $TO is unquoted on purpose: it is either empty or "timeout <n>".
    got="$($TO bash -c "$(declare -f fired_skill); fired_skill \"\$1\"" _ "$prompt")"
    got="${got//[$'\n\r']/}"

    if [ "$got" = "$expect" ]; then
      printf '   \033[32mPASS\033[0m  %-58s -> %s\n' "$label" "${got:-none}"
      pass=$((pass+1))
    else
      printf '   \033[31mFAIL\033[0m  %-58s -> %s (want %s)\n' "$label" "${got:-none}" "${expect:-none}"
      fail=$((fail+1))
      failures+=("$skill: \"$label\" fired '${got:-none}', wanted '${expect:-none}'")
    fi
  done < "$f"
done

[ "$LIST_ONLY" = 1 ] && exit 0

echo
echo "$pass passed, $fail failed"
if [ "$fail" -gt 0 ]; then
  printf '%s\n' "${failures[@]}"
  echo
  echo "A skill that will not fire is not a skill. Fix the description, not the body:"
  echo "  undertriggering -> add the words actually typed to the 'Use when' clause"
  echo "  overtriggering  -> narrow the clause, or add a negative case and re-run"
  exit 1
fi
