### GitHub: `gh` vs `github` MCP

{{ if eq .chezmoi.homeDir "/home/coder" -}}
`gh` authenticates as the agent bot for Claude Code (GitHub App `homelab-agent-bot`); the `github` MCP server
authenticates as the user. Commits stay authored and signed as the user — only the pushing actor is the App.
`~/.local/bin/gh-app-env` mints the one-hour `GH_TOKEN` into each new shell; on a 401, run
`eval "$(~/.local/bin/gh-app-env)"`. An installation token has no user behind it, so `gh api user` returns 403.

{{ end -}}
Route by payload shape, not by read/write.

| Scenario | Use | `gh` | `github` MCP | Why | Gotchas |
| --- | --- | --- | --- | --- | --- |
| Text going in: creating/updating issues, commenting on issues and pull requests, replying in review threads, linking sub-issues | MCP | yes | yes | body text passes as a JSON parameter, so backticks, `$`, quotes, and newlines survive; the same text passed through the shell is easily corrupted | |
| Data coming out, bulk or unbounded: workflow runs, job logs, issue and pull request listings | `gh` | yes | yes | `--json` and `--jq` filter the output down in one command | MCP `actions_list` returns everything and ignores `per_page` |
| Data coming out, one small structured thing: one pull request's state, one issue, one file's contents, the latest release | MCP | yes | yes | the result arrives already structured, nothing to filter or parse | |
| Push, branch, create/edit pull requests, trigger `workflow_dispatch` | `gh` | yes | no | the MCP server has no tools for these | |
| Creating gists | MCP | {{ if eq .chezmoi.homeDir "/home/coder" }}no (403){{ else }}yes{{ end }} | yes | {{ if eq .chezmoi.homeDir "/home/coder" }}the App token cannot create gists{{ else }}same reasoning as text going in{{ end }} | |
| Merging to `main` | neither | {{ if eq .chezmoi.homeDir "/home/coder" }}no{{ else }}capable, but landing is the user's (see Boundaries){{ end }} | no | open a pull request instead | |
| Checking CI status on a pull request | `gh pr checks` | yes | no | | MCP `get_status` reports `total_count: 0` when CI reports through the Checks API; `get_check_runs` returns 403 on private repositories, works on public ones |
