import Foundation

struct ObsidianTask: Identifiable, Hashable, Sendable {
    let id: UUID
    let text: String
    let isCompleted: Bool
    let noteURL: URL
    let noteTitle: String
    let dueDate: Date?

    var isOverdue: Bool {
        guard let due = dueDate else { return false }
        return !isCompleted && due < Calendar.current.startOfDay(for: Date())
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: ObsidianTask, rhs: ObsidianTask) -> Bool {
        lhs.id == rhs.id
    }
}
