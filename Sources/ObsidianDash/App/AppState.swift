import SwiftUI

@MainActor
@Observable
final class AppState {
    var vaultService = VaultService()
    var selectedSection: SidebarSection? = .overview

    enum SidebarSection: String, CaseIterable, Identifiable {
        case overview    = "Overview"
        case tasks       = "Tasks"
        case dailyNotes  = "Daily Notes"
        case stats       = "Statistics"
        case projects    = "Projects"
        case calendar    = "Calendar"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .overview:   return "square.grid.2x2.fill"
            case .tasks:      return "checkmark.circle.fill"
            case .dailyNotes: return "calendar.day.timeline.leading"
            case .stats:      return "chart.bar.xaxis"
            case .projects:   return "folder.fill"
            case .calendar:   return "calendar"
            }
        }

        var color: Color {
            switch self {
            case .overview:   return .purple
            case .tasks:      return .blue
            case .dailyNotes: return .teal
            case .stats:      return .indigo
            case .projects:   return .green
            case .calendar:   return .orange
            }
        }
    }
}
