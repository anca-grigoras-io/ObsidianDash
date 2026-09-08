import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var appState = appState

        Group {
            if appState.vaultService.hasVault {
                NavigationSplitView {
                    SidebarView()
                } detail: {
                    detailView(for: appState.selectedSection)
                        .navigationSplitViewColumnWidth(min: 500, ideal: 800)
                }
                .navigationSplitViewStyle(.balanced)
            } else {
                VaultOnboardingView()
            }
        }
        .task {
            guard appState.vaultService.hasVault else { return }
            await appState.vaultService.scanVault()
        }
    }

    @ViewBuilder
    private func detailView(for section: AppState.SidebarSection?) -> some View {
        switch section ?? .overview {
        case .overview:   OverviewView()
        case .tasks:      TasksView()
        case .dailyNotes: DailyNotesView()
        case .stats:      StatsView()
        case .projects:   ProjectsView()
        case .calendar:   CalendarDashboardView()
        }
    }
}
