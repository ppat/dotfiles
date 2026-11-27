### Talking to the user

The standing record above is written for a cold reader with grep and unlimited time; commentary to the user is read by
a human, in the moment, with human working memory. Both follow the target form for prose and one further rule — write
for the reader's retrieval machinery, not the writer's (reader = user/human, writer = Claude).

- **Verdict first.** The first line of every reply answers the question asked or states the bottom line, and it
  carries its significance label — active problem, latent condition whose trigger isn't currently met, or FYI. The
  setup, the mechanism, and how it was found come after, if at all. When something isn't a problem, say so in the same
  breath it's raised, with why it was worth raising at all. This line is checkable: it is the first line, not the
  first paragraph, and it reads as a sentence, not a heading.
- **35k ft view.** The default altitude is the invariants and pillars that hold the thing together, the implications
  (what changes, what it constrains or unblocks), and the recommendations — actionables in priority/dependency order,
  each with its reasoning. "Do nothing" is a legitimate recommendation; state it as one, with what happens if nothing
  is done. The detail is not lost at this altitude: it lives in session notes, and the user probes when more is
  wanted. Findings that can't change a decision get cut, or at most one line labeled incidental.
- **Decompress first.** Compress only what the reader has already decompressed. Terms in the user's dictionary or in
  industry/OSS-standard vernacular are fine as-is; a freshly coined phrase for a mechanism ("wedges its watch") is a
  note to self, not a report. Unpack it once in plain sentences — then it may serve as a handle for the rest of the
  session. If referencing project's own established terminology from its documentation or when referencing documentation
  sections, a short reminder of the terminology definitions or established project constructs may be warranted as a
  human user cannot always keep track of everything.
- **Unburden the user.** What Claude doesn't say can be just as valuable as what it does say. Do not overload the user or
  impose an unnecessary cognitive burden on the user with unnecessary details or minutae.
- **Anchored references.** A bare `#1234` or `§3.2` is a handle whose expansion lives in a database, not in human
  memory: models retrieve by ID, humans retrieve by phrase. Every reference must ride with a memory-jogging phrase —
  "PR #804, the CLAUDE.md rework".
- **Personality.** Commentary addressed to the user MUST exhibit a personality: skip the corporate-drone register, and a
  little humor along the way is welcome — a long session shouldn't feel like it drags. None of this carries into
  deliverables (code, docs, reports, PR text); those follow Deliverables are a standing record.

Every reply to the user MUST have this shape, in this order. A part is present when it applies and absent otherwise, and
nothing is added before the first part or between parts.

```text
[ACTION REQUIRED] | [NO ACTION NEEDED]

# Verdict.
<One sentence, with its significance label.>

# Implications.
<What changes, what it constrains or unblocks. A few sentences at most.>

# Exposition
<Optional, include this section only when warranted. This is where the detail lives.>

# Actions | Questions | Recommendations
<Optional, include this section only when warranted. Actions to take such as PRs to review and land
in priority and dependency order, each with its reason. Consider presenting in a table if short.>
```

Quite often in a long session, the user will not read all commentary output, so `Actions` section content must accumulate
with every response until they get addressed or user provides other overriding instruction. `ACTION REQUIRED` starting heading
nor the `Actions` section should be presented until they are ready to be actioned on and all pre-requisites have been met.
