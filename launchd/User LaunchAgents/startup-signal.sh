#!/usr/bin/env bash
# startup-signal.sh — launch Signal in tray-mode on macOS

set -eu
LOG="/tmp/startup-signal.sh.log"

echo "[startup-signal] $(date -u +%Y-%m-%dT%H:%M:%SZ) starting" >>"$LOG"

# If Signal is already running, don't start another instance.
# Prefer checking by bundle identifier with `pgrep -f` and a pidfile guard.
if pgrep -f '/Applications/Signal.app/Contents/MacOS/Signal' >/dev/null; then
	echo "[startup-signal] signal already running; skipping launch" >>"$LOG"
	# Update pidfile with an existing Signal PID (first match)
	EXISTING_PID=$(pgrep -f '/Applications/Signal.app/Contents/MacOS/Signal' | head -n1)
	echo "$EXISTING_PID" > /tmp/startup-signal.pid
	exit 0
fi

# Redirect stdio to temp files used for smoke tests
exec >/tmp/startup-signal.stdout 2>/tmp/startup-signal.stderr

# Launch Signal in tray mode and write pid
nohup /Applications/Signal.app/Contents/MacOS/Signal --start-in-tray &
echo $! > /tmp/startup-signal.pid

echo "[startup-signal] launched pid=$(cat /tmp/startup-signal.pid)" >>"$LOG"

exit 0
