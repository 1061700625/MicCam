import SwiftUI

struct FullDiskAccessWarningView: View {
    @EnvironmentObject private var store: PrivacyStore

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.shield")
                .foregroundColor(.orange)
            VStack(alignment: .leading, spacing: 4) {
                Text("需要完全磁盘访问权限")
                    .font(.callout.bold())
                Text("请在系统设置中为本应用开启「完全磁盘访问权限」，否则无法读取 TCC 权限记录。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("去开启") {
                store.openFullDiskAccessSettings()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding(10)
        .background(Color.orange.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
