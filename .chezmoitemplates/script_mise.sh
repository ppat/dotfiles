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

# [bootstrap.packages] (e.g. conf.d/linux.toml's Nerd Fonts) is never touched by `mise
# install`/`mise upgrade` above -- only `mise bootstrap`, `mise bootstrap --only packages`, or
# `mise bootstrap packages apply` install it (#747). chezmoi is the only orchestrator (see
# DESIGN.md), so something in a chezmoi script has to call this explicitly; it converges
# (skips already-installed packages), so it's safe to call on every apply on both OS even though
# only conf.d/linux.toml currently declares any packages.
apply_bootstrap_packages() {
  local setup_type="$1"

  log_info "Mise | $setup_type | Applying bootstrap packages (e.g. Linux Nerd Fonts)..."
  mise bootstrap packages apply --yes 2>&1 | sed -E 's|^(.*)|    \1|g'
  log_success "Mise | $setup_type | Bootstrap packages are up to date."
}
