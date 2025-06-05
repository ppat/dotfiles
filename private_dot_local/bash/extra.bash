# Additional Bash customizations

# # Better history command defaults
# export HISTSIZE=10000
# export HISTFILESIZE=20000
# export HISTCONTROL=ignoreboth:erasedups
# export HISTTIMEFORMAT="%F %T "
# shopt -s histappend

if [[ -f $HOME/.krew/bin/kubectl-cnpg ]]; then
  ln -sf $HOME/.krew/bin/kubectl-cnpg $HOME/.local/bin/cnpg
  source <($HOME/.local/bin/cnpg completion bash)
fi
