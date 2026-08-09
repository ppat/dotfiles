#!/usr/bin/env bash
set -euo pipefail

# PreToolUse hook: every commit must be attributed to, and signed with, whatever the user's
# own git config already resolves to. Two families of override get refused:
#
#   1. Identity supplied with the commit - `--author`, `-c user.email=...`,
#      GIT_AUTHOR_* / GIT_COMMITTER_* in the environment, `git config` writes to `user.*`.
#   2. Signing weakened or skipped - `--no-gpg-sign`, `-c commit.gpgsign=false`, a
#      substituted `gpg.program` or signing key, GIT_CONFIG_* injection.
#
# The configured values are never read here: the hook has no opinion on what the identity or
# signing key should be, only that nothing at the command line gets to replace it. That also
# keeps it correct on a machine whose config it has never seen.
#
# Blocking, not advisory - unlike the *-on-edit.sh hooks, there is no pre-existing-violation
# problem to wedge an agent on. Every deny corresponds to a flag the caller just typed, and
# dropping that flag is always a valid way forward. A clean command exits silently rather
# than emitting "allow", so ordinary permission prompts still apply to it.

# A missing tool must never turn this into a noisy or failing hook.
command -v jq >/dev/null 2>&1 || exit 0

input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // ""')
[ -n "$cmd" ] || exit 0

deny() {
  jq -cn --arg r "Blocked by guard-git-identity.sh: $1. Commits must use the identity and signing configuration already in the user's git config - drop the override and re-run." \
    '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: $r}}'
  exit 0
}

# ---------------------------------------------------------------------------
# Unambiguous overrides: matched against the whole command, no parsing needed.
#
# None of these strings has a legitimate read-only use, so context is irrelevant - a match
# anywhere is an override attempt regardless of which git subcommand it lands on, and that
# holds even when quoting or nesting defeats the tokenizer below. Matched case-insensitively
# because git config keys are case-insensitive.
# ---------------------------------------------------------------------------

# Identity and signing config injected through the environment, including the GIT_CONFIG_*
# family - which can set any key at all, and is the most direct way around every other check.
if printf '%s' "$cmd" | grep -qE 'GIT_(AUTHOR|COMMITTER)_(NAME|EMAIL)='; then
  deny "author/committer identity is being set via GIT_AUTHOR_*/GIT_COMMITTER_* environment variables"
fi
if printf '%s' "$cmd" | grep -qE 'GIT_CONFIG_(COUNT|KEY_[0-9]+|VALUE_[0-9]+|GLOBAL|SYSTEM|NOSYSTEM)='; then
  deny "GIT_CONFIG_* environment variables are being used to override git config for this command"
fi

# The same keys passed inline to git itself: `-c key=value`, `-ckey=value`, or
# `--config-env=key=ENVVAR`.
if printf '%s' "$cmd" | grep -qiE '(^|[[:space:]])(-c[[:space:]]*|--config-env=)(user\.(name|email|signingkey)|commit\.gpgsign|tag\.gpgsign|gpg\.)'; then
  deny "identity or signing config is being overridden inline with git -c/--config-env"
fi

# Signing turned off outright. Valid only on commands that create a commit, so no subcommand
# check is needed to rule out a read-only use.
if printf '%s' "$cmd" | grep -qE '(^|[[:space:]])--no-gpg-sign([[:space:]]|$)'; then
  deny "--no-gpg-sign disables commit signing"
fi

# Editing a git config file directly, rather than through git. Redirections only - reading
# these paths stays fine.
if printf '%s' "$cmd" | grep -qE '>>?[[:space:]]*[^[:space:]]*(\.git/config|\.gitconfig|git/config)'; then
  deny "a git config file is being written to directly"
fi

# ---------------------------------------------------------------------------
# Context-dependent overrides: these need to know which git subcommand they belong to.
#
# `--author` and `-S` are the awkward ones - `git log --author=x` and `git log -Sneedle` are
# perfectly ordinary searches, and only the commit-creating subcommands turn them into an
# override. So the command gets split into segments, and each git invocation in it is parsed
# far enough to name its subcommand.
# ---------------------------------------------------------------------------

lc() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]'; }

# Subcommands that write a commit and therefore accept --author / -S<keyid>. `git tag` is
# absent on purpose: it signs tags, not commits, and its own gpgsign key is covered above.
creates_commit() {
  case "$1" in
    commit | commit-tree | cherry-pick | revert | rebase | merge | am | citool) return 0 ;;
  esac
  return 1
}

# Split on shell separators so each segment holds at most one command. Mapping every one of
# ;&| to a newline handles && and || too, at the cost of empty segments - which are skipped.
# Newlines in the command need no translation: the read loop below already splits on them.
segments=$(printf '%s' "$cmd" | tr ';&|' '\n')

while IFS= read -r seg; do
  [ -n "$seg" ] || continue

  read -ra toks <<<"$seg" || true
  n=${#toks[@]}

  # Find the git invocation, stepping over any leading VAR=value assignments. An absolute or
  # relative path to git counts, a word merely containing "git" does not.
  i=0
  while [ "$i" -lt "$n" ]; do
    case "${toks[$i]}" in
      git | */git) break ;;
    esac
    i=$((i + 1))
  done
  [ "$i" -lt "$n" ] || continue
  i=$((i + 1))

  # Walk git's own options to reach the subcommand. The ones listed take a separate value,
  # which must be skipped so it can't be mistaken for the subcommand.
  sub=""
  while [ "$i" -lt "$n" ]; do
    case "${toks[$i]}" in
      -c | -C | --git-dir | --work-tree | --namespace | --exec-path | --config-env)
        i=$((i + 2))
        ;;
      -*)
        i=$((i + 1))
        ;;
      *)
        sub=$(lc "${toks[$i]}")
        i=$((i + 1))
        break
        ;;
    esac
  done
  [ -n "$sub" ] || continue

  if creates_commit "$sub"; then
    while [ "$i" -lt "$n" ]; do
      case "${toks[$i]}" in
        --author | --author=*)
          deny "git $sub is being given an explicit --author"
          ;;
        # An attached value is a specific key to sign with; a bare -S/--gpg-sign just signs
        # with the configured one and is left alone.
        -S?* | --gpg-sign=*)
          deny "git $sub is being pointed at a specific signing key instead of the configured one"
          ;;
      esac
      i=$((i + 1))
    done
  elif [ "$sub" = "config" ]; then
    # `git config` reaching any of the guarded keys is an override unless it is only reading
    # them. Covers the modern `git config set|unset ...` spellings as well, since the check
    # is on the key rather than on the verb.
    key_hit=0
    read_only=0
    for ((j = i; j < n; j++)); do
      case "$(lc "${toks[$j]}")" in
        --get | --get-all | --get-regexp | --get-urlmatch | --list | -l) read_only=1 ;;
        user.name* | user.email* | user.signingkey* | commit.gpgsign* | tag.gpgsign* | gpg.*) key_hit=1 ;;
      esac
    done
    if [ "$key_hit" -eq 1 ] && [ "$read_only" -eq 0 ]; then
      deny "git config is being used to change the identity or signing settings"
    fi
  fi
done <<<"$segments"

exit 0
