import AppKit
import Carbon

let support = FileManager.default.homeDirectoryForCurrentUser
    .appendingPathComponent("Library/Application Support/AirPodsMode")

func log(_ m: String) {
    FileHandle.standardError.write("\(Date()) \(m)\n".data(using: .utf8)!)
}

func run(_ name: String) {
    let url = support.appendingPathComponent(name)
    var error: NSDictionary?
    guard let script = NSAppleScript(contentsOf: url, error: &error) else { log("load \(name): \(error ?? [:])"); return }
    let result = script.executeAndReturnError(&error)
    if let error { log("\(name) failed: \(error)"); NSSound.beep() } else { log("\(name): \(result.stringValue ?? "")") }
}

let app = NSApplication.shared
app.setActivationPolicy(.prohibited)
AXIsProcessTrustedWithOptions([kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary)

if let i = CommandLine.arguments.firstIndex(of: "--run"), i + 1 < CommandLine.arguments.count {
    run(CommandLine.arguments[i + 1]); exit(0)
}

var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
InstallEventHandler(GetApplicationEventTarget(), { _, _, _ in run("toggle.applescript"); return noErr }, 1, &spec, nil, nil)
var ref: EventHotKeyRef?
// Defaults to Cmd + § (the key above Tab). Change with:
//   defaults write local.airpodsmode keyCode -int <code>
//   defaults write local.airpodsmode modifiers -int <Carbon modifier mask>
let prefs = UserDefaults.standard
let keyCode = prefs.object(forKey: "keyCode") as? Int ?? kVK_ISO_Section
let modifiers = prefs.object(forKey: "modifiers") as? Int ?? cmdKey
RegisterEventHotKey(UInt32(keyCode), UInt32(modifiers),
                    EventHotKeyID(signature: OSType(0x414E4354), id: 1), GetApplicationEventTarget(), 0, &ref)
log("started")
app.run()
