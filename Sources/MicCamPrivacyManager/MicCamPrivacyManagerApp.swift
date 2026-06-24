import SwiftUI

@main
struct MicCamPrivacyManagerApp: App {
    @StateObject private var store = PrivacyStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .frame(minWidth: 1200, minHeight: 640)
                .task {
                    await store.refresh()
                }
        }
        .windowStyle(.titleBar)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("关于 MicCam") {
                    NSApp.orderFrontStandardAboutPanel(options: [
                        .applicationName: "MicCam",
                        .applicationVersion: "0.1.0"
                    ])
                }
            }
        }
    }
}
