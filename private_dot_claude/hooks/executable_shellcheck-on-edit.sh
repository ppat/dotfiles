#!/usr/bin/env bash
set -euo pipefail

# PostToolUse hook: run shellcheck against a shell script right after Claude edits it, so
# feedback that would otherwise only arrive from CI on push shows up at edit time instead.
#
# Scope is intentionally the same set of paths lint.yaml's chezmoi/shellcheck jobs already
# treat as shell scripts (see TESTING.md) - this hook doesn't invent new lint coverage, it
# just moves the existing one earlier. `.chezmoitemplates/*` is deliberately excluded: those
# are template partials assembled into other scripts, not standalone valid shell, and CI never
# lints them directly either.
#
# Always exits 0: this is a heads-up, not a gate. It never sets a "block" decision, because a
# hard block on a pre-existing violation in a file touched for an unrelated reason would wedge
# an agent that can't get past it. CI remains the actual enforcement backstop.

input=$(cat)

file_path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty')

if [ -z "$file_path" ] || [ ! -f "$file_path" ]; then
  exit 0
fi

repo_root=$(git -C "$(dirname "$file_path")" rev-parse --show-toplevel 2>/dev/null || true)
if [ -z "$repo_root" ]; then
  exit 0
fi

rel_path=${file_path#"$repo_root"/}

in_scope=0
case "$rel_path" in
  .chezmoiscripts/*.tmpl) in_scope=1 ;;
  private_dot_local/bin/*) in_scope=1 ;;
  private_dot_local/bash/*) in_scope=1 ;;
  private_dot_config/mise/tasks/*) in_scope=1 ;;
  dot_bashrc | dot_profile) in_scope=1 ;;
  private_dot_claude/hooks/*.sh) in_scope=1 ;;
esac

if [ "$in_scope" -eq 0 ]; then
  exit 0
fi

# Degrade gracefully: a broken/missing toolchain must never turn into a noisy or hanging hook.
if ! command -v shellcheck >/dev/null 2>&1; then
  exit 0
fi

report() {
  # $1: message body. Printed for a human watching the transcript, and surfaced to Claude via
  # additionalContext so it can act on it - without ever setting "decision":"block".
  printf '%s\n' "$1" >&2
  jq -n --arg ctx "$1" '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":$ctx}}'
}

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

target="$file_path"
render_note=""

case "$file_path" in
  *.tmpl)
    if ! command -v chezmoi >/dev/null 2>&1; then
      exit 0
    fi

    patched="$tmpdir/patched.tmpl"
    cp "$file_path" "$patched"
    # Same two patches lint.yaml applies before rendering (see .github/workflows/lint.yaml,
    # "Shellcheck chezmoi scripts" step): force the darwin-only branches to evaluate against
    # this machine's real (linux) .chezmoi.os, and replace bitwardenSecrets calls with a
    # literal so rendering never shells out to fetch a real secret on every edit.
    sed -i 's|"darwin"|"linux"|' "$patched"
    sed -i 's|{{ (bitwardenSecrets ".*" .bwsAccessToken).value }}|fake-test-value|' "$patched"

    rendered="$tmpdir/rendered"
    if ! chezmoi execute-template --source="$repo_root" <"$patched" >"$rendered" 2>"$tmpdir/render.err"; then
      err=$(tail -c 500 "$tmpdir/render.err")
      report "shellcheck-on-edit: could not render ${rel_path} via 'chezmoi execute-template' (lint skipped). ${err}"
      exit 0
    fi
    target="$rendered"
    render_note=" (rendered from template)"
    ;;
esac

if [ ! -s "$target" ]; then
  # Empty render (e.g. a darwin-only script rendered on linux) - nothing to lint.
  exit 0
fi

rcflag=()
[ -f "$repo_root/.shellcheckrc" ] && rcflag=(--rcfile "$repo_root/.shellcheckrc")

# Shellcheck picks a dialect from the filename extension when there's no shebang, which
# matters for extension-less/no-shebang sourced files (private_dot_local/bash/*, dot_bashrc,
# dot_profile); reuse the original file's basename against the rendered content so that still
# works correctly.
sc_target="$tmpdir/$(basename "${file_path%.tmpl}")"
[ "$target" = "$sc_target" ] || cp "$target" "$sc_target"

if sc_output=$(shellcheck "${rcflag[@]}" "$sc_target" 2>&1); then
  exit 0
fi

sc_output=${sc_output//$sc_target/$rel_path}
report "shellcheck found issues in ${rel_path}${render_note} (non-blocking, mirrors CI's shellcheck job):

${sc_output}"
