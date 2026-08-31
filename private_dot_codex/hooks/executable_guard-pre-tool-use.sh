#!/usr/bin/env bash
set -euo pipefail

# Reuse the Claude guard implementations so both agents enforce the same protected
# operations. Claude permits an explicit "allow" response; Codex does not, and treats it
# as a failed hook. A clean Codex guard therefore exits silently, while a denial passes
# through unchanged.
input=$(cat)

for guard in guard-git-push.sh guard-git-identity.sh guard-gh-merge.sh; do
  hook="$HOME/.claude/hooks/$guard"
  [ -x "$hook" ] || continue

  output=$(printf '%s' "$input" | "$hook")
  [ -n "$output" ] || continue

  if printf '%s' "$output" | jq -e '.hookSpecificOutput.permissionDecision == "allow"' > /dev/null; then
    continue
  fi

  printf '%s\n' "$output"
  exit 0
done
