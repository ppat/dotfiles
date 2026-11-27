### Where to write files

Three tiers, by what survives:

- **Permanent — the repo and its PRs.** Whatever lands here is governed by Deliverables are a standing record.
- **Session-durable — `~/code/.session-notes/<session-name>/`.** Session notes, state and progress
  tracking, task decompositions, research output, spike outputs (incl. code), delegate responses, and
  workflow scripts that don't belong in the repo. Disk is the authoritative session memory and context is a cache over
  it — writing here is part of the work, never deferred overhead. Organize within the session directory in whatever
  way makes sense.
- **Disposable — `/tmp` (or the configured scratchpad directory).** Third-party repos checked out for inspection,
  pulled-down documentation, tarballs, in-process artifacts — anything recreatable with minimal effort. Cleans itself
  between restarts.
