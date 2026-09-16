#!/usr/bin/env bash
set -euo pipefail

# UserPromptSubmit hook: re-inject the handles of the reply rules from the global CLAUDE.md
# (Talking to the user, The target form for prose) on every main-session turn. The file states
# the rules in full. This only supplies recency, which a file at the head of context cannot.
# Silent inside subagents, whose output goes to files and to the orchestrator, not to the user.
# It adds context and never blocks a prompt.

command -v jq >/dev/null 2>&1 || exit 0

input=$(cat)
if printf '%s' "$input" | jq -e 'has("agent_id")' >/dev/null 2>&1; then
  exit 0
fi

jq -n --arg ctx 'Reply contract (Talking to the user, The target form for prose, in ~/.claude/CLAUDE.md):
- Verdict first. The first line of every reply answers the question or states the bottom line, labeled active problem, latent condition, or FYI.
- 35k ft view. Invariants, implications, recommendations in priority order. Detail lives in session notes.
- Decompress first. No coined shorthand. Anchored references. Format persistence.
- Prose form. Plain English, no invented terms, no em dashes, no colons or semicolons inside a sentence, no filler adjectives, no drone register. Fidelity over brevity.
Compliance is judged on the reply text itself, never on stating the rule.' \
  '{"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":$ctx}}'
