import Foundation

struct Note: Identifiable, Hashable, Sendable {
    let id: UUID
    let url: URL
    let title: String
    let content: String
    let frontmatter: [String: String]
    let tags: [String]
    let tasks: [ObsidianTask]
    let calendarEvents: [CalendarEvent]
    let creationDate: Date
    let modificationDate: Date
    let folder: String

    var wordCount: Int {
        content.split(whereSeparator: \.isWhitespace).count
    }

    var openTaskCount: Int {
        tasks.filter { !$0.isCompleted }.count
    }

    var isDailyNote: Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: title) != nil
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Note, rhs: Note) -> Bool {
        lhs.id == rhs.id
    }
}
