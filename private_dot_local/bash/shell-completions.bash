# Load shell completions

# enable bash completions
#
# The homebrew entry is `etc/profile.d/bash_completion.sh`, not `etc/bash_completion`: that is the
# path `bash-completion@2` documents and the only one it ships. The old v1 formula happened to
# provide both, so this covers either -- but nothing here may load v1, see Brewfile.system.darwin.
# The remaining branches are the distro-packaged locations, for hosts where homebrew isn't the
# provider.
if ! shopt -oq posix; then
  if [ -f $HOMEBREW_PREFIX/etc/profile.d/bash_completion.sh ]; then
    . $HOMEBREW_PREFIX/etc/profile.d/bash_completion.sh
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
