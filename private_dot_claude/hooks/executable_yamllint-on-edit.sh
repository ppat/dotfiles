#!/usr/bin/env bash
set -euo pipefail

# PostToolUse hook: yamllint a YAML file right after Claude edits it, in whatever repo
# Claude happens to be working in. Settings are user-level, so this fires everywhere - the
# point is to shorten the yamllint feedback loop generally, not to mirror any one repo's CI.
#
# Advisory only, always exits 0. It never sets a "block" decision: a hard block on a
# pre-existing violation in a file touched for an unrelated reason would leave an agent
# stuck, with no way past it. Each repo's own CI remains the enforcement gate.

# A missing tool must never turn this into a noisy or failing hook.
command -v jq >/dev/null 2>&1 || exit 0
command -v yamllint >/dev/null 2>&1 || exit 0

file_path=$(jq -r '.tool_input.file_path // empty')
[ -n "$file_path" ] && [ -f "$file_path" ] || exit 0

# Extension only - no content sniffing needed. A `*.yaml.tmpl` file doesn't end in .yaml or
# .yml, so chezmoi templates are already excluded here; rendering them is a property of how
# some repos store their files, not of whether the file is YAML.
case "$file_path" in
  *.yaml | *.yml) ;;
  *) exit 0 ;;
esac

# Unlike shellcheck, which finds .shellcheckrc by walking up from the target file's own
# directory, yamllint only looks in its current working directory and upward - it never looks
# relative to the file being linted. A hook running with some other cwd would silently miss
# the repo's own .yamllint, so the repo root has to be found and passed explicitly.
config_file=""
if command -v git >/dev/null 2>&1; then
  repo_root=$(git -C "$(dirname "$file_path")" rev-parse --show-toplevel 2>/dev/null) || repo_root=""
  if [ -n "$repo_root" ] && [ -f "$repo_root/.yamllint" ]; then
    config_file="$repo_root/.yamllint"
  fi
fi

# --strict turns warnings (e.g. a missing "---" document-start) into a non-zero exit too, so
# they reach the reporting branch below instead of being swallowed by `&& exit 0` on a
# warnings-only file. This hook stays advisory either way - --strict only affects whether a
# finding gets surfaced at all, not whether it can block anything.
if [ -n "$config_file" ]; then
  yl_output=$(yamllint --strict -c "$config_file" "$file_path" 2>&1) && exit 0
else
  yl_output=$(yamllint --strict "$file_path" 2>&1) && exit 0
fi

printf '%s\n' "$yl_output" >&2
jq -n --arg ctx "yamllint found issues in ${file_path} (advisory, not blocking):

${yl_output}" '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":$ctx}}'
