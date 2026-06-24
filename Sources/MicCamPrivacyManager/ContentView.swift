import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: PrivacyStore
    @State private var selection: InstalledApp.ID?

    var selectedApp: InstalledApp? {
        store.apps.first { $0.id == selection }
    }

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detail
        }
        .task {
            if store.apps.isEmpty {
                await store.refresh()
            }
        }
        .toolbar {
            ToolbarItemGroup {
                Button {
                    Task { await store.refresh() }
                } label: {
                    Label("刷新", systemImage: "arrow.clockwise")
                }
                Button {
                    store.openSettings(for: .microphone)
                } label: {
                    Label("麦克风设置", systemImage: "mic")
                }
                Button {
                    store.openSettings(for: .camera)
                } label: {
                    Label("摄像头设置", systemImage: "camera")
                }
            }
        }
    }

    private var sidebar: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "lock.shield")
                    .font(.title2)
                VStack(alignment: .leading) {
                    Text("MicCam")
                        .font(.headline)
                    Text("麦克风 / 摄像头权限总览")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding()

            ScanProgressView(stage: store.scanStage)

            if !store.hasFullDiskAccess {
                FullDiskAccessWarningView()
                    .padding(.horizontal)
            }

            // 搜索框 + 筛选开关（同一行，节省垂直空间）
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("搜索 App 名称、Bundle ID 或路径", text: $store.searchText)
                    .textFieldStyle(.roundedBorder)
                if !store.searchText.isEmpty {
                    Button {
                        store.searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }

                Toggle("有 TCC 记录", isOn: $store.showOnlyRecorded)
                    .toggleStyle(.checkbox)
                    .controlSize(.small)
                    .help("TCC 记录指 App 曾申请过麦克风/摄像头权限")
            }
            .padding(.horizontal)
            .padding(.bottom, 8)

            List(store.filteredApps, selection: $selection) { app in
                HStack(spacing: 10) {
                    AppIconView(data: app.iconData)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(app.name)
                            .lineLimit(1)
                        Text(app.bundleIdentifier)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                .tag(app.id)
            }
        }
        .navigationSplitViewColumnWidth(min: 320, ideal: 360)
    }

    @ViewBuilder
    private var detail: some View {
        if let app = selectedApp {
            AppDetailView(bundleIdentifier: app.bundleIdentifier)
        } else {
            VStack(spacing: 18) {
                Image(systemName: "lock.shield")
                    .font(.system(size: 64))
                    .foregroundStyle(.secondary)
                Text("选择一个 App 查看权限")
                    .font(.title2.bold())
                Text("左侧会列出本机已安装应用，并显示其麦克风和摄像头权限记录。")
                    .foregroundStyle(.secondary)
                LimitationNotice()
                    .frame(maxWidth: 620)
            }
            .padding(40)
        }
    }
}
