import SwiftUI

struct OverviewView: View {
    @Environment(AppState.self) private var appState

    private var svc: VaultService { appState.vaultService }

    private var greeting: String {
        switch Calendar.current.component(.hour, from: Date()) {
        case 0..<12: return "morning"
        case 12..<18: return "afternoon"
        default: return "evening"
        }
    }

    private var upcomingEvents: [CalendarEvent] {
        svc.calendarEvents
            .filter { $0.daysUntilNextOccurrence >= 0 }
            .sorted { $0.daysUntilNextOccurrence < $1.daysUntilNextOccurrence }
    }

    private var recentNotes: [Note] {
        svc.notes.sorted { $0.modificationDate > $1.modificationDate }
    }

    private var topFolders: [(String, Int)] {
        svc.notesByFolder
            .map { ($0.folder.isEmpty ? "Root" : $0.folder.components(separatedBy: "/").last ?? $0.folder, $0.notes.count) }
            .sorted { $0.1 > $1.1 }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Good \(greeting)")
                            .font(.largeTitle.bold())
                        Text(Date.now.formatted(date: .complete, time: .omitted))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if svc.isLoading {
                        ProgressView()
                    }
                }
                .padding(.horizontal)

                // Stat tiles
                HStack(spacing: 14) {
                    StatTile(title: "Notes",        value: "\(svc.notes.count)",       icon: "doc.text.fill",        color: .purple)
                    StatTile(title: "Open Tasks",   value: "\(svc.openTasks.count)",   icon: "checkmark.circle.fill", color: .blue)
                    StatTile(title: "Folders",      value: "\(svc.notesByFolder.count)", icon: "folder.fill",        color: .green)
                    StatTile(title: "Upcoming",     value: "\(upcomingEvents.prefix(30).count)", icon: "calendar",   color: .orange)
                }
                .padding(.horizontal)

                // Cards grid
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {

                    // Open tasks
                    DashboardCard(title: "Open Tasks", icon: "checkmark.circle.fill", color: .blue) {
                        if svc.openTasks.isEmpty {
                            emptyState(text: "All caught up!")
                        } else {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(svc.openTasks.prefix(5)) { task in
                                    TaskRow(task: task, compact: true)
                                    if task.id != svc.openTasks.prefix(5).last?.id { Divider() }
                                }
                                if svc.openTasks.count > 5 {
                                    Text("+\(svc.openTasks.count - 5) more tasks")
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }

                    // Upcoming events
                    DashboardCard(title: "Upcoming Events", icon: "calendar", color: .orange) {
                        if upcomingEvents.isEmpty {
                            emptyState(text: "No upcoming events")
                        } else {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(upcomingEvents.prefix(5)) { event in
                                    EventRow(event: event)
                                    if event.id != upcomingEvents.prefix(5).last?.id { Divider() }
                                }
                            }
                        }
                    }

                    // Recent notes
                    DashboardCard(title: "Recent Notes", icon: "doc.text.fill", color: .purple) {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(recentNotes.prefix(6)) { note in
                                NoteRow(note: note)
                                if note.id != recentNotes.prefix(6).last?.id { Divider() }
                            }
                        }
                    }

                    // Folders summary
                    DashboardCard(title: "Top Folders", icon: "folder.fill", color: .green) {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(topFolders.prefix(6), id: \.0) { name, count in
                                HStack {
                                    Image(systemName: "folder.fill")
                                        .font(.caption)
                                        .foregroundStyle(.green)
                                    Text(name)
                                        .font(.subheadline)
                                        .lineLimit(1)
                                    Spacer()
                                    Text("\(count)")
                                        .font(.caption.monospacedDigit())
                                        .foregroundStyle(.secondary)
                                }
                                if name != topFolders.prefix(6).last?.0 { Divider() }
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 24)
        }
        .navigationTitle("Overview")
    }

    private func emptyState(text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 8)
    }
}
