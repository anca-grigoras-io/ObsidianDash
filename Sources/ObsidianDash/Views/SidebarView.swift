import SwiftUI

struct SidebarView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var appState = appState

        List(AppState.SidebarSection.allCases, selection: $appState.selectedSection) { section in
            Label {
                Text(section.rawValue)
            } icon: {
                Image(systemName: section.icon)
                    .foregroundStyle(section.color)
            }
            .tag(section)
        }
        .listStyle(.sidebar)
        .navigationTitle("ObsidianDash")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                } label: {
                    Image(systemName: "gear")
                }
                .help("Settings")
            }

            ToolbarItem {
                if appState.vaultService.isLoading {
                    ProgressView().controlSize(.small)
                } else {
                    Button {
                        Task { await appState.vaultService.scanVault() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .help("Refresh vault")
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if let date = appState.vaultService.lastScanDate {
                Text("Updated \(date.formatted(.relative(presentation: .named)))")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}
