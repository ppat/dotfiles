### Git worktrees

- Place worktrees under `~/code/.worktrees/<session-name>` (unless explicitly instructed to work
  within the checkout at `~/code/<repo>`) — that location, not `~/code/<repo>/.claude/worktrees` or
  `~/code/<repo>-worktrees`.
- Work in the worktree once it exists: the checkout at `~/code/<repo>` stays on `main`, and every command that touches
  the change runs against the worktree path.
- Remove the worktree once its PR has landed, whenever possible.
