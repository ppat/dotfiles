# Bash aliases

# Directory navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Common commands
alias grep='grep --color=auto'
alias diff='diff --color=auto'

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
  # shellcheck disable=SC2015
  test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
  alias ls='ls --color=auto'
  alias grep='grep --color=auto'
  alias fgrep='fgrep --color=auto'
  alias egrep='egrep --color=auto'
fi

alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'
alias certs='kubectl get certificates --all-namespaces -o custom-columns="NAMESPACE:.metadata.namespace,NAME:.metadata.name,READY:.status.conditions[0].status,LAST_RENEWED:.status.notBefore,EXPIRATION:.status.notAfter,ISSUER:.spec.issuerRef.name" --sort-by=".status.notBefore"'
alias volumes='kubectl get -n longhorn-system volume -o custom-columns=NAME:.metadata.name,PVC:.status.kubernetesStatus.pvcName,STATE:.status.state,ROBUSTNESS:.status.robustness,NODE:.status.currentNodeID,IMAGE:.status.currentImage'

kpr() {
  kubectl get policyreport -A -o json | \
    jq -r ".items[] as \$item |
           \$item.results[] |
           select(.result == \"$1\") |
           [\$item.metadata.namespace,
            (\$item.metadata.ownerReferences[0].name // \"\"),
            (\$item.metadata.ownerReferences[0].kind // \"\"),
            .policy] |
           @tsv" | \
    column -t
}
alias kpr='kpr'

alias reset-to-first-time='rm -rf ~/.cache/mise ~/.cache/uv ~/.cargo ~/.colima ~/.config/aquaproj-aqua ~/.config/mise ~/.docker ~/.krew ~/.local/share/aquaproj-aqua ~/.local/share/mise ~/.local/state/mise ~/.rustup'
