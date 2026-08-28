#!/usr/bin/env bash
# Manages the local knowledge layer. The wiki is never installed into ~/.claude and
# is never read while working; only the monthly skill-review pass reads it.
#
#   ./scripts/wiki.sh init                    create the structure
#   ./scripts/wiki.sh init --remote <url>     ...and make it its own git repo
#   ./scripts/wiki.sh add "<title>"           new pattern file
#   ./scripts/wiki.sh log <skill> <verdict> "<note>"
#   ./scripts/wiki.sh sync                    commit and push, if it has a remote
#   ./scripts/wiki.sh status
#
# Set WIKI_DIR to keep it somewhere you already sync. Default: <repo>/wiki.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WIKI="${WIKI_DIR:-$REPO/wiki}"
cmd="${1:-status}"; shift || true

slug() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | sed -e 's/[^a-z0-9]\{1,\}/-/g' -e 's/^-//' -e 's/-$//'; }

case "$cmd" in
  init)
    mkdir -p "$WIKI/patterns"
    [ -f "$WIKI/impact.md" ] || cat > "$WIKI/impact.md" <<'EOF'
# Skill change log

One line per skill edit. `kept` means it stayed after use; `reverted` means it did not.
A reverted edit still leaves its pattern behind, which is the point.

| date | skill | verdict | note |
|---|---|---|---|
EOF
    [ -f "$WIKI/README.md" ] || cat > "$WIKI/README.md" <<'EOF'
# Knowledge layer

Not published, not installed, not read while working.

`patterns/` holds one file per recurring failure mode or working strategy, in prose. These are
observations drawn from `state/skill-usage.jsonl` and from work that went wrong or went well.

Read this only during a skill-review pass. Skills are compiled from it; nothing here should end up
referenced by a `SKILL.md`, because a compiled skill outperforms a skill plus notes.

A pattern that turns out to be general rather than project-specific should leave: promote it into a
skill if it is actionable workflow, or into a public doc if it is just knowledge. Delete it here once
it has.

Nothing prunes this automatically. Skim it when reviewing and delete what has stopped being true.
EOF
    if [ "${1:-}" = "--remote" ] && [ -n "${2:-}" ]; then
      if [ ! -d "$WIKI/.git" ]; then
        git -C "$WIKI" init -q && git -C "$WIKI" branch -M main
        git -C "$WIKI" remote add origin "$2"
        echo "initialised as its own repo, remote: $2"
      else
        git -C "$WIKI" remote set-url origin "$2"
        echo "remote set: $2"
      fi
    fi
    echo "wiki ready at $WIKI"
    ;;

  add)
    title="${1:?usage: wiki.sh add \"<title>\"}"
    f="$WIKI/patterns/$(slug "$title").md"
    [ -e "$f" ] && { echo "exists: $f"; exit 0; }
    mkdir -p "$WIKI/patterns"
    cat > "$f" <<EOF
# $title

## What happens

## Why

## What to do instead

## Seen
$(date +%Y-%m-%d) —
EOF
    echo "$f"
    ;;

  log)
    skill="${1:?usage: wiki.sh log <skill> <kept|reverted> \"<note>\"}"
    verdict="${2:?}"; note="${3:-}"
    printf '| %s | %s | %s | %s |\n' "$(date +%Y-%m-%d)" "$skill" "$verdict" "$note" >> "$WIKI/impact.md"
    echo "logged: $skill $verdict"
    ;;

  sync)
    [ -d "$WIKI/.git" ] || { echo "not a git repo; run: wiki.sh init --remote <url>"; exit 1; }
    git -C "$WIKI" add -A
    git -C "$WIKI" diff --cached --quiet && { echo "nothing to sync"; exit 0; }
    git -C "$WIKI" commit -q -m "wiki: $(date +%Y-%m-%d)"
    git -C "$WIKI" remote get-url origin >/dev/null 2>&1 && git -C "$WIKI" push -q origin main && echo "pushed"
    ;;

  status)
    [ -d "$WIKI" ] || { echo "no wiki yet. run: ./scripts/wiki.sh init"; exit 0; }
    n=$(find "$WIKI/patterns" -name '*.md' 2>/dev/null | wc -l | tr -d ' ')
    echo "wiki:     $WIKI"
    echo "patterns: $n"
    echo "own repo: $([ -d "$WIKI/.git" ] && echo yes || echo no)"
    [ "$n" -gt 0 ] && find "$WIKI/patterns" -name '*.md' -exec basename {} .md \; | sed 's/^/  /'
    ;;

  *) sed -n '2,12p' "$0"; exit 1 ;;
esac
