# shellcheck shell=bash

homebrew_indent_output() {
  local line
  while IFS= read -r line || [[ -n "$line" ]]; do
    printf '    %s\n' "$line"
  done
}

homebrew_retry() {
  local attempt status
  for attempt in 1 2 3; do
    if "$@" 2>&1 | homebrew_indent_output; then
      return 0
    else
      status=$?
    fi
    if [[ $attempt -lt 3 ]]; then
      log_warning "Homebrew | Command failed, retrying attempt $((attempt + 1)) of 3..."
      sleep "$((attempt * 2))"
    fi
  done
  return "$status"
}

manage_homebrew_trusted_taps() {
  local brew_file="$1" entries tap taps
  # Let Homebrew evaluate the Brewfile, including conditionals and single quotes.
  entries=$(brew bundle list --file="$brew_file" --tap --formula --cask) || return
  taps=$(printf '%s\n' "$entries" | awk -F/ 'NF >= 2 { print $1 "/" $2 }' | sort -u) || return
  [[ -n "$taps" ]] || return 0
  # Releases without explicit tap trust use their native tap policy.
  if ! brew command trust > /dev/null 2>&1; then
    return 0
  fi
  log_info "Homebrew | Trusting third-party taps..."
  while IFS= read -r tap; do
    case "$tap" in homebrew/core|homebrew/cask) continue ;; esac
    # Bundle installs taps using their declared clone URLs and options.
    homebrew_retry brew trust --tap "$tap" || return
  done <<< "$taps"
}

homebrew_recovery_directory() {
  local state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/homebrew/recovery"
  mkdir -p "$state_dir" || return
  mktemp -d "$state_dir/recovery.XXXXXXXX"
}

homebrew_preserve_backup_conflicts() {
  local log_file="$1" path relative archive parent conflicts
  conflicts=$(sed -n -e 's/^.*File exists @ syserr_fail2_in - //p' \
    -e 's/^.*same file: .* and //p' "$log_file" | sort -u) || return
  [[ -n "$conflicts" ]] || return 0
  while IFS= read -r path; do
    case "$path" in
      "$HOMEBREW_CACHE/Backup/"*) ;;
      *) continue ;;
    esac
    relative=${path#"$HOMEBREW_CACHE/Backup/"}
    case "/$relative/" in *'/../'*|*'/./'*|*'//'*) return 1 ;; esac
    [[ -e "$path" || -L "$path" ]] || continue
    # Never follow a symlinked backup directory outside Homebrew's cache.
    parent=$(cd -P "$(dirname "$path")" && pwd) || return
    [[ "$parent/" == "$HOMEBREW_CACHE/Backup/"* ]] || return 1
    archive=$(homebrew_recovery_directory) || return
    mkdir -p "$archive/$(dirname "$relative")" || return
    mv "$path" "$archive/$relative" || return
    log_warning "Homebrew | Preserved colliding backup in $archive before retrying."
  done <<< "$conflicts"
}

homebrew_repair_links() {
  local log_file="$1" formula dry_run path target parent archive relative formulae index
  local paths=() targets=()
  local formula_pattern='^[[:space:]]*brew link --overwrite ([a-zA-Z0-9][a-zA-Z0-9@+._/-]*)[[:space:]]*$'
  formulae=$(sed -En "s|$formula_pattern|\1|p" "$log_file" | sort -u) || return
  if [[ -z "$formulae" ]]; then
    if grep -F 'Could not symlink' "$log_file" > /dev/null; then
      log_error "Homebrew | Cannot identify the formula for a link failure, stopping recovery."
      return 1
    fi
    return 0
  fi
  while IFS= read -r formula; do
    dry_run=$(brew link --overwrite --dry-run "$formula") || return
    # Fail closed if Homebrew changes the dry-run output format.
    [[ "${dry_run%%$'\n'*}" == 'Would remove:' ]] || return 1
    dry_run=${dry_run#'Would remove:'}
    archive=''
    paths=() targets=()
    while IFS= read -r path; do
      [[ -n "$path" ]] || continue
      [[ "$path" == /* ]] || return 1
      path=${path%% -> *}
      [[ "$path" == "$HOMEBREW_PREFIX/"* && -L "$path" ]] || {
        log_error "Homebrew | Link conflict needs manual resolution at $path."
        return 1
      }
      relative=${path#"$HOMEBREW_PREFIX/"}
      case "/$relative/" in *'/../'*|*'/./'*|*'//'*) return 1 ;; esac
      parent=$(cd -P "$(dirname "$path")" && pwd) || return
      [[ "$parent/" == "$HOMEBREW_PREFIX/"* ]] || return 1
      target=$(readlink "$path") || return
      paths+=("$path") targets+=("$target")
      [[ "$target" == /* ]] || target="$(dirname "$path")/$target"
      parent=$(cd -P "$(dirname "$target")" && pwd) || return
      [[ "$parent/" == "$HOMEBREW_CELLAR/"* ]] || {
        log_error "Homebrew | Refusing to replace a link outside the Cellar at $path."
        return 1
      }
    done <<< "$dry_run"
    # Validate every conflict before preserving or replacing any of them.
    for index in "${!paths[@]}"; do
      path=${paths[$index]}
      if [[ -z "$archive" ]]; then
        archive=$(homebrew_recovery_directory) || return
      fi
      relative=${path#"$HOMEBREW_PREFIX/"}
      mkdir -p "$archive/$(dirname "$relative")" || return
      mv "$path" "$archive/$relative" || return
      if [[ ! -L "$archive/$relative" || $(readlink "$archive/$relative") != "${targets[$index]}" ]]; then
        mv -n "$archive/$relative" "$path" || return
        log_error "Homebrew | Conflict changed during recovery at $path. Preserved entries are in $archive."
        return 1
      fi
    done
    [[ -z "$archive" ]] || log_warning "Homebrew | Preserved displaced links in $archive."
    # Ordinary linking refuses new conflicts that appear after validation.
    brew link "$formula" 2>&1 | homebrew_indent_output || return
  done <<< "$formulae"
}

homebrew_finish_interrupted_installs() {
  local before="$1" after="$2" log_file="$3" brew_file="$4" formula changed roots dependencies allowed
  local declared=()
  # Compare Homebrew's installed versions, not guessed package names from errors.
  changed=$(awk 'FILENAME == ARGV[1] { previous[$0] = 1; next }
    !($0 in previous) { print $1 }' "$before" "$after") || return
  [[ -n "$changed" ]] || return 0
  roots=$(brew bundle list --file="$brew_file" --formula) || return
  [[ -n "$roots" ]] || return 0
  while IFS= read -r formula; do declared+=("$formula"); done <<< "$roots"
  dependencies=$(brew deps --installed --union --full-name --include-build --include-optional \
    "${declared[@]}") || return
  allowed=$(printf '%s\n%s\n' "$roots" "$dependencies" | awk -F/ '{ print $NF }' | sort -u) || return
  while IFS= read -r formula; do
    # A concurrent Brew operation can change an unrelated installed formula.
    grep -Fx -- "$formula" <<< "$allowed" > /dev/null || continue
    # The install summary follows linking and post-install work. Without it,
    # a newly poured dependency can be installed but unfinished, and Bundle
    # can skip it on retry. Reinstall keeps Homebrew's recorded build options.
    if grep -F "$HOMEBREW_CELLAR/$formula/" "$log_file" | grep -E ':[[:space:]]+[0-9,]+ files?,[[:space:]]' > /dev/null; then
      continue
    fi
    log_warning "Homebrew | Completing interrupted installation of $formula..."
    brew reinstall --formula "$formula" 2>&1 | homebrew_indent_output || return
  done <<< "$changed"
}

homebrew_bundle() (
  local brew_file="$1" work_dir log_file before after attempt status
  [[ -r "$brew_file" ]] || { log_error "Homebrew | Cannot read $brew_file."; return 1; }
  work_dir=$(mktemp -d "${TMPDIR:-/tmp}/homebrew-bundle.XXXXXXXX") || return
  trap 'rm -rf "$work_dir"' EXIT
  log_file="$work_dir/output"
  before="$work_dir/before"
  after="$work_dir/after"
  manage_homebrew_trusted_taps "$brew_file" || return
  for attempt in 1 2 3; do
    brew list --formula --versions > "$before" || return
    status=0
    # Verbose output includes completion summaries even for successful installs.
    if brew bundle --file="$brew_file" --verbose 2>&1 | tee "$log_file" | homebrew_indent_output; then
      status=0
    else
      status=$?
    fi
    # Bundle can report success despite a dependency's link failure. Inspect
    # link diagnostics regardless of its exit status. Reinstall only after a
    # failed bundle, never because a successful bundle omitted a summary.
    homebrew_preserve_backup_conflicts "$log_file" || return
    homebrew_repair_links "$log_file" || return
    [[ "$status" != 0 ]] || return 0
    brew list --formula --versions > "$after" || return
    homebrew_finish_interrupted_installs "$before" "$after" "$log_file" "$brew_file" || return
    if [[ $attempt -lt 3 ]]; then
      log_warning "Homebrew | Bundle failed, retrying attempt $((attempt + 1)) of 3..."
      sleep "$((attempt * 2))"
    fi
  done
  log_error "Homebrew | Bundle failed after 3 attempts for $brew_file."
  return "$status"
)

cleanup_homebrew_cache() (
  # HOMEBREW_NO_INSTALL_CLEANUP (see .chezmoitemplates/homebrew.env) turns off the automatic
  # cleanup that races Homebrew's own parallel downloads. Reclaim the cache deterministically
  # here instead -- unconditionally, but only once `brew bundle` is done and nothing is
  # downloading concurrently -- so disabling that cleanup doesn't let the cache grow forever.
  #
  # Housekeeping must never fail a bootstrap that otherwise succeeded, and must never *look*
  # like one either: that misreading is the whole point of this ticket. So the output is
  # buffered and only replayed when cleanup worked; a failure collapses to a single warning
  # and the script carries on.
  local cleanup_log
  cleanup_log=$(mktemp "${TMPDIR:-/tmp}/homebrew-cleanup.XXXXXXXX") || {
    log_warning "Homebrew | Cannot create cleanup log, skipping cleanup."
    return 0
  }
  trap 'rm -f "$cleanup_log"' EXIT
  log_info "Homebrew | Cleaning up old versions and stale downloads..."
  if brew cleanup > "$cleanup_log" 2>&1; then
    sed 's/^/    /' "$cleanup_log"
    log_success "Homebrew | Homebrew cleanup completed."
  else
    log_warning "Homebrew | Homebrew cleanup failed; cache not reclaimed this run, continuing."
  fi
)
