// SPDX-License-Identifier: Apache-2.0
// wfe-axhelper: the macOS trust lane's hands on the app (drivers/macos/ax.py).
//
// `wfe-axhelper serve <socket>` runs in a terminal pane in the user's GUI session (gui/<uid>), started by the
// lane (macos_platform.py) as a plain child of the pane's shell, never through open or launchd: the
// Accessibility permission it uses is the one that session already has. It answers one JSON request per
// connection on a Unix socket in the lane folder.
// `wfe-axhelper call <socket>` is the client: one JSON line on stdin, the answer on stdout. The lane on
// the build host runs it over ssh, so a typed secret only travels on stdin and is never logged here.
//
// Ops: ping, tree, press, focus, type, keys, wheel, setvalue, shot, alive, activate, windows, cgwin, probe.
// A tree is the app's windows read through AXUIElement after AXEnhancedUserInterface is set on the app (Flutter turns its
// Semantics on for it). Raw attributes come back; drivers/macos/ax.py maps roles and names. Nothing
// here asks for a permission: without Accessibility every op answers trusted=false.
import AppKit
import ApplicationServices
import Foundation

let maxNodes = 4000
let maxDepth = 80

func attr(_ el: AXUIElement, _ name: String) -> AnyObject? {
    var v: CFTypeRef?
    let err = AXUIElementCopyAttributeValue(el, name as CFString, &v)
    if err == .cannotComplete { lastHung = true }
    return err == .success ? (v as AnyObject?) : nil
}

var lastHung = false

func str(_ v: AnyObject?) -> String? {
    guard let v = v else { return nil }
    if let s = v as? String { return s }
    if let n = v as? NSNumber { return n.stringValue }
    if let a = v as? NSAttributedString { return a.string }
    return nil
}

func frame(_ el: AXUIElement) -> [Double] {
    var p = CGPoint.zero, s = CGSize.zero
    if let pv = attr(el, kAXPositionAttribute) { AXValueGetValue(pv as! AXValue, .cgPoint, &p) } else { return [] }
    if let sv = attr(el, kAXSizeAttribute) { AXValueGetValue(sv as! AXValue, .cgSize, &s) } else { return [] }
    return [Double(p.x), Double(p.y), Double(s.width), Double(s.height)]
}

func children(_ el: AXUIElement) -> [AXUIElement] {
    return (attr(el, kAXChildrenAttribute) as? [AXUIElement]) ?? []
}

func actions(_ el: AXUIElement) -> [String] {
    var names: CFArray?
    guard AXUIElementCopyActionNames(el, &names) == .success, let a = names as? [String] else { return [] }
    return a
}

func appElement(_ pid: pid_t) -> AXUIElement {
    let app = AXUIElementCreateApplication(pid)
    AXUIElementSetMessagingTimeout(app, 10)
    // Flutter's macOS engine builds its accessibility tree when an assistive app sets this.
    AXUIElementSetAttributeValue(app, "AXEnhancedUserInterface" as CFString, kCFBooleanTrue)
    AXUIElementSetAttributeValue(app, "AXManualAccessibility" as CFString, kCFBooleanTrue)
    return app
}

func windows(_ app: AXUIElement) -> [AXUIElement] {
    return (attr(app, kAXWindowsAttribute) as? [AXUIElement]) ?? []
}

func describe(_ el: AXUIElement, _ path: [Int]) -> [String: Any] {
    var d: [String: Any] = ["path": path]
    d["role"] = str(attr(el, kAXRoleAttribute)) ?? ""
    if let s = str(attr(el, kAXSubroleAttribute)) { d["sub"] = s }
    if let s = str(attr(el, kAXTitleAttribute)), !s.isEmpty { d["title"] = s }
    if let s = str(attr(el, kAXDescriptionAttribute)), !s.isEmpty { d["desc"] = s }
    if let s = str(attr(el, kAXHelpAttribute)), !s.isEmpty { d["help"] = s }
    if let s = str(attr(el, kAXValueAttribute)) { d["value"] = s }
    if let s = str(attr(el, kAXPlaceholderValueAttribute)), !s.isEmpty { d["placeholder"] = s }
    if let e = attr(el, kAXEnabledAttribute) as? Bool { d["enabled"] = e }
    if let f = attr(el, kAXFocusedAttribute) as? Bool, f { d["focused"] = true }
    if let s = attr(el, kAXSelectedAttribute) as? Bool, s { d["selected"] = true }
    let fr = frame(el)
    if !fr.isEmpty { d["frame"] = fr }
    let a = actions(el)
    if !a.isEmpty { d["actions"] = a }
    return d
}

// Each element once: a window's children can lead back to the app element (and through it to the menu bar),
// which read as nested copies of the app until maxDepth. The app element and the menu bar are not walked.
let skipRoles: Set<String> = ["AXApplication", "AXMenuBar", "AXMenuBarItem"]

func walk(_ app: AXUIElement) -> [[String: Any]] {
    var out: [[String: Any]] = []
    var seen: [CFHashCode: [AXUIElement]] = [:]
    func first(_ el: AXUIElement) -> Bool {
        let h = CFHash(el)
        if let same = seen[h], same.contains(where: { CFEqual($0, el) }) { return false }
        seen[h, default: []].append(el)
        return true
    }
    _ = first(app)
    func go(_ el: AXUIElement, _ path: [Int]) {
        if out.count >= maxNodes || path.count > maxDepth || !first(el) { return }
        if path.count > 1, let r = str(attr(el, kAXRoleAttribute)), skipRoles.contains(r) { return }
        out.append(describe(el, path))
        for (k, c) in children(el).enumerated() { go(c, path + [k]) }
    }
    for (w, win) in windows(app).enumerated() { go(win, [w]) }
    return out
}

func resolve(_ app: AXUIElement, _ path: [Int]) -> AXUIElement? {
    let ws = windows(app)
    guard let first = path.first, first < ws.count else { return nil }
    var el = ws[first]
    for k in path.dropFirst() {
        let cs = children(el)
        guard k < cs.count else { return nil }
        el = cs[k]
    }
    return el
}

// The node at `path` when it is still the one the driver read (same role and the same title/value/desc).
func target(_ req: [String: Any]) -> (AXUIElement?, String?) {
    guard let pid = req["pid"] as? Int, let path = req["path"] as? [Int] else { return (nil, "pid and path wanted") }
    guard let el = resolve(appElement(pid_t(pid)), path) else { return (nil, "different node: the path is gone") }
    if let want = req["key"] as? String {
        let d = describe(el, path)
        let have = [d["role"], d["title"], d["value"], d["desc"]].map { ($0 as? String) ?? "" }.joined(separator: "\u{1}")
        if have != want && !(req["loose"] as? Bool ?? false) { return (nil, "different node at the path") }
    }
    return (el, nil)
}

func activate(_ pid: Int) {
    NSRunningApplication(processIdentifier: pid_t(pid))?.activate(options: [])
}

func postKey(_ pid: pid_t, _ code: CGKeyCode, _ flags: CGEventFlags = []) {
    let src = CGEventSource(stateID: .hidSystemState)
    for down in [true, false] {
        guard let e = CGEvent(keyboardEventSource: src, virtualKey: code, keyDown: down) else { continue }
        e.flags = flags
        e.postToPid(pid)
        usleep(12000)
    }
}

func postText(_ pid: pid_t, _ text: String) {
    let src = CGEventSource(stateID: .hidSystemState)
    for ch in text {
        let u = Array(String(ch).utf16)
        for down in [true, false] {
            guard let e = CGEvent(keyboardEventSource: src, virtualKey: 0, keyDown: down) else { continue }
            e.keyboardSetUnicodeString(stringLength: u.count, unicodeString: u)
            e.postToPid(pid)
            usleep(8000)
        }
    }
}

let KEYS: [String: (CGKeyCode, CGEventFlags)] = [
    "escape": (53, []), "back": (53, []), "enter": (36, []), "tab": (48, []), "shift_tab": (48, .maskShift),
    "page_down": (121, []), "page_up": (116, []), "space": (49, []), "end": (119, []), "home": (115, []),
    "delete": (51, []), "select_all": (0, .maskCommand), "ctrl_enter": (36, .maskCommand),
    "shift": (56, []), "quit": (12, .maskCommand),
]

// A scroll-wheel turn posted to the app (lines; negative is down), at the pointer's place in its window.
func postWheel(_ pid: pid_t, _ lines: Int32) {
    let src = CGEventSource(stateID: .hidSystemState)
    guard let e = CGEvent(scrollWheelEvent2Source: src, units: .line, wheelCount: 1, wheel1: lines, wheel2: 0, wheel3: 0) else { return }
    e.postToPid(pid)
}

func windowID(_ pid: Int) -> Int? {
    guard let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] else { return nil }
    for w in list where (w[kCGWindowOwnerPID as String] as? Int) == pid && (w[kCGWindowLayer as String] as? Int) == 0 {
        return w[kCGWindowNumber as String] as? Int
    }
    return nil
}

func handle(_ req: [String: Any]) -> [String: Any] {
    let trusted = AXIsProcessTrusted()
    let op = req["op"] as? String ?? ""
    if op == "ping" {
        return ["ok": true, "trusted": trusted, "screen": CGPreflightScreenCaptureAccess(), "pid": Int(getpid()),
                "exe": CommandLine.arguments[0]]
    }
    if op == "alive" {
        guard let pid = req["pid"] as? Int else { return ["ok": false, "error": "pid wanted"] }
        return ["ok": true, "alive": kill(pid_t(pid), 0) == 0]
    }
    if op == "cgwin" {
        // A process's windows from the window server (no Accessibility, no Screen Recording): on screen or not.
        guard let pid = req["pid"] as? Int else { return ["ok": false, "error": "pid wanted"] }
        let wins = (CGWindowListCopyWindowInfo([.optionAll], kCGNullWindowID) as? [[String: Any]]) ?? []
        return ["ok": true, "windows": wins.filter { ($0[kCGWindowOwnerPID as String] as? Int) == pid }.map {
            ["layer": $0[kCGWindowLayer as String] ?? 0, "onscreen": $0[kCGWindowIsOnscreen as String] ?? false,
             "bounds": $0[kCGWindowBounds as String] ?? [:]]
        }]
    }
    if op == "windows" {
        // Every on-screen window's owner (name, pid) and layer: the lane's guard against a system dialog
        // (SecurityAgent, CoreServicesUIAgent, UserNotificationCenter). No titles: those need Screen Recording.
        let wins = (CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]]) ?? []
        return ["ok": true, "windows": wins.map {
            ["owner": $0[kCGWindowOwnerName as String] ?? "", "pid": $0[kCGWindowOwnerPID as String] ?? 0,
             "layer": $0[kCGWindowLayer as String] ?? 0, "bounds": $0[kCGWindowBounds as String] ?? [:]]
        }]
    }
    if !trusted { return ["ok": false, "trusted": false, "error": "no Accessibility permission for this helper"] }
    guard let pid = req["pid"] as? Int else { return ["ok": false, "error": "pid wanted"] }
    lastHung = false
    switch op {
    case "activate":
        activate(pid)
        return ["ok": true]
    case "probe":
        // Raw AX error codes on the app element: why a tree came back empty.
        let app = appElement(pid_t(pid))
        var out: [String: Any] = ["ok": true]
        for name in [kAXRoleAttribute, kAXTitleAttribute, kAXWindowsAttribute, kAXChildrenAttribute,
                     kAXMainWindowAttribute, kAXFocusedWindowAttribute, "AXEnhancedUserInterface"] {
            var v: CFTypeRef?
            let err = AXUIElementCopyAttributeValue(app, name as CFString, &v)
            var d: [String: Any] = ["err": Int(err.rawValue)]
            if let a = v as? [AnyObject] { d["count"] = a.count } else if let s = str(v as AnyObject?) { d["value"] = s }
            out[name] = d
        }
        let set = AXUIElementSetAttributeValue(app, "AXEnhancedUserInterface" as CFString, kCFBooleanTrue)
        out["setEnhanced"] = Int(set.rawValue)
        let wins = (CGWindowListCopyWindowInfo([.optionAll], kCGNullWindowID) as? [[String: Any]]) ?? []
        out["cgWindows"] = wins.filter { ($0[kCGWindowOwnerPID as String] as? Int) == pid }.map {
            ["layer": $0[kCGWindowLayer as String] ?? 0, "onscreen": $0[kCGWindowIsOnscreen as String] ?? false,
             "bounds": $0[kCGWindowBounds as String] ?? [:]]
        }
        out["activationPolicy"] = NSRunningApplication(processIdentifier: pid_t(pid))?.activationPolicy.rawValue ?? -1
        return out
    case "tree":
        let nodes = walk(appElement(pid_t(pid)))
        return ["ok": true, "nodes": nodes, "hung": lastHung && nodes.isEmpty]
    case "press":
        let (el, err) = target(req)
        guard let e = el else { return ["ok": false, "error": err ?? "no node"] }
        let r = AXUIElementPerformAction(e, kAXPressAction as CFString)
        return r == .success ? ["ok": true] : ["ok": false, "error": "AXPress: \(r.rawValue)"]
    case "focus":
        let (el, err) = target(req)
        guard let e = el else { return ["ok": false, "error": err ?? "no node"] }
        activate(pid)
        let r = AXUIElementSetAttributeValue(e, kAXFocusedAttribute as CFString, kCFBooleanTrue)
        return r == .success ? ["ok": true] : ["ok": false, "error": "AXFocused: \(r.rawValue)"]
    case "setvalue":
        let (el, err) = target(req)
        guard let e = el else { return ["ok": false, "error": err ?? "no node"] }
        let r = AXUIElementSetAttributeValue(e, kAXValueAttribute as CFString, (req["text"] as? String ?? "") as CFString)
        return r == .success ? ["ok": true] : ["ok": false, "error": "AXValue: \(r.rawValue)"]
    case "type":
        postText(pid_t(pid), req["text"] as? String ?? "")
        return ["ok": true]
    case "keys":
        for name in (req["keys"] as? [String] ?? []) {
            guard let (code, flags) = KEYS[name] else { return ["ok": false, "error": "no key \(name)"] }
            postKey(pid_t(pid), code, flags)
            usleep(UInt32((req["gap_ms"] as? Int ?? 120) * 1000))
        }
        return ["ok": true]
    case "wheel":
        let n = req["lines"] as? Int ?? -5
        for _ in 0..<max(1, req["times"] as? Int ?? 1) { postWheel(pid_t(pid), Int32(n)); usleep(30000) }
        return ["ok": true]
    case "erase":
        for _ in 0..<(req["n"] as? Int ?? 0) { postKey(pid_t(pid), 51) }
        return ["ok": true]
    case "shot":
        // Only with Screen Recording already granted: asking would put a prompt on the user's screen.
        guard CGPreflightScreenCaptureAccess() else { return ["ok": false, "screen": false, "error": "no Screen Recording permission"] }
        guard let wid = windowID(pid), let path = req["file"] as? String else { return ["ok": false, "error": "no app window"] }
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
        p.arguments = ["-x", "-o", "-l", String(wid), path]
        do { try p.run() } catch { return ["ok": false, "error": "screencapture: \(error)"] }
        p.waitUntilExit()
        return ["ok": p.terminationStatus == 0 && FileManager.default.fileExists(atPath: path)]
    default:
        return ["ok": false, "error": "no op \(op)"]
    }
}

func readLine(_ fd: Int32) -> Data {
    var data = Data()
    var b: UInt8 = 0
    while read(fd, &b, 1) == 1 {
        if b == 10 { break }
        data.append(b)
        if data.count > 1 << 22 { break }
    }
    return data
}

func writeAll(_ fd: Int32, _ data: Data) {
    data.withUnsafeBytes { (p: UnsafeRawBufferPointer) in
        var off = 0
        while off < p.count {
            let n = write(fd, p.baseAddress! + off, p.count - off)
            if n <= 0 { break }
            off += n
        }
    }
}

func sockaddr(_ path: String) -> sockaddr_un {
    var a = sockaddr_un()
    a.sun_family = sa_family_t(AF_UNIX)
    let bytes = Array(path.utf8)
    withUnsafeMutableBytes(of: &a.sun_path) { p in
        for (i, b) in bytes.prefix(p.count - 1).enumerated() { p[i] = b }
    }
    return a
}

func serve(_ path: String) -> Never {
    unlink(path)
    let fd = socket(AF_UNIX, SOCK_STREAM, 0)
    var a = sockaddr(path)
    let len = socklen_t(MemoryLayout<sockaddr_un>.size)
    guard withUnsafePointer(to: &a, { $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { bind(fd, $0, len) } }) == 0 else {
        FileHandle.standardError.write("bind \(path) failed\n".data(using: .utf8)!)
        exit(2)
    }
    chmod(path, 0o600)
    listen(fd, 8)
    FileHandle.standardError.write("wfe-axhelper serving \(path); trusted=\(AXIsProcessTrusted())\n".data(using: .utf8)!)
    while true {
        let c = accept(fd, nil, nil)
        if c < 0 { continue }
        let line = readLine(c)
        var ans: [String: Any]
        if let req = (try? JSONSerialization.jsonObject(with: line)) as? [String: Any] {
            ans = handle(req)
        } else {
            ans = ["ok": false, "error": "bad request"]
        }
        var out = (try? JSONSerialization.data(withJSONObject: ans)) ?? Data("{\"ok\":false}".utf8)
        out.append(10)
        writeAll(c, out)
        close(c)
    }
}

func call(_ path: String) -> Never {
    let line = readLine(0)
    let fd = socket(AF_UNIX, SOCK_STREAM, 0)
    var a = sockaddr(path)
    let len = socklen_t(MemoryLayout<sockaddr_un>.size)
    guard withUnsafePointer(to: &a, { $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { connect(fd, $0, len) } }) == 0 else {
        print("{\"ok\":false,\"error\":\"no helper on the socket\",\"down\":true}")
        exit(0)
    }
    var req = line
    req.append(10)
    writeAll(fd, req)
    var out = Data()
    var buf = [UInt8](repeating: 0, count: 65536)
    while true {
        let n = read(fd, &buf, buf.count)
        if n <= 0 { break }
        out.append(contentsOf: buf[0..<n])
    }
    FileHandle.standardOutput.write(out)
    exit(0)
}

let args = CommandLine.arguments
if args.count == 3 && args[1] == "serve" { serve(args[2]) }
if args.count == 3 && args[1] == "call" { call(args[2]) }
FileHandle.standardError.write("usage: wfe-axhelper serve|call <socket>\n".data(using: .utf8)!)
exit(64)
