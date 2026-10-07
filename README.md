# AirPods Mode

One key press to switch AirPods between Transparency and Noise Cancellation on macOS 27. Tested with AirPods Max 2.

**Default hotkey: Cmd+§** (the key above Tab on a Swedish keyboard).

## How it works

macOS 27 blocks the private Bluetooth API (`setListeningMode:`) and hides Apple's menu bar items from System Events. The Sound menu extra still shows up through the Accessibility API, under `com.apple.MenuBarAgent`'s `AXExtrasMenuBar`. So on each hotkey press, the helper:

1. opens the Sound menu,
2. clicks the other mode in the AirPods' *Listening Mode* section,
3. closes the menu.

- `Sources/main.swift` is a background app with no Dock icon. It registers the hotkey and runs `toggle.applescript`, which calls the helper.
- `Sources/toggle.swift` is the helper that clicks the menu. It inherits the app's Accessibility permission, so you can rebuild it without granting permission again.

## Install

```sh
./install.sh
```

Then turn on **AirPods Mode** in System Settings → Privacy & Security → Accessibility. The app starts at login.

Every rebuild of the app invalidates the Accessibility approval, because the app is ad-hoc signed. If the hotkey stops working after a reinstall, remove AirPods Mode from the Accessibility list with **−** and add it again.

## Change the hotkey

You don't need to rebuild:

```sh
defaults write local.airpodsmode keyCode -int 10      # virtual key code (10 = §)
defaults write local.airpodsmode modifiers -int 256   # Carbon mask: cmd 256, shift 512, option 2048, control 4096
launchctl kickstart -k gui/$(id -u)/local.airpodsmode
```

## Pick a mode

```sh
"~/Library/Application Support/AirPodsMode/toggle" Adaptive   # or Off / Transparency / "Noise Cancellation"
```

Run this through the app, not straight from a terminal, unless the terminal has Accessibility permission.

## Uninstall

```sh
./uninstall.sh
```

The log is at `/tmp/airpodsmode.log`.
