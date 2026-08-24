#!/usr/bin/env node
// Assert that every commit header Renovate can emit is one commitlint.config.js accepts.
//
// Emission (Renovate) and acceptance (commitlint) are separate systems that drift silently, and in
// this repo nothing downstream stops the drift: the commit-message lint is deliberately advisory
// (see .claude/rules/commits.md), so an off-enum scope produces a red check that still merges and
// then accumulates. That makes this check the only thing standing between a preset bump and months
// of quietly mislabelled history -- it is load-bearing here in a way it would not be in a repo whose
// lint is a required context.
//
// WHAT THIS PROVES, precisely: every type and scope *literal* reachable from the Renovate config
// this repo pins -- its own files plus the ppat/renovate-presets files it extends, read at the
// pinned tag -- is in the commitlint enums or is provably overridden here, and the breaking-marker
// templates still match the upstream shape they were derived from.
//
// WHAT IT DOES NOT PROVE: which rule wins for a given dependency. Renovate resolves that from repo
// state -- which files a manager finds, which of them end up in one branch -- and no static reading
// closes it. That half is covered by the required merge-time commit lint, which gates whatever the
// open mechanism actually produced. Built-in presets (`:ignoreModulesAndTests`, `docker:pinDigests`,
// the `mergeConfidence:*` pair) and third-party ones are NOT read; they are listed as uncovered in
// the output so the gap stays visible instead of being assumed away.

import { readFileSync } from 'node:fs'
import { createRequire } from 'node:module'

const require = createRequire(import.meta.url)
const fail = []
const note = []

const commitlint = require(`${process.cwd()}/commitlint.config.js`)
const TYPES = commitlint.rules['type-enum'][2]
const SCOPES = commitlint.rules['scope-enum'][2]

const readLocal = (p) => JSON.parse(readFileSync(p, 'utf8'))
const root = readLocal('.github/renovate.json')

// A prefix built from handlebars over semanticCommitType/Scope carries no literal of its own -- what
// it renders is the semanticCommit* values collected separately. A prefix that is a whole literal
// header (the kubernetes preset's `feat(kubernetes-api)!:`) does carry one, and must be checked.
const PASSTHROUGH = /^\{\{semanticCommitType\}\}\{\{#if semanticCommitScope\}\}\(\{\{semanticCommitScope\}\}\)\{\{\/if\}\}!?:$/
const LITERAL_HEADER = /^([a-z]+)(?:\(([^)]*)\))?!?:$/

// Resolve every `extends` entry to something readable, or record it as uncovered.
const sources = [{ name: '.github/renovate.json', config: root, local: true }]
const uncovered = []

for (const ref of root.extends ?? []) {
  const shared = ref.match(/^github>ppat\/renovate-presets(?::([\w-]+))?#(.+)$/)
  const own = ref.match(/^github>ppat\/dotfiles\/\/(.+)$/)

  if (shared) {
    const [, name = 'default', tag] = shared
    const url = `https://raw.githubusercontent.com/ppat/renovate-presets/${tag}/${name}.json`
    const res = await fetch(url)
    if (!res.ok) {
      fail.push(`cannot read extended preset ${ref} (${url} -> HTTP ${res.status})`)
      continue
    }
    sources.push({ name: ref, config: JSON.parse(await res.text()), local: false })
  } else if (own) {
    sources.push({ name: ref, config: readLocal(`${own[1]}.json`), local: true })
  } else {
    uncovered.push(ref)
  }
}

// Collect every site that can place a type or scope into a header, by walking for the key names
// rather than hand-listing the rules that use them today. A hand-written site list is the same
// failure mode this check exists to catch, one level up.
const HEADER_KEYS = ['semanticCommitType', 'semanticCommitScope', 'commitMessagePrefix']
const sites = []

const matcherSignature = (rule) =>
  JSON.stringify(Object.keys(rule).filter((k) => k.startsWith('match')).sort().map((k) => [k, rule[k]]))

const walk = (node, ctx, path) => {
  if (Array.isArray(node)) return node.forEach((v, i) => walk(v, ctx, `${path}[${i}]`))
  if (!node || typeof node !== 'object') return
  // A packageRules entry is the unit Renovate overrides, so remember its matcher for anything found
  // beneath it -- that is what lets an off-enum upstream literal be proven overridden below.
  const rule = Object.keys(node).some((k) => k.startsWith('match')) ? matcherSignature(node) : ctx.rule
  for (const [key, value] of Object.entries(node)) {
    if (HEADER_KEYS.includes(key) && typeof value === 'string') {
      sites.push({ ...ctx, rule, path: `${path}.${key}`, key, value })
    }
    walk(value, { ...ctx, rule }, `${path}.${key}`)
  }
}
for (const { name, config, local } of sources) walk(config, { source: name, local, rule: null }, name)

// Literals this repo supplies itself, indexed by the matcher they attach to. An upstream literal
// whose matcher is re-stated locally with an acceptable header is overridden, not emitted.
const localOverrides = new Map()
for (const site of sites) {
  if (site.local && site.key === 'commitMessagePrefix' && site.rule) localOverrides.set(site.rule, site)
}

// A matcher this repo turns off emits nothing at all, so an upstream literal attached to it is
// neutralised rather than overridden. Tracked separately from the override map so that deleting the
// `enabled: false` rule re-fails here instead of silently re-arming the upstream header.
const locallyDisabled = new Set()
for (const { name, config, local } of sources) {
  if (!local) continue
  for (const rule of config.packageRules ?? []) {
    if (rule.enabled === false) locallyDisabled.add(matcherSignature(rule))
  }
}

const checkHeaderLiteral = (value, site) => {
  const m = value.match(LITERAL_HEADER)
  if (!m) {
    fail.push(`commitMessagePrefix '${value}' at ${site.path} is neither the pass-through template nor a literal header -- cannot be checked`)
    return false
  }
  const [, type, scope = ''] = m
  const bad = []
  if (!TYPES.includes(type)) bad.push(`type '${type}'`)
  if (!SCOPES.includes(scope)) bad.push(`scope '${scope}'`)
  return bad.length ? bad : true
}

for (const site of sites) {
  if (site.key === 'semanticCommitType') {
    if (!TYPES.includes(site.value)) fail.push(`type '${site.value}' emitted at ${site.path} is not in type-enum`)
    continue
  }
  if (site.key === 'semanticCommitScope') {
    if (!SCOPES.includes(site.value)) fail.push(`scope '${site.value}' emitted at ${site.path} is not in scope-enum`)
    continue
  }
  if (PASSTHROUGH.test(site.value)) continue

  const verdict = checkHeaderLiteral(site.value, site)
  if (verdict === true || verdict === false) continue

  // Off-enum literal. Acceptable only if this repo re-states the same matcher with a header it does
  // accept -- an assertion, so deleting the override or an upstream matcher change re-fails here.
  if (!site.local && locallyDisabled.has(site.rule)) {
    note.push(`upstream literal '${site.value}' (${site.source}) is unreachable -- its matcher is disabled locally`)
    continue
  }
  const override = localOverrides.get(site.rule)
  if (site.local || !override || checkHeaderLiteral(override.value, override) !== true) {
    fail.push(`${verdict.join(' and ')} from literal prefix at ${site.path} not in enum, and no local rule overrides or disables that matcher`)
  } else {
    note.push(`upstream literal '${site.value}' (${site.source}) is overridden locally by '${override.value}'`)
  }
}

// The scope a dependency gets when NO packageRule names it. This is the one drift the enum check
// above cannot see: the inherited default is the empty string, which is a legal scope here because
// humans use it for repo-level docs -- so a manager that no rule matches emits a scope-less header
// that passes commitlint, passes this file's enum check, and is wrong. Assert the repo overrides it.
//
// Effective value is the repo's own top-level setting if it has one, else the last extended preset
// that sets one, which is the order Renovate resolves them in.
const topLevelDefaults = sites.filter((s) => s.key === 'semanticCommitScope' && !s.rule)
const ownDefault = topLevelDefaults.find((s) => s.source === '.github/renovate.json')
const effectiveDefault = ownDefault ?? topLevelDefaults[topLevelDefaults.length - 1]
if (!effectiveDefault) {
  fail.push('no top-level semanticCommitScope found in any source -- cannot tell what an unmatched dependency emits')
} else if (!effectiveDefault.value) {
  fail.push(
    `the effective default scope is empty (set at ${effectiveDefault.path}), so a dependency no packageRule ` +
    'matches emits a scope-less header that every other check accepts -- override it locally'
  )
} else {
  note.push(`unmatched dependencies fall through to '${effectiveDefault.value}' (${effectiveDefault.source})`)
}

// The two breaking-marker rules in commit-taxonomy.json are derived from the upstream major rule:
// one strips its '!', the other restores it. If a preset bump changes the upstream template shape
// those two stop describing the same header and the derivation is silently wrong -- catch that here
// rather than on the next major bump.
const passthrough = sites.filter((s) => s.key === 'commitMessagePrefix' && PASSTHROUGH.test(s.value)).map((s) => s.value)
const stripped = passthrough.filter((v) => !v.includes('!'))
const marked = passthrough.filter((v) => v.includes('!'))
if (!stripped.length || !marked.length) {
  fail.push('expected both a marker-stripping and a marker-restoring pass-through prefix; the upstream template shape has changed')
} else if (!marked.every((v) => v.replace('!:', ':') === stripped[0])) {
  fail.push('the marker-restoring prefix is no longer the marker-stripping one plus "!" -- re-derive both from the upstream major rule')
}

note.unshift(`checked ${sites.length} header-producing sites across ${sources.length} config sources`)
note.push(`types accepted: ${TYPES.join(', ')}`)
note.push(`scopes accepted: ${SCOPES.map((s) => s || "''").join(', ')}`)
note.push(`NOT read (built-in or third-party presets, assumed to set no header fields): ${uncovered.join(', ') || 'none'}`)

for (const n of note) console.log(`  ${n}`)
if (fail.length) {
  console.error('\ncommit taxonomy check FAILED:')
  for (const f of fail) console.error(`  - ${f}`)
  process.exit(1)
}
console.log('\ncommit taxonomy check passed: every emittable type and scope literal is in the enum')
