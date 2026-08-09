# PoC #747: task vs. script, for "query external state -> compare -> mutate" work

**Nothing under `poc/` deploys.** The whole directory is excluded via `.chezmoiignore` (`poc/`) — verify with
`chezmoi managed --source .`, which must not list anything below this path. Both trees are read-only history:
the answer to "which one is live" is always the one under `.chezmoiscripts/` or `private_dot_config/mise/tasks/`
proper, never here.

## What was compared

Two shapes for `dotfiles:krew` (reconcile installed kubectl plugins against a declared list — a krew index
update, a diff against installed plugins, then installs/upgrades):

- **[747-krew-task-form/](747-krew-task-form/)** — a mise file task (`private_dot_config/mise/tasks/dotfiles/`),
  using `tools = [...]` for resolution and deliberately omitting `sources=`/`outputs=`.
- The **script form** — a `run_after_*` chezmoi script using `mise exec ... --` for tool resolution — is what's
  actually shipped, at `.chezmoiscripts/run_after_22_krew.sh.tmpl`. It is not duplicated here; read it there.

Both were evaluated against the owner's rule: the winner is whichever shape is least complected and has the
fewest failure modes, with silent failures weighted far more heavily than loud ones.

## Verdict: script, not task

**One line:** the obvious `sources=[<plugin-file>]` / `outputs=["$KREW_ROOT/receipts/*.yaml"]` encoding makes a
mise task's staleness cache actively lie — delete one receipt and the task reports "sources up-to-date,
skipping" forever; fail halfway through an install run and that failure is cached as success, permanently.
`sources` alone (no `outputs`) gates the cache on success, but adding `outputs` is what's needed to skip
no-op runs, and that's exactly what turns the cache into a footgun. Omitting `outputs` avoids the lie but also
gives up the only reason to prefer a task here.

The task form's one clear win — tool resolution via `tools = [...]` — is available to scripts too, via
`mise exec <tools> --`. Once that's accounted for, the task body is a near-verbatim relocation of the script
body: relocation alone scores zero on "least complected." Six failure modes were identified that exist only in
the task form and not the script form. Full write-up: ticket #747.

This verdict is specific to pattern P7 (query-then-mutate against live external state that mise cannot
fingerprint as a file set). It does not generalize to every mise task — `dotfiles:completions`
(`private_dot_config/mise/tasks/dotfiles/executable_completions.tmpl`) is unaffected and stays a task: it is a
pure function that owns all of its outputs, which is exactly the case `sources`/`outputs` is sound for.
