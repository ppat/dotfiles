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

volumes2table() {
  kubectl get -n longhorn-system volume \
    -o custom-columns=PVC:.status.kubernetesStatus.pvcName,NAME:.metadata.name,STATE:.status.state,ROBUSTNESS:.status.robustness,IMAGE:.status.currentImage,LOCALITY:.spec.dataLocality,MIGRATABLE:.spec.migratable,REPLICAS:.spec.numberOfReplicas,STALE_TIMEOUT:.spec.staleReplicaTimeout,SIZE:.spec.size,ACTUALSIZE:.status.actualSize,NODE:.status.currentNodeID,LASTBACKUP:.status.lastBackupAt \
    --no-headers | \
    awk '{
      # Core fields are always in the same positions (1-11)
      image_field = $5
      locality = $6
      migratable = $7
      replicas = $8
      stale_timeout = $9
      size = $10
      actual_size = $11

      # Handle optional fields based on field count
      if (NF == 11) {
        # Both NODE and LASTBACKUP missing
        node_field = ""
        last_backup = ""
      } else if (NF == 12) {
        # One field present - need to determine which
        # Check if field 12 looks like a date (contains T or -)
        if ($12 ~ /[T-]/) {
          # Field 12 is LASTBACKUP, NODE is missing
          node_field = ""
          last_backup = $12
        } else {
          # Field 12 is NODE, LASTBACKUP is missing
          node_field = $12
          last_backup = ""
        }
      } else if (NF == 13) {
        # Both fields present
        node_field = $12
        last_backup = $13
      } else {
        # Fallback for unexpected field counts
        node_field = ""
        last_backup = ""
      }

      # Extract version from image
      version = (split(image_field, a, ":") > 1 ? a[2] : image_field)

      # Convert bytes to MiB
      size_mib = (size != "" && size > 0 ? sprintf("%.0f", size / 1048576) : "")
      actual_size_mib = (actual_size != "" && actual_size > 0 ? sprintf("%.0f", actual_size / 1048576) : "")

      # Format last backup (remove time, keep date)
      backup_date = (split(last_backup, b, "T") > 1 ? b[1] : last_backup)

      printf "%-32.32s %s %s %s %s %s %s %s %s %s %s %s %s\n",
        $1, $2, $3, $4, version, locality, migratable, replicas, stale_timeout, size_mib, actual_size_mib, node_field, backup_date
    }' | \
    sort | \
    (echo "PVC NAME STATE ROBUSTNESS IMAGE LOCALITY MIGRATABLE REPLICAS STALE_TIMEOUT SIZE ACTUALSIZE NODE LASTBACKUP" && cat) | \
    column -t
}
alias volumes='volumes2table'

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

kprp() {
  local policy_name="$1"
  local result_value="$2"

  if [[ -z "$policy_name" || -z "$result_value" ]]; then
    echo "Usage: kprp <policy_name> <result_value>"
    echo "Example: kprp disallow-host-path fail"
    return 1
  fi

  kubectl get policyreport -A -o json | \
    jq -r --arg policy "$policy_name" --arg result "$result_value" "
      .items[] as \$item |
      \$item.results[] |
      select(.policy == \$policy and .result == \$result) |
      [\$item.metadata.namespace,
       (\$item.metadata.ownerReferences[0].name // \"\"),
       (\$item.metadata.ownerReferences[0].kind // \"\"),
       .policy,
       .rule,
       .result,
       .severity] |
      @tsv" | \
    column -t
}
alias kprp='kprp'

alias reset-to-first-time='rm -rf ~/.cache/mise ~/.cache/uv ~/.cargo ~/.colima ~/.config/aquaproj-aqua ~/.config/mise ~/.docker ~/.krew ~/.local/share/aquaproj-aqua ~/.local/share/mise ~/.local/state/mise ~/.rustup'
alias yaml-keys='yq eval '"'"'.. | select(tag == "!!str" or tag == "!!int" or tag == "!!bool" or tag == "!!null") | path | join(".")'"'"''
