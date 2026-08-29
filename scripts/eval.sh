#!/usr/bin/env bash
# Tests whether skills actually fire. Reads evals/<skill>.jsonl, runs each prompt through
# a fresh headless session, and reports which skill the model reached for.
#
#   ./scripts/eval.sh                    every skill
#   ./scripts/eval.sh deslop oss         named skills only
#   ./scripts/eval.sh --list             show cases without running them
#   ./scripts/eval.sh --repeat 3         run each case N times, majority vote, flag disagreement
#
# Each line of evals/<skill>.jsonl:
#   {"prompt": "...", "expect": "deslop"}          must fire this skill
#   {"prompt": "...", "expect": null}              must fire nothing
#   {"prompt": "...", "expect": "x", "src": "log:2026-08-28"}   provenance, optional
#
# Measurement notes, learned the hard way:
#   - Cases run from an empty directory. Run them from the repo and its own CLAUDE.md loads
#     as project context, so the suite measures the environment as much as the description.
#   - Tools are blocked so the model cannot go exploring instead of deciding. `--allowedTools`
#     does not restrict; `--disallowedTools` does.
#   - Every case is a cold conversation opener. Real invocations are usually mid-session, so
#     a prompt that only makes sense in context cannot be represented here.
#   - Do NOT set CLAUDE_CONFIG_DIR here. Measured on 2.1.251: with it set, the model never
#     invokes a skill, even pointed at the default ~/.claude. Skills still appear in the init
#     payload, so it looks configured and silently measures nothing. 0/5 with it set against
#     5/5 without, same directory. This ruled out evaluating a scratch config, which is why
#     verify.sh works on the tree the ~/.claude symlinks already point at.
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EVALS="$REPO/evals"
TIMEOUT="${EVAL_TIMEOUT:-90}"
export CLAUDE_SKILL_EVAL=1   # keeps eval sessions out of the usage log the audit reads

LIST_ONLY=0; REPEAT=1
while [ "$#" -gt 0 ]; do
  case "$1" in
    --list)     LIST_ONLY=1; shift ;;
    --repeat)   REPEAT="$2"; shift 2 ;;
    --) shift; break ;;
    -*) echo "unknown flag: $1"; exit 1 ;;
    *) break ;;
  esac
done

command -v jq >/dev/null || { echo "error: jq is required"; exit 1; }
command -v claude >/dev/null || { echo "error: claude CLI not on PATH"; exit 1; }

if command -v timeout >/dev/null;    then TO="timeout $TIMEOUT"
elif command -v gtimeout >/dev/null; then TO="gtimeout $TIMEOUT"
else TO=""; fi


# Cases run here so no project CLAUDE.md is picked up from the caller's directory.
SANDBOX="$(mktemp -d)"

BLOCKED="Bash Read Glob Grep Edit Write WebFetch WebSearch Task TodoWrite NotebookEdit"

# One run of one prompt. Prints the skill invoked, or empty. `error_max_turns` is the normal
# outcome: the run is stopped at the routing decision on purpose, before any work happens.
run_once() {
  ( cd "$SANDBOX" && $TO claude -p "$1" \
      --output-format stream-json --verbose \
      --max-turns 2 \
      --disallowedTools "$BLOCKED" \
      --permission-mode bypassPermissions < /dev/null 2>/dev/null ) \
  | sed $'s/\x1b\][^\x07]*\x07//g' | grep '^{' \
  | jq -rs '[ .[]
      | (.message.content // [])[]?
      | select(type == "object" and .type == "tool_use" and .name == "Skill")
      | .input.skill ] | first // ""'
}

# Runs a case REPEAT times. Prints "<result>\t<stable|unstable>".
fired_skill() {
  local i out all=""
  for i in $(seq 1 "$REPEAT"); do
    out="$(run_once "$1")"; out="${out//[$'\n\r']/}"
    all="$all${out:-none}"$'\n'
  done
  local top count distinct
  top="$(printf '%s' "$all" | grep -v '^$' | sort | uniq -c | sort -rn | head -1 | awk '{print $2}')"
  distinct="$(printf '%s' "$all" | grep -v '^$' | sort -u | wc -l | tr -d ' ')"
  [ "$top" = "none" ] && top=""
  if [ "$distinct" -gt 1 ]; then printf '%s\tunstable\n' "$top"; else printf '%s\tstable\n' "$top"; fi
}

if [ "$#" -gt 0 ]; then
  files=(); for s in "$@"; do files+=("$EVALS/$s.jsonl"); done
else
  files=("$EVALS"/*.jsonl)
fi

if [ "$LIST_ONLY" = 0 ]; then
  echo "instrument: $(claude --version 2>/dev/null | tr -d '\r')  |  $(date -u +%Y-%m-%dT%H:%MZ)"
    echo "skills:     $(find "$HOME/.claude/skills" -maxdepth 1 -mindepth 1 2>/dev/null | wc -l | tr -d ' ') installed  |  repeat=$REPEAT"
  echo
fi

pass=0; fail=0; unstable=0; failures=()

for f in "${files[@]}"; do
  [ -f "$f" ] || { echo "skip: no eval file $(basename "$f")"; continue; }
  skill="$(basename "$f" .jsonl)"
  echo "── $skill"
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    prompt="$(jq -r '.prompt' <<<"$line")"
    expect="$(jq -r 'if .expect == null then "" else .expect end' <<<"$line")"
    src="$(jq -r '.src // ""' <<<"$line")"
    label="$(cut -c1-56 <<<"$prompt")"

    if [ "$LIST_ONLY" = 1 ]; then
      printf '   %-14s %-56s %s\n' "${expect:-none}" "$label" "$src"
      continue
    fi

    res="$(fired_skill "$prompt")"
    got="${res%%$'\t'*}"; stability="${res##*$'\t'}"

    if [ "$stability" = "unstable" ]; then
      printf '   \033[33mUNSTABLE\033[0m  %-56s -> %s (disagreed across %s runs)\n' "$label" "${got:-none}" "$REPEAT"
      unstable=$((unstable+1))
      failures+=("$skill: \"$label\" unstable across $REPEAT runs")
    elif [ "$got" = "$expect" ]; then
      printf '   \033[32mPASS\033[0m      %-56s -> %s\n' "$label" "${got:-none}"
      pass=$((pass+1))
    else
      printf '   \033[31mFAIL\033[0m      %-56s -> %s (want %s)\n' "$label" "${got:-none}" "${expect:-none}"
      fail=$((fail+1))
      failures+=("$skill: \"$label\" fired '${got:-none}', wanted '${expect:-none}'")
    fi
  done < "$f"
done

[ "$LIST_ONLY" = 1 ] && exit 0

echo
echo "$pass passed, $fail failed, $unstable unstable"
if [ "$fail" -gt 0 ] || [ "$unstable" -gt 0 ]; then
  printf '%s\n' "${failures[@]}"
  echo
  echo "Check the case before the description. A case written as a question rather than a task"
  echo "often will not fire however well the description matches."
  echo "  undertriggering -> reorder the 'Use when' clause so the missing phrasing leads"
  echo "  overtriggering  -> narrow the clause and add the negative case that caught it"
  echo "  unstable        -> the case sits on the decision boundary; raise --repeat before judging"
  exit 1
fi
