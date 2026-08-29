#!/usr/bin/env bash
# Proves whether a proposed change helps, before anyone applies it.
#
#   ./scripts/verify.sh proposal.diff
#   ./scripts/verify.sh proposal.diff --repeat 1     cheaper, noisier
#
# Runs the full suite, applies the diff to the working tree, runs it again, then puts the
# tree back. Prints per-case movement and a verdict. Applies nothing permanently.
#
# Why the working tree and not a scratch copy: `claude -p` reads skills from ~/.claude, whose
# skill entries are symlinks into this repo. A scratch config cannot be measured at all --
# setting CLAUDE_CONFIG_DIR stops the model invoking skills, measured 0/5 against 5/5 without
# it on 2.1.251. So the tree the symlinks point at is the only evaluable one, and git is the
# safety net rather than isolation.
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIFF="${1:?usage: verify.sh <proposal.diff> [--repeat N]}"
REPEAT=3
[ "${2:-}" = "--repeat" ] && REPEAT="${3:-3}"

cd "$REPO"
[ -f "$DIFF" ] || { echo "error: no such diff: $DIFF"; exit 1; }

# 1. The tree must be clean, or restoring it afterwards would destroy real work.
if [ -n "$(git status --porcelain)" ]; then
  echo "error: working tree is dirty. Commit or stash first -- this script restores by discarding."
  git status --short | sed 's/^/  /'
  exit 1
fi

# 2. A pass that edits a description must not also edit the cases that judge it.
touches_desc=0; touches_eval=0
while IFS= read -r line; do
  case "$line" in
    +++\ b/skills/*SKILL.md|---\ a/skills/*SKILL.md) touches_desc=1 ;;
    +++\ b/evals/*|---\ a/evals/*)                   touches_eval=1 ;;
  esac
done < "$DIFF"
if [ "$touches_desc" = 1 ] && [ "$touches_eval" = 1 ]; then
  echo "refused: this diff edits a skill and its eval cases in the same pass."
  echo "Moving the target and the test together is how a suite stops meaning anything."
  echo "Split it: change the cases, verify, then change the description."
  exit 1
fi

results() { sed 's/\x1b\[[0-9;]*m//g' "$1" | grep -aE '^   (PASS|FAIL|UNSTABLE)' \
  | sed -E 's/^   ([A-Z]+) +(.{1,56}[^ ]) +-> ([^ ]*).*/\1\t\2\t\3/'; }

TMP="$(mktemp -d)"
restore() {
  git checkout -- . 2>/dev/null
  if [ -n "$(git status --porcelain)" ]; then
    echo
    echo "WARNING: tree is still dirty after restore. Inspect before doing anything else:"
    git status --short | sed 's/^/  /'
  fi
}
trap restore EXIT INT TERM

echo "baseline  (repeat=$REPEAT)"
./scripts/eval.sh --repeat "$REPEAT" > "$TMP/before.txt" 2>&1
results "$TMP/before.txt" > "$TMP/before.tsv"
tail -1 "$TMP/before.txt" | sed 's/^/  /'

echo
echo "applying $DIFF"
git apply --check "$DIFF" 2>/dev/null || { echo "error: diff does not apply cleanly"; exit 1; }
git apply "$DIFF"
git --no-pager diff --stat | sed 's/^/  /'

echo
echo "candidate (repeat=$REPEAT)"
./scripts/eval.sh --repeat "$REPEAT" > "$TMP/after.txt" 2>&1
results "$TMP/after.txt" > "$TMP/after.tsv"
tail -1 "$TMP/after.txt" | sed 's/^/  /'

restore; trap - EXIT INT TERM

echo
echo "movement"
python3 - "$TMP/before.tsv" "$TMP/after.tsv" <<'PY'
import sys
def load(p):
    d = {}
    for line in open(p):
        parts = line.rstrip("\n").split("\t")
        if len(parts) == 3: d[parts[1]] = (parts[0], parts[2])
    return d
b, a = load(sys.argv[1]), load(sys.argv[2])
fixed = broke = unstable = same = 0
for case in sorted(set(b) | set(a)):
    bs, as_ = b.get(case, ("MISSING", "")), a.get(case, ("MISSING", ""))
    if bs[0] == as_[0]:
        if as_[0] == "UNSTABLE": unstable += 1; print(f"  unstable  {case[:56]}")
        else: same += 1
        continue
    if as_[0] == "PASS":       fixed += 1;  print(f"  fixed     {case[:56]}  {bs[1] or 'none'} -> {as_[1] or 'none'}")
    elif as_[0] == "UNSTABLE": unstable += 1; print(f"  unstable  {case[:56]}  now disagrees with itself")
    else:                      broke += 1;  print(f"  BROKE     {case[:56]}  {bs[1] or 'none'} -> {as_[1] or 'none'}")
if not (fixed or broke or unstable): print("  no change")
print()
print(f"  fixed {fixed}, broke {broke}, unstable {unstable}, unchanged {same}")
print()
if broke: print("VERDICT: reject. It breaks cases that were passing.")
elif unstable: print("VERDICT: inconclusive. Cases disagree with themselves; raise --repeat.")
elif fixed: print("VERDICT: accept. Apply with: git apply <diff>")
else: print("VERDICT: no measured effect. Applying it is a matter of taste, not evidence.")
PY

echo
echo "tree restored: $([ -z "$(git status --porcelain)" ] && echo clean || echo DIRTY)"
