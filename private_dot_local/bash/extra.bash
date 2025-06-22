# Additional Bash customizations

if [[ -f $HOME/.krew/bin/kubectl-cnpg ]]; then
  ln -sf $HOME/.krew/bin/kubectl-cnpg $HOME/.local/bin/cnpg
  source <($HOME/.local/bin/cnpg completion bash)
fi
