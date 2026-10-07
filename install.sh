#!/bin/bash
# Builds AirPods Mode and installs it as a login item.
set -euo pipefail
cd "$(dirname "$0")"

APP="$HOME/Applications/AirPods Mode.app"
SUP="$HOME/Library/Application Support/AirPodsMode"
AGENT="$HOME/Library/LaunchAgents/local.airpodsmode.plist"
LABEL="local.airpodsmode"

mkdir -p "$APP/Contents/MacOS" "$SUP" "$(dirname "$AGENT")"
swiftc -O Sources/main.swift -o "$APP/Contents/MacOS/AirPodsMode"
swiftc -O Sources/toggle.swift -o "$SUP/toggle"

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleIdentifier</key><string>$LABEL</string>
<key>CFBundleName</key><string>AirPods Mode</string>
<key>CFBundleExecutable</key><string>AirPodsMode</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>LSUIElement</key><true/>
<key>NSAppleEventsUsageDescription</key><string>Clicks the AirPods listening mode in Control Center.</string>
</dict></plist>
PLIST
codesign -s - --force "$APP"

cat > "$SUP/toggle.applescript" <<SCRIPT
return do shell script quoted form of "$SUP/toggle" & " 2>&1"
SCRIPT

cat > "$AGENT" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>Label</key><string>$LABEL</string>
<key>ProgramArguments</key><array><string>$APP/Contents/MacOS/AirPodsMode</string></array>
<key>RunAtLoad</key><true/>
<key>KeepAlive</key><true/>
<key>StandardErrorPath</key><string>/tmp/airpodsmode.log</string>
</dict></plist>
PLIST

launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$AGENT"
tccutil reset Accessibility "$LABEL" >/dev/null 2>&1 || true

echo "Installed. Turn on AirPods Mode in System Settings → Privacy & Security → Accessibility."
open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
