import AppKit
import SwiftUI

struct AppDetailView: View {
    @EnvironmentObject private var store: PrivacyStore
    let bundleIdentifier: String

    private var app: InstalledApp? {
        store.apps.first { $0.bundleIdentifier == bundleIdentifier }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                if let app = app {
                    header(app: app)
                    permissionBadges(app: app)
                    actions(app: app)
                    AdvancedTCCCommandsView(bundleIdentifier: bundleIdentifier)
                    pathSection(app: app)
                } else {
                    Text("App 数据已失效")
                        .foregroundStyle(.secondary)
                }
                explanation
            }
            .padding(28)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func header(app: InstalledApp) -> some View {
        HStack(spacing: 16) {
            AppIconView(data: app.iconData)
                .scaleEffect(1.8)
                .frame(width: 58, height: 58)
            VStack(alignment: .leading, spacing: 4) {
                Text(app.name)
                    .font(.largeTitle.bold())
                Text(app.bundleIdentifier)
                    .font(.callout.monospaced())
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }
            Spacer()
        }
    }

    private func permissionBadges(app: InstalledApp) -> some View {
        HStack(spacing: 12) {
            PermissionBadge(service: .microphone, decision: app.microphone)
            PermissionBadge(service: .camera, decision: app.camera)
            Spacer()
        }
    }

    private func actions(app: InstalledApp) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("常规操作")
                .font(.headline)
            HStack {
                Button("打开麦克风隐私设置") { store.openSettings(for: .microphone) }
                Button("打开摄像头隐私设置") { store.openSettings(for: .camera) }
                Button("在 Finder 中显示") { store.revealInFinder(app) }
            }
        }
    }

    private func pathSection(app: InstalledApp) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("路径")
                .font(.headline)
            Text(app.path)
                .font(.system(.body, design: .monospaced))
                .textSelection(.enabled)
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    private var explanation: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("说明")
                .font(.headline)
            Text("系统设置里看不到旧 App 时，可以手动写入当前用户的 TCC.db。这个做法不是 Apple 官方 API，可能需要关闭 SIP、授予终端完全磁盘访问权限，并且不同 macOS 版本 access 表字段可能变化。执行后通常需要重启或重新登录。")
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Advanced TCC Commands View

struct AdvancedTCCCommandsView: View {
    @EnvironmentObject private var store: PrivacyStore
    let bundleIdentifier: String
    @State private var service: PrivacyService = .microphone
    @State private var action         = TCCAction.grant
    @State private var showCopyToast  = false
    @State private var executionResult: ExecutionResult?

    private var app: InstalledApp? {
        store.apps.first { $0.bundleIdentifier == bundleIdentifier }
    }

    var command: String {
        let builder = TCCCommandBuilder(bundleIdentifier: bundleIdentifier, service: service)
        switch action {
        case .grant:  return builder.grantCommand
        case .deny:   return builder.denyCommand
        case .delete: return builder.deleteCommand
        case .verify: return builder.verifyCommand
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("高级：生成 TCC Shell 命令")
                .font(.headline)
            Text("适合你提到的手动 sqlite3 方案。建议先备份 TCC.db；风险自担。")
                .font(.callout)
                .foregroundStyle(.secondary)

            // 第一行：权限、动作选择器 + 操作按钮
            HStack(spacing: 16) {
                Picker("权限", selection: $service) {
                    Text("麦克风").tag(PrivacyService.microphone)
                    Text("摄像头").tag(PrivacyService.camera)
                }
                .pickerStyle(.segmented)
                .frame(width: 160)

                Picker("动作", selection: $action) {
                    ForEach(TCCAction.allCases) { item in
                        Text(item.title).tag(item)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 300)

                Button("复制命令") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(command, forType: .string)
                    withAnimation(.spring(response: 0.3)) {
                        showCopyToast = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation(.easeOut(duration: 0.3)) {
                            showCopyToast = false
                        }
                    }
                }
                .buttonStyle(.bordered)

                Button("执行命令") {
                    executeCommand()
                }
                .buttonStyle(.borderedProminent)

                Spacer()
            }
            .overlay(alignment: .topLeading) {
                if showCopyToast {
                    CopyToastView()
                        .offset(y: -44)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }

            // 命令展示区
            Text(command)
                .font(.system(.caption, design: .monospaced))
                .textSelection(.enabled)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(nsColor: .textBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            if let result = executionResult {
                ExecutionResultView(result: result) {
                    executionResult = nil
                }
            }
        }
        .padding(14)
        .background(Color.blue.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Execute Command

    private func executeCommand() {
        let cmd           = command
        let currentAction = action
        let svc           = service
        let bid           = bundleIdentifier

        Task.detached(priority: .userInitiated) { [cmd, currentAction, svc, bid] in
            let tmpDir     = FileManager.default.temporaryDirectory
            let scriptFile = tmpDir.appendingPathComponent("tcc_\(UUID().uuidString).sh")
            do {
                try cmd.write(to: scriptFile, atomically: true, encoding: .utf8)
                try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptFile.path)

                let appleScriptSource = "do shell script \"bash \(scriptFile.path)\" with administrator privileges"
                guard let appleScript = NSAppleScript(source: appleScriptSource) else {
                    await MainActor.run {
                        executionResult = ExecutionResult(success: false, message: "无法创建 AppleScript")
                    }
                    try? FileManager.default.removeItem(at: scriptFile)
                    return
                }
                var nsError: NSDictionary?
                let output = appleScript.executeAndReturnError(&nsError)
                try? FileManager.default.removeItem(at: scriptFile)

                let result: ExecutionResult

                if let err = nsError {
                    let message = err["NSAppleScriptErrorMessage"] as? String ?? "未知错误"
                    result = ExecutionResult(success: false, message: message)
                } else {
                    let outputString = output.stringValue?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                    let serviceName  = svc == .microphone ? "麦克风" : "摄像头"

                    if currentAction == .verify {
                        if outputString.isEmpty {
                            result = ExecutionResult(
                                success: true,
                                message: "⚠️ 未找到「\(serviceName)」的 TCC 记录\n（该 App 可能从未申请过此权限）"
                            )
                        } else {
                            let lines  = outputString.components(separatedBy: "\n")
                            var formattedParts: [String] = []
                            for line in lines where !line.isEmpty {
                                let parts = line.components(separatedBy: "→")
                                if parts.count >= 2 {
                                    let status = parts[0].trimmingCharacters(in: .whitespaces)
                                    let time   = parts[1].trimmingCharacters(in: .whitespaces)
                                    formattedParts.append("🔐 \(serviceName)权限状态：\(formatAuthStatus(status))")
                                    formattedParts.append("📅 最后修改：\(formatTimestamp(time))")
                                }
                            }
                            if formattedParts.isEmpty {
                                result = ExecutionResult(success: true, message: "查询结果：\n\(outputString)")
                            } else {
                                result = ExecutionResult(success: true, message: formattedParts.joined(separator: "\n"))
                            }
                        }
                    } else {
                        let message = outputString.isEmpty ? "✅ 命令执行成功（无输出表示写入正常）" : outputString
                        result = ExecutionResult(success: true, message: message)
                    }
                }

                await MainActor.run {
                    executionResult = result
                    // 执行写操作后，真正重新读取该 App 的 TCC 状态（不 fake 内存）
                    if result.success && currentAction != .verify {
                        store.refreshApp(bundleID: bid)
                    }
                }
            } catch let e {
                let message = e.localizedDescription
                await MainActor.run {
                    executionResult = ExecutionResult(success: false, message: message)
                }
            }
        }
    }
}

// MARK: - 文件级辅助函数（非 Actor 隔离，可从 Task.detached 安全调用）

fileprivate func formatAuthStatus(_ raw: String) -> String {
    switch raw.trimmingCharacters(in: .whitespaces) {
    case "0", "❌ 拒绝":          return "❌ 已拒绝"
    case "1":                         return "未知(1)"
    case "2", "✅ 已允许":         return "✅ 已允许"
    case "3", "⚠️ 受限":          return "⚠️ 受限"
    case let v:                    return "未知(\(v))"
    }
}

fileprivate func formatTimestamp(_ raw: String) -> String {
    let s = raw.trimmingCharacters(in: .whitespaces)
    if let ts = TimeInterval(s), ts > 0 {
        let date = Date(timeIntervalSince1970: ts)
        let fmt  = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return fmt.string(from: date)
    }
    return s.isEmpty ? "未知" : s
}

// MARK: - TCC Action

enum TCCAction: String, CaseIterable, Identifiable {
    case grant
    case deny
    case delete
    case verify

    var id: String { rawValue }

    var title: String {
        switch self {
        case .grant:  return "允许"
        case .deny:   return "拒绝"
        case .delete: return "删除记录"
        case .verify: return "验证"
        }
    }
}

// MARK: - Copy Toast

struct CopyToastView: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.white)
            Text("已复制到剪贴板")
                .foregroundStyle(.white)
                .font(.callout.bold())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.green.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(0.15), radius: 6, y: 2)
    }
}

// MARK: - Execution Result

struct ExecutionResult: Identifiable {
    let id       = UUID()
    let success: Bool
    let message: String
}

struct ExecutionResultView: View {
    let result:  ExecutionResult
    let dismiss: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.title3)
                .foregroundStyle(result.success ? .green : .red)
            VStack(alignment: .leading, spacing: 4) {
                Text(result.success ? "执行成功" : "执行失败")
                    .font(.headline)
                Text(result.message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(result.success ? Color.green.opacity(0.08) : Color.red.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(result.success ? Color.green.opacity(0.3) : Color.red.opacity(0.3), lineWidth: 1)
        )
    }
}
