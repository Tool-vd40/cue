import AppKit

/// Updates from GitHub Releases: read the latest release, download `Cue.zip`,
/// swap the app in place and relaunch. No framework, no server of our own.
enum Updater {
    static let repo = "Tool-vd40/cue"

    static var currentVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
    }

    /// "1.10.0" is newer than "1.9.2"; a leading "v" in the tag is ignored.
    static func isNewer(_ tag: String, than version: String) -> Bool {
        let t = tag.hasPrefix("v") ? String(tag.dropFirst()) : tag
        return t.compare(version, options: .numeric) == .orderedDescending
    }

    /// `interactive: false` is the silent launch check: speaks up only when
    /// there's something to install.
    static func check(interactive: Bool) {
        let url = URL(string: "https://api.github.com/repos/\(repo)/releases/latest")!
        URLSession.shared.dataTask(with: url) { data, _, error in
            let release = data.flatMap { try? JSONDecoder().decode(Release.self, from: $0) }
            DispatchQueue.main.async {
                guard let release else {
                    if interactive { alert(String(localized: "Couldn't check for updates."), error?.localizedDescription ?? "") }
                    return
                }
                guard isNewer(release.tag_name, than: currentVersion),
                      let zip = release.assets.first(where: { $0.name == "Cue.zip" }) else {
                    if interactive { alert(String(localized: "You're up to date."), "Cue \(currentVersion)") }
                    return
                }
                offer(release.tag_name, zip.browser_download_url)
            }
        }.resume()
    }

    private static func offer(_ tag: String, _ zipURL: URL) {
        let a = NSAlert()
        a.messageText = String(localized: "Cue \(tag) is available")
        a.informativeText = String(localized: "You have \(currentVersion). Install and relaunch?")
        a.addButton(withTitle: String(localized: "Install"))
        a.addButton(withTitle: String(localized: "Later"))
        NSApp.activate(ignoringOtherApps: true)
        guard a.runModal() == .alertFirstButtonReturn else { return }

        URLSession.shared.downloadTask(with: zipURL) { tmp, _, error in
            let installed = tmp.map { (try? install($0)) != nil } ?? false
            DispatchQueue.main.async {
                if !installed {
                    alert(String(localized: "Update failed."), error?.localizedDescription ?? "")
                }
            }
        }.resume()
    }

    /// Unpacks to a temp folder, checks it's really Cue, then
    /// hands the swap to a shell that waits for us to quit — a running app
    /// can't replace its own bundle.
    private static func install(_ zip: URL) throws {
        let target = Bundle.main.bundleURL
        guard target.pathExtension == "app" else { throw CocoaError(.fileWriteUnknown) }

        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try run("/usr/bin/ditto", ["-x", "-k", zip.path, dir.path])
        let fresh = dir.appendingPathComponent("Cue.app")
        guard Bundle(url: fresh)?.bundleIdentifier == Bundle.main.bundleIdentifier else {
            throw CocoaError(.fileReadCorruptFile)
        }

        let pid = ProcessInfo.processInfo.processIdentifier
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/bin/sh")
        p.arguments = ["-c", """
            while kill -0 \(pid) 2>/dev/null; do sleep 0.2; done
            rm -rf "$1" && mv "$2" "$1" && open "$1"
            """, "sh", target.path, fresh.path]
        try p.run()
        DispatchQueue.main.async { NSApp.terminate(nil) }
    }

    private static func run(_ tool: String, _ args: [String]) throws {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: tool)
        p.arguments = args
        try p.run()
        p.waitUntilExit()
        guard p.terminationStatus == 0 else { throw CocoaError(.fileReadCorruptFile) }
    }

    private static func alert(_ title: String, _ text: String) {
        let a = NSAlert()
        a.messageText = title
        a.informativeText = text
        NSApp.activate(ignoringOtherApps: true)
        a.runModal()
    }

    private struct Release: Decodable {
        let tag_name: String
        let assets: [Asset]
    }

    private struct Asset: Decodable {
        let name: String
        let browser_download_url: URL
    }
}
