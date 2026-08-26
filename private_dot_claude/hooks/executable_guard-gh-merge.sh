#!/usr/bin/env bash
set -euo pipefail

input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // ""')

deny() {
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Blocked by guard-gh-merge.sh: landing PRs is reserved for the user (%s)"}}\n' "$1"
  exit 0
}

# Landing PRs is the user's action; guard-git-push.sh covers `git push`, this covers the two
# `gh` paths that can merge a PR. Matches the subcommand anywhere in a compound command, but
# only with `pr`/`merge` adjacent -- `gh --repo X pr merge` style flag interleaving is not
# matched, which is acceptable: the goal is stopping the model's habitual form, the credential
# layer backstops the rest.
if printf '%s' "$cmd" | grep -qE '(^|[;&|]|[[:space:]])gh[[:space:]]+pr[[:space:]]+merge([[:space:]]|$)'; then
  deny "gh pr merge"
fi

# REST equivalent: PUT /repos/{owner}/{repo}/pulls/{n}/merge
if printf '%s' "$cmd" | grep -qE '(^|[;&|]|[[:space:]])gh[[:space:]]+api[[:space:]]' \
  && printf '%s' "$cmd" | grep -qE 'pulls/[^/[:space:]]+/merge([^[:alnum:]_]|$)'; then
  deny "gh api pulls merge endpoint"
fi

exit 0
