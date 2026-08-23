#!/usr/bin/env bash
set -euo pipefail

# PostToolUse hook: shellcheck a shell script right after Claude edits it, in whatever repo
# Claude happens to be working in. Settings are user-level, so this fires everywhere - the
# point is to shorten the shellcheck feedback loop generally, not to mirror any one repo's CI.
#
# Advisory only, always exits 0. It never sets a "block" decision: a hard block on a
# pre-existing violation in a file touched for an unrelated reason would leave an agent
# stuck, with no way past it. Each repo's own CI remains the enforcement gate.

# A missing tool must never turn this into a noisy or failing hook.
command -v jq >/dev/null 2>&1 || exit 0
command -v shellcheck >/dev/null 2>&1 || exit 0

file_path=$(jq -r '.tool_input.file_path // empty')
[ -n "$file_path" ] && [ -f "$file_path" ] || exit 0

# Decide shell-ness from the file itself rather than from a path allowlist, so this keeps
# working in repos whose layout nobody anticipated. Extension first (cheap, and the only
# signal for sourced fragments that legitimately have no shebang), then the shebang - which
# is what catches the extension-less executables that most real scripts turn out to be.
# zsh is deliberately absent: shellcheck cannot analyse it and would only emit noise.
is_shell_script() {
  case "$1" in
    *.sh | *.bash | *.ksh | *.dash) return 0 ;;
    *.zsh) return 1 ;;
  esac
  head -n 1 "$1" 2>/dev/null | grep -qE '^#!.*[ /](sh|bash|dash|ksh)( |$)'
}

is_shell_script "$file_path" || exit 0

# A .shellcheckrc is found by walking up from the script's own directory, so each repo's own
# suppressions apply automatically with no path wiring needed here.
sc_output=$(shellcheck "$file_path" 2>&1) && exit 0

printf '%s\n' "$sc_output" >&2
jq -n --arg ctx "shellcheck found issues in ${file_path} (advisory, not blocking):

${sc_output}" '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":$ctx}}'
