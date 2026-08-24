---
description: How to choose the type and scope of a commit in this repo, and why the choice is a claim about the diff.
---

# Commit types and scopes

This repo has no release layer — no tags, no releases, no changelog generator, nothing that parses a commit header.
`main` is the release and `chezmoi apply` is the delivery. So the header is not an instruction to any machinery: it is
a **claim about the diff**, and the one claim worth keeping true is *did this change reach a machine?*

**The checks are deliberately advisory.** `main` has no required status contexts and is not getting any: this is a
one-maintainer dotfiles repo, and the taxonomy exists to tell the agents and humans writing commit messages what to
write, not to block a merge. A red `commit-lint` is a prompt to fix the header, not a wall. Do not "fix" this by
adding required contexts — it is a decision, not an oversight.

The header carries two fields answering two questions: **type** is *what kind of change is this?* and **scope** is
*what did it change?* They are independent in one direction only: a type claiming **machine behaviour** cannot sit on
a scope that never reaches a machine, and commitlint rejects the pairing.

This repo squash-merges with `squash_merge_commit_title=COMMIT_OR_PR_TITLE`, so a single-commit PR lands its commit
header and a **multi-commit PR lands its PR title**. Both are checked; on a multi-commit branch the title is the one
that survives, so it has to be right.

## The delivery boundary

Everything follows from one question, asked of whatever the commit touched:

> **Does `chezmoi apply` put this on a machine, or change what it puts there?**

Two consequences that are easy to get backwards:

- **Being in `.chezmoiignore` does not make something internal.** `Brewfile.*` and `krew-plugins.txt` are ignored, so
  chezmoi never copies them — but the apply scripts read them out of the source directory and install what they list.
  They ship. Ignored means "not deployed as a dotfile", not "not delivered".
- **A tool is not internal because it is a linter.** `shellcheck`, `yamllint`, `markdownlint-cli2` and `pre-commit`
  are pinned in the *deployed* mise config, so they land in `$HOME` and ship. The same tools pinned in
  `.pre-commit-config.yaml` or a workflow `env:` do not. Ask where the pin lives, not what the tool is for.

## Scopes

The shipped scopes are not a list of surfaces. There are exactly three ways this repo delivers anything — a package
manager installs software, an apply-time script runs, or a file is written into `$HOME` — and there is one scope per
mechanism. That is deliberate: naming surfaces instead (`vscode`, `kube`, `shell`, `git`) means grouping whichever
directories happen to hold more than one file, and it leaves the rest of the tree with nowhere to go.

Apply these **in order, stopping at the first match**. The ordering is what guarantees every commit lands in exactly
one scope.

| # | Scope | Matches | Ships? |
| --- | --- | --- | --- |
| 1 | `github-actions` | A `uses:` ref bumped or re-pinned — *anywhere*, and nothing else. **Not** the rest of what Renovate's `github-actions` manager finds: a `runs-on:` runner, a job `container:` or `services:` image is `internal-dependencies` | no |
| 2 | `agents` | `private_dot_claude/**`, `.claude/**`, root `CLAUDE.md`, ccstatusline, any other AI-coding-agent instruction surface — *anywhere* | no |
| 3 | `pkg-lang` | A language-runtime pin moved in the deployed mise config | yes |
| 4 | `pkg-cli` | Any other pin moved in the deployed mise config, or its lockfile refreshed | yes |
| 5 | `pkg-system` | Software installed by a manager other than mise: `Brewfile.*`, `krew-plugins.txt`, or a version pin inside a `.chezmoiscripts/` installer | yes |
| 6 | `internal-dependencies` | A toolchain/dev dependency moved, or a tooling config file hand-edited (`.pre-commit-config.yaml`, root `mise.toml`) | no |
| 7 | `renovate` | This repo's Renovate *configuration* | no |
| 8 | `internal-workflows` | This repo's own CI: `.github/workflows/**`, `.github/scripts/**`, `commitlint.config.js`, linter configs (`.yamllint`, `.shellcheckrc`, `.markdownlint-cli2.yaml`) | no |
| 9 | `bootstrap` | The apply pipeline: `.chezmoiscripts/**`, `.chezmoitemplates/**`, `.chezmoiignore`, `.chezmoi.toml.tmpl` | yes |
| 10 | `home` | Every file chezmoi writes into `$HOME` — shell, editor, cluster, credential and application config alike | yes |
| 11 | *(empty)* | Repo-level documentation or policy belonging to no single surface: `README.md`, `DESIGN.md`, `TESTING.md`, `.vscode/` | no |

Scopes 1 and 2 name a kind of *declaration*, so they are location-independent and sort first. Scopes 3–5 are the
package managers, 6–8 this repo's own machinery, and 9–10 the two remaining delivery mechanisms. Row 10 is what makes
the table exhaustive: nothing chezmoi deploys can miss every row.

`agents`, `github-actions`, `internal-dependencies`, `internal-workflows` and `renovate` mean the same thing here as
in `ppat/github-workflows` and `ppat/homelab-ops-kubernetes-apps`, and the shared Renovate presets emit two of them.
**`agents` is internal here even though this repo deploys `~/.claude`** — an instruction file steers an agent, not the
machine it sits on, which is why it means the same thing in a repo that ships one and a repo that does not. That is
also what keeps it off both sides of the boundary; a scope that straddled it could not be paired with a type at all.

When a commit spans mechanisms, scope it to the one that **motivated** it — adding a tool to the deployed mise config
and teaching a bootstrap script to use it is `pkg-cli`. If it genuinely has two motivations, split it.

## Types

Allowed: `chore`, `ci`, `docs`, `feat`, `fix`, `perf`, `refactor`, `revert`, `test`.

`build` and `style` are deliberately **not** allowed: there is no build system, and `style` is redundant with
`refactor`/`chore`. `revert` is kept despite going unused: its meaning is fixed, the parser special-cases it, and it
is the one type you cannot improvise mid-incident.

`ci` and `test` split this repo's CI by what a workflow is **for**. `full-apply-test.yaml` exercises the deliverable
end to end — a real `chezmoi apply` on a clean machine — so changing it is `test`. The workflows that lint, gate and
automate the repo are `ci`. Both live under `.github/workflows/`; the type is what tells them apart.

`feat`/`fix`/`perf`/`refactor` assert something about **machine behaviour**; the subject-matter types `ci`, `test`,
`docs`, `chore` describe the *kind of thing* changed and take precedence when they apply.

| Change | Header |
| --- | --- |
| New capability on a machine | `feat(home):` / `feat(bootstrap):` / `feat(pkg-*):` |
| Corrected behaviour on a machine | `fix(home):` / `fix(bootstrap):` / `fix(pkg-*):` |
| Anything in `.github/workflows/` or `.github/scripts/`, **including fixing a genuine bug there** | `ci(internal-workflows):` |
| A change to `full-apply-test.yaml` — the end-to-end apply test | `test(internal-workflows):` |
| A change to the Renovate rules | `ci(renovate):` |
| Hand-edit to a linter config or `commitlint.config.js` | `chore(internal-workflows):` |
| Hand-edit to `.pre-commit-config.yaml` or root `mise.toml` | `chore(internal-dependencies):` |
| Anything under `~/.claude`, `.claude/` or root `CLAUDE.md` | `chore(agents):` / `docs(agents):` |
| Repo docs on their own | `docs:` |

**A type claiming machine behaviour cannot sit on a non-shipping scope, or on an empty scope**, and
`commitlint.config.js` rejects both. The empty-scope half matters here: with `home` catching every deployed file, a
scope-less `fix:` is never the only honest option, so it is always the wrong one.

**Why `ci`, not `fix`, for a bug in a workflow.** Conventional Commits defines `ci` by subject matter — "changes to CI
configuration files and scripts" — and a workflow *is* one, so `ci` is accurate and the word "fix" belongs in the
subject. `fix` would assert a correction to machine behaviour, which is the false claim. There is no escape hatch:
`fix(internal-workflows)` is rejected.

## Breaking changes

Mark them with **`!` after the type and optional scope** — `feat(pkg-cli)!:`. Nothing here consumes it, so it is
purely a claim, and the claim it is given is *a major version of something installed on a machine changed*. That makes
`git log --grep '!:'` answer "what could have broken my setup", which is the only reason to keep the marker at all.

- **A change you write by hand** — mark it only if a machine needs manual intervention before it works again. The
  non-shipping scopes are **never** breaking.
- **A dependency bump** — the test is the file, not judgement. A major of anything pinned in the deployed mise config,
  its lockfile, or a `.chezmoiscripts/` installer carries `!`; a major of anything else does not. Renovate applies
  this mechanically, so leave its titles alone.

## What Renovate emits, and why it must match

`scope-enum` must accept every scope Renovate can produce. Because the lint is advisory, the failure here is not that
updates stop — they merge anyway, red, and the mislabelled headers pile up unnoticed. That is the quiet failure this
section exists to prevent.

`.github/renovate/commit-taxonomy.json` maps Renovate's output onto the scopes above and is extended **last** so its
rules win. `.github/scripts/check-commit-taxonomy.mjs` asserts that mapping on every PR — run it after touching either
side. It proves every emittable type and scope *literal* is in the enums; it cannot prove which rule wins for a given
dependency, because Renovate resolves that from repo state.

**Re-run it whenever the shared-preset pin moves.** An upstream rule that starts matching a manager this repo uses
reopens the emission-vs-acceptance gap with no local change. `commit-taxonomy.json` is written to be *invariant*
across such a bump; verify that rather than assuming it. The invariants it depends on:

- **Claim every scope locally, even the ones an upstream preset already sets.** Inheriting a scope makes the header
  depend on a matcher this repo does not own; a preset that narrows one drops the dependency to the repo default with
  no local change and no failing check.
- **Claim each scope with no `matchUpdateTypes`,** or the unnamed update types (`replacement`, `rollback`, `bump`) fall
  through to the repo default.
- **Keep the repo-level `semanticCommitScope` non-empty.** The shared preset sets it to `""`, and an empty scope is
  legal here — row 11 uses it — so a dependency no rule matches would emit a scope-less header that passes commitlint,
  passes the taxonomy check, and is still wrong. That is the one drift the enum check cannot see, so it is asserted
  separately.
- **Never assume a type survives.** Restore it locally, keyed on path, rather than relying on an upstream update-type
  mapping reaching the end of the chain.
- **Classify by file, never by package name.** The same tool is internal or shipped depending on which file pins it.
- **An upstream literal header naming a scope this repo lacks must be overridden or disabled** by a local rule
  re-stating the same matcher. The check asserts that rule exists rather than suppressing the literal.

## Cases that would otherwise be guessed

- **A version pin inside an apply script.** The pin bump is `pkg-system`; a change to what the script *does* is
  `bootstrap`. Same file, two scopes, decided by what changed.
- **Root `mise.toml`.** It is chezmoi-ignored and reaches no machine, so anything declared there is
  `internal-dependencies` — not `pkg-cli`, despite being a mise file. The deployed mise config is the shipped one.
- **`.chezmoiignore` and `.chezmoi.toml.tmpl`.** These decide which machine class receives what, so changing them
  changes machines: `bootstrap`, and shipped.
- **A credential.** There is no `secrets` scope; scope it to what the credential serves. The deployed secret templates
  are `home`, the kubeconfig generator is `bootstrap`. `git log -p -S bitwardenSecrets` finds them all.
- **VS Code.** The deployed settings are `home`; the repo's own `.vscode/` is row 11 and reaches no machine.
