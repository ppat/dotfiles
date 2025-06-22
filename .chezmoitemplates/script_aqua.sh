# shellcheck shell=bash
aqua_prerequisites() {
  local setup_type="$1"
  log_info "Aqua | $setup_type | Initializing Aqua..."
  if ! command -v aqua > /dev/null; then
    log_error "Aqua | $setup_type | Aqua binary is not in path, cannot proceed!"
    exit 1
  fi
}

show_aqua_env() {
  local setup_type="$1"
  log_info "Aqua | $setup_type | Using aqua env..."
  env | grep '^AQUA' | sort | sed -E 's|^(.*)|    \1|g'
}

setup_aqua_packages() {
  local setup_type="$1"
  log_info "Aqua | $setup_type | Installing or upgrading aqua packages..."
  if [[ "$setup_type" == "First-Time" ]]; then
    aqua install 2>&1 | sed -E 's|^(.*)|  \1|g'
  else
    aqua install --all 2>&1 | sed -E 's|^(.*)|  \1|g'
  fi
  log_success "Aqua | $setup_type | Aqua install is complete."
}

display_installed_aqua_packages() {
  local setup_type="$1"
  log_info "Aqua | $setup_type | Display installed packages..."
  aqua list --installed --all | column -t 2>&1 | sed -E 's|^(.*)|  \1|g'
}
