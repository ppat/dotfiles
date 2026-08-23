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

`gh` authenticates as the GitHub App `homelab-agent-bot`; the `github` MCP server
authenticates as me. Commits stay authored and signed as me — only the pushing actor
is the App. `~/.local/bin/gh-app-env` mints the one-hour `GH_TOKEN` for each new
shell; on a 401, run `eval "$(~/.local/bin/gh-app-env)"`.

Route by payload shape, not by read/write:

| Scenario | Use | Acts as | Why |
| --- | --- | --- | --- |
| Text going in (issue/PR/comment bodies) | MCP | me | JSON params — no shell mangling of backticks, `$`, quotes, newlines |
| Data out, bulk or unbounded | `gh` + `--json`/`--jq` | App | filters before context; MCP results land whole and unfilterable |
| Data out, one small structured thing | MCP | me | no jq to author, no parse retry |
| Push, branch, PR create/edit, `workflow_dispatch` | `gh` | App | every write MCP lacks goes through `gh` |
| Issue create/update, comments, PR review replies, sub-issues, gists | MCP | me | the only writes MCP has; gists are MCP-only (`gh` gets 403) |
| Merge to `main` | neither | — | a repository ruleset blocks it; PRs only |
| `gh api user` | fails | — | an installation token has no authenticated user (403) |

Measured traps in MCP:

- `actions_list` ignores `per_page` — use `gh run list`.
- `pull_request_read`: `get_check_runs` 403s on private repos (works on public), and
  `get_status` reports `total_count: 0` where CI reports via Checks — use `gh pr checks`.
