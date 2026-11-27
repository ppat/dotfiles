### General tooling

- Install whatever tools are needed globally via `mise` (including `pipx` and `npm` packages), e.g.
  `mise exec node -- node --version`.
- For repository dependencies, prefer `bun` over `npm` and `uv` over `pipx`. A repo-specific `mise.toml` is fine for
  tooling tied to that repo's workflows.
- MCP servers: `context7` for documentation lookup, `playwright` for browser automation.
