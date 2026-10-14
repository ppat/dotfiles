#!/usr/bin/env bash
set -euo pipefail

# Run only on disposable CI runners or in the sandbox Homebrew container.
repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
source "$repo_dir/.chezmoitemplates/script_header.sh"
source "$repo_dir/.chezmoitemplates/homebrew-maintenance.sh"
command -v brew > /dev/null
test_dir=$(mktemp -d)
# Record native commands so final-state assertions cannot hide extra reinstalls.
brew() {
  printf '%s\n' "$*" >> "$test_dir/commands"
  command brew "$@"
}

assert_bundle_reinstalls() {
  local expected="$1" actual
  : > "$test_dir/commands"
  homebrew_bundle "$test_dir/Brewfile"
  actual=$(sed -n 's/^reinstall --formula //p' "$test_dir/commands")
  [[ "$actual" == "$expected" ]] || {
    printf 'Unexpected reinstalls. Expected [%s], got [%s]\n' "$expected" "$actual" >&2
    return 1
  }
}

assert_no_install_recovery() {
  [[ $(grep -c '^list --formula --versions$' "$test_dir/commands") == 1 ]]
  if grep -Eq '^(deps|reinstall) ' "$test_dir/commands"; then
    printf 'Successful bundle performed interrupted-install recovery queries\n' >&2
    return 1
  fi
}
export HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_INSTALL_CLEANUP=1 HOMEBREW_NO_ANALYTICS=1
export HOMEBREW_NO_INSTALLED_DEPENDENTS_CHECK=1
HOMEBREW_PREFIX=$(brew --prefix)
HOMEBREW_CELLAR=$(brew --cellar)
export HOMEBREW_PREFIX HOMEBREW_CELLAR
export HOMEBREW_CACHE="$test_dir/cache"
export XDG_STATE_HOME="$test_dir/state"
export HOMEBREW_RECOVERY_TEST_ARCHIVE="$test_dir/source.tar.gz"
mkdir -p "$test_dir/source" "$HOMEBREW_CACHE/Backup/bin"
printf '#!/bin/sh\necho recovery-fixture\n' > "$test_dir/source/dotfiles-recovery-test-tool"
chmod +x "$test_dir/source/dotfiles-recovery-test-tool"
tar -czf "$HOMEBREW_RECOVERY_TEST_ARCHIVE" -C "$test_dir/source" .
HOMEBREW_RECOVERY_TEST_SHA256=$(shasum -a 256 "$HOMEBREW_RECOVERY_TEST_ARCHIVE" | awk '{print $1}')
export HOMEBREW_RECOVERY_TEST_SHA256

cp -R "$repo_dir/tests/homebrew/fixtures" "$test_dir/tap"
git -C "$test_dir/tap" init -q
git -C "$test_dir/tap" add .
git -C "$test_dir/tap" -c user.name=CI -c user.email=ci@example.com -c commit.gpgsign=false commit -qm fixtures
if brew command trust > /dev/null 2>&1; then
  brew trust --tap "file://$test_dir/tap"
fi
brew tap dotfiles-recovery-test/fixtures "file://$test_dir/tap"

cleanup() {
  local formula
  for formula in recovery-consumer recovery-link-consumer recovery-backup recovery-conflict recovery-owner; do
    if brew list --formula "$formula" > /dev/null 2>&1; then
      brew uninstall --formula --ignore-dependencies "$formula" || :
    fi
  done
  brew untap dotfiles-recovery-test/fixtures || :
  rm -rf "$test_dir"
  [[ -z "${cross_device_cache:-}" ]] || rm -rf "$cross_device_cache"
}
trap cleanup EXIT

printf 'brew "dotfiles-recovery-test/fixtures/recovery-consumer"\n' > "$test_dir/Brewfile"
assert_bundle_reinstalls ''
assert_no_install_recovery
[[ -f "$HOMEBREW_CELLAR/recovery-backup/1.0/postinstall-complete" ]]
assert_bundle_reinstalls ''
assert_no_install_recovery
brew uninstall --formula recovery-consumer recovery-backup

brew install --formula dotfiles-recovery-test/fixtures/recovery-owner
printf 'brew "dotfiles-recovery-test/fixtures/recovery-conflict"\n' > "$test_dir/Brewfile"
assert_bundle_reinstalls ''
[[ -f "$HOMEBREW_CELLAR/recovery-conflict/1.0/postinstall-complete" ]]
[[ $(readlink "$HOMEBREW_PREFIX/bin/dotfiles-recovery-test-tool") == *recovery-conflict* ]]
assert_bundle_reinstalls ''
brew uninstall --formula recovery-conflict
brew unlink recovery-owner
brew link recovery-owner

printf 'brew "dotfiles-recovery-test/fixtures/recovery-link-consumer"\n' > "$test_dir/Brewfile"
assert_bundle_reinstalls ''
assert_no_install_recovery
[[ -f "$HOMEBREW_CELLAR/recovery-conflict/1.0/postinstall-complete" ]]
[[ $(readlink "$HOMEBREW_PREFIX/bin/dotfiles-recovery-test-tool") == *recovery-conflict* ]]
brew uninstall --formula recovery-link-consumer recovery-conflict
brew unlink recovery-owner
brew link recovery-owner

# A colliding backup must not let a retry skip a dependency's unfinished install.
ln -s "$HOMEBREW_CELLAR/recovery-owner/1.0/bin/dotfiles-recovery-test-tool" \
  "$HOMEBREW_CACHE/Backup/bin/dotfiles-recovery-test-tool"
printf 'brew "dotfiles-recovery-test/fixtures/recovery-consumer"\n' > "$test_dir/Brewfile"
assert_bundle_reinstalls recovery-backup
[[ -f "$HOMEBREW_CELLAR/recovery-backup/1.0/postinstall-complete" ]]
[[ $(readlink "$HOMEBREW_PREFIX/bin/dotfiles-recovery-test-tool") == *recovery-backup* ]]
assert_bundle_reinstalls ''

brew uninstall --formula recovery-consumer recovery-backup
brew unlink recovery-owner
brew link recovery-owner

# Crossing filesystems makes Ruby's move fall back to copying a symlink. A
# pre-existing destination then reproduces Homebrew's Backup EEXIST failure.
if [[ -d /dev/shm && -w /dev/shm ]]; then
  cross_device_cache=$(mktemp -d /dev/shm/homebrew-recovery.XXXXXXXX)
  export HOMEBREW_CACHE="$cross_device_cache"
  mkdir -p "$HOMEBREW_CACHE/Backup/bin"
  touch "$test_dir/previous-backup"
  ln -s "$test_dir/previous-backup" "$HOMEBREW_CACHE/Backup/bin/dotfiles-recovery-test-tool"
  assert_bundle_reinstalls recovery-backup
  [[ -f "$HOMEBREW_CELLAR/recovery-backup/1.0/postinstall-complete" ]]
  [[ $(readlink "$HOMEBREW_PREFIX/bin/dotfiles-recovery-test-tool") == *recovery-backup* ]]
  brew uninstall --formula recovery-consumer recovery-backup
fi

printf 'user file\n' > "$HOMEBREW_PREFIX/bin/dotfiles-recovery-test-tool"
printf 'brew "dotfiles-recovery-test/fixtures/recovery-conflict"\n' > "$test_dir/Brewfile"
if homebrew_bundle "$test_dir/Brewfile"; then
  printf 'Recovery replaced a user file\n' >&2
  exit 1
fi
[[ $(< "$HOMEBREW_PREFIX/bin/dotfiles-recovery-test-tool") == 'user file' ]]
rm "$HOMEBREW_PREFIX/bin/dotfiles-recovery-test-tool"

printf 'Native Homebrew recovery scenarios passed.\n'
