import AppKit
import Foundation

private let logURL = URL(fileURLWithPath: "/tmp/MicCamPrivacyManager.log")

func log(_ message: String) {
    let line = "[\(ISO8601DateFormatter().string(from: Date()))] \(message)\n"
    if let handle = try? FileHandle(forWritingTo: logURL) {
        handle.seekToEndOfFile()
        handle.write(Data(line.utf8))
        handle.closeFile()
    } else {
        FileManager.default.createFile(atPath: logURL.path, contents: Data(line.utf8))
    }
}

struct AppScanner {
    func scanApplications() -> [InstalledApp] {
        let searchRoots = [
            "/Applications",
            NSString(string: "~/Applications").expandingTildeInPath,
            "/System/Applications",
            "/System/Applications/Utilities",
            "/System/Volumes/Data/Applications"
        ]

        var seen = Set<String>()
        var apps: [InstalledApp] = []

        for root in searchRoots {
            let rootURL = URL(fileURLWithPath: root)
            guard FileManager.default.fileExists(atPath: rootURL.path) else {
                log("[AppScanner] 跳过不存在的路径: \(root)")
                continue
            }
            log("[AppScanner] 扫描路径: \(root)")
            guard let enumerator = FileManager.default.enumerator(
                at: rootURL,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles, .skipsPackageDescendants]
            ) else {
                log("[AppScanner] 无法枚举路径: \(root)")
                continue
            }

            for case let url as URL in enumerator where url.pathExtension == "app" {
                guard let bundle = Bundle(url: url),
                      let bid = bundle.bundleIdentifier,
                      !seen.contains(bid)
                else {
                    continue
                }

                seen.insert(bid)
                autoreleasepool {
                    let app = makeInstalledApp(url: url, bundle: bundle, bundleID: bid)
                    apps.append(app)
                }
            }
        }

        let sortedApps = apps.sorted { lhs, rhs in
            lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
        log("[AppScanner] 扫描完成: 找到 \(sortedApps.count) 个有效应用")
        return sortedApps
    }

    private func makeInstalledApp(url: URL, bundle: Bundle, bundleID: String) -> InstalledApp {
        let displayName = bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
        let bundleName = bundle.object(forInfoDictionaryKey: "CFBundleName") as? String
        let name = displayName ?? bundleName ?? url.deletingPathExtension().lastPathComponent

        return InstalledApp(
            id: bundleID,
            name: name,
            bundleIdentifier: bundleID,
            path: url.path,
            iconData: nil,
            microphone: .notDetermined,
            camera: .notDetermined
        )
    }
}
