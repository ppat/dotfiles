#!/usr/bin/env bash
set -euo pipefail

input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // ""')

# Only act on commands that invoke `git push`
if ! printf '%s' "$cmd" | grep -qE '(^|[;&|]|[[:space:]])git[[:space:]]+push([[:space:]]|$)'; then
  exit 0
fi

# Extract the `git push ...` segment up to the next shell separator
seg=$(printf '%s' "$cmd" | grep -oE 'git[[:space:]]+push[^;&|]*' | head -1)
rest=$(printf '%s' "$seg" | sed -E 's/^git[[:space:]]+push//')

remote_seen=0
target=""
for tok in $rest; do
  case "$tok" in
    -*) continue ;;
  esac
  if [ "$remote_seen" -eq 0 ]; then
    remote_seen=1
    continue
  fi
  if [[ "$tok" == *:* ]]; then
    target="${tok##*:}"
  else
    target="$tok"
  fi
done

if [ -z "$target" ]; then
  target=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
fi

if [ "$target" = "main" ] || [ "$target" = "master" ]; then
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Blocked by guard-git-push.sh: push targets protected branch \\"%s\\""}}\n' "$target"
else
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow","permissionDecisionReason":"guard-git-push.sh: push targets non-protected branch \\"%s\\""}}\n' "$target"
fi
