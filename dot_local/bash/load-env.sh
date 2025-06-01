#!/usr/bin/env bash
# Central script to load environment variables from .env files

# Detect if this script is being sourced or executed
(return 0 2>/dev/null) && SOURCED=1 || SOURCED=0

if [[ $SOURCED -eq 0 ]]; then
  echo "Error: This script must be sourced, not executed."
  echo "Usage: source ~/.local/bash/load-env.sh"
  exit 1
fi

# Function to load .env file and export variables
load_env_file() {
  local env_file="$1"
  if [[ -f "$env_file" ]]; then
    echo "Loading environment from $env_file"

    # Read the file line by line
    while IFS= read -r line || [[ -n "$line" ]]; do
      # Skip comments and empty lines
      if [[ -z "$line" || "$line" =~ ^# ]]; then
        continue
      fi

      # Extract variable name and value
      if [[ "$line" =~ ^([A-Za-z0-9_]+)=(.*)$ ]]; then
        local var_name="${BASH_REMATCH[1]}"
        local var_value="${BASH_REMATCH[2]}"

        # Remove surrounding quotes if present
        var_value="${var_value#\"}"
        var_value="${var_value%\"}"
        var_value="${var_value#\'}"
        var_value="${var_value%\'}"

        # Handle variable expansion in values
        # This replaces $VAR or ${VAR} with their values
        var_value=$(eval echo "$var_value")

        # Export the variable
        export "$var_name"="$var_value"
      fi
    done < "$env_file"
  else
    echo "Warning: Environment file $env_file not found."
  fi
}

# Setup environment directory path
ENV_DIR="$HOME/.config/env"

# Load core environment variables first
load_env_file "$ENV_DIR/.env"

# Load OS-specific environment variables
case "$(uname)" in
  Darwin)
    load_env_file "$ENV_DIR/.env.macos"
    ;;
  Linux)
    load_env_file "$ENV_DIR/.env.linux"
    ;;
  *)
    echo "Unknown operating system: $(uname)"
    ;;
esac

# Load dynamic KUBECONFIG from conf.d directory if it exists
if [ -d "$HOME/.kube/conf.d" ]; then
    KUBECONFIG_VALUE=""
    for conf in "$HOME/.kube/conf.d"/*; do
        if [ -f "$conf" ]; then
            if [ -z "$KUBECONFIG_VALUE" ]; then
                KUBECONFIG_VALUE="$conf"
            else
                KUBECONFIG_VALUE="$KUBECONFIG_VALUE:$conf"
            fi
        fi
    done
    export KUBECONFIG="$KUBECONFIG_VALUE"
fi

# Load machine-specific local environment variables last (these override previous settings)
load_env_file "$ENV_DIR/.env.local"

# Setup function to reload environment
reload_env() {
  source "$HOME/.local/bash/load-env.sh"
  echo "Environment reloaded!"
}

# Optional: Display loaded environment variables
show_env() {
  # Display main configuration paths
  echo "====== Environment Configuration ======"
  echo "Mise config:  $MISE_CONFIG"
  echo "Aqua root:    $AQUA_ROOT_DIR"
  echo "Homebrew:     ${HOMEBREW_PREFIX:-not set}"
  echo "Krew root:    $KREW_ROOT"
  echo "Kubeconfig:   $KUBECONFIG"

  # Display shell info
  echo ""
  echo "====== Shell Settings ======"
  echo "Editor:       $EDITOR"
  echo "Language:     $LANG"

  # Show PATH in a readable format
  echo ""
  echo "====== PATH ======"
  echo "$PATH" | tr ':' '\n' | nl
}

# Export the show_env and reload_env functions so they can be used in the shell
export -f show_env
export -f reload_env

echo "Environment loaded successfully. Use 'show_env' to display details or 'reload_env' to reload."
