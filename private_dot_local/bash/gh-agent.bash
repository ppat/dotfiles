# Agent GitHub App identity (coder workspaces only -- this file is chezmoiignored elsewhere).
#
# Every new shell asks gh-app-env for a short-lived GitHub App installation token and
# exports it as GH_TOKEN, which gh prefers over any stored oauth token and which
# `gh auth git-credential` serves to git for HTTPS pushes. The token is cached and only
# re-minted when it has <10 minutes to live, so this costs a file read per shell.
# gh-app-env prints nothing (and this is a no-op) until the App is configured -- see
# ~/.local/bin/gh-app-env for the fail-soft conditions.
#
# KNOWN FAILURE MODE, deliberate: a single shell or process that lives past the token's
# one-hour expiry starts getting 401s (e.g. `gh run watch` across the boundary). The
# fix is a new shell, which agents get on every command invocation anyway. Do not cache
# longer to "fix" this -- one hour is GitHub's cap on installation tokens.
if command -v gh-app-env > /dev/null 2>&1; then
  eval "$(gh-app-env)"
fi
