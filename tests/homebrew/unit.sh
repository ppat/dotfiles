#!/usr/bin/env bash
set -euo pipefail

# Brew is a shell fixture throughout this test. No installed Brew is executed.
repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
source "$repo_dir/.chezmoitemplates/homebrew-maintenance.sh"
source <(sed -n '/^manage_homebrew_package_manager() {/,/^}/p' \
  "$repo_dir/.chezmoiscripts/run_before_10_homebrew.sh.tmpl")
test_dir=$(mktemp -d)
trap 'rm -rf "$test_dir"' EXIT

log_info() { printf '%s\n' "$*"; }
log_warning() { printf '%s\n' "$*"; }
log_error() { printf '%s\n' "$*"; }
log_success() { printf '%s\n' "$*"; }
sleep() { :; }

mv() {
  if [[ "$scenario" == changed-conflict && "$1" == "$HOMEBREW_PREFIX/bin/tool" ]]; then
    rm "$1"
    printf 'concurrent user file\n' > "$1"
  fi
  command mv "$@"
}

command() {
  if [[ "$*" == '-v brew' && "$scenario" == installer-* ]]; then
    return 1
  fi
  builtin command "$@"
}

curl() {
  case "$scenario" in
    installer-download-failure)
      printf 'touch %q\n' "$case_dir/installer-ran"
      return 7
      ;;
    installer-empty) return 0 ;;
    *) return 99 ;;
  esac
}

emit_live_output() {
  local acknowledgement status=0
  exec 5<> "$case_dir/acknowledgement"
  printf 'live stdout marker\n'
  printf 'live stderr marker\n' >&2
  # Completion requires a reader to have already received both output lines.
  read -r -t 5 acknowledgement <&5 || status=15
  exec 5>&-
  [[ "$status" == 0 && "$acknowledgement" == received ]] || return 15
}

brew() {
  printf '%s\n' "$*" >> "$case_dir/commands"
  case "$1 ${2:-}" in
    'command trust') [[ "$scenario" != legacy-trust ]] || return 1 ;;
    'list --formula')
      if [[ "$scenario" == interrupted || "$scenario" == reinstall-failure || "$scenario" == successful-install || "$scenario" == completed-before-failure ]]; then
        if [[ -f "$case_dir/attempt" ]]; then
          printf 'dependency@2 2.0\n'
        fi
      fi
      if [[ "$scenario" == concurrent-install && -f "$case_dir/attempt" ]]; then
        printf 'unrelated 1.0\n'
      fi
      ;;
    'reinstall --formula')
      [[ "$scenario" != reinstall-failure ]] || return 16
      [[ "$3" == dependency@2 ]]
      touch "$case_dir/install-complete"
      ;;
    'bundle list')
      [[ "$scenario" != list-failure ]] || return 7
      if [[ "$*" == *'--tap'* ]]; then
        printf '%s\n' "$mock_entries"
      else
        printf 'consumer\n'
      fi
      ;;
    'deps --installed') printf 'dependency@2\n' ;;
    'trust --tap')
      [[ "$scenario" != trust-failure ]] || return 8
      ;;
    'bundle --file='*)
      [[ "$*" == *' --verbose' ]] || return 98
      local attempt=0
      [[ ! -f "$case_dir/attempt" ]] || read -r attempt < "$case_dir/attempt"
      attempt=$((attempt + 1))
      printf '%s\n' "$attempt" > "$case_dir/attempt"
      case "$scenario" in
        live-bundle) emit_live_output || return ;;
        successful-install) printf 'Bundle complete without formula summaries\n' ;;
        completed-before-failure)
          printf '%s/dependency@2/2.0: 5 files, 16KB\n' "$HOMEBREW_CELLAR"
          [[ $attempt -gt 1 ]] || return 6
          ;;
        interrupted|reinstall-failure)
          if [[ ! -f "$case_dir/install-complete" ]]; then
            printf 'Installation interrupted\n'
            return 1
          fi
          ;;
        unknown-suggestion)
          printf 'Could not symlink bin/tool\n  brew link --overwrite --formula dependency@2\n'
          return 1
          ;;
        successful-dependency-link-failure)
          printf 'Could not symlink bin/tool\n  brew link --overwrite dependency@2\n'
          return 0
          ;;
        permanent) printf 'Permission denied\n'; return 9 ;;
        transient) [[ $attempt -gt 1 ]] || { printf 'Download failed\n'; return 6; } ;;
        concurrent-install) [[ $attempt -gt 1 ]] || { printf 'Download failed\n'; return 6; } ;;
        link|regular-file|external-link|mixed|repair-failure|dry-run-failure|unknown-dry-run|changed-conflict)
          if [[ ! -f "$case_dir/repaired" ]]; then
            printf 'Error linking dependency\n  brew link --overwrite dependency@2\n'
            return 1
          fi
          ;;
        backup|backup-outside|same-file-prefix)
          if [[ -e "$HOMEBREW_CACHE/Backup/bin/tool" ]]; then
            if [[ "$scenario" == same-file-prefix ]]; then
              printf '::error::consumer: same file: %s/bin/tool and %s/Backup/bin/tool\n' "$HOMEBREW_PREFIX" "$HOMEBREW_CACHE"
            else
              printf 'Error: consumer: File exists @ syserr_fail2_in - %s/Backup/bin/tool\n' "$HOMEBREW_CACHE"
            fi
            return 1
          fi
          ;;
      esac
      ;;
    'link --overwrite')
        [[ "$scenario" != dry-run-failure ]] || return 10
        if [[ "$scenario" == unknown-dry-run ]]; then
          printf 'Would remove:\n  unexpected indented output\n'
          return 0
        fi
        printf 'Would remove:\n%s/bin/tool -> %s\n' "$HOMEBREW_PREFIX" "$HOMEBREW_CELLAR/old/1/bin/tool"
        [[ "$scenario" != mixed ]] || printf '%s/bin/user-file\n' "$HOMEBREW_PREFIX"
      ;;
    'link dependency@2')
      [[ "$scenario" != repair-failure ]] || return 11
      ln -s "$HOMEBREW_CELLAR/dependency@2/2/bin/tool" "$HOMEBREW_PREFIX/bin/tool"
      touch "$case_dir/repaired"
      ;;
    'cleanup ')
      printf 'cleanup diagnostic\n'
      [[ "$scenario" != cleanup-failure ]] || return 12
      ;;
    'update ')
      local update_attempt=0
      [[ ! -f "$case_dir/update-attempt" ]] || read -r update_attempt < "$case_dir/update-attempt"
      update_attempt=$((update_attempt + 1))
      printf '%s\n' "$update_attempt" > "$case_dir/update-attempt"
      [[ "$scenario" != update-permanent ]] || return 13
      [[ $update_attempt -gt 1 ]] || return 14
      ;;
    *) printf 'Unexpected mock Brew command %s\n' "$*" >&2; return 99 ;;
  esac
}

setup_case() {
  scenario="$1"
  case_dir="$test_dir/$scenario"
  export HOMEBREW_PREFIX="$case_dir/prefix"
  export HOMEBREW_CELLAR="$HOMEBREW_PREFIX/Cellar"
  export HOMEBREW_CACHE="$case_dir/cache"
  export XDG_STATE_HOME="$case_dir/state"
  export TMPDIR="$case_dir/tmp"
  mock_entries=''
  mkdir -p "$HOMEBREW_PREFIX/bin" "$HOMEBREW_CELLAR/old/1/bin" \
    "$HOMEBREW_CELLAR/dependency@2/2/bin" "$HOMEBREW_CACHE/Backup/bin" "$TMPDIR"
  touch "$case_dir/Brewfile" "$case_dir/commands" "$HOMEBREW_CELLAR/old/1/bin/tool"
  ln -s ../Cellar/old/1/bin/tool "$HOMEBREW_PREFIX/bin/tool"
}

assert_attempts() {
  local actual=0
  [[ ! -f "$case_dir/attempt" ]] || read -r actual < "$case_dir/attempt"
  [[ "$actual" == "$1" ]] || { printf 'Expected %s attempts, got %s\n' "$1" "$actual"; exit 1; }
}

assert_no_install_recovery() {
  [[ $(grep -c '^list --formula --versions$' "$case_dir/commands") == 1 ]]
  if grep -Eq '^(deps|reinstall) ' "$case_dir/commands"; then exit 1; fi
  [[ -z $(find "$TMPDIR" -mindepth 1 -print) ]]
}

assert_failure() {
  local status=0
  homebrew_bundle "$case_dir/Brewfile" > "$case_dir/output" 2>&1 || status=$?
  [[ "$status" == "$1" ]] || { printf 'Expected status %s, got %s\n' "$1" "$status"; exit 1; }
}

assert_live_output() {
  local line
  mkfifo "$case_dir/acknowledgement"
  exec 6<> "$case_dir/acknowledgement"
  "$@" | while IFS= read -r line; do
    printf '%s\n' "$line" >> "$case_dir/output"
    if [[ "$line" == *'live stderr marker'* ]]; then
      grep -q 'live stdout marker' "$case_dir/output" || exit 1
      printf 'received\n' >&6
    fi
  done
  exec 6>&-
  [[ $(grep -c 'live stdout marker' "$case_dir/output") == 1 ]]
  [[ $(grep -c 'live stderr marker' "$case_dir/output") == 1 ]]
}

setup_case live-bundle
assert_live_output homebrew_bundle "$case_dir/Brewfile"
assert_attempts 1

setup_case no-taps
homebrew_bundle "$case_dir/Brewfile"
assert_attempts 1
assert_no_install_recovery
if grep -q '^trust' "$case_dir/commands"; then exit 1; fi

setup_case taps
mock_entries=$'owner/tap\nowner/tap/formula\nother/tools/cask\nhomebrew/core/formula'
homebrew_bundle "$case_dir/Brewfile"
[[ $(grep -c '^trust --tap' "$case_dir/commands") == 2 ]]
if grep -q '^trust --tap homebrew/' "$case_dir/commands"; then exit 1; fi

setup_case list-failure
assert_failure 7
assert_attempts 0

setup_case legacy-trust
mock_entries=owner/tap
homebrew_bundle "$case_dir/Brewfile"
assert_attempts 1
if grep -q '^trust' "$case_dir/commands"; then exit 1; fi

setup_case trust-failure
mock_entries=owner/tap
assert_failure 8
assert_attempts 0
[[ $(grep -c '^trust --tap' "$case_dir/commands") == 3 ]]

setup_case transient
homebrew_bundle "$case_dir/Brewfile"
assert_attempts 2

setup_case permanent
assert_failure 9
assert_attempts 3
[[ -z $(find "$TMPDIR" -type f -print) ]]

setup_case interrupted
homebrew_bundle "$case_dir/Brewfile"
assert_attempts 2
[[ -f "$case_dir/install-complete" ]]

setup_case reinstall-failure
assert_failure 16
assert_attempts 1

for successful_case in successful-install completed-before-failure; do
  setup_case "$successful_case"
  homebrew_bundle "$case_dir/Brewfile"
  if grep -q '^reinstall' "$case_dir/commands"; then exit 1; fi
  if [[ "$successful_case" == successful-install ]]; then
    assert_attempts 1
    assert_no_install_recovery
  else
    assert_attempts 2
  fi
done

setup_case concurrent-install
homebrew_bundle "$case_dir/Brewfile"
assert_attempts 2
if grep -q '^reinstall' "$case_dir/commands"; then exit 1; fi

setup_case link
homebrew_bundle "$case_dir/Brewfile"
assert_attempts 2
[[ $(readlink "$HOMEBREW_PREFIX/bin/tool") == "$HOMEBREW_CELLAR/dependency@2/2/bin/tool" ]]
archive_link=$(find "$XDG_STATE_HOME" -type l -print)
[[ $(readlink "$archive_link") == ../Cellar/old/1/bin/tool ]]

setup_case successful-dependency-link-failure
homebrew_bundle "$case_dir/Brewfile"
assert_attempts 1
assert_no_install_recovery
[[ -f "$case_dir/repaired" ]]
[[ $(readlink "$HOMEBREW_PREFIX/bin/tool") == "$HOMEBREW_CELLAR/dependency@2/2/bin/tool" ]]

setup_case regular-file
rm "$HOMEBREW_PREFIX/bin/tool"
printf 'user content\n' > "$HOMEBREW_PREFIX/bin/tool"
assert_failure 1
assert_attempts 1
[[ $(< "$HOMEBREW_PREFIX/bin/tool") == 'user content' ]]

setup_case external-link
ln -sf "$case_dir/Brewfile" "$HOMEBREW_PREFIX/bin/tool"
assert_failure 1
assert_attempts 1
[[ $(readlink "$HOMEBREW_PREFIX/bin/tool") == "$case_dir/Brewfile" ]]

setup_case mixed
touch "$HOMEBREW_PREFIX/bin/user-file"
assert_failure 1
assert_attempts 1
[[ $(readlink "$HOMEBREW_PREFIX/bin/tool") == ../Cellar/old/1/bin/tool ]]
[[ ! -e "$XDG_STATE_HOME" ]]

setup_case changed-conflict
assert_failure 1
assert_attempts 1
[[ $(< "$HOMEBREW_PREFIX/bin/tool") == 'concurrent user file' ]]
if grep -q '^link dependency@2' "$case_dir/commands"; then exit 1; fi

setup_case repair-failure
assert_failure 11
assert_attempts 1

setup_case dry-run-failure
assert_failure 10
assert_attempts 1

setup_case unknown-dry-run
assert_failure 1
assert_attempts 1
[[ $(readlink "$HOMEBREW_PREFIX/bin/tool") == ../Cellar/old/1/bin/tool ]]

setup_case unknown-suggestion
assert_failure 1
assert_attempts 1
[[ $(readlink "$HOMEBREW_PREFIX/bin/tool") == ../Cellar/old/1/bin/tool ]]

setup_case backup
printf 'previous backup\n' > "$HOMEBREW_CACHE/Backup/bin/tool"
homebrew_bundle "$case_dir/Brewfile"
assert_attempts 2
archive_file=$(find "$XDG_STATE_HOME" -type f -print)
[[ $(< "$archive_file") == 'previous backup' ]]

setup_case backup-outside
rmdir "$HOMEBREW_CACHE/Backup/bin"
ln -s "$case_dir" "$HOMEBREW_CACHE/Backup/bin"
touch "$case_dir/tool"
assert_failure 1
assert_attempts 1
[[ -e "$case_dir/tool" ]]

setup_case same-file-prefix
printf 'previous backup\n' > "$HOMEBREW_CACHE/Backup/bin/tool"
homebrew_bundle "$case_dir/Brewfile"
assert_attempts 2
archive_file=$(find "$XDG_STATE_HOME" -type f -print)
[[ $(< "$archive_file") == 'previous backup' ]]

setup_case cleanup-failure
cleanup_homebrew_cache > "$case_dir/output"
if grep -q 'cleanup diagnostic' "$case_dir/output"; then exit 1; fi
grep -q 'Homebrew cleanup failed; cache not reclaimed this run, continuing' "$case_dir/output"
[[ -z $(find "$TMPDIR" -type f -print) ]]

setup_case update-transient
manage_homebrew_package_manager
[[ $(< "$case_dir/update-attempt") == 2 ]]

setup_case update-permanent
status=0
manage_homebrew_package_manager > "$case_dir/output" 2>&1 || status=$?
[[ "$status" == 13 ]]
[[ $(< "$case_dir/update-attempt") == 3 ]]
if grep -q 'has been updated' "$case_dir/output"; then exit 1; fi

for installer_case in installer-download-failure installer-empty; do
  setup_case "$installer_case"
  status=0
  manage_homebrew_package_manager > "$case_dir/output" 2>&1 || status=$?
  [[ "$status" != 0 && ! -e "$case_dir/installer-ran" ]]
  if grep -q 'install completed' "$case_dir/output"; then exit 1; fi
done

printf 'Homebrew maintenance failure scenarios passed.\n'
