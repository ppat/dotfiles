# Maintaining `CLAUDE.md.tmpl`

This file is for the session (human or agent) that next edits the deployed global CLAUDE.md. It records the design so
changes build on it instead of accreting against it. It is chezmoi-ignored: it lives beside the template but never
lands in `~/.claude`.

## What the document is

A standing operating contract whose **only mechanism of action is conditioning inference**. There is no runtime and no
enforcement behind it — every effect it has, it has by shaping token generation. It is injected into every session,
into every subagent (recursively — subagents can spawn subagents), and it survives compaction because it is re-sent
with every request. It is therefore designed around how LLM inference works, not around generic CLAUDE.md convention.
When a "best practice" and an inference argument conflict, the inference argument won.

Two structural consequences of the injection model:

- **Salience decays positionally, not by omission.** The file is always present, but in a long session it sits ever
  deeper in the context. The counter is not repetition (impossible) but addressability — see handles below.
- **Every audience reads everything.** Delegates receive the same file, so no section may be incoherent when read by a
  subagent. This is why the Delegation section is keyed on *holding the spawn capability*, never on being "the main
  agent".

## The techniques in play

Each of these is load-bearing somewhere. Do not strip one without replacing the work it does.

| Technique | Why | Where |
| --- | --- | --- |
| Salience zoning | Behavior-shaping content conditions every token and needs the primacy zone; lookup content only needs to be findable, so it sits in the trough | Interpreting requests → Boundaries are the shaping zone; Tooling and environment is the trough |
| Named handles | Attention retrieves by similarity, so short stable names act as high-precision probes — and as a vocabulary the user can invoke mid-session ("apply Chesterton's fence") | Lens names, "The brief", "Drift, not tokens", "Deliverables are a standing record", section titles generally |
| Ownership framing over negation | Negation primes the negated act ("don't merge" activates *merge*); assigning the act to the user leaves no forbidden-action representation to leak, and doubles as a workflow definition | Boundaries prose ("landing is the user's action"); the bright-line table keeps literal "never" rows because bright lines also need unambiguity |
| Explicit actor naming | Bare first/second-person pronouns ("I", "you") get misread in both directions — sessions have attributed the user's actions to the model and vice versa | Whole document: the human is always "the user", the model is "Claude", and actorless imperatives address Claude |
| Schema over prose | Format-following persists across long contexts far better than prose admonition | The brief's five numbered fields; the routing/access tables |
| Deliberate priming devices | Making the model generate certain tokens conditions what it generates next | Hickey's "say so — naming that strength is part of the judgment" exists to force grounding tokens, not as etiquette; "decompose before executing" anchors work-block openings |
| Capability-conditional delegation | RACI is fractal: an agent's role follows from whether it can spawn subagents, not from tree position | Delegation's opening paragraph |
| Full-sentence distillation | Telegraphic fragments condition generation worse than complete sentences; cutting happens by dropping content, not by compressing wording | Whole document |
| No harness duplication | Restating what the harness already instructs (concision, tool habits) spends salience and adds nothing | Whole document — by absence |

## Structural decisions

- **Two strata, never merged.** "How to work" is four binding obligations; "Defeasible lenses" is an optional-fit
  toolkit. The strata marker at the top of How to work is the seam. Flattening them weakens both: obligations stop
  binding, lenses stop being ignorable.
- **Autonomy section is an inversion, not a deletion.** It replaced a "When to ask vs. proceed" section. A section
  organized around asking keeps *asking* primed as a move; structural guards plus capable models shifted the default
  to proceeding. What survived the inversion: batching, no-silent-workaround, execute-fully-once-agreed.
- **Interpreting requests hardens as autonomy grows.** Guards bound harm, not waste. The expensive failure of an
  autonomous run is competent work against a misread intent, so meaning-fixation rules (terminology binds, exact task
  scope, session direction binding) are the highest-leverage content for autonomous operation. The orthogonality
  sentence (scope discipline ≠ permission dependence) keeps the autonomy push from eroding scope discipline.
- **Anecdote policy.** The two delegate exemplars in The brief stay because vivid target behavior primes better than
  an abstract rule; session-specific statistics were dropped as session residue.
- **Talking to the user overlaps the harness deliberately — the handles are the point.** Harness prose ("lead with
  the outcome") demonstrably decays over long sessions, so this section carries the user-specific deltas (altitude
  default, the decompression rule, anchored references, format persistence, tone) and names each rule so a four-token
  correction ("35k ft view", "decompress that") retrieves it mid-session. Its diagnosis unifies the two observed
  failures — wall-of-text dumps and opaque coined shorthand — as one error: writing for the writer's retrieval
  machinery instead of the reader's. "Wedges its watch" stays verbatim as the anti-exemplar per the anecdote policy.
  Scope is user-facing commentary only: delegate-to-orchestrator traffic stays under the Output contract, and
  deliverables stay under Deliverables are a standing record — including the tone rule, which licenses personality in
  commentary and none in deliverables.
- **The document must pass its own standards.** "Deliverables are a standing record" applies to this file pair too:
  present state only, no history, nothing a capable model already knows, gotchas kept precisely because they are
  hard-won (e.g. the cgroup memory breakdown).

## Deliberate absences

- **Transitional or tool-enforced permission state.** Which MCPs currently accept writes is enforced by tool
  configuration and changes over time; the document carries only durable rules. Do not add "currently
  allowed/disallowed" statements.
- **Anything temporal.** The standing-record rule the document imposes on deliverables excludes it here too.
- **Repo-specific facts.** Those belong to repo-level CLAUDE.md files, which are additive to this one.

## Editing rules

- Both template branches must render: CI forces `.chezmoi.os` to `linux` and renders with the runner's `homeDir`, so
  the non-coder branch is what CI actually exercises. Neither `homeDir` branch may depend on data absent from the
  other environment.
- Machine-specific content goes inside the existing `homeDir` conditionals in "Tooling and environment" only;
  everything above that section stays machine-agnostic and template-free.
- Every new load-bearing principle gets a short stable handle, and existing handles are renamed only with reason —
  they are retrieval keys in past transcripts and in the user's vocabulary.
- Name actors explicitly: "the user" and "Claude", never bare "I"/"me"/"you". Actorless imperatives address Claude.
- Wrap prose at 120 columns; tables run their natural width.
- Verify with the CI-faithful render (`sed 's|"darwin"|"linux"|g'` then `chezmoi execute-template --source=.`), then
  read the rendered output once as a cold reader.
