import SwiftUI

@main
struct ObsidianDashApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .frame(minWidth: 960, minHeight: 640)
        }
        .defaultSize(width: 1200, height: 780)
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandGroup(after: .appInfo) {
                Button("Refresh Vault") {
                    Task { await appState.vaultService.scanVault() }
                }
                .keyboardShortcut("r", modifiers: .command)
            }
        }

        Settings {
            SettingsView()
                .environment(appState)
        }
    }
}
