#!/usr/bin/env bash
set -euo pipefail
cmd=$(jq -r '.tool_input.command // ""')
for pattern in "rm -rf" "git reset --hard" "git push.*--force" "DROP TABLE" "DROP DATABASE"; do
  if echo "$cmd" | grep -qiE "$pattern"; then
    echo "BLOCKED: '$cmd' matches dangerous pattern '$pattern'. Use a safer alternative." >&2
    exit 2
  fi
done
exit 0
