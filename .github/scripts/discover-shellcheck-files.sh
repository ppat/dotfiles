#!/usr/bin/env bash
# Discover the repo's shell scripts for the "shellcheck" full-sweep job in lint.yaml.
#
# Why this exists: the reusable ppat/github-workflows lint-shellcheck.yaml's own ALL-discovery
# selects files via `find ... -executable`. This repo is a chezmoi *source* tree: scripts are
# committed at git mode 100644 and only gain the executable bit at deploy time, applied by
# chezmoi via the `executable_` filename-prefix convention -- so -executable matches nothing
# here, and the shared workflow's ALL path is a dead end for this repo specifically. That's a
# storage convention this one consumer uses, not something the ~16-repo-shared workflow should
# have to know about, so the fix lives here instead.
#
# Discover shell files the way a human would recognize them, from how each file declares
# itself, not from its git mode:
#   - a shebang naming sh/bash/dash/ksh
#   - a `# shellcheck shell=...` directive -- how sourced files with no shebang (dot_bashrc,
#     dot_profile, private_dot_local/bash/*.bash) self-declare their dialect
#   - a .sh or .bash extension
#
# Chezmoi templates (*.tmpl) are excluded: they carry Go template syntax (`{{ }}`) that a
# shell linter cannot parse. They're rendered and linted separately by the "chezmoi" job
# elsewhere in lint.yaml.
set -euo pipefail

files=()
while IFS= read -r -d '' file; do
  file="${file#./}"

  case "${file}" in
    *.sh | *.bash)
      files+=("${file}")
      continue
      ;;
  esac

  read -r first_line < "${file}" || true
  if [[ "${first_line}" =~ ^#!.*[\ /](sh|bash|dash|ksh)([[:space:]]|$) ]]; then
    files+=("${file}")
    continue
  fi

  if grep -qE '^# shellcheck shell=(sh|bash|dash|ksh)([[:space:]]|$)' "${file}"; then
    files+=("${file}")
  fi
done < <(find . -type f -not -path './.git/*' -not -name '*.tmpl' -print0)

if [[ "${#files[@]}" -eq 0 ]]; then
  echo "::error::no shell files discovered -- the discovery predicate in" \
    "${BASH_SOURCE[0]} is likely broken (expected the repo's real shell inventory," \
    "e.g. dot_bashrc, private_dot_local/bin/executable_*)" >&2
  exit 1
fi

printf '%s\n' "${files[@]}" | sort
