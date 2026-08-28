#!/usr/bin/env bash
set -euo pipefail
file=$(jq -r '.tool_input.file_path // .tool_input.path // ""')
# Allow non-secret templates/samples (e.g. .env.example, .env.sample, .env.template).
case "$file" in
  *.example|*.sample|*.template|*.dist) exit 0 ;;
esac
for pattern in "\.env$" "\.env\." "\.pem$" "\.key$" "credentials" "secrets/"; do
  if echo "$file" | grep -qiE "$pattern"; then
    echo "BLOCKED: '$file' looks like a secret/credential file. Ask Sameer before touching." >&2
    exit 2
  fi
done
exit 0
