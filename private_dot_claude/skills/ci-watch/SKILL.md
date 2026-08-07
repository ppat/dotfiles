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
subagent dispatched for exactly this (the common case in practice — this
task gets delegated more often than not, precisely because "watch a
multi-minute run" is exactly the kind of thing worth getting off the main
thread). It closes off the specific failure modes seen across real sessions
so far (root cause: [ppat/dotfiles#705](https://github.com/ppat/dotfiles/issues/705)),
each with its own section below — but treat that issue's list as a
first-pass understanding, not a closed set. If you hit a way this task can
go wrong that isn't named here, that's a gap in this file, not a sign you
misread it — see [Amending this skill](#amending-this-skill).

## Check first — you may already be done

Everything past this point is about how to behave *while a run is still in
flight*. If you're coming back to this after time has passed since the push
— you did other work in between, you're resuming a task picked up earlier —
don't assume any of the blocking machinery below applies. One cheap call
answers whether you even need it:

```bash
gh run view <id> -R <owner>/<repo> --json status,conclusion,startedAt,updatedAt
```

(No `<id>` handy? `gh run list -R <owner>/<repo> --branch <branch> --limit 1
--json databaseId` — see [step 0](#0-find-the-run) for matching it to your
push rather than assuming "most recent.") If `status == "completed"`, you're
already done: skip straight to
[step 4](#4-get-the-outcome-not-the-raw-log) to read the result and
[The report shape](#the-report-shape) to write it up — none of the rest of
this file is relevant to that case. The blocking procedure below is for when
the run is genuinely still going.

## The one rule that overrides your instincts

**Run the blocking watch command in the foreground. Only end your turn once
you have a terminal result, or a bound-hit you're reporting using a status
you just freshly checked — never on an unverified belief that something is
still pending.**

This cuts against several things that otherwise feel like reasonable moves:

- **Not fabricating a result is not the same as stopping.** "I won't guess,
  so I'll wait for it to resolve on its own" is the single most common way
  this task actually fails, and it's the hardest to catch because it reads
  as caution rather than as the stall it is. The correct alternatives to
  fabricating are exactly two: keep blocking, or report the real state you
  actually just observed — with a resume handle — because you've hit a
  genuine bound. Ending your turn on an unverified "still waiting" is
  neither of those; it's silence dressed up as integrity.
- **Deferring the wait to any mechanism is the same failure as
  backgrounding, whatever it's called** — a backgrounded shell command, a
  `Monitor` subscription, "I'll be notified when it's done." **Do not apply
  that here.** Ending your turn ends *your* participation regardless of what
  you set up to run after you. A watch that's been handed off to something
  else, followed by the turn ending anyway, is indistinguishable from never
  having watched at all — the run finishes unobserved, whether or not
  something was theoretically wired up to resume you later. This is a
  deliberate, specific exception to general agent guidance (including this
  harness's own Bash-tool docs, and the existence of the `Monitor` tool
  itself) that otherwise correctly recommends exactly this kind of deferral
  for long-running work.
- **If the pull to defer comes from the watch itself feeling too heavy to
  sit through in the foreground** — too much output, too long a block —
  that's a problem to fix, not a reason to hand the wait to something else.
  See [step 2](#2-block-in-the-foreground-with-a-bound--and-set-the-tool-calls-own-timeout):
  foreground watching doesn't have to flood your context, so there's no
  remaining reason to defer it.
- **The last tool call before you end your turn, for any reason — terminal
  result, bound-hit, or a mid-task update — is always one fresh status
  query** (`gh pr checks` / `gh run view --json status,conclusion`), even
  when you're confident you already know the answer. Its actual output goes
  in the report, not your memory of an earlier check; a belief that
  something is "still pending" is only as good as the last time you
  genuinely looked.

### Observed in practice

Two real subagents, in the session this amendment was written for, both had
this skill available and both stub-ended anyway:

> "I'll stop here and wait for the actual completion notification from the
> background CI watch rather than poll or fabricate a result."

Reality: the work was fully complete and pushed — 40 checks passing, one job
still running. It had backgrounded the watch, then ended its turn; "rather
than poll or fabricate" made the stop read as rigor instead of the stall it
was.

> "Still waiting on the `pre-commit` check; I'll hold here until the monitor
> reports all checks resolved."

Reality: every check was already green at the moment that was written. It
had handed the wait to a `Monitor` and stopped — and never ran the one fresh
check that would have caught it.

**Both are plausibly explained by the same mechanical trigger, not two
separate discipline lapses.** This harness's Bash tool defaults to a
120-second cap and *silently backgrounds* a call once that cap fires,
handing control back regardless of whether the run is done. Neither quote
reads like a deliberate choice to background anything — both read like an
agent rationalizing control that had already been handed back to it without
its choosing. See the [tool-call timeout guidance in step
2](#2-block-in-the-foreground-with-a-bound--and-set-the-tool-calls-own-timeout)
for the actual fix: set the timeout parameter explicitly, don't rely on a
shell wrapper alone.

The recovery this points to has also been observed working correctly: one
subagent's tool call returned with a "moved to background" style message —
the timeout parameter hadn't been set — and rather than treat that as
license to end its turn, it stopped the backgrounded task and reissued the
watch with the timeout parameter set to its actual bound. That's the
intended response to seeing that message: stop and reissue, not stop and
wait.

If you are a subagent and this is your whole task, your task is not complete
until you can report a terminal status (`success`/`failure`/`cancelled`/
timed-out-at-my-bound) — not "started" or "in progress."

## If you're a subagent

This is the default way this skill gets invoked, so it earns its own section
rather than a caveat. Three things follow from being a delegate specifically:

- **Your final report is your entire return value.** The agent that spawned
  you sees the text you send back, not your tool-call history — it never saw
  the run's live progress, doesn't know which commands you tried, and can't
  scroll up. The [report shape](#the-report-shape) below has to be
  self-contained: quote the actual evidence inline, don't write "as shown
  above."
- **"Block until terminal" has a practical ceiling even though it's the
  rule.** You have your own finite context and the caller has finite
  patience. If you've reissued the blocking watch several times (a handful,
  not an open-ended loop) and still have no terminal result, that's the
  moment to stop and hand back an honest non-terminal report — last observed
  status, how many bound-hits, elapsed time — rather than trying to be the
  one invocation that sees it through no matter what. A clear "not yet
  resolved, here's exactly where it stood" is a legitimate result for one
  invocation; the caller's job is then to resume *you* (the same way it
  reached you the first time) rather than treat the non-terminal report as a
  failure or spin up a second watcher.
- **Confirm your own tool access before committing to the task.** If you
  don't actually have `gh`/Bash available in this context, say so in your
  first response instead of quietly reaching for one of the MCP tools this
  skill tells you to avoid (see below) and reporting whatever it happens to
  return.

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

By default this lists *every* check, required or not — a report of "PR is
green" from this alone can be true of the optional checks and still miss a
required one still pending. If the actual question is "can this merge," add
`--required` to filter to just those.

**`--required` is narrower, not better — don't reach for it as the default.**
It answers "can this merge," not "did my change pass." Measured directly: on
a repo where the expensive suite (a multi-minute chainsaw job) isn't
configured as a required branch-protection check, `--required` returned only
4 rows and silently omitted that job entirely — the one that actually
mattered for the task at hand. A short row count from `--required` reads
like the full picture; it isn't. Use the unfiltered list for "did everything
run and pass," and reach for `--required` only when mergeability is
specifically the question being asked.

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

### 2. Block, in the foreground, with a bound — and set the tool call's own timeout

**Before you issue anything below: set the timeout parameter on the tool
call itself, explicitly, to your bound. A shell-level `timeout` wrapper does
not substitute for this, and skipping it is plausibly the actual mechanism
behind the worst failures this skill exists to prevent.**

Confirmed directly: this harness's own Bash tool defaults to a
**120-second** cap, and once that cap fires, the harness **silently
backgrounds the call** and hands control back to you — while the run can
still be minutes from finishing. Wrapping the command in
`timeout 590 gh run watch ...` does **not** prevent this: the shell wrapper
only bounds the command once it's already running in the foreground, but the
harness's own default cap can fire *first*, moving the whole call to the
background regardless of what you wrapped it in. So: set the tool call's own
timeout parameter (this harness exposes one up to 600000ms) to your bound,
every time, not just when a run "seems long." Keep an inner shell `timeout`
too if you like, as a belt-and-suspenders bound below the tool's own — it's
just not sufficient by itself.

**Calibration for a kind/Flux/chainsaw-class suite: start at 8-10 minutes
(580000-600000ms) for the tool-call timeout, not the harness default.**
Three real measurements so far, all comfortably inside that range and all
well past the 120-second default: 5m50s, 5m56s, and 7m41s for the longest
job (7m50s end to end, needing one bound-hit-then-resume). A 120-second
default is nowhere near sufficient for anything in this class.

**If a tool call ever returns with something like "moved to background" /
"running in background" / a task id to check on later, that is not the run
finishing and it is not you legitimately watching.** It means the timeout
parameter wasn't set explicitly and the harness's default cap fired. Stop
the backgrounded task (this harness: `TaskStop`) and reissue the watch with
the timeout parameter set correctly this time — don't read the returned
control as permission to end your turn. This is plausibly the actual
mechanism behind both incidents in
[Observed in practice](#observed-in-practice): both quotes read like an
agent rationalizing control that was handed back to it ("wait for the actual
completion notification from the background CI watch," "I'll hold here
until the monitor reports"), not a deliberate choice to background anything.
If that's right, "don't background the watch" isn't purely a discipline
rule with a discipline fix — it has a mechanical trigger, and the durable
fix is setting the bound correctly up front so the harness never backgrounds
you in the first place.

```bash
# the tool call's own timeout parameter is set to e.g. 580000ms here —
# that's the setting doing the real work; the shell `timeout` below it is
# a secondary bound, not a substitute for it
timeout <bound_seconds> gh run watch <id> -R <owner>/<repo> --exit-status --interval 15 \
  > /tmp/watch-<id>.log 2>&1
echo "watch exited: $?"
```

**Redirect to a file — don't let `gh run watch`'s own progress output print
straight into your transcript.** This is separate from, and just as
important as, the "don't paste a whole log into context" rule in step 4:
`gh run watch` redraws its *entire* job/step tree on every refresh tick, and
when it isn't attached to a real terminal — which is exactly the case when a
tool call captures it — those redraws don't overwrite in place, they print
one after another. A run that takes 20+ minutes at the default 3-second
interval emits hundreds of near-duplicate full-tree snapshots. That's a
correct, foreground, non-backgrounded command that still floods context
purely from its own verbosity — confirmed directly: an 18-second run in this
skill's own dogfooding produced four full redraws before finishing. Setting
`--interval` higher thins that out, but redirecting to a file is what
actually keeps it out of context; you don't need the live progress view,
only the final exit code, so nothing is lost by never reading that file
(only tail it, per step 3, if a bound-hit leaves you needing "what was the
last observed state").

This is worth doing even when it feels like extra ceremony, because it's
plausibly *why* this task gets deferred to backgrounding or a `Monitor` in
the first place: foreground-watching a long run used to mean sitting through
a context-flooding wall of redraws, so deferring it looked like the only way
to avoid that cost. Redirecting removes the flood, which removes the reason
to defer — the fix in this section and the "watch in the foreground, always"
rule above are meant to reinforce each other, not stand as two unrelated
rules.

Read the exit code carefully — two different things produce a non-zero exit
here and they mean opposite things:

- **124** — the shell `timeout` fired. Your bound was reached; the run's own
  outcome is still unknown. This is *not* a run failure, it's your own
  wrapper cutting the command off. See the next section for what to do next.
- **Any other non-zero value** — `gh run watch --exit-status` propagating the
  run's actual conclusion. The run itself finished and failed/was cancelled.

If instead of either of those, control returns via the tool's own
background/timeout mechanism (no exit code at all, just a "moved to
background" style message) — that's the case described above, not a bound-
hit. Treat it as "the timeout parameter wasn't set," stop the task, and
reissue with it set.

Neither an exit 124 nor a backgrounded-call is the same thing as `gh` itself
erroring out (auth failure, rate limit, a transient 5xx) before it ever
reached a terminal run state — that's a tooling failure, not a CI-run
outcome, and reporting it as "the run failed" would be wrong. Check
`/tmp/watch-<id>.log` for a `gh`-level error message (rather than normal
job/step output) to tell the two apart.

**Do not** run this with `&`, `nohup`, or a background-execution flag. Doing
so and then ending your turn regardless was itself one of the observed
failures — it reads as compliance ("I started the watch") while producing the
identical unobserved-outcome as never watching at all.

#### Alternative shape: a bounded, exit-on-terminal poll loop

`gh run watch` plus a redirect (above) isn't the only valid implementation
of "block in the foreground." A hand-rolled loop sidesteps the
redraw-flooding problem structurally instead of by redirecting around it —
its output is bounded by how many ticks it takes, not by the size of the
job/step tree, and its last printed line already *is* your last-observed
state, so there's no file to `tail` on a bound-hit. **The tool-call timeout
parameter rule above applies here too** — a `while` loop is still one long
foreground tool call as far as the harness's own default cap is concerned,
so set the parameter explicitly regardless of which shape you use:

```bash
end=$((SECONDS + <bound_seconds>))
status=unknown; conclusion=""
while [ "$SECONDS" -lt "$end" ]; do
  read -r status conclusion <<< "$(gh run view <id> -R <owner>/<repo> \
    --json status,conclusion --jq '[.status,.conclusion] | @tsv')"
  echo "$(date -u +%H:%M:%S) status=$status conclusion=$conclusion"
  [ "$status" = "completed" ] && break
  sleep 20
done
echo "final: status=$status conclusion=$conclusion"
```

This satisfies exactly the same invariant as step 2, it's just a different
implementation of it: one foreground tool call, blocking until terminal or
bound, minimal output either way. It is *not* the polling this skill warns
against — checking once and then giving up, or coming back later on your
own schedule outside this tool call, is the failure mode; a loop that holds
the tool call open and doesn't return control until it's done or out of
bound is not. Use whichever shape you find easier to get right; both were
run against a real multi-minute suite as part of writing this skill (the
loop above cost 6 lines of output total across a 7m41s wait when tested
directly).

### 3. On a bound-hit: resume, don't restart, don't ask for a new watcher

A single foreground call can run out its bound before a long suite (e.g. a
kind-cluster → Flux bootstrap → module-deploy → assertions chainsaw run) is
done. That is expected, not a failure — reissue the exact same blocking
command again in the same turn:

```bash
timeout <bound_seconds> gh run watch <id> -R <owner>/<repo> --exit-status --interval 15 \
  > /tmp/watch-<id>.log 2>&1
```

`gh run watch` reattaches to the same run and picks up wherever it left off.
Keep doing this — same turn, still foreground — until you get a terminal
result, or (as a subagent) you've hit the practical ceiling described in
[If you're a subagent](#if-youre-a-subagent) and it's time to report a
non-terminal status instead. Either way, if you need to say what the last
observed state was, `tail -n 20 /tmp/watch-<id>.log` gives you that without
having ever let the full redraw history into context.

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

**Expect most suites to finish inside one call; a single bound-hit on the
longest ones is ordinary, not a sign anything is wrong.** Two real data
points so far, both kind-cluster/chainsaw module suites: one ran 7m41s for
its longest job (7m50s end to end, 41 passed / 3 skipped) and needed one
bound-hit-then-resume against a foreground call capped near 10 minutes;
another — one of the longer suites in the same repo — ran 356s (5m56s) all
green with no bound-hit at all. So don't read "one bound-hit" as a fixed
expectation for every suite; it's specifically what to expect from the
slowest ones, and it isn't evidence of a stall when it happens. Resume per
step 3, and finish on the next call. Misreading a normal bound-hit as a
problem was part of what produced both incidents in
[Observed in practice](#observed-in-practice); don't repeat it in the other
direction by treating your own bound-hit as bad news either.

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
burn a cycle re-diagnosing it as something your change caused.

The pattern this section teaches matters more than any specific example of
it, because a "known pre-existing red" doesn't stay true forever — it gets
fixed, and a skill that states one as a current fact will eventually be
wrong about it. (This already happened once while writing this section: an
earlier draft cited `homelab-ops-kubernetes-apps`'s `diff`/`validate-k8s`
jobs, red because flux-local couldn't diff digest-pinned OCI charts, as a
live example — a later run of this exact procedure against that repo found
both passing. Whatever caused it seems to have been fixed since, which is
itself the point: the *method* — check the base branch, don't trust a
remembered "that job's always red" — is what caught the staleness, not
memory of the specific example.) So treat any specific pre-existing-red fact
you're told, including any example that was ever in this file, as something
to re-verify against the base branch for *this* run, not as ambient
knowledge to assume forever. Whenever a repo's own docs/README/CI history do
currently name a job as persistently red for an unrelated reason, that's a
useful head start over re-deriving it from scratch — but "useful head start"
still means confirm it, not skip the check.

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
can find it without asking. If you're a subagent, this report *is* your
return value in full — the caller reconstructs everything about the run from
this text alone, so write it that way rather than assuming shared context.

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

**Hard rule, checked first, no exceptions: is the status in your report from
a query you just ran, or from something you checked earlier and are now
recalling?** If it's recalled rather than fresh, run one more `gh pr checks`
/ `gh run view --json status,conclusion` right now and use *that* output.
This single check would have caught both real incidents in
[Observed in practice](#observed-in-practice) — one thought it was still
waiting on a check that had already gone green, and both would have produced
a correct report from a check they either skipped or let go stale.

Then check your own report against the rest of the failure modes this skill
exists to prevent. If any answer is "yes", go fix it before ending the turn:

- Did I write anything like "I'll wait" / "waiting for the run" / "I'll hold
  here until it reports" as my final message — with no fresh check backing
  it? → Stop. That's a stall wearing the shape of rigor, not a report. Issue
  the foreground blocking call now, or report a bound-hit instead.
- Did I hand the wait off to *anything* — a backgrounded command, a
  `Monitor`, "I'll be notified" — and end the turn anyway? → Same fix,
  regardless of which mechanism it was.
- Did I tell myself stopping was the responsible alternative to fabricating
  a result? → It isn't; the two real alternatives are keep blocking, or
  report the freshly-checked real state. See
  [The one rule](#the-one-rule-that-overrides-your-instincts).
- Did I read `conclusion` without first confirming `status == "completed"`?
  → Re-check; a `queued`/`in_progress` run's `conclusion` is `null` and means
  nothing yet.
- Did I paste a large log into context instead of grepping a file? → Redo via
  the structured `--json jobs` query or a targeted `grep` on the saved file.
- Did I let `gh run watch`'s own progress output print directly into my
  transcript instead of redirecting it to a file? → On anything longer than a
  trivial run, that's the same context-flood as pasting a log, just from a
  different command.
- Did I read a `gh`-level error (auth/rate-limit/network) as if it were the
  run's own conclusion? → Check the log for a tooling error before reporting
  a run failure.
- Did I call a red job "my regression" without checking whether it's also
  red on the base branch? → Check before naming it.
- Am I about to spawn a second watcher because the first one seems stalled?
  → Resume the existing one instead.
- (Subagent) Am I looping the resume step indefinitely instead of reporting
  a non-terminal status back after a reasonable number of bound-hits? → See
  [If you're a subagent](#if-youre-a-subagent).

## Amending this skill

This skill is expected to accumulate corrections as it gets used on real
runs — especially long chainsaw-style suites, which is where it earns its
keep. When a real run surfaces friction this file doesn't cover (a bound that
was wrong, a `gh` output shape that didn't match what's documented here, a
failure mode not named above), fold the correction directly into the relevant
section above rather than appending a changelog — keep this file describing
current best practice, not a history of edits. Prefer tightening an existing
section over growing new ones; this file works because it's short enough to
actually be read before a watch, not despite being read.
