import Foundation

struct TCCCommandBuilder {
    let bundleIdentifier: String
    let service: PrivacyService

    var databasePath: String {
        "~/Library/Application\\ Support/com.apple.TCC/TCC.db"
    }

    /// 生成显式列名 INSERT（不依赖列顺序，兼容不同 macOS 版本）
    private func insertSQL(authValue: Int) -> String {
        let cols = [
            "service", "client", "client_type",
            "auth_value", "auth_reason", "auth_version",
            "csreq", "policy_id",
            "indirect_object_identifier_type", "indirect_object_identifier",
            "indirect_object_code_identity",
            "flags", "last_modified",
            "pid", "pid_version", "boot_uuid", "last_reminded"
        ]
        let vals = [
            "'\(service.rawValue)'",
            "'\(bundleIdentifier)'",
            "0",
            "\(authValue)",
            "4",   // auth_reason: user-set
            "1",   // auth_version
            "NULL", "NULL",
            "NULL", "'UNUSED'",
            "NULL",
            "0",
            "CAST(strftime('%s','now') AS INTEGER)",
            "NULL", "NULL", "'UNUSED'", "0"
        ]
        let colStr = cols.joined(separator: ", ")
        let valStr = vals.joined(separator: ", ")
        return "INSERT OR REPLACE INTO access (\(colStr)) VALUES (\(valStr));"
    }

    var grantCommand: String {
        "sqlite3 \(databasePath) \"\(insertSQL(authValue: 2))\""
    }

    var denyCommand: String {
        "sqlite3 \(databasePath) \"\(insertSQL(authValue: 0))\""
    }

    var deleteCommand: String {
        "sqlite3 \(databasePath) \"DELETE FROM access WHERE service='\(service.rawValue)' AND client='\(bundleIdentifier)';\""
    }

    var verifyCommand: String {
        "sqlite3 -separator ' → ' \(databasePath) \"SELECT auth_value,CAST(last_modified AS INTEGER) FROM access WHERE service='\(service.rawValue)' AND client='\(bundleIdentifier)';\""
    }
}
