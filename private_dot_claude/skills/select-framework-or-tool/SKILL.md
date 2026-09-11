---
name: select-framework-or-tool
description: >
  Use this skill whenever a project must choose between real alternatives for
  a language, framework, library, runtime, database, broker, toolchain, test
  stack, packaging, or platform, where the choice will be lived with and has
  to be defensible later: "Go or Rust for this service", "pick the browser
  framework", "which migration tool", "Postgres as the queue or a broker",
  "Helm or Kustomize", "what should our test runner be". It teaches a method
  sized to the decision: derive requirements from the project as it stands
  today, cost the incumbent as a candidate, research by instrument with
  sources and epistemic marks, grade on a stated scale, measure what
  documentation cannot say, spike the leader when only building can settle
  it, and present the comparison so the tables carry the decision. Do NOT
  use it for a version bump, for settings of a tool already chosen, or for a
  lookup that ends in an answer rather than a choice.
---

# Selecting a language, framework, library, tool, or platform

You are producing, grounded in evidence gathered for this specific project:

1. **A selection report** — the pick, the requirements it was judged against
   and their weights, every alternative with the case that was made *for* it,
   and the consequences, including what it costs to leave and, for anything
   that must be operated, what it costs to run.
2. **An evidence trail** the report can be checked against — research reports
   with linked sources and epistemic marks, measurements with the commands
   that produced them, and a claim-by-claim source walk of the report.
3. **A spike result, or a spike list with flip conditions** — see step 5 for
   which.

Not a survey. Keep the alternatives honest and put the numbers in tables,
not prose. The report lives in the session notes; carrying its result into
the project's own documents is the job of whatever documentation process
that project runs, and the report has to hold everything that process will
need.

**Sizing.** The full apparatus below — parallel research tracks, a second
round, a spike, review until it stops moving the pick — was built for a
decision that is expensive to reverse and will be lived with for years. The
cost of a method is paid on every run; its benefit is realised only where
reversal is expensive. A choice that is cheap to make and cheap to undo gets
the parts that keep earning at any size, which by step are these.

- Step 1 whole, because every move in it reduces the work that follows.
- Step 2 whole, because the incumbent and the excluded shapes cost a
  paragraph each.
- Of step 3, everything except the delegation mechanisms it marks as such.
- Of step 4, everything except the long-term factor table, because a cheap,
  reversible choice does not load five-to-ten-year questions; dropping the
  table also drops the long-term factors from what the landscape work has
  to answer. The modernity row stays, because a small, fast decision is
  exactly where an answer from training data goes unnoticed.
- Of step 5, the deciding rule as written.
- Of step 6, its bullets in its order, dropping only the confidence table
  and the section on what the evidence cannot bear, because both exist to
  let a reader weigh evidence the pick rests on, and a cheap pick rests on
  little; and thinning the prose pass to the winner's honest case against,
  because the losers' cases are what the grid already shows. The
  consequences stay, because for anything that must be operated what it
  costs to run is most of the value in writing anything down, and for a
  library or a tool the exit cost and the gotchas carry it instead.

This sizing has not yet been tested by a selection run at small size; the
first such run records, under the amendment protocol, which parts it dropped
and whether that was right. State which parts you are dropping and why, so
the sizing is on the record rather than silent.

**A sample of two.** This method comes from two selections: an
implementation stack across four languages, and a browser framework with its
testing toolchain across eight candidates. Where a sentence below rests on
one instance it says so, and "in both selections" is the strength of the
claim, not a law. The amendment protocol at the end is how single-instance
material becomes doctrine.

## The lenses that govern every selection

The owner's standing weights, stated once here so every step can assume
them, each with the reason it holds so it can be applied to a case this file
never anticipated.

- **Safety through structure, not through more work.** Where the design
  requires a guarantee, prefer the candidate whose ordinary path cannot
  produce the unsafe state over the one that needs a check, a lint, or a
  discipline to decline it. Work that must be implemented, maintained, and
  kept in step inhibits evolution; structure does not erode.
- **Avoid a class of problems rather than mitigate it.** A candidate that
  brings a whole class of failure and troubleshooting with it loses to one
  where the class cannot arise, even when each instance could be mitigated.
  The cost of a class is every future instance plus every future diagnosis,
  and neither appears in a feature comparison; an option that creates more
  work for the project than it removes usually does so through a class.
- **Nothing today that is not needed today.** Defer freely except where
  deferral is irreversible or the failure it permits is silent. A selection
  that buys capability the roadmap does not reach is cost with no return.
- **Simple made easy.** Judge a candidate on what it braids together, not on
  how familiar it looks. The familiar-but-complected option never wins over
  the simpler-but-harder one merely because it is nearer to hand; the hard
  part of the simple option is the reasoning that chooses it, and what
  follows the choice is easier.
- **Pareto.** A few properties carry most of the weight. Rank them
  ruthlessly and give the rest brief treatment.
- **Asymmetric payoff.** Where being wrong is cheap and reversible, try it.
  Where it is expensive and alternatives exist, do not. Where it is
  expensive but the decision would simplify much else, restructure so that
  being wrong becomes cheap — an exit that is a one-line alias is worth
  designing for.
- **Optionality is preserved.** Do not make a decision that removes a future
  the project may want, and keep concerns un-braided so the component that
  must vary later can vary alone. Components know only each other's
  contracts.
- **Modernity as of the current year.** Decide on the field as it stands
  now, not as training data remembers it. A model being replaced by its own
  successor is a bet on the outgoing half; a tool that reached its stable
  release this year changes a grade that was right last year.

## Evidence discipline

Rank evidence: **measured > verified from a primary source > documented >
judgment.** Mark load-bearing claims — the ones a grade or a rejection rests
on — with which it is, and the date:

- `[measured <date>]` — you ran it here, under this project's constraints,
  and the command is in the notes.
- `[verified <date>]` — you read it from a primary source this session: a
  package registry, a release feed, a repository's source, an advisory
  database, the vendor's own documentation page. A confirmed absence takes
  the same mark with "as an absence" added.
- `[judgment]` — your reasoning over the above.
- `[unverified]` — you could not confirm it. Say why, and name it as a spike
  item if the pick depends on it.

Rules that came from being burned:

- **Registries and release feeds over search summaries.** A retrieval tool
  that summarises a page rather than returning it invented release dates and
  maintenance states four times across the two selections; the structured
  API was right every time. When a number disagrees with recollection, the
  registry wins.
- **Tooling facts rot fastest.** Every load-bearing version, cadence, or
  maintenance claim carries its date.
- **"Supports X" is a hypothesis until the smallest thing that exercises it
  runs.** In one selection a published plugin turned out to be an empty
  package. Facts of that kind are found by a hello-world or by reading the
  source, and each goes in the report as a consequence, because a builder
  meets it on day one.
- **A constraint that discriminates hardest in the first pass may be the one
  that binds least.** Weigh a settled decision by what *stands on* it —
  which other decisions, which downstream work, which pipelines share it —
  not by where it is mentioned. When a weight moves, re-read every ranking
  that leaned on it, keeping the per-requirement grades and discarding the
  aggregate. In one selection a toolchain constraint that had sunk two
  candidates in the first pass was demoted from a gate to a tiebreaker once
  it was weighed by what stood on it; the grades survived unchanged. The
  second round then found the cost of working around it was higher than
  first graded, not lower, which is a separate finding about the same
  constraint: the demotion was right, and the assumption that it was cheap
  to work around was not.
- **A documentation page silent on your hardest constraint is itself a
  finding.** The candidate whose documentation never mentioned the
  project's binding policy was the one the policy broke.
- **An absence is evidence only when the search that failed is described.**
  Give the queries, the corpus, and the count, grade the result below
  positive evidence, and mark it as a verified absence so the next reader
  does not repeat the search. The absence of a bad signal is
  not a good signal: a project with no maintenance statement either way has
  a gap, not a clean bill of health.
- **A maintainer's position is not a bug.** When a candidate does not work
  with something the project has fixed, find out whether the gap is an open
  bug or a stated position, quote the maintainer, and say which. A bug may
  close; a position is permanent for planning and is graded as permanent.

## The steps, in order

Each step's output is the next step's input, and the order is what keeps the
pick derived rather than rationalised.

### 1. Derive the requirements from the project as it stands today

First restate the decision as the smallest set of questions that can be
answered independently, because a question that braids two decisions
produces a candidate set that is really a cross-product, and the braid
usually hides one question whose answer is already settled. In one
selection "which test stack" came apart into whether a real browser had to
be in the permanent gate at all and, only if so, whether it had to live in
the project's toolchain.

The check is against the project's entire current design. Where the project
keeps written design — what it has committed to, what it has ruled out, and
how it sequences work, in whatever documents hold them — read all of it.
Where it does not, the requirements live in the code, the schema, the
deployment shape, and the operator's stated constraints, in that order of
authority, and a requirement that rests only on inference is marked and
confirmed before it carries weight. Where the project does not exist yet,
they come from the intended deliverable's shape — who runs it, where it must
install, what it must interoperate with, what the maintainers can absorb —
and that is the most volatile input the method has, so it is the first thing
the flip conditions are written against. Write down what any candidate must
do, each requirement with its source, ordered provisionally by how strongly
you expect it to discriminate, and re-order once the grades exist. In both
selections roughly the first half separated the field and the second half
was a wash that earned brief treatment. The count is whatever the project
loads: sixteen for a language and stack, twelve for a browser framework, a
handful for a migration tool.

"Today" matters. A research pass made before the design settled leans on a
world that no longer exists; when the design has since moved, the current
documents are the definitive understanding and the earlier pass is
background, read from a position of whether it is still valid given what is
now known. Re-derive rather than inherit.

**Weights.** Some requirements order the field and some only break ties, and
the difference has to be settled before grading, not after. The owner's own
words are the only reliable signal of which is which, so quote them in the
notes. Where the owner has not stated weights, propose a weighting derived
from the requirements, send it as one question together with the candidate
set, and hold the research until it returns — weights discovered after the
research has run cannot be applied without re-reading all of it.

Three things to establish here that shape everything after:

- **What the design has already removed or already guards.** An ecosystem
  argument made before the design settled may not survive it: a design that
  forbids a feature removes every candidate's strength in that feature from
  the comparison, and a guarantee the design already holds by structure
  elsewhere makes a candidate's own guarantee one increment of a layered
  defence, not the invariant. This is also where you decide which vectors
  the design does not load at all; do not grade on those, and say which you
  dropped, because a dropped vector is itself a finding about the project.
- **Which component actually discharges each requirement.** A requirement
  another component already carries is not a requirement on this choice.
  Walk the list and mark, for each, the layer that can serve or prove it and
  what is lost by moving it there, and say which you moved. The count that
  comes back resizes the decision: in one selection seven controls had been
  treated as the candidate's responsibility and exactly one could live
  nowhere else.
- **The proving scenario.** The one composite use that exercises the most
  requirements at once, or the failure that would quietly kill the project
  if the candidate mishandled it. If you spike, it builds this and nothing
  else; if you do not, it is what the spike list is written against.

### 2. Fix the candidate set, with the incumbent as a named column

Four kinds of candidate, and the first is required:

- **The status quo, costed.** What the project does today, what it costs to
  keep doing it, and what it would cost at the scale the requirements
  describe. Where the project is new, the incumbent is whatever the team
  already builds and operates in, costed the same way. Omitting it is the
  cheapest way to reach a wrong answer that survives review, because every
  remaining column then looks like an improvement on every other.
- **The mainstream candidates.**
- **The paradigm-different shape.** Server-rendered against client-rendered,
  compiled against interpreted, managed against self-hosted, declarative
  desired-state against imperative versioned. And the polyglot variations: a
  second language confined to one deployable behind a contract, or a core in
  one language under shells in another.
- **The platforms the owner has excluded**, each in the report with what it
  would have offered and whether the exclusion changed the outcome. An
  exclusion that removed an option which would have lost anyway is
  reassurance; one that removed the option that would have won is a decision
  the owner should be shown again, and the report is the only place they
  will see it.

The unconventional candidates are there so the report carries a real case
for them rather than a dismissal — one turned out to be structurally
disqualified by a constraint the project already held, which is more useful
to the next reader than silence.

State up front which prior decisions a candidate would ripple into and the
burden of proof that applies, because a burden stated before the research
runs cannot be re-litigated once the answer is known, and a candidate that
was always going to fail it is dropped before the budget is spent on it. A
candidate that reverses a settled decision's operative clause carries a
higher burden than one that needs a looser reading of a passing sentence;
say which is which before researching.

A stated cost is usually compound and hides a small true surface, so
decompose it until each part is priced. Table the ripples that run in the
project's favour beside the ones that cost, because a ripple table with only
costs is an argument rather than an analysis. In one selection "a different
language cannot use the shared libraries" was true and turned out to be
bounded to types and read queries.

### 3. Research by instrument

Split the research by *how* a question is answered, not by candidate, with
one track set apart not by its instrument but by its independence. At full
size these are parallel subagent tracks; at small size they are an
afternoon's checklist, but the split still holds, because the instruments
survive the change of scale. The independence does not, since it is a second
agent; at small size its substitute is re-deriving each load-bearing
ecosystem claim from the registry before trusting your own earlier note.

| Track | The kind of question it answers | Instrument |
| --- | --- | --- |
| Landscape and long-term fit | What the candidate is today and where it is going: governance, release cadence, breaking changes, advisory record, agent-readable documentation, per-requirement grades, the long-term factors | Registries, release feeds, advisory databases, source, documentation |
| Empirical fit | What the candidate costs and does under this project's binding constraints, in the places documentation reliably gets wrong: its footprint, its behaviour under the constraint that discriminates hardest, what it does in the failure that matters | A scratch directory outside the repository, one candidate at a time, cleaned up after each |
| Verification of tooling facts | Whether the ecosystem claims the landscape track leans on are true: maintenance state, spec currency, whether a feature exists at all | The same registries and release feeds, by a second agent briefed not to read the landscape report first, so the check is independent of the claim; at small size, your own re-derivation from the registry |
| Companion picks | Whatever travels with the pick: the test toolchain, the code generator, the migration runner, the dependency policy | The same instruments, briefed separately |

Write down what you believe and why before the research starts, so that
the research can refute it; at any size the refutations are where the
value is, and at small size the one refuting your own notes is you. In one
selection the refutation "the escape route contains the thing it escapes"
removed a candidate. Once the field narrows, go back over the thin spots,
feeding each line of enquiry the others' load-bearing findings, and expect
grades to move when you do: an adapter two passes had assumed existed had
never been published.

The next three paragraphs are what makes delegation pay, and they apply
when the tracks are delegates rather than a checklist.

Brief each track with those beliefs. One agent holds the whole landscape so
grading is consistent across candidates. Selection-specific items for the
brief, beyond the standing delegation shape: the grading key, the long-term
factors, the measurements with their commands, and the output contract
(links on every factual claim, marks on load-bearing ones, confidence, what
would change the reading).

Make the refutation a deliverable rather than a hope: the output contract
includes a table with one row per belief the brief stated and a verdict on
each (confirmed, refuted with the grade that changes, understated, right on
one half), plus a last row for the belief the brief did not state and the
delegate would put first. Without the table, agreement and silence look
identical. In one selection that last row is where the binding constraint
arrived: the brief had ranked the candidates' own properties, and the
delegate answered that a toolchain fixed by an earlier decision
discriminated harder than any of them. The delegate also checks the brief's
factual premises against the project before using them and says what each
correction changes, because beliefs are offered to be refuted but facts are
copied forward unchecked, and a wrong fact silently mis-sizes a cost.

The second round runs **with the same agents**, on the thin spots they
named, because their accumulated context is what lets round two go deeper
rather than restart. A round is a closed loop with three fixed parts:

- It opens by restating your rulings on the previous round as hypotheses it
  may refute, because a ruling is a decision about weight and not a fact.
- It closes by naming its successor's questions with each answer's
  consequence pre-committed ("if yes with a small plugin the project owns,
  cost the ownership; if no, the candidate is deciding against a settled
  decision and is recorded that way"), because a question whose answers
  carry no consequences returns information rather than a decision.
- It ends with a was-now-why table of every cell it moved, so the grid's
  history is legible without re-reading the prose.

### 4. Grade, then read the grades four ways

**Per-requirement grades on a stated key.** Four levels have been enough. As
numbers, 4 to 1; as words, strong, adequate, weak, fails: the candidate
carries the requirement natively (4); it is carried with known, bounded
discipline or one small maintained package (3); it is carried only by
convention or with a named gotcha (2); it cannot honestly satisfy the
requirement (1). No half grades: one selection drifted to seven effective
levels through hedges like "adequate to strong", and a column with a hedge in
it cannot be read per column at all. The caveat that produces the hedge goes
in a notes column, where it is worth more than the hedge was. Grade every
candidate on every loaded requirement, the incumbent and the unconventional
ones included, so that no cell is hand-picked, and say which cells rest on a
measurement and which on documentation. The result is the grid, one row per
candidate and one column per requirement, and it is the first of the two
tables the report opens with.

**Long-term likelihood of success**, because "which is best today" and
"which leaves the system alive, maintained, evolvable, and un-rewritten in
five to ten years" are different questions. Score only the factors this
project loads, and say which you dropped:

| Factor | Question |
| --- | --- |
| Platform trajectory and governance | Who funds it, who maintains it, how concentrated the commit history is, whether a rewrite of its core is in flight, whether its compatibility promise has held |
| Longevity of the load-bearing dependencies | Not the candidate — what it drags in: single maintainers, governance handovers, a demonstrated rotate-and-deprecate metabolism, an official client in maintenance mode |
| Guarantee durability under years of edits | Which properties hold by structure and which by convention, and what a hurried future edit or a less careful agent reaches for |
| Maintenance burden on the actual maintainers | Breaking-change frequency the dependency bot will surface, majors since a fixed date, an unannounced restructure ahead, against how many people will absorb it |
| Completion risk | Whether this candidate stalls the builders before value lands — a stalled project scores zero on every other factor |
| Review burden after opening the project, where that is planned | Contributor pool size against contribution variance, and how much of the review the compiler or the lint carries |
| Agent-tooling trajectory | Corpus size, agent-readable documentation published, and whether the candidate's idioms pull agents toward what the project forbids; an agent iterating against a compiler that rejects wrong programs converges with less steering |

**Modernity as its own row.** Whether the candidate's model is current or
being replaced by its own successor — judged only on the vectors the design
loads, per step 1.

Before reading the grid, look for dominated candidates: one beaten on every
loaded requirement is removed without any weighting argument, which is worth
finding before the weighting fight starts. State dominance as dominance and
name the one condition that would break it, because a dominance claim with
no stated condition is indistinguishable from a strong opinion.

Then read the whole grid four ways, and write the readings down, because a
reading held in working memory cannot be checked by the reviewer or
reconstructed by the next reader, and the readings are where the decision
happens:

1. **No weak cell.** Prefer the column whose worst case is "adequate by
   design" over the column with a higher ceiling and one structural
   weakness on a load-bearing requirement.
2. **Redundant increments versus single points of failure.** A candidate's
   wins on a property the design already guards by several other layers are
   worth less than a rival's wins on the one property nothing else backs
   up. In the stack selection the type-level ceiling was redundant with the
   schema and the interface boundary, while velocity and completion risk
   guarded the one outcome nothing else did: a project that ships and stays
   shipped.
3. **Asymmetry under inversion.** Describe what regretting each candidate
   looks like and what it costs to reverse. An exit that is an alias at the
   build boundary is not the same as an exit that is a rewrite; in the stack
   selection the language choice, with a shared library under every
   deployable, was judged the least reversible decision the project would
   make. The report must say which kind each exit is, narrowed honestly to
   what actually survives the exit, not "the code". Beside the reversal
   cost, say when and how loudly each failure surfaces, because a mistake
   the build refuses on day one costs less than the same mistake accreting
   quietly until the milestone ends.
4. **Detachability of the wins and the losses.** For each candidate, ask
   which of its strengths can be had without choosing it — a separate
   deployable behind a contract, an offline step, a generated artifact — and
   which of its weaknesses can be confined to one component. A candidate
   whose wins are all detachable and whose losses are not is dominated,
   however good its best cells look. A detachable strength is also one of
   the three ways a requirement stops discriminating, under the traps. In
   the stack selection the machine-learning requirement left the language
   choice entirely this way, because the only work that loaded it was its
   own deployable behind its own contract.

Close the analysis with **flip conditions**, stated so the recommendation is
falsifiable. They come in three kinds, and a report with only the first is
under-specified: a weighting the owner may hold instead of the one assumed
("if compiler-grade unconstructability outranks completion risk, the other
answer is Rust, and here is what it costs"), a result a spike or measurement
may return, and a future observation with a named trigger, which is the kind
that keeps working after the report is filed. Each says what of the report
survives the flip, because "everything else transfers" is what makes a flip
a cheap decision rather than a new selection. Where another decision is
still open, mark which options are indifferent to it, since an option that
does not have to wait is worth something in itself. Then a **sanctioned
escape hatch**, documented rather than pre-taken, where one exists.

Then the **spike list**, sized in hours or half-days. Each row names the
grade or claim it would confirm, so the list is derived from the table
rather than invented. It has three classes: the rows that run now; the rows
that run only if the pick flips, which is what makes a flip condition
executable; and the rows deferred until the work that loads them arrives.

### 5. Spike the leader when only building can settle it

Spike when the claims that decide the pick are ones only building can verify
and the build is hours, not weeks. Otherwise ship the spike list with flip
conditions, state the pick as provisional on it, and say which you did and
why. The stack selection shipped with a spike list; the browser selection
spiked because the owner wanted the alternative in hand if the leader failed.

Build the proving scenario on the leading candidate, in a scratch directory
outside the repository, against fixtures that carry the project's hostile
inputs, under the project's real constraints. Where they apply:

- Run the same critical test in the fast environment (a shim, an in-memory
  fake, a container) and in the real one, once, and record whether they
  agreed on every assertion.
- Do one mutation demonstration where the pick guards a rule: remove the
  mechanism, demand red, record *which* tests went red. A test that stays
  green under the mutation is the finding.
- Try to express each rule the pick imposes as a check the build runs, and
  find out which rules need an exact instrument instead and which cannot be
  expressed precisely at all. The last kind are consequences.

The spike's code proves a candidate, never a deliverable. Keep it outside the
repository so no build-state claim in the project's own documents becomes
false, and say where it lives. The one exception is a spike the project's
own plan already schedules: the selection's questions may ride on it, but
then the code is the project's and its build state does change, so the
report names which questions rode, what the spike answered as a by-product,
and what remains unproven. Either way, where an uncertainty can be settled
by one cheap experiment, do not buy a standing cost to hedge it: the hedge
is paid on every run forever and never returns the answer.

### 6. Present the comparison so the tables carry the decision

The shape that survived adversarial review, in this order:

- **The pick and the rules that travel with it.** Each pick, and every rule
  a builder or an agent will get wrong, with the enforcement named (a check
  the build runs, a fixture that must fail, a file diffed in CI) — structure
  over memory. Then a table mapping each requirement to the mechanism that
  meets it.
- **Two tables, the chosen candidate first in both.** The first is the
  grid, every candidate scored on every requirement, so a reader sees where
  each excels and where each fails without hand-picked cells. The second
  carries the decision drivers in the order the decision was made, with the
  measured values and, for each cell, the configuration it was taken on. A
  short reading follows, whose arithmetic is derived per column ("three
  candidates have no cell below 3; two carry two 2s; the rest carry a 1").
- **The prose pass over every candidate, the winner included.** A fixed
  shape for each: the strongest honest case for it, the strongest honest
  case against it, and a net reading, with no number the tables already
  carry. The grid scores parts and systems are chosen whole, so a candidate
  can win most cells and still lose, and a reader cannot see that in a
  table; the winner's case against is the part that is tempting to soften
  and the part that makes the flip conditions credible. Reject with the
  mechanism, not the citation: a rejection that cites a rule dies when the
  rule is edited, and where a candidate disqualifies itself, its own
  documentation doing so is the strongest sentence available.
- **Consequences.** The exit cost honestly, the gotchas the spike or the
  measurements found, the assumptions about other components, every check
  the pick introduces with what proves it, and, where the pick introduces
  something to operate, the operational consequences: backup and restore,
  the upgrade path, what monitoring it now owes, and what its failure looks
  like at three in the morning. Those are the ones a maintainer pays every
  week and the ones no research track surfaces.
- **Flip conditions and the spike result**, or the spike list the pick is
  provisional on.
- **A confidence table**, one row per load-bearing claim: the claim, a
  confidence level, and the observation that would change it. "Nothing
  plausible, and here is why" is a legitimate entry; a third cell naming a
  mood rather than an observation is not finished.
- **What the evidence cannot bear.** What could not be verified, which
  numbers are proxies rather than measurements, and the over-reading a
  reader is likely to make of your own evidence, said before someone else
  makes it. A raw count offered as a rate, a proxy offered as a measurement,
  and a single instance offered as a pattern are the three that recur.
- **What the report does not decide**, and where those decisions belong, so
  its authority is bounded and a slate of defaults is not read as a set of
  commitments. Close with the questions that remain, in dependency order,
  each marked with who answers it; where a question is the owner's — a
  standing cost accepted, a proof downgraded, a taste call — the report
  states the strongest argument on each side and formulates the question
  precisely, and does not pick.

Then a **claim-by-claim source walk** of the report against the research
files and the owner's words, and an **adversarial review** of the report by
one fresh reviewer, re-run with the same reviewer — its accumulated context
is what makes later rounds find what a fresh reader would not — until a round
returns nothing that would move a grade, a reading, or the pick.

## The traps

Each was found the hard way, in one of the two selections. Check every one.

### Fluency cuts both ways

Corpus size is a proxy for how well agents write a candidate's idioms and
also for how often they reach for the ecosystem's defaults, some of which
the project has decided against. Name the defaults that would break the
project's decisions, and convert the diffuse worry into structural controls:
a dependency roster diffed in CI, an import-boundary check, a test that runs
under the real constraint. A concentrated, enumerable risk with a control is
cheaper than a much smaller corpus. And the small candidates often publish
more agent-readable documentation per capita than the large one; check
rather than assume.

### "Free" properties have failure records

A property every candidate provides by default does not discriminate, and a
property a candidate provides is a dependency you must keep patched — two
of eight had shipped a regression in the property in question within
eighteen months. It is one increment of a layered defence, which is why the
test that proves it exists regardless of the default. Grade it as patch
latency under the maintainers you have, not as a boolean.

### The escape route may contain the thing it escapes

Moving to a second tool to avoid owning a plugin for the first turned out to
add the second tool *on top of* the first, because the second tool's plugin
depended on it. Before recommending an alternative route, list its
dependencies and check whether the route you are leaving is a subset of it.

### Graded on one configuration, measured on another

A candidate's requirement grade assumed an add-on that its footprint
measurement had not installed. Both were true; the table stated neither.
Every row of a comparison table states which configuration each cell was
taken on, and a cell that assumes a component the measurement did not
install says so.

### A requirement can stop discriminating

Three ways, and one consequence. No candidate carries the requirement, so
every one writes the same small module. No candidate removes a forbidden
capability, so the ban converts into an enforcement obligation that travels
with whichever is chosen, and "the pick does not help here" is the finding.
Or a documented hatch can serve it, so it leaves the primary decision. In
each case the requirement drops out of the comparison and the weight moves
elsewhere; notice when this happens and say so, rather than letting a stale
column keep ordering the field. The consequence: when the requirement
converts into a component the project owns, that component is the one piece
of work that survives a later change of candidate.

### The requirement that seems to force a standing cost

When one requirement appears to demand an expensive permanent commitment — a
second runtime, a second toolchain, a service to operate — decompose it into
its separate assertions before accepting the price, locate each, and price
the irreducible remainder by naming the specific failures only it catches.
If you cannot name them, the remainder is not real and the commitment is
bought on atmosphere. Then ask whether a toolchain the project already runs
can carry the remainder. In one selection a control that read as "a real
browser must be in the permanent gate" came apart into four assertions,
three provable in the language already present, and the fourth justified by
three named failures the cheaper check would pass.

### A known defect is priced against your own preconditions

An advisory or a known bug in a candidate is not a grade by itself. Read
what the defect needs in order to fire and check whether this project can
construct those preconditions at all. When it cannot, say so structurally,
naming the facts that make it unreachable, and write those facts into the
consequences as a falsifier, because what you have really recorded is a
standing assumption about another component. In one selection a
high-severity advisory in the leader was unreachable because the server
feeding it is generated from a typed registry that cannot emit the shape the
defect needs; the day any field in that position becomes free-form is the
falsifier.

### Tautological tests

A test that compares a served value to the constant the code under test was
built from stays green when that constant is broken; the expectation is
written out literally in the test, independently. A lint rule can read
correctly and match nothing; every lint ban that stands in for a control has
a checked-in file that violates it and a script that demands the linter go
red. And an assertion that checks presence rather than shape passes whether
or not the hostile input was interpreted; assert the literal input intact
*and* that nothing was constructed from it.

### The obligation is narrower than the tooling that sells it

An obligation your project actually holds is usually narrower than the
category of tooling that sells it, so grade ecosystems on the obligation
held, not on the maturity of tools that sell a broader one. In the browser
selection the obligation was a per-control demonstration that tests go red
when the mechanism is removed, which a small script does in any ecosystem;
the mutation-testing products graded so heavily in the first pass served
only an optional deeper search.

### Where does the seam sit?

When a candidate introduces a boundary — a second language, a second build
tool, a second runtime — ask whether the seam sits between deployables, where
a contract can hold it, or inside one, where two toolchains braid into every
component. In the stack selection that question was decisive: a core in one
language under shells in another put a foreign-function boundary at the
highest-traffic internal seam, while a second language confined to one
deployable behind its contract was a sanctioned hatch.

### A claim of "only" is derived, never asserted

A reading paragraph's "only two candidates carry a 1" produced a finding in
three consecutive review rounds because it was asserted from memory of the
table rather than derived from its columns. Every "only", "none", and "the
other" in a reading is recomputed from the table it reads, per column, before
it is written.

### The wrong prior in the reviewer, and in you

An adversarial reviewer can manufacture a defect by judging a candidate
against a model that does not govern the project, and you can do the same to
yourself by inheriting a lean from a research pass made before the design
settled, or by grading on a vector the design does not load (step 1 names
where that is decided). In the stack selection the earlier pass had leaned
toward a compiled language on a guarantee the settled design had since
placed in the schema and the interface boundary. Before calling a candidate
weak on something, name the model you are judging it against and check that
the project as it stands actually exercises it.

### The report must stand without the session

"Requirements 1, 2, 5, and 10" means nothing to a reader who was not there.
Name the source once and give each number its short name at every use. "The
recommendation" and "the spike" need antecedents inside the report. Whoever
carries the result into the project's documents will have only the report,
not the conversation.

## Amending this skill

After each selection this is applied to, record what the method missed, which
trap fired again, which step was dropped for size and whether that was
right, and which sentence a delegate or reviewer could not resolve. A trap
that fires in a second selection is promoted from instance to doctrine; a
step that is dropped every time is demoted to the full-size variant. Keep
one instance beside each rule, because the instance is what lets the next
reader judge whether the rule governs their case, and keep it to one, because
a list of instances from one project reads as that project's checklist rather
than the rule.
