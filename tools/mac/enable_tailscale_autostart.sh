#!/bin/bash
# Install Tailscale login-item + LaunchAgent KeepAlive + unattended mode.
# Run ONCE on the Mac as vladmann. Does not print or store keys.
set -euo pipefail
USER_NAME="$(id -un)"
UID_NUM="$(id -u)"
HOME_DIR="$(eval echo "~$USER_NAME")"
APP="/Applications/Tailscale.app"
SUPPORT="$HOME_DIR/Library/Application Support/naeon"
AGENTS="$HOME_DIR/Library/LaunchAgents"
LABEL="com.naeon.tailscale.autostart"
HERE="$(cd "$(dirname "$0")" && pwd)"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This installer is macOS-only (run on macbook-pro-vlad)." >&2
  exit 1
fi
if [[ ! -d "$APP" ]]; then
  echo "Install Tailscale.app into /Applications first: https://tailscale.com/download/mac" >&2
  exit 1
fi

mkdir -p "$SUPPORT" "$AGENTS" "$HOME_DIR/Library/Logs"
cp "$HERE/tailscale_keepalive.sh" "$SUPPORT/tailscale_keepalive.sh"
chmod 755 "$SUPPORT/tailscale_keepalive.sh"
# Plist uses a fixed vladmann path; rewrite if this user differs.
sed "s|/Users/vladmann|$HOME_DIR|g" "$HERE/com.naeon.tailscale.autostart.plist" > "$AGENTS/${LABEL}.plist"

# Login item (GUI session)
osascript >/dev/null 2>&1 <<OSA || true
tell application "System Events"
  if not (exists login item "Tailscale") then
    make login item at end with properties {path:"$APP", hidden:true, name:"Tailscale"}
  end if
end tell
OSA

# Unattended now (survives logout)
TS=""
if command -v tailscale >/dev/null 2>&1; then
  TS="$(command -v tailscale)"
elif [[ -x "$APP/Contents/MacOS/Tailscale" ]]; then
  TS="$APP/Contents/MacOS/Tailscale"
fi
open -a Tailscale || true
sleep 2
if [[ -n "$TS" ]]; then
  "$TS" set --unattended || true
  "$TS" up || true
fi

# launchd (modern bootstrap)
if launchctl print "gui/${UID_NUM}/${LABEL}" >/dev/null 2>&1; then
  launchctl bootout "gui/${UID_NUM}" "$AGENTS/${LABEL}.plist" 2>/dev/null || true
fi
launchctl bootstrap "gui/${UID_NUM}" "$AGENTS/${LABEL}.plist"
launchctl enable "gui/${UID_NUM}/${LABEL}"
launchctl kickstart -k "gui/${UID_NUM}/${LABEL}"

echo "Tailscale autostart installed for $USER_NAME"
echo "  login item: Tailscale.app"
echo "  LaunchAgent: $AGENTS/${LABEL}.plist"
echo "  keepalive: $SUPPORT/tailscale_keepalive.sh"
if [[ -n "$TS" ]]; then
  echo "  status:"
  "$TS" status || true
fi
