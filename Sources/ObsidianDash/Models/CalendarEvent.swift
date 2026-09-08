import Foundation
import SwiftUI

struct CalendarEvent: Identifiable, Hashable, Sendable {
    let id: UUID
    let title: String
    let type: EventType
    let originalDate: Date
    let noteURL: URL?
    let noteTitle: String?

    enum EventType: Hashable, Sendable {
        case birthday
        case anniversary
        case workAnniversary
        case custom(String)

        var label: String {
            switch self {
            case .birthday: return "Birthday"
            case .anniversary: return "Anniversary"
            case .workAnniversary: return "Work Anniversary"
            case .custom(let s): return s
            }
        }

        var icon: String {
            switch self {
            case .birthday: return "birthday.cake"
            case .anniversary: return "heart.fill"
            case .workAnniversary: return "briefcase.fill"
            case .custom: return "star.fill"
            }
        }

        var color: Color {
            switch self {
            case .birthday: return .pink
            case .anniversary: return .red
            case .workAnniversary: return .blue
            case .custom: return .orange
            }
        }
    }

    var nextOccurrence: Date {
        let cal = Calendar.current
        let now = Date()
        let comps = cal.dateComponents([.month, .day], from: originalDate)
        let currentYear = cal.component(.year, from: now)

        if let thisYear = cal.date(from: DateComponents(year: currentYear, month: comps.month, day: comps.day)),
           thisYear >= cal.startOfDay(for: now) {
            return thisYear
        }
        return cal.date(from: DateComponents(year: currentYear + 1, month: comps.month, day: comps.day)) ?? originalDate
    }

    var daysUntilNextOccurrence: Int {
        let cal = Calendar.current
        return cal.dateComponents([.day], from: cal.startOfDay(for: Date()), to: nextOccurrence).day ?? 0
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: CalendarEvent, rhs: CalendarEvent) -> Bool {
        lhs.id == rhs.id
    }
}
