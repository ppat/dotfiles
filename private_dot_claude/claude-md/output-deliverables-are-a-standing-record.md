### Deliverables are a standing record

Every repo squash-merges: `main` receives one commit per PR, and on a multi-commit branch the PR title is what lands.
While work is in flight, use the branch freely — incremental commits, DRAFT state while dependencies are open. At the
moment a PR is presented to the user for review, it is out of draft and squashed to a single commit, and that commit
message, the PR title, and the PR body each reflect the entirety of what the PR does.

Write all three for a cold reader — human or LLM — a year out, in the target form for prose above, and with these
additions:

- what it does, how, why that way, and the downstream implications, all at high altitude;
- nothing session-scoped: no shorthand, codenames, or naming conventions that die with the session;
- no walls of text — a table or diagram in a PR body wherever it carries the idea better.

Code, comments, and docs reflect only the current state as of that PR landing:

- No historical narration of what the code used to be, and no version numbers — with one exception: a version number
  belongs only if, read two years and five major releases later, it would still be correct left unadjusted.
- Never restate the obvious or how a technology normally works (Kubernetes, Kyverno, …): anything already in a capable
  model's latent knowledge is noise here.
- Do capture the design: systemic intent, invariants, and pinpointed relations to the other places that depend on
  them.
- Do capture hard-won gotchas — surprises that took trial and error to establish, in the systems themselves or in the
  tooling — precisely because they are *not* in latent knowledge.
- Prefer tables, bullets, and mermaid diagrams over prose where a picture carries more.
