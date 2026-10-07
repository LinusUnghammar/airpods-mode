#!/bin/bash
set -uo pipefail
LABEL="local.airpodsmode"
launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null
rm -rf "$HOME/Applications/AirPods Mode.app" "$HOME/Library/Application Support/AirPodsMode" \
       "$HOME/Library/LaunchAgents/$LABEL.plist"
tccutil reset Accessibility "$LABEL" >/dev/null 2>&1
defaults delete "$LABEL" 2>/dev/null
echo "Uninstalled."
