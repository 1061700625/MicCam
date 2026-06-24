import AppKit
import SwiftUI

struct AppIconView: View {
    let data: Data?

    var body: some View {
        if let data, let image = NSImage(data: data) {
            Image(nsImage: image)
                .resizable()
                .frame(width: 32, height: 32)
        } else {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.2))
                .frame(width: 32, height: 32)
                .overlay(Image(systemName: "app"))
        }
    }
}

struct PermissionBadge: View {
    let service: PrivacyService
    let decision: TCCDecision

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(decision.color)
                .frame(width: 8, height: 8)
            VStack(alignment: .leading, spacing: 2) {
                Text(service.title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(decision.label)
                    .font(.callout.weight(.medium))
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct LimitationNotice: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("重要限制")
                .font(.headline)
            Text("常规情况下，macOS 不提供第三方 App 直接替其他 App 开关麦克风/摄像头权限的官方 API。高级用户可以通过 sqlite3 修改当前用户 TCC.db 来补录权限，但可能需要关闭 SIP、授予终端完全磁盘访问权限，并承担版本兼容和系统安全风险。")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(Color.orange.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
