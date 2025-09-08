# Load shell completions

# enable bash completions
if ! shopt -oq posix; then
  if [ -f $HOMEBREW_PREFIX/etc/bash_completion ]; then
    . $HOMEBREW_PREFIX/etc/bash_completion
  elif [ -f /usr/local/etc/bash_completion ]; then
    . /usr/local/etc/bash_completion
  elif [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

command_specific_setup() {
  case $1 in
    kubectl)
      alias k=kubectl
      complete -o default -F __start_kubectl k
      ;;
    *)
      ;;
  esac
}

if [[ -d "$HOME/.local/bash-completions" ]]; then
  while IFS= read -r -d '' _completion_file; do
    current_command="${_completion_file##*/}"
    if command -v ${current_command} > /dev/null; then
      source "${_completion_file}"
      command_specific_setup "${current_command}"
    fi
  done < <(find "$HOME/.local/bash-completions" -type f -print0)
  unset _completion_file
fi

# zoxide
# if command -v zoxide > /dev/null; then
#   source <()
# fi
