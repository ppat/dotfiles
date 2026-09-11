#!/usr/bin/env bash
set -euo pipefail

# PreToolUse hook: `gh auth setup-git` writes a credential helper into Git configuration.
# The workspace's existing GitHub authentication path must remain separate from that global
# Git configuration change.

# A missing tool must never turn this into a noisy or failing hook.
command -v jq >/dev/null 2>&1 || exit 0

input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // ""')
[ -n "$cmd" ] || exit 0

deny() {
  jq -cn \
    --arg r 'Blocked by guard-gh-auth-setup-git.sh: gh auth setup-git changes Git credential-helper configuration and is not permitted.' \
    '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: $r}}'
  exit 0
}

# Inspect only command-position words in each compound command, so prose such as
# `echo "gh auth setup-git"` does not trigger the guard. Common wrappers retain the command
# position of the next word; no input is evaluated.
segments=$(printf '%s' "$cmd" | tr ';&|' '\n')
while IFS= read -r segment; do
  read -ra tokens <<<"$segment" || true
  index=0

  while [ "$index" -lt "${#tokens[@]}" ] && [[ "${tokens[$index]}" =~ ^[[:alpha:]_][[:alnum:]_]*= ]]; do
    index=$((index + 1))
  done

  case "${tokens[$index]:-}" in
    command)
      index=$((index + 1))
      while [[ "${tokens[$index]:-}" == -* ]]; do index=$((index + 1)); done
      ;;
    env)
      index=$((index + 1))
      while [[ "${tokens[$index]:-}" =~ ^(-.*|[[:alpha:]_][[:alnum:]_]*=) ]]; do index=$((index + 1)); done
      ;;
    sudo)
      index=$((index + 1))
      while [[ "${tokens[$index]:-}" == -* ]]; do index=$((index + 1)); done
      ;;
  esac

  if [ "${tokens[$index]:-}" = "gh" ] \
    && [ "${tokens[$((index + 1))]:-}" = "auth" ] \
    && [ "${tokens[$((index + 2))]:-}" = "setup-git" ]; then
    deny
  fi
done <<<"$segments"
