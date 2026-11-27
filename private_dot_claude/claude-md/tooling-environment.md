### Environment

{{ if eq .chezmoi.homeDir "/home/coder" -}}
The session runs inside a Coder workspace pod in a Kubernetes cluster. Memory is the constraint to respect: the pod
can be OOM-killed and restarted, which interrupts every session in it — and this may not be the only Claude Code
session in the pod.

- Check the pod's own resource usage, not the host's:

  ```bash
  cat /sys/fs/cgroup/memory.max      # cgroup v2 limit (bytes, or "max")
  cat /sys/fs/cgroup/memory.current  # cgroup v2 current usage
  ```

- `memory.current` alone overstates the danger — it conflates reclaimable and non-reclaimable memory. The kernel
  evicts page cache and reclaimable slab under pressure before it OOM-kills anything, so the number that actually
  predicts an OOM kill is the *anonymous* (+ unreclaimable slab + kernel stack) memory, not raw
  RSS/`memory.current`. Break it down:

  ```bash
  grep -E '^(anon|file|slab_reclaimable|slab_unreclaimable|kernel_stack) ' /sys/fs/cgroup/memory.stat
  ```

- Delegation and parallelism remain fine and encouraged — what needs shaping is the memory profile of individual
  commands, scripts, and tool calls, including what delegates are told to run.
{{ else -}}
The session runs on a macOS laptop.
{{ end -}}
