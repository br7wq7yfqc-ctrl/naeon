#!/bin/bash
# Keep Tailscale.app up and unattended so SSH over 100.101.32.21 survives reboot/logout.
set -u
APP="/Applications/Tailscale.app"
LOG="${HOME}/Library/Logs/naeon-tailscale-autostart.log"
mkdir -p "$(dirname "$LOG")"
log() { echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) $*" >>"$LOG"; }

if [[ ! -d "$APP" ]]; then
  log "ERROR: Tailscale.app not in /Applications"
  exit 1
fi

if ! pgrep -x Tailscale >/dev/null 2>&1; then
  open -a Tailscale
  log "opened Tailscale.app"
  sleep 3
fi

TS=""
if command -v tailscale >/dev/null 2>&1; then
  TS="$(command -v tailscale)"
elif [[ -x "$APP/Contents/MacOS/Tailscale" ]]; then
  TS="$APP/Contents/MacOS/Tailscale"
fi

if [[ -n "$TS" ]]; then
  "$TS" set --unattended >>"$LOG" 2>&1 || log "warn: set --unattended failed"
  "$TS" up >>"$LOG" 2>&1 || log "warn: tailscale up failed"
  "$TS" status >>"$LOG" 2>&1 || true
fi

# Block while GUI is alive; KeepAlive relaunches if it dies.
while pgrep -x Tailscale >/dev/null 2>&1; do
  sleep 20
done
log "Tailscale.app exited; KeepAlive will relaunch"
exit 1
