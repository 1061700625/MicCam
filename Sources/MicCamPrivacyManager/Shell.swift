import Foundation

struct ShellResult {
    let output: String
    let error: String
    let status: Int32

    var succeeded: Bool { status == 0 }
}

enum Shell {
    static func run(_ launchPath: String, arguments: [String]) -> ShellResult {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: launchPath)
        process.arguments = arguments

        let stdout = Pipe()
        let stderr = Pipe()
        process.standardOutput = stdout
        process.standardError = stderr

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return ShellResult(output: "", error: error.localizedDescription, status: -1)
        }

        let outData = stdout.fileHandleForReading.readDataToEndOfFile()
        let errData = stderr.fileHandleForReading.readDataToEndOfFile()

        return ShellResult(
            output: String(data: outData, encoding: .utf8) ?? "",
            error: String(data: errData, encoding: .utf8) ?? "",
            status: process.terminationStatus
        )
    }
}
