#!/usr/bin/env bash
set -euo pipefail

# PermissionRequest hook. Approves plan-mode plan file writes in sessions started by `cc <account>`.
#
# `cc` points CLAUDE_CONFIG_DIR at ~/.claude-accounts/<account>, whose `plans` entry is a symlink into the
# shared store (~/.claude/plans) so every account sees the same plans. Claude Code writes plans to
# "$CLAUDE_CONFIG_DIR/plans/<slug>.md" and checks the write against both that path and the symlink target.
# Its plan-file exemption matches only the first; the target under ~/.claude trips the sensitive-path check,
# which auto mode cannot approve. There is no setting that moves the default plans folder (plansDirectory
# must sit inside the project), so this hook answers that one prompt instead.
#
# It approves only a Write or Edit of a plain `*.md` file directly inside "$CLAUDE_CONFIG_DIR/plans",
# and only when that folder is the link to the shared store's plans folder. Anything else gets no answer
# from this hook and prompts as usual.

input=$(cat)
tool=$(printf '%s' "$input" | jq -r '.tool_name // ""')
path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // ""')

case "$tool" in
  Write|Edit) ;;
  *) exit 0 ;;
esac

config="${CLAUDE_CONFIG_DIR:-}"
shared="${CLAUDE_SHARED_DIR:-$HOME/.claude}"
[[ -n "$config" && -d "$shared/plans" ]] || exit 0

plans="$config/plans"
[[ "$path" == "$plans/"* ]] || exit 0
name="${path#"$plans/"}"
[[ "$name" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*\.md$ ]] || exit 0

# The folder must be the cc-managed link into the shared store, and the file itself must not be a link.
[[ -L "$plans" ]] || exit 0
[[ "$(readlink -f "$plans")" == "$(readlink -f "$shared/plans")" ]] || exit 0
[[ ! -L "$path" ]] || exit 0

printf '{"hookSpecificOutput":{"hookEventName":"PermissionRequest","decision":{"behavior":"allow"}}}\n'
