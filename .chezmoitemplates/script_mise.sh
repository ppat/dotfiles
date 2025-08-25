# shellcheck shell=bash

mise_prerequisites() {
  local setup_type="$1"
  if ! command -v mise > /dev/null; then
    log_error "Mise | $setup_type | Mise binary is not in path, cannot proceed!"
    exit 1
  fi
}

show_mise_env() {
  local setup_type="$1"
  log_info "Mise | $setup_type | Using mise env..."
  env | grep '^MISE' | sort | sed -E 's|^(.*)|    \1|g'
}

display_installed_mise_packages() {
  local setup_type="$1"
  log_success "Mise | $setup_type | Display installed packages..."
  mise ls 2>&1 | sed -E 's|^(.*)|    \1|g'
}

setup_mise_packages() {
  local setup_type="$1"

  log_info "Mise | $setup_type | Activating Mise..."
  eval "$(mise activate bash)" 2>&1 | sed -E 's|^(.*)|    \1|g'

  log_info "Mise | $setup_type | Installing or upgrading mise packages..."
  mise upgrade --yes 2>&1 | sed -E 's|^(.*)|    \1|g'
  log_success "Mise | $setup_type | Mise install is complete."
}
