# The Coder workspace memory watchdog (coder repo: script-memory-watchdog.sh) stamps a soft
# RLIMIT_DATA on the VS Code server tree via prlimit to keep it from re-approaching the
# container's memory.max. Terminals forked from ptyHost inherit that soft limit. The watchdog
# deliberately leaves the hard limit at "unlimited" specifically so a shell can restore itself --
# do that here, every time an interactive shell starts, rather than requiring the operator to
# notice and fix it by hand.
ulimit -d unlimited 2>/dev/null || true
