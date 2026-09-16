# Maintaining `CLAUDE.md.tmpl`

This file is for the session (human or agent) that next edits the deployed global CLAUDE.md. It records the design and
the evidence behind it so changes build on both instead of accreting against them. It is chezmoi-ignored. It lives
beside the template but never lands in `~/.claude`.

## What the document is

A standing operating contract whose **only mechanism of action is conditioning inference**. There is no runtime and no
enforcement behind it. Anthropic's own words for the same fact are that Claude treats CLAUDE.md "as context, not
enforced configuration", and that a rule which must hold every time belongs in a hook instead. The document is
therefore designed around how inference works and what the evidence on instruction adherence says, not around generic
CLAUDE.md convention. When a "best practice" and an inference argument conflict, the inference argument wins.

How the harness delivers it, all vendor-documented:

- It is injected as a **user message after the system prompt**, not as part of the system prompt. Under the
  instruction-hierarchy ordering (system, then user, then conversation, then tool output) it sits at the same formal
  tier as whatever the user types next. When it wins a conflict it wins on specificity, recency, and trigger-keying,
  never on rank.
- It reaches every **custom subagent** (the `general-purpose` type and anything defined under `~/.claude/agents` or
  `.claude/agents`), recursively. The built-in `Explore` and `Plan` subagents skip it. They are used for tightly
  scoped lookups where that does not matter.
- It **survives compaction**. Claude Code re-reads it from disk and re-injects it after `/compact` and after auto
  compaction.

Two structural consequences:

- **Every audience reads everything.** Delegates receive the same file, so no section may be incoherent when read by a
  subagent. This is why Delegation is keyed on *holding the spawn capability*, never on being "the main agent", and why
  a brief never restates this file.
- **The file is never the whole mechanism.** What it cannot guarantee, hooks do. The pairings are listed under
  Hook pairing below.

## What predicts adherence

The user's own per-section adherence observations and the controlled studies agree on four predictors. Position in the
file is not one of them.

| Predictor | What it means | Evidence |
| --- | --- | --- |
| Trigger sharpness | The rule fires at a moment that shares surface tokens with the rule. Typing `gh` retrieves the routing table. Writing a PR body retrieves Deliverables. | The two best-followed sections (Tooling, Deliverables) have this. The worst (Talking to the user) has none. Path-scoped rules in Claude Code are the vendor building a product feature on exactly this property. |
| Checkability | The model can verify compliance while generating. | Anthropic's memory docs make specificity the stated lever, with the paired example "Use 2-space indentation" over "Format code properly". IFEval had to be built on verifiable instructions because unverifiable ones cannot be graded reliably. |
| Schema form | Tables and numbered fields are self-reinforcing once generation starts in that shape. Prose stays the right vessel for narrative content. | Anthropic's prompting docs recommend structured formats for state that is checkable and unstructured text for progress notes. |
| Alignment with trained defaults | Where the rule agrees with what the model would do anyway, adherence is free. Where it contradicts a strong default, prose alone has a ceiling. | Literal instruction following and the no-overengineering rule match current-generation vendor guidance verbatim. Reply-time narration is a documented current-generation default the file works against. |

Findings that shape the rest of this document:

- **Position does not matter.** A factorial study of 1,650 Claude Code sessions found no detectable adherence effect
  from file size, instruction position, or file architecture. An ETH Zurich evaluation of AGENTS.md files found that
  context files do not generally improve task success and add over 20% inference cost, with the harm concentrated in
  generic, derivable content. The lab guidance to put critical instructions first or last concerns a single long
  prompt, a different scale from a standing file re-read every session.
- **Knows-but-violates.** Three convergent 2025 to 2026 sources find that a model can restate a rule while breaking
  it. Reply-time failure is execution, not retrieval. Reminders address retrieval and buy a moderate gain (about five
  points on instruction-following benchmarks) without closing the gap under iterative work. The test of any fix is
  therefore the artifact (the reply text, the PR body, the worktree path), never the model's recitation of the rule.
- **Constraint count degrades adherence.** Every rule earns its place by the specificity test. Would removing it cause
  a mistake? Content a capable model derives on its own is removed, because the evidence says it is not merely inert
  but harmful.
- **Positive targets for diffuse dispositions, literal negation for bright lines.** Anthropic's prompting docs say
  "Tell Claude what to do instead of what not to do" for style and format rules, and ship literal "do not" phrasing
  for narrow behavioral gates. Both forms appear here, each where it works.
- **Emphasis language overtriggers on current models.** The vendor's dated guidance is to dial back "CRITICAL" and
  "MUST" phrasing. The one place the file carries emphasis ("HARD NO", "The ban there is total") is the user's own
  text, kept verbatim by the user's decision, and it is on the re-validation checklist.
- **Guidance is versioned to the model generation.** Anthropic organizes its prompting docs per model and expects
  re-validation at each transition. Three techniques (emphasis strength, thoroughness-forcing, subagent restraint)
  point the opposite way from one generation to the next. Hence the checklist below.

## The techniques in play

Each of these is load-bearing somewhere. Do not strip one without replacing the work it does.

| Technique | Why | Where |
| --- | --- | --- |
| Moment and artifact | A disposition decays. A rule that names the moment it fires and the artifact it leaves is checkable and its absence is proof of a skipped step. | The stated reading in Interpreting requests, the decomposition file in How to work, the delegation-decision line in the gate, the first-line verdict in Talking to the user, the file link in the Output contract |
| Named handles | Attention retrieves by similarity, so short stable names act as high-precision probes, and as a vocabulary the user invokes mid-session ("apply Chesterton's fence", "35k ft view", "decompress that") | Lens names, the four How to work handles, "The brief", "The delegation gate", "On a delegate's report", "Drift, not tokens", "Deliverables are a standing record", "Format persistence", section titles generally. "Delegate by default" is not a handle here, because a flat default in either direction is what the evidence rules out. The delegation rule answers to "The delegation gate". |
| Positive target beside a ban | Vendor guidance for diffuse style rules. The ban states the boundary, the target states the destination. | "Never try to sound smart" and the drone-register ban in The target form for prose each carry a positive target sentence |
| Ownership framing | Assigning an act to the user leaves no forbidden-action representation to leak, and doubles as a workflow definition. The literature does not test this technique. It is kept on the user's judgment and because it reads as a definition rather than a prohibition. | Boundaries prose ("Landing work is the user's action"), "Departing from the session's established direction is the user's decision" |
| Bright lines stay literal | Narrow, checkable gates need unambiguity more than framing. | The Boundaries table, the punctuation ban, the shorthand ban, the "never under `.claude/worktrees`" clause |
| Explicit actor naming | Bare first/second-person pronouns get misread in both directions. | Whole document. The human is always "the user", the model is "Claude", and actorless imperatives address Claude. The user's prose text is reflowed to this convention with no clause dropped. |
| Schema over prose | Format-following persists across long contexts far better than prose admonition. | The brief's six numbered fields, the three delegate functions, the five-step report procedure, the first-line verdict with its label, the routing and access tables |
| Function-conditioned brief | What a producer needs is close to the opposite of what a verifier needs. A disclosed verdict or lean anchors a judge, an instruction to disregard it does not undo the effect, so the exclusion is structural (no Reasoning field for a verifier). A verifier asked for gaps manufactures them, so it gets a relevance filter. | The brief, the executor / investigator / verifier bullets |
| Delegation gate | The evidence supports delegating a unit whose context is isolable or whose output is high-volume and mostly irrelevant to the orchestrator, and keeping sequential phases of one change together. It does not support a flat default in either direction. | "The delegation gate" |
| Deliberate priming devices | Making the model generate certain tokens conditions what it generates next. | Hickey's "say so, naming that strength is part of the judgment" forces grounding tokens. "Before executing, decompose" anchors work-block openings. The decomposition file makes the priming observable. |
| Capability-conditional delegation | RACI is fractal. An agent's role follows from whether it can spawn subagents, not from tree position. | Delegation's opening paragraph |
| Full-sentence distillation | Telegraphic fragments condition generation worse than complete sentences. Cutting happens by dropping content, not by compressing wording. | Whole document |
| Harness overlap, deliberate | Restating what the harness already instructs spends salience, except where the harness prose demonstrably decays and the user needs a copy they own and can name. | Talking to the user overlaps the harness on purpose. Everything else avoids duplication by absence. |

## Hook pairing

The file states the standard. Where the standard must hold every time, or where recency is the mechanism, a hook in
`settings.json` carries it. The file never depends on a hook to be coherent, and a hook never contains a rule the file
does not state.

| Rule in the file | Hook | What the hook adds |
| --- | --- | --- |
| Talking to the user, The target form for prose | `reply-contract-reminder.sh` (UserPromptSubmit) | Re-injects the handles every turn in the main session. Recency, which the file at the head of context cannot supply. Expected effect is moderate, so the first-line verdict format stays as the checkable half. |
| The punctuation bright lines in The target form for prose | `prose-lint-on-edit.sh` (PostToolUse on Edit and Write) | Advisory lint of the text Claude just wrote to a markdown file. Em dashes, semicolons, and mid-sentence colons, with the exemptions the rule grants. |
| Boundaries, never rows | `guard-git-push.sh`, `guard-gh-merge.sh`, `guard-git-dangerous.sh` (PreToolUse on Bash) | Deterministic denial. The prose keeps the rationale and the "always available" column. |

## Structural decisions

- **Two strata, never merged.** How to work is four binding obligations. Defeasible lenses is an optional-fit toolkit.
  The strata marker at the top of How to work is the seam. Flattening them weakens both. Obligations stop binding,
  lenses stop being ignorable.
- **The four How to work handles are bullet headers.** The aliases ("measure twice, cut once", "Occam's razor",
  "epistemic coherence", "substantive disagreement") lead each bullet in bold, matching the lens format. This makes
  them retrievable as handles and removes the label colons the prose rule forbids.
- **Autonomy is an inversion, not a deletion.** A section organized around asking keeps *asking* primed as a move.
  Structural guards plus capable models shift the default to proceeding. What the section carries is batching,
  no-silent-workaround, and execute-fully-once-agreed.
- **Interpreting requests hardens as autonomy grows.** Guards bound harm, not waste. The expensive failure of an
  autonomous run is competent work against a misread intent, so meaning-fixation rules (terminology binds, exact task
  scope, session direction binding) are the highest-leverage content for autonomous operation. The orthogonality
  sentence (scope discipline is not permission dependence) keeps the autonomy push from eroding scope discipline.
  These rules match current-generation vendor guidance on literal instruction following, which makes them partly
  redundant with trained defaults. They stay as the user-owned statement, with the one-line stated reading as their
  observable artifact.
- **The lenses are a pool, not the pool.** The intro says these are the lenses the user values most and reaches for
  most often, and that a more specific lens is welcome when it fits. The full expositions stay in this file by the
  user's decision. A skill was considered for them and rejected, because a lens has to be present to be reached for
  spontaneously and to serve as a mid-session vocabulary.
- **The brief stays in this file** by the same decision. It is invoked at the moment of delegation, and an indirection
  through a skill at that moment would cost adherence in the section that already adheres least.
- **The target form for prose is the shared stratum.** It binds artifacts and commentary alike, so it sits above
  Deliverables are a standing record and Talking to the user, and those two carry only their deltas and point back to
  it. Every clause of the user's text is present. The actor is Claude. Two positive-target sentences are additions.
  The code, URL, and label-cell exemption is a clarification the document needs to pass its own rule.
- **Talking to the user names its handles and makes the verdict checkable.** The harness's own prose telling the
  model to lead with the outcome decays over long sessions, so this section carries the user-specific deltas
  (altitude default, the decompression rule, anchored references, format persistence, personality) under names a
  four-token correction can retrieve. The first line of a reply is the checkable artifact. The reminder hook supplies
  recency. Its diagnosis unifies the two observed failures, wall-of-text dumps and opaque coined shorthand, as one
  error, writing for the writer's retrieval machinery instead of the reader's. "Wedges its watch" stays verbatim as
  the anti-exemplar per the anecdote policy.
- **Anecdote policy.** The two delegate exemplars in The brief stay because vivid target behavior primes better than an
  abstract rule. Session-specific statistics are session residue and are excluded.
- **Length is above the vendor's 200-line target by the user's decision.** The controlled studies find no adherence
  effect from size. The vendor's cap is about per-turn token cost and review burden, and the user accepts that cost for
  this content. The discipline in its place is content selection. Nothing derivable from the repo, nothing a capable
  model already knows, every rule past the specificity test.
- **The document passes its own standards.** Deliverables are a standing record and The target form for prose apply to
  this file pair too. Present state only, no history, nothing a capable model already knows, gotchas kept precisely
  because they are hard-won (the cgroup memory breakdown), and no em dashes, colons, or semicolons inside a sentence.

## Deliberate absences

- **Transitional or tool-enforced permission state.** Which MCPs currently accept writes is enforced by tool
  configuration and changes over time. The document carries only durable rules. Do not add "currently
  allowed/disallowed" statements.
- **Anything temporal, and any model version or generation.** The standing-record rule the document imposes on
  deliverables excludes them here too. The tier names in Size the model to the task are delegation roles, not
  versions. Model-generation concerns live in this file's checklist, not in the template.
- **Repo-specific facts.** Those belong to repo-level CLAUDE.md files, which are additive to this one.
- **Restatement of the harness.** Tool habits, concision, and the like are the harness's job, except for the one
  deliberate overlap noted above.

## Model-transition re-validation checklist

The vendor's guidance is measured per model and re-checked per model. When the default model or a delegate model
changes generation, re-check each item against artifacts, never by asking the model whether it complies.

1. **Emphasis.** Does the "HARD NO" and "The ban there is total" phrasing over-trigger (prose that is stilted or
   over-hedged) or under-trigger (the marks still appear)? Read ten replies and two PR bodies.
2. **Delegation propensity.** Count delegations against the gate over a session. Over-delegation of quick, targeted
   changes and under-delegation of sprawling searches are both misses.
3. **Reply verbosity.** Check the first line of replies that close work blocks for the verdict and its label, and the
   presence or absence of narration after tool calls. The trained default moves between generations.
4. **Subagent inheritance.** Confirm in the current docs that custom subagents still receive `~/.claude/CLAUDE.md`
   and that `Explore` and `Plan` still skip it.
5. **Hook events.** Confirm UserPromptSubmit and PostToolUse still exist with the stdin and stdout shapes the hooks
   assume. Run the synthetic-payload tests.
6. **Positive versus negative framing.** Re-read the vendor's current phrasing guidance and compare against the two
   positive-target sentences and the literal bans.

## Editing rules

- Both template branches must render. CI forces `.chezmoi.os` to `linux` and renders with the runner's `homeDir`, so
  the non-coder branch is what CI actually exercises. Neither `homeDir` branch may depend on data absent from the other
  environment.
- Machine-specific content goes inside the existing `homeDir` conditionals in Tooling and environment only. Everything
  above that section stays machine-agnostic and template-free.
- Every disposition names the moment it fires and the artifact it leaves. A rule with neither will decay, and its
  adherence cannot be observed.
- Every rule passes the specificity test. Would removing it cause a mistake a capable model would not otherwise make?
- Every new load-bearing principle gets a short stable handle, and existing handles are renamed only with reason. They
  are retrieval keys in past transcripts and in the user's vocabulary.
- Name actors explicitly. "The user" and "Claude", never bare "I", "me", or "you". Actorless imperatives address Claude.
- No em dashes, colons, or semicolons inside a sentence, in either file. Colons are allowed after a bullet header, at
  the end of a line leading into a list or code block, and in short headings. Code spans, code blocks, URLs, template
  syntax, and label cells in tables are exempt.
- Wrap prose at 120 columns. Tables run their natural width.
- Verify with the CI-faithful render (`sed 's|"darwin"|"linux"|g'` then `chezmoi execute-template --source=.`), run
  `markdownlint-cli2` with the repo config on the rendered output, grep the rendered output for em dashes and for
  semicolons and colons outside the exemptions, and read the rendered output once as a cold reader.
- A rule that must hold every time is a hook or a setting, not a sentence. Add the pairing to the table above and keep
  the sentence, because the file states the standard the hook enforces.

## Sources

Grades. A is lab research or official documentation. B is peer-reviewed or widely cited. C is practitioner work with
evidence, or a preprint without a confirmed venue. Where a technique names a model generation, treat it as measured on
that generation.

### Anthropic, grade A

- Claude Code docs, "How Claude remembers your project" (CLAUDE.md, rules, auto memory, compaction, the 200-line
  target, "context, not enforced configuration", user-message delivery). <https://code.claude.com/docs/en/memory>
- Claude Code docs, "Best practices for Claude Code" (reviewer independence, the gap-manufacturing caveat, hooks for
  zero-exception actions). <https://code.claude.com/docs/en/best-practices>
- Claude Code docs, "Create custom subagents" (CLAUDE.md inheritance, Explore and Plan exception, when to keep work in
  the main conversation). <https://code.claude.com/docs/en/sub-agents>
- Claude Code docs, "Automate actions with hooks" and the hooks reference (UserPromptSubmit `additionalContext`,
  PostToolUse). <https://code.claude.com/docs/en/hooks-guide>, <https://code.claude.com/docs/en/hooks>
- Claude Code docs, "Skills" (progressive disclosure, when a CLAUDE.md section has become a procedure).
  <https://code.claude.com/docs/en/skills>
- Claude Code docs, "Worktrees" (default `.claude/worktrees/<name>/` location, `worktree.baseRef`).
  <https://code.claude.com/docs/en/worktrees>
- Claude platform docs, "Prompting best practices" (per-model guidance, positive framing for format rules, emphasis
  overtrigger, reminder injection for long conversations, reply verbosity defaults, literal instruction following,
  overengineering guard).
  <https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices>
- Anthropic Engineering, "How we built our multi-agent research system", 2025-06-13 (subagent brief schema, scaling
  heuristics, adjudication step). <https://www.anthropic.com/engineering/built-multi-agent-research-system>
- Anthropic, "Building multi-agent systems: when and how to use them", 2026-01-23 (context isolability as the
  decision rule, sequential phases belong together, context protection as the first justification, 3 to 10x token
  cost). <https://claude.com/blog/building-multi-agent-systems-when-and-how-to-use-them>
- Anthropic Engineering, "Effective context engineering for AI agents", 2025-09-29 (right altitude, external
  note-taking, compaction, sub-agent summarization).
  <https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents>
- Anthropic Engineering, "Building effective agents", 2024-12-19.
  <https://www.anthropic.com/engineering/building-effective-agents>

### Other labs, grade A

- OpenAI, Wallace et al., "The Instruction Hierarchy: Training LLMs to Prioritize Privileged Instructions",
  2024-04. <https://arxiv.org/abs/2404.13208>
- OpenAI, McAleese et al., "LLM Critics Help Catch LLM Bugs", 2024-06. <https://arxiv.org/abs/2407.00215>
- Google, "Prompt design strategies", updated 2026-06-10.
  <https://ai.google.dev/gemini-api/docs/prompting-strategies>
- OpenAI, Codex AGENTS.md guidance (directory-scoped loading, 32 KiB cap).
  <https://developers.openai.com/codex/guides/agents-md>
- Cursor, rules documentation (focused, actionable, scoped rules). <https://cursor.com/docs/context/rules>

### Peer-reviewed or widely cited, grade B

- Cemri et al., "Why Do Multi-Agent LLM Systems Fail?" (MAST taxonomy, verification failure modes), NeurIPS 2025.
  <https://arxiv.org/abs/2503.13657>
- Kapetanovic et al., "Anchoring Bias in LLM-as-a-Judge Systems", CIKM 2026 (a disclosed prior score cuts error
  correction by 47.9%, warnings and chain-of-thought do not remove the effect). <https://arxiv.org/abs/2608.25869>
- Qiu and Gill, "Adversarial Review: Structured Disagreement for Grounded Agentic Code Review", 2026-08 preprint
  (full shared context with forced evidence-grounded disagreement). <https://arxiv.org/abs/2608.18167>
- Gloaguen, Mündler, Müller, Raychev, Vechev, "Evaluating AGENTS.md: Are Repository-Level Context Files Helpful for
  Coding Agents?", 2026-02, revised 2026-06 (context files do not generally improve success, add over 20% cost, harm
  concentrated in derivable content). <https://arxiv.org/abs/2602.11988>
- Laban et al., "LLMs Get Lost In Multi-Turn Conversation", 2025-05 (39% average multi-turn degradation, premature
  convergence). <https://arxiv.org/abs/2505.06120>
- Dongre et al., "When Attention Closes: How LLMs Lose the Thread in Multi-Turn Interaction", 2026-05 (goal tokens
  persist in residual representations while the attention pathway closes). <https://arxiv.org/abs/2605.12922>
- Wu et al., "Effectively Controlling Reasoning Models through Thinking Intervention", 2025 (reminder prompting
  raises IFEval strict accuracy by about five points). <https://arxiv.org/abs/2503.24370>
- Elder, Duesterwald, Muthusamy, "Boosting Instruction Following at Scale", 2025-10 (degradation with instruction
  count). <https://arxiv.org/abs/2510.14842>
- Jiang et al., "FollowBench", ACL 2024. <https://arxiv.org/abs/2310.20410>
- Zhou et al., "Instruction-Following Evaluation for Large Language Models" (IFEval), 2023-11.
  <https://arxiv.org/abs/2311.07911>
- Zhang et al., "IHEval: Evaluating Language Models on Following the Instruction Hierarchy", NAACL 2025.
  <https://arxiv.org/abs/2502.08745>
- "How Language Models Process Negation", 2026-05 (negation represented correctly, overridden by late-layer
  shortcuts). <https://arxiv.org/abs/2605.03052>
- Huang et al., "Large Language Models Cannot Self-Correct Reasoning Yet", ICLR 2024. <https://arxiv.org/abs/2310.01798>
- Gao et al., "DecisionBench: A Benchmark for Emergent Delegation in Long-Horizon Agentic Workflows", 2026-05
  preprint (routing fidelity invisible from outcome quality). <https://arxiv.org/abs/2605.19099>
- Cui et al., "Uno-Orchestra: Parsimonious Agent Routing via Selective Delegation", 2026-05 preprint.
  <https://arxiv.org/abs/2605.05007>

### Practitioner work with evidence, grade C

- McMillan, "Instruction Adherence in Coding Agent Configuration Files: A Factorial Study of Four File-Structure
  Variables", 2026-05 preprint (1,650 sessions, null result on size, position, architecture, and conflicts).
  <https://arxiv.org/abs/2605.10039>
- Kruthof, "Models Recall What They Violate: Constraint Adherence in Multi-Turn LLM Ideation", 2026-04 preprint
  (knows-but-violates, checkpointing reduces but does not close the gap). <https://arxiv.org/abs/2604.28031>
- Hong, Troynikov, Huber (Chroma), "Context Rot: How Increasing Input Tokens Impacts LLM Performance", 2025-07-14.
  <https://research.trychroma.com/context-rot>
- Walden Yan (Cognition), "Don't Build Multi-Agents", 2025-06-12 (conflicting implicit decisions between siloed
  producers). <https://cognition.ai/blog/dont-build-multi-agents>
- Cognition, "Devin can now Manage Devins", 2026-03 (isolated scopes make orchestration work).
  <https://cognition.ai/blog/devin-can-now-manage-devins>
- Manus, "Context Engineering for AI Agents: Lessons from Building Manus", 2025-07-18 (the filesystem as context).
  <https://manus.im/blog/Context-Engineering-for-AI-Agents-Lessons-from-Building-Manus>
- LangChain, "How and when to build multi-agent systems", 2025-06-16.
  <https://blog.langchain.com/how-and-when-to-build-multi-agent-systems/>
