#!/usr/bin/env bash
set -euo pipefail

# PostToolUse hook: advisory check of the prose Claude just wrote to a Markdown file against the
# two mechanical bright lines in the global CLAUDE.md's target form for prose, no em dashes and
# no semicolons inside a sentence. Only the text of this edit is checked (the Write content or
# the Edit new_string), never the rest of the file, so pre-existing text in any repo is left
# alone. Fenced code blocks and inline code spans are stripped first. Colons are not checked,
# because their allowed uses (bullet headers, headings, tables, times, URLs) make a mechanical
# check noisy.
#
# Advisory only, always exits 0. Each repo's own CI remains the enforcement gate.

command -v jq >/dev/null 2>&1 || exit 0

input=$(cat)
file_path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty')
case "$file_path" in
  *.md | *.markdown | *.md.tmpl) ;;
  *) exit 0 ;;
esac

text=$(printf '%s' "$input" | jq -r '.tool_input.content // .tool_input.new_string // ([.tool_input.edits[]?.new_string] | join("\n"))')
[ -n "$text" ] || exit 0

# shellcheck disable=SC2016
stripped=$(printf '%s\n' "$text" | awk 'BEGIN{f=0} /^[[:space:]]*(```|~~~)/{f=!f; next} !f{print}' | sed 's/`[^`]*`//g')

hits=$(printf '%s\n' "$stripped" | grep -n -E '—|;' | cut -c1-200 | head -20 || true)
[ -n "$hits" ] || exit 0

jq -n --arg file "$file_path" --arg hits "$hits" \
  '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":("prose-lint: em dash or semicolon in the text just written to " + $file + " (advisory, not blocking). The target form for prose bans both inside a sentence. Code was stripped before checking. Line numbers count within the written text.\n" + $hits)}}'
