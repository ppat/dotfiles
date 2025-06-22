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

# kubectl
if command -v kubectl > /dev/null; then
  source <(kubectl completion bash)
  alias k=kubectl
  complete -o default -F __start_kubectl k
fi

# helm
if command -v helm > /dev/null; then
  source <(helm completion bash)
fi

# flux
if command -v flux > /dev/null; then
  source <(flux completion bash)
fi

# gh
if command -v gh > /dev/null; then
  source <(gh completion -s bash)
fi

# kustomize
# if command -v kustomize > /dev/null; then
#   source <(kustomize completion bash)
# fi

# terraform
# if [[ -d "$TFENV_CONFIG_DIR/versions/" ]]; then
#   if find $TFENV_CONFIG_DIR/versions/ -name terraform -type f -executable > /dev/null; then
#     # shellcheck disable=SC2012
#     complete -C $TFENV_CONFIG_DIR/versions/$(ls $TFENV_CONFIG_DIR/versions | sort -rn | head -1)/terraform terraform
#   fi
# fi

# yq
# if command -v yq > /dev/null; then
#   source <(yq shell-completion bash)
# fi

# # poetry
# if command -v poetry > /dev/null; then
#   source <(poetry completions bash)
# fi

# # pip
# if command -v pip > /dev/null; then
#   source <(pip completion --bash)
# fi

# kind
# if command -v kind > /dev/null; then
#   source <(kind completion bash)
# fi

# zoxide
# if command -v zoxide > /dev/null; then
#   source <(zoxide init bash)
# fi

# Mise completions
# if command -v mise &> /dev/null; then
#  eval "$(mise completion bash)"
# fi

# Aqua completions
# if command -v aqua &> /dev/null; then
#  source <(aqua completion bash)
# fi
