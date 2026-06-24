import AppKit
import Foundation

enum ScanStage: Equatable {
    case idle
    case scanningApps(found: Int)
    case readingTCC
    case merging
    case done(count: Int)
}

@MainActor
final class PrivacyStore: ObservableObject {
    @Published var apps: [InstalledApp] = []
    @Published var searchText = ""
    @Published var showOnlyRecorded = false
    @Published var lastRefresh: Date?
    @Published var scanStage: ScanStage = .idle
    @Published var hasFullDiskAccess: Bool = true

    private let scanner = AppScanner()
    private let tccReader = TCCReader()

    var filteredApps: [InstalledApp] {
        apps.filter { app in
            let matchesSearch = searchText.isEmpty
                || app.name.localizedCaseInsensitiveContains(searchText)
                || app.bundleIdentifier.localizedCaseInsensitiveContains(searchText)
                || app.path.localizedCaseInsensitiveContains(searchText)
            let matchesRecorded = !showOnlyRecorded || app.hasAnyRecord
            return matchesSearch && matchesRecorded
        }
    }

    func refresh() async {
        checkFullDiskAccess()
        apps = []
        scanStage = .scanningApps(found: 0)
        log("[PrivacyStore] 开始扫描...")

        // 在后台线程扫描应用
        let scannedApps = await Task.detached(priority: .userInitiated) {
            log("[PrivacyStore] 调用 scanner.scanApplications()...")
            let result = self.scanner.scanApplications()
            log("[PrivacyStore] 扫描完成，返回 \(result.count) 个应用")
            return result
        }.value

        log("[PrivacyStore] 扫描阶段完成: 找到 \(scannedApps.count) 个应用")
        scanStage = .readingTCC

        // 在后台线程读取 TCC
        let entries = await Task.detached(priority: .userInitiated) {
            self.tccReader.readEntries()
        }.value
        log("[PrivacyStore] TCC读取完成: 找到 \(entries.count) 条记录")

        // 在主线程合并数据
        scanStage = .merging
        var entryMap: [String: [PrivacyService: TCCEntry]] = [:]
        for entry in entries {
            entryMap[entry.client, default: [:]][entry.service] = entry
        }

        let newApps = scannedApps.map { app in
            var copy = app
            copy.microphone = entryMap[app.bundleIdentifier]?[.microphone]?.decision ?? .notDetermined
            copy.camera = entryMap[app.bundleIdentifier]?[.camera]?.decision ?? .notDetermined
            return copy
        }
        apps = newApps
        lastRefresh = Date()
        scanStage = .done(count: apps.count)
        log("[PrivacyStore] 合并完成: 最终显示 \(apps.count) 个应用")
        log("[PrivacyStore] apps 数组现在有 \(self.apps.count) 个元素")

        // 异步加载图标（批量更新，减少 UI 刷新次数）
        let appPaths = newApps.map { $0.path }
        let appIDs   = newApps.map { $0.id }
        Task.detached(priority: .low) {
            let batchSize = 20
            var batch: [(bid: String, data: Data)] = []

            for (i, path) in appPaths.enumerated() {
                autoreleasepool {
                    let icon = NSWorkspace.shared.icon(forFile: path)
                    if let iconData = icon.tiffRepresentation {
                        batch.append((appIDs[i], iconData))
                    }
                }

                // 每积累 batchSize 个图标，批量更新一次 MainActor
                if batch.count >= batchSize {
                    let batchCopy = batch
                    await MainActor.run {
                        for (bid, data) in batchCopy {
                            if let idx = self.apps.firstIndex(where: { $0.id == bid }) {
                                self.apps[idx].iconData = data
                            }
                        }
                    }
                    batch.removeAll(keepingCapacity: true)
                    // 让出主线程，避免卡顿
                    try? await Task.sleep(for: .milliseconds(20))
                }
            }

            // 剩余不足一批的，也更新掉
            if !batch.isEmpty {
                let batchCopy = batch
                await MainActor.run {
                    for (bid, data) in batchCopy {
                        if let idx = self.apps.firstIndex(where: { $0.id == bid }) {
                            self.apps[idx].iconData = data
                        }
                    }
                }
            }

            log("[PrivacyStore] 图标加载完成")
        }
    }

    func checkFullDiskAccess() {
        let tccPath = NSString(string: "~/Library/Application Support/com.apple.TCC/TCC.db").expandingTildeInPath
        if FileManager.default.fileExists(atPath: tccPath) {
            hasFullDiskAccess = FileManager.default.isReadableFile(atPath: tccPath)
        } else {
            hasFullDiskAccess = true
        }
    }

    /// 仅刷新指定 bundleID 的权限状态（真正读库，不触发全量扫描）
    func refreshApp(bundleID: String) {
        let entries = tccReader.readEntries(for: bundleID)
        let entryMap: [PrivacyService: TCCEntry] = {
            var m: [PrivacyService: TCCEntry] = [:]
            for e in entries { m[e.service] = e }
            return m
        }()
        if let idx = apps.firstIndex(where: { $0.bundleIdentifier == bundleID }) {
            apps[idx].microphone = entryMap[.microphone]?.decision ?? .notDetermined
            apps[idx].camera     = entryMap[.camera]?.decision     ?? .notDetermined
        }
    }

    func openSettings(for service: PrivacyService) {
        guard let url = URL(string: service.systemSettingsPane) else { return }
        NSWorkspace.shared.open(url)
    }

    func revealInFinder(_ app: InstalledApp) {
        NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: app.path)])
    }

    func openFullDiskAccessSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles") else { return }
        NSWorkspace.shared.open(url)
    }
}
