#!/usr/bin/env bash
# Links this repo into ~/.claude. Safe to re-run. Never overwrites your own files.
#
#   ./scripts/install.sh            install or update
#   ./scripts/install.sh --dry-run  show what would change
#
# Override the target with CLAUDE_CONFIG_DIR=/some/path (used by the tests).
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
STAMP="$(date +%Y%m%d-%H%M%S)"
# Backups live outside skills/ and agents/. A backup left in place inside skills/
# registers as a second, competing skill with the same triggers as the one it
# replaced, which quietly corrupts routing.
BACKUP="$DEST/.backups/$STAMP"
DRY=0
[ "${1:-}" = "--dry-run" ] && DRY=1

say()  { printf '%s\n' "$*"; }
run()  { if [ "$DRY" = 1 ]; then say "  would: $*"; else "$@"; fi; }

command -v jq >/dev/null || { say "error: jq is required"; exit 1; }

# A destination that resolves back inside the repo would corrupt the working tree.
if [ -e "$DEST" ]; then
  real_dest="$(cd "$DEST" 2>/dev/null && pwd -P || true)"
  case "$real_dest" in
    "$REPO"|"$REPO"/*) say "error: $DEST resolves inside $REPO. Refusing."; exit 1 ;;
  esac
fi

run mkdir -p "$DEST"

# --- linked directories -------------------------------------------------------
# One symlink per entry, so files you add yourself alongside them survive.
link_entries() {
  local sub="$1" src="$REPO/$1" dst="$DEST/$1"
  [ -d "$src" ] || return 0
  run mkdir -p "$dst"
  local entry name target
  for entry in "$src"/*; do
    [ -e "$entry" ] || continue
    name="$(basename "$entry")"
    target="$dst/$name"
    if [ -L "$target" ]; then
      [ "$(readlink "$target")" = "$entry" ] && continue
      run rm "$target"
    elif [ -e "$target" ]; then
      say "  backing up existing $sub/$name -> .backups/$STAMP/$sub/$name"
      run mkdir -p "$BACKUP/$sub"
      run mv "$target" "$BACKUP/$sub/$name"
    fi
    run ln -s "$entry" "$target"
    say "  linked $sub/$name"
  done
}

say "linking into $DEST"
for d in skills agents hooks rules; do link_entries "$d"; done

# in-progress skills are not installed
if [ -L "$DEST/skills/in-progress" ]; then run rm "$DEST/skills/in-progress"; fi

# --- copied files -------------------------------------------------------------
# CLAUDE.md is copied, not linked: Claude Code skips a symlinked ~/.claude/CLAUDE.md
# in Cowork desktop sessions. Re-run this script (or scripts/sync.sh) after editing it.
for f in CLAUDE.md AGENTS.md; do
  if [ -f "$DEST/$f" ] && ! cmp -s "$REPO/$f" "$DEST/$f"; then
    say "  backing up existing $f -> $f.bak-$STAMP"
    run cp "$DEST/$f" "$DEST/$f.bak-$STAMP"
  fi
  run cp "$REPO/$f" "$DEST/$f"
  say "  copied $f"
done

# --- settings.json ------------------------------------------------------------
# Merges only the hooks block. Everything else in your settings.json is left alone.
SETTINGS="$DEST/settings.json"
TEMPLATE="$REPO/settings.template.json"
[ -f "$SETTINGS" ] || { run mkdir -p "$DEST"; [ "$DRY" = 1 ] || echo '{}' > "$SETTINGS"; }

merged="$(jq -n \
  --slurpfile cur "${SETTINGS:-/dev/null}" \
  --slurpfile tpl "$TEMPLATE" '
  def ours: ["block-dangerous.sh","protect-secrets.sh","log-skill.sh","log-prompt.sh"];
  # True only if every command in this group is one of ours, so a group the user
  # wrote is never stripped. Both sides are bound: `endswith(.)` inside a `$c |`
  # pipeline would compare $c against itself and match everything.
  def is_ours:
    [ (.hooks // [])[] | (.command // "") ] as $cmds
    | ($cmds | length) > 0
      and ([ $cmds[] as $c | ours[] as $s | select($c | endswith($s)) ] | length) == ($cmds | length);
  ($cur[0] // {}) as $c
  | ($tpl[0].hooks // {}) as $t
  | $c
  | .hooks = (
      reduce ($t | keys_unsorted[]) as $ev (
        ($c.hooks // {});
        .[$ev] = ( ((.[$ev] // []) | map(select(is_ours | not))) + $t[$ev] )
      )
    )
' 2>/dev/null)" || { say "error: failed to merge settings.json"; exit 1; }

if [ "$DRY" = 1 ]; then
  say "  would merge hooks into settings.json"
else
  [ -f "$SETTINGS" ] && cp "$SETTINGS" "$SETTINGS.bak-$STAMP"
  printf '%s\n' "$merged" > "$SETTINGS"
  say "  merged hooks into settings.json (backup: settings.json.bak-$STAMP)"
fi

say
say "done. run /context in a new session to confirm CLAUDE.md loaded."
