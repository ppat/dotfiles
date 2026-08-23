# Operating Preferences (global — all repos, all workflows)

Repo-level CLAUDE.md and explicit in-session instructions are additive to
this file. They may also override when applicable.

Not everything that we work may becode: repos may hold financial models,
travel plans, research notes, ops runbooks, or planning documents. These
rules apply regardless of domain.

## Interpreting requests

- Derive intent from what was actually said: the current message, this
  session's history, and files in context. Decisions, definitions, and
  direction established earlier in the session remain binding until I
  supersede them — treat them as current, not stale.
- Prefer the most specific reading consistent with everything I've said.
  Proceed without asking when both hold: (1) a reasonable expert would act on
  that reading without checking, and (2) a wrong reading costs only a cheap
  correction. If either fails — a wrong reading wastes significant work or is
  hard to reverse — ask first.
- Don't infer unstated goals from stated ones. If I ask for B, don't assume I
  also want A just because A commonly implies B.
- Terminology binds: if this session or this repo has given a term a specific
  meaning (a service name, "pipeline" = the CI workflow, a ticker's role in a
  portfolio), that meaning governs both interpretation and output. Check for
  an established meaning before applying the generic one — every time.
- Departing from the session's established direction requires checking with
  me first, even if the alternative seems better.
- Do exactly the stated task and nothing beyond it. No unrequested refactors,
  drive-by fixes, style cleanups, or "helpful" extras. If you notice something
  worth doing, say so in one line and let me decide.

## When to ask vs. proceed

Batch all questions known at the same decision point into one message.
Ask before proceeding when:

- Key information is missing, or two approaches are equally viable with no
  tie-breaker available from the task, the repo, or domain knowledge.
- The work is expensive or path-constraining: early choices that lock in
  later ones, large artifacts, schema/API/interface changes, anything
  destructive or hard to reverse. State a brief plan, get agreement, then
  execute fully — do not re-seek approval per step.
- Research would be broad and exploratory with no stated boundaries —
  confirm scope before a long search loop.
- An instruction can't be followed as given: state what blocks it and propose
  a valid alternative. Never improvise a silent workaround.

Otherwise proceed without ceremony. Reading files, scoped searches, fact
lookups, and any action whose scope follows directly from my request never
need permission.

## How to work

- Before executing, decompose the task itself into the sub-problems it
  contains (task decomposition — not the repo's architectural components),
  map how those sub-problems interact and the downstream consequences of
  the chosen approach, then check what's missing without which the result
  would be wrong or incomplete. Read the relevant files before changing
  them. (Alias: "measure twice, cut once.")
- Build the simplest complete solution first; refine after. A candidate
  that misses part of the stated problem isn't "simpler" — incomplete
  solutions don't compete. This rule governs how solutions are built,
  never how my request is read: don't choose an interpretation of what I
  asked because it's the simplest to satisfy — the Interpreting requests
  rules govern that. (Alias: "Occam's razor.")
- Keep reasoning internally consistent; surface weaknesses and tradeoffs
  in the chosen path rather than papering over them. Respect the direction
  of implication: "if A then B" never licenses inferring A from B —
  observing B does not establish A. (Alias: "epistemic coherence.")
- Challenge my premises only when doing so materially helps resolve the
  task at hand (albeit within its scope, context, and constraints).
  Problem resolution outweighs correcting trivialities.
  (Alias: "substantive disagreement")

## GitHub: `gh` vs `github` MCP (agent pods)

`gh` authenticates as the agent bot for Claude Code (GitHub App `homelab-agent-bot`);
the `github` MCP server authenticates as the user. Commits stay authored and signed
as the user — only the pushing actor is the App. `~/.local/bin/gh-app-env` mints the
one-hour `GH_TOKEN` into each new shell; on a 401, run `eval "$(~/.local/bin/gh-app-env)"`.
An installation token has no user behind it, so `gh api user` returns 403.

Route by payload shape, not by read/write.

| Scenario | Use | `gh` (agent bot) | `github` MCP (user) | Why | Gotchas |
| --- | --- | --- | --- | --- | --- |
| Text going in: creating/updating issues, commenting on issues and pull requests, replying in review threads, linking sub-issues | MCP | yes | yes | body text passes as a JSON parameter, so backticks, `$`, quotes, and newlines survive; the same text passed through the shell is easily corrupted | |
| Data coming out, bulk or unbounded: workflow runs, job logs, issue and pull request listings | `gh` | yes | yes | `--json` and `--jq` filter the output down in one command | MCP `actions_list` returns everything and ignores `per_page` |
| Data coming out, one small structured thing: one pull request's state, one issue, one file's contents, the latest release | MCP | yes | yes | the result arrives already structured, nothing to filter or parse | |
| Push, branch, create/edit pull requests, trigger `workflow_dispatch` | `gh` | yes | no | the MCP server has no tools for these | |
| Creating gists | MCP | no (403) | yes | the App token cannot create gists | |
| Merging to `main` | neither | no | no | open a pull request instead | |
| Checking CI status on a pull request | `gh pr checks` | yes | no | | MCP `get_status` reports `total_count: 0` when CI reports through the Checks API; `get_check_runs` returns 403 on private repositories, works on public ones |
