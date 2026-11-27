### Sandboxes

Write policy for both lives in Boundaries.

- `sandbox-talos` — a write-allowed single-node Kubernetes cluster (kube context `sandbox-talos`) for testing out
  changes and ideas.
{{- if eq .chezmoi.homeDir "/home/coder" }}
- `sandbox-docker` — this workspace has the Docker CLI but no docker-in-docker; use the sandbox docker VM as
  `DOCKER_HOST` over ssh: `ssh -i ~/.ssh/sandbox_docker_vm docker@docker-vm.sandbox-docker.svc.cluster.local`. It
  serves whatever local workflows need a real machine, not just docker.
{{- end }}
