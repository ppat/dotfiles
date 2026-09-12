#!/usr/bin/env bash
set -euo pipefail

# PreToolUse hook: refuse Git's repository-surgery and recovery-erasure commands. These
# commands rewrite history, mutate refs below Git's usual safety rails, or discard the
# recovery data used to undo mistakes. They do not belong in normal day-to-day development.
#
# This intentionally does not broadly ban destructive Git commands. Rebase, reset, clean,
# force-with-lease pushes, and ordinary reflog inspection all have normal development uses.
# In particular, the guarded `git prune` subcommand is distinct from `git pull --prune`,
# which remains allowed.

# A missing tool must never turn this into a noisy or failing hook.
command -v jq >/dev/null 2>&1 || exit 0

input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // ""')
[ -n "$cmd" ] || exit 0

deny() {
  jq -cn --arg r "Blocked by guard-git-dangerous.sh: git $1 is repository surgery or recovery-data erasure and is not permitted for normal development." \
    '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: $r}}'
  exit 0
}

lc() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]'; }

# Git accepts global options before its subcommand. Skip options with a separate value so the
# value cannot be mistaken for the subcommand; all other options are standalone or use `=`.
git_subcommand() {
  local -n git_tokens=$1
  local i=$2
  local count=${#git_tokens[@]}

  while [ "$i" -lt "$count" ]; do
    case "${git_tokens[$i]}" in
      -C | -c | --git-dir | --work-tree | --namespace | --exec-path | --config-env)
        i=$((i + 2))
        ;;
      --)
        return 1
        ;;
      -*)
        i=$((i + 1))
        ;;
      *)
        GIT_SUBCOMMAND=$(lc "${git_tokens[$i]}")
        GIT_ARGUMENT_START=$((i + 1))
        return 0
        ;;
    esac
  done

  return 1
}

# Return the first subcommand after `git reflog`, skipping its flags. The destructive reflog
# forms have an explicit verb, while `git reflog`, `show`, `list`, and `exists` are inspection.
reflog_action() {
  local -n reflog_tokens=$1
  local i=$2
  local count=${#reflog_tokens[@]}

  while [ "$i" -lt "$count" ]; do
    case "${reflog_tokens[$i]}" in
      --expire | --expire-unreachable)
        i=$((i + 2))
        ;;
      -*)
        i=$((i + 1))
        ;;
      *)
        REFLOG_ACTION=$(lc "${reflog_tokens[$i]}")
        return 0
        ;;
    esac
  done

  return 1
}

stash_action() {
  local -n stash_tokens=$1
  local i=$2
  local count=${#stash_tokens[@]}

  while [ "$i" -lt "$count" ]; do
    case "${stash_tokens[$i]}" in
      -m | --message | --pathspec-from-file)
        i=$((i + 2))
        ;;
      -*)
        i=$((i + 1))
        ;;
      *)
        STASH_ACTION=$(lc "${stash_tokens[$i]}")
        return 0
        ;;
    esac
  done

  return 1
}

# Split compound shell commands without evaluating them. A `git` word is inspected only when it
# occupies command position, so prose or search terms such as `echo git gc` are not misread as
# Git invocations. Leading assignments and the common `command`, `env`, and `sudo` wrappers are
# recognized; nothing from the request is evaluated.
is_assignment() {
  [[ "$1" =~ ^[[:alpha:]_][[:alnum:]_]*= ]]
}

guard_segment() {
  local -n segment_tokens=$1
  local i=0
  local count=${#segment_tokens[@]}

  while [ "$i" -lt "$count" ] && is_assignment "${segment_tokens[$i]}"; do
    i=$((i + 1))
  done

  # Peel wrappers which retain the command position of the word that follows them.
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

  # `return 0`, never a bare `return`. A bare one inherits the status of the test immediately
  # before it -- which at this point has just FAILED -- so under the `set -e` at the top it
  # aborts the entire hook, and the loop at the bottom never examines the remaining segments of
  # the command line. Both of these mean "no command word in this segment to guard", which is
  # success, and saying so explicitly is what keeps the walk going.
  [ "$i" -lt "$count" ] || return 0
  case "${segment_tokens[$i]}" in
    git-filter-repo | */git-filter-repo)
      deny "filter-repo"
      ;;
    git | */git)
      git_subcommand segment_tokens $((i + 1)) || return 0

      case "$GIT_SUBCOMMAND" in
        filter-branch | filter-repo | fast-import | prune | gc | repack | pack-refs | update-ref | replace)
          deny "$GIT_SUBCOMMAND"
          ;;
        reflog)
          if reflog_action segment_tokens "$GIT_ARGUMENT_START"; then
            case "$REFLOG_ACTION" in
              write | delete | drop | expire) deny "reflog $REFLOG_ACTION" ;;
            esac
          fi
          ;;
        stash)
          if stash_action segment_tokens "$GIT_ARGUMENT_START"; then
            case "$STASH_ACTION" in
              drop | clear) deny "stash $STASH_ACTION" ;;
            esac
          fi
          ;;
      esac
      ;;
  esac
}

segments=$(printf '%s' "$cmd" | tr ';&|' '\n')
while IFS= read -r segment; do
  [ -n "$segment" ] || continue
  read -ra tokens <<<"$segment" || true
  # `|| true` so that no future non-zero return inside guard_segment can abort this loop and
  # leave the later segments unexamined. A guard that stops early is worse than one that is
  # absent, because it still reads as coverage. Denial does not travel by return status -- deny()
  # writes its decision and exits -- so nothing here needs a non-zero to be observable.
  guard_segment tokens || true
done <<<"$segments"

exit 0
