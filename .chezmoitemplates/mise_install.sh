# shellcheck shell=bash

mise_install() {
  log_info "Language SDKs & Tools | Activating Mise package manager..."
  if ! command -v mise > /dev/null; then
    log_error "Language SDKs & Tools | Mise binary is not in path, cannot proceed!"
    exit 1
  fi
  eval "$(mise activate bash)" 2>&1 | sed -E 's|^(.*)|    \1|g'
  log_info "Language SDKs & Tools | Installing or upgrading mise packages..."
  mise upgrade --yes 2>&1 | sed -E 's|^(.*)|    \1|g'
  log_success "Language SDKs & Tools | Mise install is complete."
  echo
  log_success "Language SDKs & Tools | Display installed packages..."
  mise ls 2>&1 | sed -E 's|^(.*)|    \1|g'
}
