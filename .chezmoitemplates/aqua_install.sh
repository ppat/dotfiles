# shellcheck shell=bash

aqua_install() {
  log_info "CLI Tools | Initializing Aqua..."
  if ! command -v aqua > /dev/null; then
    log_error "CLI Tools | Aqua binary is not in path, cannot proceed!"
    exit 1
  fi
  log_info "CLI Tools | Installing or upgrading aqua packages..."
  aqua install --all 2>&1 | sed -E 's|^(.*)|  \1|g'
  log_success "CLI Tools | Aqua install is complete."
  echo
  log_info "CLI Tools | Display installed packages..."
  aqua list --installed --all | column -t 2>&1 | sed -E 's|^(.*)|  \1|g'
}
