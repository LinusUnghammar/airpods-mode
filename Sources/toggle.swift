import AppKit
import ApplicationServices

func attr(_ e: AXUIElement, _ a: String) -> AnyObject? { var v: AnyObject?; AXUIElementCopyAttributeValue(e, a as CFString, &v); return v }
func kids(_ e: AXUIElement) -> [AXUIElement] { (attr(e, "AXChildren") as? [AXUIElement]) ?? [] }
func flatten(_ e: AXUIElement, _ d: Int = 0) -> [AXUIElement] { d > 8 ? [] : [e] + kids(e).flatMap { flatten($0, d + 1) } }
func press(_ e: AXUIElement) { AXUIElementPerformAction(e, kAXPressAction as CFString) }
func role(_ e: AXUIElement) -> String { attr(e, "AXRole") as? String ?? "" }
func label(_ e: AXUIElement) -> String { attr(e, "AXDescription") as? String ?? "" }
func id(_ e: AXUIElement) -> String { attr(e, "AXIdentifier") as? String ?? "" }
func fail(_ m: String) -> Never { print(m); exit(1) }

func app(_ bid: String) -> AXUIElement {
    guard let p = NSRunningApplication.runningApplications(withBundleIdentifier: bid).first else { fail("\(bid) not running") }
    return AXUIElementCreateApplication(p.processIdentifier)
}

func waitFor<T>(_ f: () -> T?) -> T? {
    for _ in 0..<30 { if let v = f() { return v }; Thread.sleep(forTimeInterval: 0.05) }
    return nil
}

guard AXIsProcessTrusted() else { fail("AirPods Mode needs Accessibility permission") }
let bar = attr(app("com.apple.MenuBarAgent"), "AXExtrasMenuBar") as! AXUIElement
guard let sound = flatten(bar).first(where: { id($0) == "com.apple.menuextra.sound" }) else { fail("no sound menu") }
let cc = app("com.apple.controlcenter")
let soundOpen = { (attr(cc, "AXWindows") as? [AXUIElement] ?? []).first { w in flatten(w).contains { id($0) == "controlcenter-volume-slider" } } }

press(sound)
defer { if soundOpen() != nil { press(sound) } }
guard let window = waitFor(soundOpen) else { fail("sound menu did not open") }

func listeningModes() -> [AXUIElement] {
    var inSection = false, modes: [AXUIElement] = []
    for e in flatten(window) where id(e).contains("AirPods") {
        if role(e) == "AXHeading" { inSection = label(e) == "Listening Mode"; continue }
        if inSection && role(e) == "AXCheckBox" { modes.append(e) }
    }
    return modes
}

if listeningModes().isEmpty, let triangle = flatten(window).first(where: { role($0) == "AXDisclosureTriangle" && id($0).contains("AirPods") }) {
    press(triangle)
}
guard let modes = waitFor({ let m = listeningModes(); return m.isEmpty ? nil : m }) else { fail("no AirPods listening modes (are they the sound output?)") }

if CommandLine.arguments.dropFirst().first == "--status" { print("status:", modes.first { (attr($0, "AXValue") as? Int) == 1 }.map(label) ?? "?"); exit(0) }
let wanted = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : nil
let current = modes.first { (attr($0, "AXValue") as? Int) == 1 }.map(label)
let target = wanted ?? (current == "Transparency" ? "Noise Cancellation" : "Transparency")
guard let button = modes.first(where: { label($0) == target }) else { fail("no \(target) option; have \(modes.map(label))") }
press(button)
let confirmed = waitFor { listeningModes().first { (attr($0, "AXValue") as? Int) == 1 && label($0) == target } } != nil
print("\(current ?? "?") -> \(target) confirmed=\(confirmed)")
