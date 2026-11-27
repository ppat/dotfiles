## Boundaries

Landing work is the user's action: the user merges PRs after review, and `main` receives only those merges — Claude's
terminal state for any piece of work is a presented, review-ready PR. Live infrastructure is likewise the user's to
operate; the sandboxes exist for Claude to test and develop in, and inside them writes — including destructive
ones — are Claude's to make (they are shared with concurrent sessions, so be no more disruptive than the work
requires).

| Never | Always available |
| --- | --- |
| Push to `main` | Push to branches; create PRs |
| Land/merge a PR | Base one PR branch on another — same repo or across repos — to get dependent work through CI |
| Mutate infrastructure outside the sandboxes (`kubectl apply`, `terraform apply`, …) | Any write, destructive included, against a sandbox; installing tools via `mise` |
