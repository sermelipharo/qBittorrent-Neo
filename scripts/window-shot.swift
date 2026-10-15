// Captures only the windows of the given process (by name) into PNG files,
// so UI checks never record other apps on screen.
// Usage: swift scripts/window-shot.swift <owner name or pid> out-prefix
import CoreGraphics
import Foundation

let args = CommandLine.arguments
guard args.count >= 3 else {
    print("usage: window-shot <owner name> <out prefix>")
    exit(2)
}
let owner = args[1]
let prefix = args[2]
let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] ?? []
var n = 0
let pid = Int32(owner)
for w in list where (pid != nil ? (w[kCGWindowOwnerPID as String] as? Int32) == pid : (w[kCGWindowOwnerName as String] as? String) == owner) {
    guard let id = w[kCGWindowNumber as String] as? Int,
          (w[kCGWindowLayer as String] as? Int) == 0 else { continue }
    let path = "\(prefix)-\(n).png"
    let p = Process()
    p.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
    p.arguments = ["-x", "-o", "-l", String(id), path]
    try? p.run()
    p.waitUntilExit()
    print(path)
    n += 1
}
if n == 0 { print("no windows for \(owner)"); exit(1) }
