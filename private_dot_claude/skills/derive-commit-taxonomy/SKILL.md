---
name: derive-commit-taxonomy
description: >
  Use this skill when asked to derive, design, overhaul, or audit a commit
  type/scope taxonomy for a repository — "design the commit taxonomy", "what
  scopes should this repo have", "set up commitlint scopes", "align commitlint
  with release-please and Renovate", "write the commit conventions rule for
  this repo", or any task whose deliverable is a repo's conventional-commit
  vocabulary plus the enforcement that makes it real. Use it equally when
  diagnosing the machinery around an existing taxonomy — "Renovate is emitting
  scopes commitlint rejects", "the commit lint gate isn't actually blocking
  anything", "what does this preset bump do to commit scopes" — those are this
  skill's questions Q3, Q4 and Q6 standing alone. It teaches a METHOD — an
  ordered set of questions, the traps that took adversarial review rounds to
  find, and a verification shape — not an answer: every repo's taxonomy is
  different (especially the scopes), and importing another repo's enum is the
  first named failure mode. Derived from two repositories so far; treat its
  generalisations accordingly and extend it after each new repo it is applied
  to. Do NOT use it for writing an individual commit message in a repo whose
  taxonomy already exists — that is what the repo's own commit rules are for.
---

# Deriving a commit taxonomy for a repo you have not seen

You are producing four things, grounded in evidence from this specific repo:

1. **A taxonomy**: the closed set of commit types and scopes, each earning its
   place by naming something real in this repo.
2. **Enforcement**: the gate that makes the taxonomy a constraint rather than a
   suggestion, sequenced so no intermediate state is unsafe.
3. **A rule document** future sessions can decide from (see
   [Writing the rule](#writing-the-rule-document)).
4. **Verification** that the emission machinery and the gate agree — closure
   where the mechanism permits it, declared sampling where it does not (see
   [Verification](#verification)).

What you are NOT doing: copying the enum from a repo where this was done
before. Two repos have been through this method; one needed scopes carrying
released-artifact identity (21 independently versioned modules), the other
needed scopes naming maintenance surfaces of a single artifact. Their type
enums converged; their scope enums share almost nothing. The scopes are where
the repo's real structure shows up, and that structure must be *derived*, not
assumed. A sample of two is also too small to trust any "usually" in this file
— where this skill says "in both repos so far", read that as the strength of
the claim, not a law.

## Evidence discipline

Rank evidence: **resolved behaviour > config text > commit history > docs.**

- *Resolved behaviour* means you ran the actual mechanism or observed it on a
  real PR/release — a parser run against a real message, a branch-protection
  API response, a merged PR's actual squash title.
- *Config text* is what the config says it will do — trust it only after
  checking the tool version, since claims about release tooling are properties
  of a pinned version, not of the tool's name.
- *Commit history* is **scenarios, not resolutions**. Where the gate was never
  enforced, history records only what nobody blocked — inconsistent history
  has an innocent explanation, and "the enum rejects X" is a weaker claim than
  it looks. Establish enforcement (Q3) before treating history as evidence of
  anything.
- *Docs* are the weakest layer, and auto-generated docs are worse than weak —
  they are confidently wrong.

## The questions, in order

The order matters: each question's answer changes how the next can be read.

### Q1 — What are the released artifacts, and what routes a release?

Not "what directories exist". Find the routing table — release-please's
path→component map, semantic-release config, a tag script, whatever this repo
uses — and read the taxonomy off what the release layer can actually address.
In a multi-artifact repo the scope may need to carry artifact identity; in a
single-artifact repo it will not, and the useful axis is more likely "does
this change reach a consumer of the artifact?" — the shipped/internal
boundary. Also establish what *sizes* a release (usually type + breaking
marker) and what *renders* in the changelog (visibility flags), including the
edge semantics: in release-please, `hidden` gates whether a release exists at
all, and a breaking marker renders and bumps regardless of `hidden`.

### Q2 — For each header field, what reads it, and does anything act on it?

The central question, because the instinct is wrong. The instinct says scope
is operative — that it routes releases. In both repos so far, the release
machinery routed by **path** and sized by **type**; scope routed *nothing*
(verified by grepping the pinned release tool's source for scope usage, not by
reading its docs). When that holds, the header is a **claim about the diff**,
not an instruction to the machinery — and the design problem transforms: an
apparent "two axes forced into one field" tension dissolves, and the correct
safeguard is a truth-keeping check (does the scope match the paths?) rather
than a cleverer scope scheme.

But verify it here: some stacks do act on scope (per-scope changelog routing,
scope-keyed release rules). Fields something acts on need routing design;
fields nothing acts on need truth-keeping. Classify every field before
designing any.

Also establish which *string* is release-facing. In a squash-merge repo with
`squash_merge_commit_title: COMMIT_OR_PR_TITLE`, a single-commit PR lands its
commit header and a multi-commit PR lands its **PR title** — so the same repo
can lint some release-facing strings and not others, and interior commit
bodies may be entirely inert to the release parser (run the parser to check).

### Q3 — Is the gate actually enforced on what lands?

A lint job existing tells you almost nothing. Ask all of:

1. Does the job exist and run on the events that matter (including `edited`,
   or post-approval title edits slip past a title lint)?
2. **Is it in branch protection's required contexts / rulesets?** A failing
   non-required check blocks nothing. Verify with the API
   (`gh api repos/O/R/branches/<default>/protection` and `.../rulesets`),
   never by reading a workflow file.
3. Does the aggregate job actually invoke it? An enumerated hook list in a
   `pre-commit` CI job can silently omit the one hook you rely on (e.g. a
   `commit-msg`-stage hook that `pre-commit run --all-files` never fires).
4. **Does the merge path respect it — per actor?** See the first trap below;
   this decomposes further than it looks.

Until all four hold, the taxonomy is advisory, history is unreliable (see
evidence discipline), and any migration plan built on "non-conforming PRs will
fail" is planning against the wrong failure.

### Q4 — What can the bot emit, and would the gate accept it?

Emission (Renovate or any bot composing commit headers from config) and
acceptance (commitlint or equivalent) are separate systems that can silently
disagree. Derive the bot's **emittable set** from its config — every rule and
field that can place a type or scope into a header — and check it against the
enum. The disagreement has two failure modes and you must establish which one
this repo faces: if the gate is required and the merge path respects it,
off-enum emission **stops updates loudly**; if not, off-enum headers
**accumulate silently** for months. Both have been observed. Which one you
face determines the entire migration sequencing: fix emitters and prepare the
enum *before* arming the gate, so no intermediate state either blocks routine
updates or lets junk accumulate.

### Q5 — Which scopes name something the release layer knows about, and which do not?

Split the candidate scope list into: scopes the release layer can address
(released artifacts), scopes naming real-but-unreleased surfaces (a shared
component library that ships by riding other artifacts' releases, CI
machinery, agent instructions, dependency plumbing), and scopes naming
nothing. The split is usually the design's real structure, and it gives you
the type/scope pairing rule almost for free: types claiming shipped behaviour
changed (`feat`/`fix`/`perf`/`refactor`) can only sit on scopes that can carry
that claim.

Where history shows several names for one surface with no decision rule
(three habits split across six scopes), the diagnosis is usually **ambiguity,
not disuse** — the granularity was never what was under-served; the decision
procedure was. One name with a rule beats six names without one. But check
the denominator before arguing from usage counts, and say plainly when a new
rule outlaws the majority historical habit — adoption then depends on the
gate, not on drift.

### Q6 — What does a shared-preset or config upgrade do to emission?

If the bot's config extends shared presets, a preset bump changes emission for
every consumer at once — a scope rename upstream reopens the
emission-vs-acceptance gap with no local change. The enum must move **before**
the pin, never after. Diff the preset versions field by field (a "one
variable" pin bump can be a five-file behavioural jump), and prefer local
config that is *invariant* across preset versions: claim scopes
unconditionally, restore types explicitly, rather than relying on upstream
rules reaching the end of the chain.

## The traps

These took two adversarial review rounds to find. Check each one explicitly.
Two further traps attack verification schemes specifically; they live in
[Verification](#verification), next to the layer each one breaks.

### Enforcement decomposes further than "is the check required"

Even after Q3's four questions, trace the actual merge path **per actor
class**. Concretely observed: a config said `platformAutomerge: true` (which
would let GitHub merge on required checks only, ignoring the advisory lint),
so the hazard was called "silent accumulation by the bot" — but the repo had
`allow_auto_merge: false`, which made platform automerge **inert**; the bot's
fallback merge path gated on *all* checks, and every red PR in history had
been merged by a *human* clicking past the red. Same config text, opposite
hazard, different remedy. The lesson: resolve who actually merged the
non-conforming PRs (`gh pr view --json mergedBy`) and design the gate for
that actor — a config flag that implies a merge behaviour is a hypothesis
about the merge path, not an observation of it.

### A check the dominant actor cannot satisfy is not a check

Ask *who produces most commits here, and can they comply?* A scope-vs-paths
concordance rule is structurally unsatisfiable by a bot whose grouped updates
legitimately span several artifacts in one branch — it emits one scope for a
multi-artifact diff, and no per-commit convention can prevent that. Enforcing
anyway creates a permanent exception list, and a permanently-advisory check is
worse than none: it spends everyone's audit instinct without buying
protection. The honest options are: exempt that actor (paths carry the truth
for machine commits), weaken to advisory **with a recorded sunset condition**
(review the fire log by a date; gate on demonstrated true positives; delete if
noise-only), or drop the check. Every check should end up either required or
explicitly advisory-with-a-sunset — nothing permanently in between.

### The wrong-prior trap: an adversarial pass can manufacture a defect

The sharpest failure of the whole exercise so far. An adversarial review found
a rule that "silently stripped the breaking marker from calver majors", with
real observed evidence — a year rollover cutting a patch release. It looked
exactly like a latent defect, survived one adjudication round, got "fixed",
and the fix was wrong: **a calver major is the year segment**, no more
semantically loaded than the month. Nothing breaks because the calendar turns.
The rule existed precisely to stop semver-derived breaking treatment reaching
a versioning scheme where it is meaningless, and the review judged it against
a semver prior that did not govern the artifact.

The generalisable form:

> Before calling a rule defective, name the model you are judging it against
> and check that the model actually governs the artifact. The stronger
> question is not "is this rule wrong?" but "is this rule wrong, or is my
> model of what it is for wrong?"

This is Chesterton's fence failing *even with the lens explicitly in the
brief*, because the fence question was asked about the rule and not about the
reviewer's own prior. Corollaries worth checking every time:

- When a dependency's versioning scheme is not semver, audit **every**
  inherited default whose rationale assumes semver — breaking markers,
  automerge policy, release-age soaks, major/minor PR separation, grouping.
  Each reasons about risk from a number that does not carry that meaning.
- The trap has a mirror image: do not classify by surface shape. A
  `YYYY.M.x` tag can be semver-intended (the owner may say so in config), and
  a year-branded product version (SQL Server 2022) is a real major.
  Mechanical "looks like a date ⇒ calver" is the same error with the sign
  flipped.
- Sweep for the prior elsewhere once found: in the same exercise it had also
  been baked into a CI falsifier, which then enforced the wrong model.

### Write the intent onto the fence

The structural prevention for the wrong-prior trap. Chesterton's fence only
works if someone wrote on the fence: the calver rule above was nearly
destroyed because its description said what the rule *did*, and the semantics
that made it correct lived in nobody's head but its author's. So give every
config rule this exercise writes or corrects a description stating **what
problem it solves** — the mechanics are readable from the rule; the reason is
not. And while auditing existing config, treat your own inferences as the
signal: **any rule whose intent you had to infer is a rule whose description
is inadequate.** Fix the description in the same change — the inference you
just did is exactly the thing worth persisting.

One danger class deserves an explicit pass: **a setting that reads as a
semantic assertion but is actually a workaround.** `versioning:`,
`separateMajorMinor`, `rangeStrategy` all read as declarations about the
dependency ("this project is semver"); where one is really a workaround for a
tag shape or a tool quirk, say so where the setting lives, or the next reader
will take it as ground truth about the upstream project — and reason from it.

### Smaller traps, briefly

- **Chesterton's fence by intent, not letter**: a deliberate rule can still be
  buggy — preserve the purpose, fix the implementation. (And see above for
  the case where the "bug" was the purpose.)
- **A matcher broader than its own description** is how latent defects hide:
  check every rule's match conditions against what its description or name
  claims it covers, in both directions (broader and narrower).
- **Degenerate template renders**: path-indexing templates can render empty or
  truncated segments silently (`feat(infra-)!:` from a missing path index).
  Include the degenerate cases in any closure computation.

## Verification

Neither of the two obvious approaches works alone, and both failed in
practice:

- A **raw cross-product** (files × managers × update types × …) explodes
  combinatorially and still proves nothing about absence — you cannot
  enumerate your way to "the config cannot emit X".
- A **purely analytic reading** of the config is cheaper and stronger — derive
  the emittable set, check it against the enum — but it missed two live
  defects: the derivation covered only the fields someone thought to
  enumerate, and part of the outcome depended on repo state the config does
  not determine.

The shape that held is three layers, split by whether the mechanism is
closed. The first two each come with the attack that keeps them honest —
run the attack against your own scheme before trusting the layer; each
attack found a real hole exactly where an analytic argument sounded airtight.

### Layer 1 — closure by construction, where the mechanism is closed

Where emission is static literals plus finite template expansions over
enumerable inputs, derive the complete emittable set and assert it is a
subset of the enum — as a **CI check re-run on every commit**, not a one-time
analysis. Re-running per commit turns repo-state dependence from a gap into
the mechanism: a new directory, a moved package, or a pin bump re-derives the
closure automatically. The re-run trigger must include occupancy changes (a
package appearing in a new directory), not just config changes.

**The attack — verify the verifier's own scope.** A soundness argument like
"every emitted scope is in the enum" holds only over the mechanism it was
checked against. Both live defects found in one repo came from a config field
the checker did not enumerate (`commitMessagePrefix` templates, while the
checker read only `semanticCommitScope`). Enumerate **every** field and site
that can produce the artifact you are constraining — including sites outside
the system you were told to check (the release tool's own PR-title pattern is
a scope-carrying site) — and enumerate them mechanically, not by hand: a
hand-written site list is the same failure mode the checker exists to catch,
one level up. Then state the argument's scope explicitly.

### Layer 2 — runtime gating plus declared sampling, where the mechanism is open

Some outcomes (which of a multi-item branch's compiled headers is emitted)
depend on unbounded repo state, so closure cannot honestly be claimed there.
Instead: settle the selection mechanism against the tool's source if you can,
sample the composition shapes that actually occur, **say plainly that this is
sampling**, and place a required merge-time check behind it so whatever the
open mechanism produces is still gated for enum membership at the door.
State precisely what the gate gives you (enum conformance) and what it does
not (honesty of the scope against the diff).

**The attack — cut equivalence classes on what varies the outcome, including
repo state.** Sampling is only as good as the class boundary. The tempting
axes are config properties: manager, update type, datasource. The real axis
often includes **repo state** — which package files share a branch, which
directories a dependency occupies — which changes with the dependency graph,
not the config. So the first thing to run against any class scheme: **find
two real cells in one declared class with different outcomes.** One
counterexample (the same dependency, same manager, same update type,
resolving to two different scopes on two real PRs) collapses the class and
the coverage it implied. Where the outcome depends on repo state, either
include that state in the class axis or widen the claim's label from
"closure" to "sampling".

### Layer 3 — falsification against named trap classes

Turn every defect found during derivation into a standing falsifier. Then
prove the green run is not vacuous by **injecting defects**: re-introduce
each real historical defect (including the withdrawn wrong "fix" — guard both
directions) and require the harness to catch every one. A verification suite
that has never caught an injected defect is an argument, not a check. And
hold the falsifiers themselves to the wrong-prior trap — a falsifier can
enforce the very prior it should be catching, and once did.

## Writing the rule document

The deliverable a future session actually uses — typically
`.claude/rules/commits.md` in the target repo. The bar: **a future session
must pick the right header from the diff alone, without asking.** Rules that
earned their place:

- **Enumerate only closed sets.** Types and scopes are closed sets — enumerate
  them exhaustively (an ordered, stop-at-first-match scope table makes the
  choice deterministic). Everything else — which dependencies are calver,
  which directories fan into multiple artifacts — states the *deciding rule*
  and where the source of truth lives, never the current list: lists rot.
- **Name the awkward scenarios as rules**, not as lore: the multi-artifact
  atomic change, the shared-surface-plus-artifact diff, the surface with no
  release routing, the test directory serving two artifacts. These are where
  future sessions would otherwise guess.
- **State what the header is** (a claim about the diff, or operative — per
  Q2's answer for this repo), because that one sentence is what makes every
  other rule make sense.
- **No self-history, no version numbers.** State the standing rule, not what
  changed or when. Gotchas stay as gotchas, not war stories.
- **No claims that depend on another repo's current state** — that coupling
  goes stale silently. If the taxonomy interacts with a shared preset, state
  the invariant to re-check, not the preset's current contents.
- Tables where they carry density; prose for reasoning that does not
  tabulate. Keep it short enough to always be loaded (well under 200 lines).

## Amending this skill

This method has been applied to two repositories. The questions and traps
above transferred between those two; the answers did not — and some of what
reads as general here may yet prove to be a property of that pair (both are
one-maintainer repos, squash-merge, release-please + Renovate + commitlint;
a merge-commit repo, a multi-maintainer repo, or a different release stack
will stress different assumptions). After applying this skill to a new repo:
record what the method missed, which trap fired again (recurrence is what
promotes a one-repo observation to doctrine), and which "in both repos so
far" claims survived a third data point — then edit this file. The traps
section earns its keep only if it grows.
