#!/usr/bin/env bash
set -euo pipefail

# Reuse the Claude guard implementations so both agents enforce the same protected
# operations. Claude permits an explicit "allow" response; Codex does not, and treats it
# as a failed hook. A clean Codex guard therefore exits silently, while a denial passes
# through unchanged.
input=$(cat)

for guard in guard-git-push.sh guard-git-identity.sh guard-git-dangerous.sh guard-gh-merge.sh guard-gh-auth-setup-git.sh; do
  hook="$HOME/.claude/hooks/$guard"
  [ -x "$hook" ] || continue

  # `|| true` because this script runs under `set -e`: without it, a guard that exits non-zero
  # for any reason aborts the whole dispatcher, and every guard LISTED AFTER IT is silently
  # skipped. One guard's bug then disables the rest of the chain, which is the worst available
  # failure mode for a set of guards -- the protection disappears and nothing says so.
  output=$(printf '%s' "$input" | "$hook") || true
  [ -n "$output" ] || continue

  if printf '%s' "$output" | jq -e '.hookSpecificOutput.permissionDecision == "allow"' > /dev/null; then
    continue
  fi

  printf '%s\n' "$output"
  exit 0
done
