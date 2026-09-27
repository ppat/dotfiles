#!/usr/bin/env bash
set -euo pipefail

# PreToolUse hook: process termination must target explicit PIDs. Name and pattern based
# selection can kill unrelated processes that happen to match the same text.

# A missing tool must never turn this into a noisy or failing hook.
command -v jq >/dev/null 2>&1 || exit 0

input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // ""')
[ -n "$cmd" ] || exit 0

deny() {
  jq -cn --arg r "Blocked by guard-process-kill.sh: $1. Terminate processes only with kill and explicit positive numeric PIDs." \
    '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: $r}}'
  exit 0
}

is_assignment() {
  [[ "$1" =~ ^[[:alpha:]_][[:alnum:]_]*= ]]
}

# Inspect only command-position words in each compound command, so prose such as
# `printf 'do not use pkill'` does not trigger the guard. Common wrappers retain the command
# position of the word that follows them; no input is evaluated.
guard_segment() {
  local -n segment_tokens=$1
  local i=0
  local count=${#segment_tokens[@]}

  while [ "$i" -lt "$count" ] && is_assignment "${segment_tokens[$i]}"; do
    i=$((i + 1))
  done

  while [ "$i" -lt "$count" ]; do
    case "${segment_tokens[$i]}" in
      command)
        i=$((i + 1))
        while [ "$i" -lt "$count" ] && [[ "${segment_tokens[$i]}" == -* ]]; do
          i=$((i + 1))
        done
        ;;
      env)
        i=$((i + 1))
        while [ "$i" -lt "$count" ]; do
          case "${segment_tokens[$i]}" in
            --) i=$((i + 1)); break ;;
            -C | --chdir) i=$((i + 2)) ;;
            -*) i=$((i + 1)) ;;
            *)
              is_assignment "${segment_tokens[$i]}" && { i=$((i + 1)); continue; }
              break
              ;;
          esac
        done
        ;;
      sudo)
        i=$((i + 1))
        while [ "$i" -lt "$count" ]; do
          case "${segment_tokens[$i]}" in
            --) i=$((i + 1)); break ;;
            -u | -g | -h | -p | -r | -t | -C | --user | --group | --host | --prompt | --role | --type | --close-from | --chdir | --command-timeout)
              i=$((i + 2))
              ;;
            -*) i=$((i + 1)) ;;
            *) break ;;
          esac
        done
        ;;
      *) break ;;
    esac
  done

  [ "$i" -lt "$count" ] || return 0
  case "${segment_tokens[$i]}" in
    pkill | */pkill)
      deny "pkill selects processes by pattern"
      ;;
    killall | */killall)
      deny "killall selects processes by name"
      ;;
    kill | */kill)
      i=$((i + 1))
      while [ "$i" -lt "$count" ]; do
        case "${segment_tokens[$i]}" in
          -l | -L | --list | --table)
            return 0
            ;;
          -s | --signal | -q | --queue)
            i=$((i + 2))
            ;;
          --signal=* | --queue=*)
            i=$((i + 1))
            ;;
          --timeout)
            i=$((i + 3))
            ;;
          --)
            i=$((i + 1))
            break
            ;;
          -*)
            # Short signal forms such as -9 and -TERM consume no separate argument.
            i=$((i + 1))
            ;;
          *)
            break
            ;;
        esac
      done

      while [ "$i" -lt "$count" ]; do
        [[ "${segment_tokens[$i]}" =~ ^[1-9][0-9]*$ ]] \
          || deny "kill target '${segment_tokens[$i]}' is not an explicit positive numeric PID"
        i=$((i + 1))
      done
      ;;
  esac
}

segments=$(printf '%s' "$cmd" | tr ';&|' '\n')
while IFS= read -r segment; do
  [ -n "$segment" ] || continue
  read -ra tokens <<<"$segment" || true
  guard_segment tokens || true
done <<<"$segments"

exit 0
