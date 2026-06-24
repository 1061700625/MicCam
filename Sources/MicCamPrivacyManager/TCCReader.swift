import Foundation

struct TCCReader {
    private var databasePath: String {
        NSString(string: "~/Library/Application Support/com.apple.TCC/TCC.db").expandingTildeInPath
    }

    /// 读取所有 TCC 记录
    func readEntries() -> [TCCEntry] {
        guard FileManager.default.fileExists(atPath: databasePath) else { return [] }
        let services = PrivacyService.allCases.map { "'\($0.rawValue)'" }.joined(separator: ",")
        let query = "SELECT service,client,auth_value FROM access WHERE service IN (\(services));"
        let result = Shell.run("/usr/bin/sqlite3", arguments: [databasePath, "-separator", "\t", query])
        guard result.succeeded else { return [] }
        return result.output
            .split(separator: "\n")
            .compactMap { parseLine(String($0)) }
    }

    /// 只读取指定 bundleID 的 TCC 记录
    func readEntries(for bundleID: String) -> [TCCEntry] {
        guard FileManager.default.fileExists(atPath: databasePath) else { return [] }
        let services = PrivacyService.allCases.map { "'\($0.rawValue)'" }.joined(separator: ",")
        let query = "SELECT service,client,auth_value FROM access WHERE service IN (\(services)) AND client='\(bundleID)';"
        let result = Shell.run("/usr/bin/sqlite3", arguments: [databasePath, "-separator", "\t", query])
        guard result.succeeded else { return [] }
        return result.output
            .split(separator: "\n")
            .compactMap { parseLine(String($0)) }
    }

    private func parseLine(_ line: String) -> TCCEntry? {
        let parts = line.components(separatedBy: "\t")
        guard parts.count >= 3,
              let service = PrivacyService(rawValue: parts[0])
        else { return nil }

        let authValue = Int(parts[2]) ?? -1
        let decision = decisionFromAuthValue(authValue)
        return TCCEntry(service: service, client: parts[1], decision: decision, lastModified: nil)
    }

    private func decisionFromAuthValue(_ value: Int) -> TCCDecision {
        switch value {
        case 0: return .denied
        case 1: return .unknown("unknown")
        case 2: return .allowed
        case 3: return .limited
        default: return .unknown(String(value))
        }
    }
}
