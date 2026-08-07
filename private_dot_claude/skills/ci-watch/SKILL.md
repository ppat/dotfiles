---
name: ci-watch
description: >
  Use this skill whenever you — main agent or a delegated subagent — are asked
  to watch, monitor, wait for, or check the status of a GitHub Actions run:
  "watch the CI run", "wait for CI to finish", "check if the PR is green",
  "did the tests pass", "monitor the chainsaw suite", "keep an eye on the
  workflow", or any brief that ends with "let me know when it's done". Generic
  across repos and workflows — a 30-second lint job and a 40-minute
  kind-cluster/chainsaw suite both go through the same procedure. It exists
  because unguided CI-watch delegations have failed the same handful of ways
  repeatedly: ending a turn on an intention to wait, backgrounding the watch
  command and ending the turn anyway, mistaking a queued run for a running or
  finished one, dumping entire logs into context, and treating a pre-existing
  red as a regression caused by the current change. Follow this rather than
  improvising a `gh run list`/`gh run watch` sequence from memory — the
  failure modes below have each cost a real session. Do NOT use it for
  interpreting local (non-GitHub-Actions) test output, or for other CI
  systems.
---

# Watching a GitHub Actions run

This skill governs any task shaped like "watch/wait for/check on a GitHub
Actions run" — whether you're the main agent watching your own push or a
subagent dispatched for exactly this. It closes off six specific failure
modes seen across real sessions (root cause:
[ppat/dotfiles#705](https://github.com/ppat/dotfiles/issues/705)). Each
section below exists to close one of them off — see the checklist at the
bottom to verify you actually did.

## The one rule that overrides your instincts

**Run the blocking watch command in the foreground, and do not end your turn
until you have a terminal result or have deliberately hit your own stated
bound.**

This cuts against two things that otherwise feel like reasonable moves:

- General agent guidance (including this harness's own Bash-tool
  instructions) says to background long-running commands and let a
  notification resume you later. **Do not apply that here.** A watch that
  gets backgrounded and then the turn ends anyway is indistinguishable from
  never having watched at all — the run finishes unobserved, whether or not
  a notification was theoretically wired up to fire. This is the specific,
  deliberate exception to that general advice.
- Saying "I'll wait for the run to complete" or "waiting for CI" and ending
  your turn is not progress, it's a stall wearing the shape of an update. If
  you find yourself about to write a sentence like that, stop — either issue
  the blocking command in the foreground right now, or if you already hit
  your bound, report the bound-hit explicitly (see below) instead of an
  intention.

If you are a subagent and this is your whole task, your task is not complete
until you can report a terminal status (`success`/`failure`/`cancelled`/
timed-out-at-my-bound) — not "started" or "in progress."

## Tools, and traps to skip

Use the `gh` CLI. Known traps that waste a turn if you reach for the
obvious-looking alternative instead:

- **GitHub MCP `actions_list` ignores its `per_page` parameter** — it can
  silently return the wrong page of runs. Use `gh run list` instead.
- **GitHub MCP `get_check_runs` 403s on private repos** (works on public
  ones, which makes it easy to trust from prior experience and then get
  burned). Use `gh pr checks` or `gh run view` instead.
- **GitHub MCP `get_status` returns `total_count: 0`** on repos where CI
  reports via the Checks API rather than the legacy Status API — which reads
  as "no CI configured" when CI is in fact running. Don't trust an
  empty/zero result from it as proof nothing is running; cross-check with
  `gh run list`.

None of these are unusable, but for this task `gh` is the direct, unambiguous
path — use it rather than triaging which MCP tool's blind spot you just hit.

## The procedure

### 0. Find the run

If you triggered the run yourself (just pushed, just opened a PR), match it
by branch/commit rather than assuming "most recent" is yours — a shared repo
can have concurrent runs from other pushes:

```bash
gh run list -R <owner>/<repo> --workflow=<file>.yaml --branch <branch> --limit 3 \
  --json databaseId,status,conclusion,headBranch,headSha,createdAt
```

Watching a PR's overall checks (possibly several workflows) rather than one
named workflow run is a different, equally valid entry point:

```bash
gh pr checks <pr-number-or-branch> -R <owner>/<repo> --json name,state,bucket
```

### 1. Cheap pre-check — has it already finished?

This has been skipped often enough to call out on its own: check status
before you commit to blocking on it. A run dispatched a few minutes ago by
someone else may already be done.

```bash
gh run view <id> -R <owner>/<repo> --json status,conclusion,startedAt,updatedAt
```

`status` and `conclusion` are two different axes — see
[Decomplecting the states](#decomplecting-the-states) below. Only skip step 2
if `status == "completed"`.

### 2. Block, in the foreground, with a bound

```bash
timeout <bound_seconds> gh run watch <id> -R <owner>/<repo> --exit-status
echo "watch exited: $?"
```

Read the exit code carefully — two different things produce a non-zero exit
here and they mean opposite things:

- **124** — the shell `timeout` fired. Your bound was reached; the run's own
  outcome is still unknown. This is *not* a run failure, it's your own
  wrapper cutting the command off. See the next section for what to do next.
- **Any other non-zero value** — `gh run watch --exit-status` propagating the
  run's actual conclusion. The run itself finished and failed/was cancelled.

If your harness's own tool call has a built-in timeout parameter (many do,
often capped around 10 minutes), prefer that over `timeout` — but if you use
it, treat hitting *that* cap exactly like exit code 124 above: unresolved,
not failed.

**Do not** run this with `&`, `nohup`, or a background-execution flag. Doing
so and then ending your turn regardless was itself one of the observed
failures — it reads as compliance ("I started the watch") while producing the
identical unobserved-outcome as never watching at all.

### 3. On a bound-hit: resume, don't restart, don't ask for a new watcher

A single foreground call can run out its bound before a long suite (e.g. a
kind-cluster → Flux bootstrap → module-deploy → assertions chainsaw run) is
done. That is expected, not a failure — reissue the exact same blocking
command again in the same turn:

```bash
timeout <bound_seconds> gh run watch <id> -R <owner>/<repo> --exit-status
```

`gh run watch` reattaches to the same run and picks up wherever it left off.
Keep doing this — same turn, still foreground — until you get a terminal
result or you decide (see next) that you've spent enough bound-hits to stop
and report.

If you are the one who *dispatched* a watcher (main agent orchestrating a
subagent) and it appears stalled, resume that same subagent — don't spawn a
second one for the same run. A second watcher doubles the token cost of a
stall without changing the outcome; the run finishes at whatever speed it
finishes at regardless of how many things are watching it.

**Sizing the bound**: size it off the failure path, not the happy path. A
run that's about to fail can take dramatically longer than one that passes —
e.g. a property-based test spends minutes shrinking a failing case before it
gives up, where the same suite passing exits in seconds. If you don't know
the workflow's typical runtime, check recent history first:

```bash
gh run list -R <owner>/<repo> --workflow=<file>.yaml --status completed --limit 5 \
  --json conclusion,startedAt,updatedAt
```

and size the bound above the slowest observed run, not the fastest.

### 4. Get the outcome, not the raw log

Get per-job/per-step results structurally before ever touching a log file —
this alone answers "what failed" for most runs without downloading anything:

```bash
gh run view <id> -R <owner>/<repo> --json jobs \
  --jq '.jobs[] | {name, conclusion, steps: [.steps[] | select(.conclusion != "success" and .conclusion != null) | {name, conclusion}]}'
```

Only reach for the log when you need the *why* behind a specific failing
step, and even then:

```bash
gh run view <id> -R <owner>/<repo> --log-failed > /tmp/run-<id>.log   # red run — far smaller than --log
gh run view <id> -R <owner>/<repo> --log        > /tmp/run-<id>.log   # only if you need a green run's own output
```

Write to a file, never straight into context, then extract only what answers
your actual question:

```bash
grep -Ei "error|fail|assert" /tmp/run-<id>.log | tail -n 40
```

Know what you're looking for *before* you grep — for a test suite that means
collected/selected/deselected/passed/failed counts and any "no tests ran"
equivalent; for a multi-phase deploy suite (chainsaw-style) that means which
phase failed (cluster bootstrap vs. dependency install vs. module apply vs.
assertion) — not just that it failed. Grep for warnings even on an all-green
run; a passing job routinely carries something that matters (a cache that
silently didn't save, a step that was silently skipped by an `if:` that
didn't fire) that a status field alone won't surface.

## Decomplecting the states

Three things get conflated and shouldn't be:

- **`status`** (`queued` / `in_progress` / `completed`) — where the run is in
  its lifecycle. A `queued` run hasn't started consuming a runner yet; don't
  read it as stalled or as "basically running."
- **`conclusion`** (`success` / `failure` / `cancelled` / `skipped` / ...) —
  only meaningful once `status == "completed"`; it's `null` before that.
  Checking `conclusion` alone without checking `status` first is how a queued
  run gets misread.
- **What actually happened** — a `success` conclusion doesn't mean "ran the
  thing correctly." Distinguish, and say explicitly which one you found:
  1. green **and it ran** the thing you care about;
  2. green **and it ran nothing** (a marker/filter that matched zero
     tests/files — a "0 selected" is not a pass, it's a no-op wearing a
     pass);
  3. green **with a step silently skipped** (a conditional `if:` that never
     fired, a publish step gated on absent credentials).

## Baseline before blaming your change

A red job is not automatically a regression caused by the change you're
watching for. Before treating it as one, check whether the same job is *also*
red independent of your change:

```bash
gh run list -R <owner>/<repo> --workflow=<file>.yaml --branch main --status completed --limit 5 \
  --json conclusion,headSha
```

If the same job fails the same way on `main`/the PR's base with no relation
to your diff, name it as a known pre-existing failure and move on — don't
burn a cycle re-diagnosing it as something your change caused. (Concrete
example from this estate: in `homelab-ops-kubernetes-apps`, the `diff` and
`validate-k8s` jobs fail for reasons unrelated to any given change —
flux-local can't diff digest-pinned OCI charts. An agent that chases that as
its own regression has misspent a cycle on a known issue.) This generalizes:
whenever a repo's own docs/README/CI history already name a job as
persistently red for an unrelated reason, trust that over re-deriving it from
scratch — but still verify it's still true for *this* run rather than
assuming forever.

## Triggering a run (adjacent, same machinery)

If the task is "prove this works" rather than "watch what's already running",
dispatching a run yourself is often more convincing than reading one that
already happened:

```bash
gh workflow run <file>.yaml -R <owner>/<repo> --ref <branch>
```

The new run doesn't appear instantly — poll `gh run list` a few times
(cheap, not the blocking watch) until it shows up, then continue from
[step 0](#0-find-the-run) above.

## The report shape

Five slots, in this order. Lead with the run id and workflow name so a human
can find it without asking.

1. **Workflow health** — did it select/run anything, with counts quoted; did
   it complete inside its bound.
2. **Each mechanism the run exists to exercise** — quote the actual step
   output/evidence; for any absence, say which case from
   [Decomplecting the states](#decomplecting-the-states) it is.
3. **The outcome**, named as one of the enumerated possibilities above, not
   just described in prose.
4. **Anything new** — a genuine failure, its reproduction, and which layer it
   belongs to (vs. a pre-existing red, named as such).
5. **Anything worth a human's attention that wasn't asked about.** "Nothing"
   is a valid answer here — but give the slot a real look before writing it;
   it has repeatedly carried the most value of the five (e.g. "this run is
   worth keeping as a reference baseline," or "the restore-miss is explained
   by GitHub's child→parent cache scoping, not a defect").

## Before you end your turn

Check your own report against the failure modes this skill exists to
prevent. If any answer is "yes", go fix it before ending the turn:

- Did I write anything like "I'll wait" / "waiting for the run" / "monitoring
  in the background" as my final message? → Stop. Issue the foreground
  blocking call now, or report a bound-hit instead.
- Did I background the watch command and end the turn anyway? → Same fix.
- Did I read `conclusion` without first confirming `status == "completed"`?
  → Re-check; a `queued`/`in_progress` run's `conclusion` is `null` and means
  nothing yet.
- Did I paste a large log into context instead of grepping a file? → Redo via
  the structured `--json jobs` query or a targeted `grep` on the saved file.
- Did I call a red job "my regression" without checking whether it's also
  red on the base branch? → Check before naming it.
- Am I about to spawn a second watcher because the first one seems stalled?
  → Resume the existing one instead.

## Amending this skill

This skill is expected to accumulate corrections as it gets used on real
runs — especially long chainsaw-style suites, which is where it earns its
keep. When a real run surfaces friction this file doesn't cover (a bound that
was wrong, a `gh` output shape that didn't match what's documented here, a
seventh failure mode), fold the correction directly into the relevant
section above rather than appending a changelog — keep this file describing
current best practice, not a history of edits. Prefer tightening an existing
section over growing new ones; this file works because it's short enough to
actually be read before a watch, not despite being read.
