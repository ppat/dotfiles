// Commit header taxonomy for this repo. See .claude/rules/commits.md for the decision procedure
// (which scope a given diff takes); this file is only the enforcement of it.
//
// Why these rules exist at all: this repo has no release layer -- no tags, no releases, nothing
// parses a commit header. `main` IS the release and `chezmoi apply` is the delivery. So the header
// is a *claim about the diff*, and the one claim worth keeping true is: did this change reach a
// machine? The checks are advisory by design (see the rule document); the audience is the agents
// and humans writing commit messages, not a merge gate.
//
// The scope vocabulary is shared with the sibling repos and means the same thing in each --
// `agents`, `github-actions`, `internal-dependencies`, `internal-workflows` and `renovate` are
// lifted from ppat/github-workflows and ppat/homelab-ops-kubernetes-apps, and the shared Renovate
// presets emit two of them.
//
// Runs via ppat/github-workflows/.github/workflows/lint-commit-messages.yaml, which installs its
// own package.json when this repo has no bun.lock -- that is where @commitlint/cli,
// @commitlint/config-conventional and commitlint-plugin-function-rules come from. Adding a
// bun.lock here means vendoring those three as well.

// Scopes naming something chezmoi delivers to a machine. There are exactly three ways that happens,
// which is why there are exactly these scopes: a package manager installs software (pkg-*), an
// apply-time script does something (bootstrap), or a file is written into $HOME (home). Named
// surfaces below that -- a `vscode`, a `kube`, a `shell` -- were tried and dropped: they grouped
// whichever directories happened to hold more than one file, and left glow, battery-notifier and
// the LaunchAgents with nowhere to go.
const SHIPPED_SCOPES = [
  'bootstrap',
  'home',
  'pkg-cli',
  'pkg-lang',
  'pkg-system',
]

// Scopes naming surfaces that reach no machine. `agents` is internal in every repo that has it, and
// uniformly so here despite this repo *deploying* an agent's configuration: an instruction file
// steers an agent, not the machine it sits on. That is what keeps it off both sides of the boundary.
const INTERNAL_SCOPES = [
  'agents',
  'github-actions',
  'internal-dependencies',
  'internal-workflows',
  'renovate',
]

// Types asserting that behaviour on a machine changed.
const SHIPPED_BEHAVIOUR_TYPES = ['feat', 'fix', 'perf', 'refactor']

// A type claiming machine behaviour may only sit on a scope that can carry the claim. The empty
// scope cannot: with `home` catching every deployed file, a scope-less `fix:` is never the only
// honest option, so it is always the wrong one.
const validateTypeScopePairing = (parsedCommit) => {
  const { type, scope } = parsedCommit
  if (!SHIPPED_BEHAVIOUR_TYPES.includes(type)) return [true]

  return [
    SHIPPED_SCOPES.includes(scope),
    `type '${type}' asserts a change to machine behaviour and cannot sit on scope '${scope || '(empty)'}', ` +
    `which never reaches a machine -- use chore, ci or docs, or name what was delivered: ` +
    `${SHIPPED_SCOPES.join(', ')} (see .claude/rules/commits.md)`,
  ]
}

// The mirror, and just as load-bearing: `ci` and `test` describe this repo's own machinery, so
// pairing either with a delivered scope asserts CI work on something that was installed.
const validateMachineryTypeScopePairing = (parsedCommit) => {
  const { type, scope } = parsedCommit
  if (!['ci', 'test'].includes(type)) return [true]

  return [
    !scope || INTERNAL_SCOPES.includes(scope),
    `type '${type}' describes this repo's own machinery and cannot sit on scope '${scope}', which names ` +
    `something delivered to a machine -- use an internal scope or none: ${INTERNAL_SCOPES.join(', ')} ` +
    `(see .claude/rules/commits.md)`,
  ]
}

module.exports = {
  extends: ['@commitlint/config-conventional'],
  plugins: ['commitlint-plugin-function-rules'],
  rules: {
    // Renovate composes headers from depName plus a version range, and GitHub appends " (#NNN)" on
    // squash; 100 is too tight for e.g.
    // "feat(pkg-cli)!: update aqua:kubernetes-sigs/kustomize (5.8.1 -> 6.0.0) (#1234)".
    'header-max-length': [2, 'always', 120],

    // Renovate pastes upstream release notes into the PR body, and squash_merge_commit_message is
    // COMMIT_MESSAGES, so markdown tables and links land in the body and cannot be rewrapped
    // without corrupting them.
    'body-max-line-length': [0],
    'footer-max-line-length': [0],

    // Restricts the set @commitlint/config-conventional allows. Dropped: 'build' (no build system
    // here) and 'style' (redundant with refactor/chore). 'revert' is kept despite going unused: its
    // meaning is fixed, the parser special-cases it, and it is the one type you cannot improvise
    // mid-incident.
    //
    // 'ci' and 'test' split this repo's CI by what a workflow is *for*: full-apply-test.yaml
    // exercises the deliverable end to end, so editing it is `test(internal-workflows)`; lint.yaml,
    // commit-lint.yaml and renovate.yaml automate the repo, so they are `ci(internal-workflows)`.
    // Both stay out of `fix`, which would assert a correction to machine behaviour -- the word
    // "fix" belongs in the subject, not the type.
    'type-enum': [2, 'always', [
      'chore',
      'ci',
      'docs',
      'feat',
      'fix',
      'perf',
      'refactor',
      'revert',
      'test',
    ]],

    // '' is reachable: repo-level documentation or policy belonging to no single surface. It is the
    // last row of the decision table in .claude/rules/commits.md, not a default.
    'scope-enum': [2, 'always', ['', ...SHIPPED_SCOPES, ...INTERNAL_SCOPES]],

    'function-rules/scope-enum': [2, 'always', validateTypeScopePairing],
    'function-rules/type-enum': [2, 'always', validateMachineryTypeScopePairing],

    // Renovate lowercases subjects and hand-written subjects follow; config-conventional's default
    // subject-case rule already forbids sentence/start/pascal/upper case, which is what we want.
    'body-case': [0, 'always'],
  },
}
