#!/usr/bin/env bash
set -euo pipefail

# PostToolUse hook: run markdownlint-cli2 on a Markdown file right after Claude edits it, in
# whatever repo Claude happens to be working in. Settings are user-level, so this fires
# everywhere - the point is to shorten the markdownlint feedback loop generally, not to
# mirror any one repo's CI.
#
# Advisory only, always exits 0. It never sets a "block" decision: a hard block on a
# pre-existing violation in a file touched for an unrelated reason would wedge an agent that
# has no way past it. Each repo's own CI remains the enforcement gate.

# A missing tool must never turn this into a noisy or failing hook.
command -v jq >/dev/null 2>&1 || exit 0
command -v markdownlint-cli2 >/dev/null 2>&1 || exit 0

file_path=$(jq -r '.tool_input.file_path // empty')
[ -n "$file_path" ] && [ -f "$file_path" ] || exit 0

case "$file_path" in
  *.md | *.markdown) ;;
  *) exit 0 ;;
esac

# markdownlint-cli2 resolves a repo's own .markdownlint-cli2.{yaml,jsonc,...} by walking up
# from the target file, independent of this shell's cwd - confirmed empirically, not from the
# --config help text. No --config is passed here: forcing one config on every repo would
# defeat the point of each repo choosing (or not choosing) its own rule set.
ml_output=$(markdownlint-cli2 "$file_path" 2>&1) && exit 0

printf '%s\n' "$ml_output" >&2
jq -n --arg ctx "markdownlint found issues in ${file_path} (advisory, not blocking):

${ml_output}" '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":$ctx}}'
