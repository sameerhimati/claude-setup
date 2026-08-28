#!/usr/bin/env bash
# Monthly skill review. Reads the usage log, computes what fired and what didn't,
# then asks a fresh session to read the knowledge layer and propose changes.
#
#   ./scripts/audit.sh            stats, then propose
#   ./scripts/audit.sh --stats    stats only, no model call, no cost
#
# This is the only place the wiki is read. Proposals are written to a file and never
# applied: a skill edit is reviewed, then kept or reverted by hand.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
LOG="$DEST/state/skill-usage.jsonl"
WIKI="${WIKI_DIR:-$REPO/wiki}"
OUT="$WIKI/proposals-$(date +%Y-%m-%d).md"
DAYS="${AUDIT_DAYS:-90}"

command -v jq >/dev/null || { echo "error: jq is required"; exit 1; }
[ -f "$LOG" ] || { echo "no usage log at $LOG. Nothing to audit yet."; exit 0; }

installed=$(find "$REPO/skills" -mindepth 2 -maxdepth 2 -name SKILL.md \
  -not -path '*/in-progress/*' -exec dirname {} \; | xargs -n1 basename | sort)

cutoff=$(python3 -c "import datetime,sys;print((datetime.datetime.now(datetime.timezone.utc)-datetime.timedelta(days=int(sys.argv[1]))).strftime('%Y-%m-%dT%H:%M:%SZ'))" "$DAYS")

stats="$(python3 - "$LOG" "$cutoff" <<'PY'
import json, sys, collections
log, cutoff = sys.argv[1], sys.argv[2]
auto, typed, prompts, named = collections.Counter(), collections.Counter(), [], collections.Counter()
total = 0
for line in open(log, errors="ignore"):
    line = line.strip()
    if not line: continue
    try: o = json.loads(line)
    except Exception: continue
    if o.get("ts", "") < cutoff: continue
    src, sk = o.get("source"), (o.get("skill") or "")
    if src == "auto" and sk: auto[sk] += 1
    elif src == "typed" and sk: typed[sk] += 1
    elif src == "prompt":
        total += 1
        t = (o.get("text") or "").strip()
        if t: prompts.append(t)
print("FIRED")
for s, n in auto.most_common(): print(f"  {s}\tauto={n}\ttyped={typed.get(s,0)}")
for s, n in typed.most_common():
    if s not in auto: print(f"  {s}\tauto=0\ttyped={n}")
print(f"\nPROMPTS_WITH_NO_SKILL\t{total}")
for t in prompts[-120:]: print("  " + t[:160])
PY
)"

echo "$stats" | head -30
echo
echo "window: last $DAYS days   log: $LOG"
[ "${1:-}" = "--stats" ] && exit 0

mkdir -p "$WIKI/patterns"
patterns="$(find "$WIKI/patterns" -name '*.md' 2>/dev/null | wc -l | tr -d ' ')"
echo "reading $patterns pattern file(s), then proposing..."

prompt="You are doing a monthly skill review. Propose changes; do not make them.

Read every file under $WIKI/patterns/ and $WIKI/impact.md if they exist. Those hold what has
already been learned, so do not re-derive conclusions that are written there. Read the descriptions
of the installed skills in $REPO/skills/*/SKILL.md, and $REPO/skills/writing-skills/SKILL.md for the
authoring standard you are holding them to.

Here is usage for the last $DAYS days. 'auto' means the model invoked the skill; 'typed' means the
user typed the slash command. Prompts listed under PROMPTS_WITH_NO_SKILL are requests where no skill
fired at all.

$stats

Installed skills:
$installed

Produce four sections, and write nothing outside the output file:

1. MISSING. Cluster the prompts where nothing fired. Where a cluster recurs and no installed skill
   covers it, propose a skill: name, a draft description written to the standard, and three eval
   cases including one negative. Say how many prompts are in the cluster. A cluster of one is not a
   skill.
2. BROKEN TRIGGERS. Any skill named in a prompt that did not then fire. Propose a description edit,
   quoting the phrasing that should have matched. This is the highest-value category.
3. DEAD. Any installed skill with zero invocations in the window. Recommend deletion and name what
   replaces it, or say why it should stay.
4. NEW PATTERNS. Anything in the usage data worth recording in $WIKI/patterns/ that is not already
   there. Give a filename and the body. These outlive individual skill edits.

Rules: one proposed change per skill, as a diff, not a rewrite. Do not edit any skill. Do not
suggest that a skill read the wiki; skills are compiled from it. Be concrete and brief. If a section
has nothing, write 'none'.

Write the result to $OUT and then stop."

claude -p "$prompt" \
  --permission-mode acceptEdits \
  --disallowedTools "WebFetch WebSearch" \
  < /dev/null >/dev/null 2>&1 || true

if [ -f "$OUT" ]; then
  echo "wrote $OUT"
  echo
  sed -n '1,40p' "$OUT"
  echo
  echo "Review it. Apply one change at a time, then: ./scripts/wiki.sh log <skill> <kept|reverted> \"<note>\""
else
  echo "no proposal file was written. Run with --stats to check the log has data."
fi
