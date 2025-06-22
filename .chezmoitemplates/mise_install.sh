# shellcheck shell=bash

mise_prerequisites() {
  if ! command -v mise > /dev/null; then
    log_error "Mise | Mise binary is not in path, cannot proceed!"
    exit 1
  fi
}

show_mise_env() {
  log_info "Mise | Using mise env..."
  env | grep MISE | sort | sed -E 's|^(.*)|    \1|g'
}

activate_mise() {
  log_info "Mise | Activating Mise package manager..."
  eval "$(mise activate bash)" 2>&1 | sed -E 's|^(.*)|    \1|g'
}

install_or_upgrade_mise_packages() {
  log_info "Mise | Installing or upgrading mise packages..."
  mise upgrade --yes 2>&1 | sed -E 's|^(.*)|    \1|g'
  log_success "Mise | Mise install is complete."
}

display_installed_mise_packages() {
  log_success "Mise | Display installed packages..."
  mise ls 2>&1 | sed -E 's|^(.*)|    \1|g'
}
