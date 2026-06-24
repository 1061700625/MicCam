import SwiftUI

struct ScanProgressView: View {
    let stage: ScanStage

    var body: some View {
        HStack(spacing: 8) {
            if case .done = stage {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            } else {
                ProgressView()
                    .scaleEffect(0.7)
            }
            Text(stageText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var stageText: String {
        switch stage {
        case .idle:
            return "空闲"
        case .scanningApps(let found):
            return "正在扫描应用…（已找到 \(found) 个）"
        case .readingTCC:
            return "正在读取 TCC 权限记录…"
        case .merging:
            return "正在合并数据…"
        case .done(let count):
            return "已扫描 \(count) 个应用"
        }
    }
}
