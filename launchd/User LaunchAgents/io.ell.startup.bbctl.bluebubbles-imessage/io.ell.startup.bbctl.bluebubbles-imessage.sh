#!/usr/bin/env bash
set -euo pipefail

# Prepare state directory
mkdir -p "$HOME/.local/state/bbctl"

# Upgrade/install tooling (non-fatal if offline)
"$(dirname "$0")/install-bbctl.sh" --upgrade || true

# Diagnostics (ignore failures)
bbctl whoami || true
printf '\nStarting bridge: sh-imessage\n'

# Exec the bridge (replaces shell)
exec bbctl run --no-override-config sh-imessage
