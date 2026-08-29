#!/usr/bin/env bash
set -euo pipefail

# Codex supplies apply_patch edits as a unified patch in tool_input.command rather than
# Claude's single tool_input.file_path. Extract every destination path, then feed each
# existing Claude linter the payload shape it already understands.
command -v jq >/dev/null 2>&1 || exit 0

input=$(cat)
patch=$(printf '%s' "$input" | jq -r '.tool_input.command // ""')
[ -n "$patch" ] || exit 0

declare -A seen=()
while IFS= read -r line; do
  case "$line" in
    "+++ b/"*) path=${line#+++ b/} ;;
    "+++ "*) path=${line#+++ } ;;
    *) continue ;;
  esac
  [ "$path" = "/dev/null" ] || [ -n "$path" ] || continue
  seen["$path"]=1
done <<< "$patch"

for file_path in "${!seen[@]}"; do
  [ -f "$file_path" ] || continue
  payload=$(jq -cn --arg path "$file_path" '{tool_input:{file_path:$path}}')
  for linter in shellcheck-on-edit.sh yamllint-on-edit.sh markdownlint-on-edit.sh; do
    hook="$HOME/.claude/hooks/$linter"
    [ -x "$hook" ] || continue
    printf '%s' "$payload" | "$hook"
  done
done
