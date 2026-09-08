import SwiftUI

struct DailyNotesView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedNote: Note?

    private var svc: VaultService { appState.vaultService }

    var body: some View {
        HSplitView {
            // Left: note list
            VStack(spacing: 0) {
                if svc.dailyNotes.isEmpty {
                    ContentUnavailableView(
                        "No Daily Notes",
                        systemImage: "calendar.day.timeline.leading",
                        description: Text("Daily notes named YYYY-MM-DD will appear here.")
                    )
                } else {
                    List(svc.dailyNotes, selection: $selectedNote) { note in
                        DailyNoteListRow(note: note)
                            .tag(note)
                    }
                    .listStyle(.sidebar)
                }
            }
            .frame(minWidth: 180, idealWidth: 220, maxWidth: 280)

            // Right: note content
            if let note = selectedNote {
                DailyNoteDetailView(note: note)
            } else {
                ContentUnavailableView(
                    "Select a Note",
                    systemImage: "doc.text",
                    description: Text("Pick a daily note from the list.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            selectedNote = svc.dailyNotes.first
        }
        .navigationTitle("Daily Notes")
    }
}

private struct DailyNoteListRow: View {
    let note: Note

    private var displayDate: Date? {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.date(from: note.title)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            if let date = displayDate {
                Text(date.formatted(.dateTime.weekday(.wide)))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(date.formatted(.dateTime.month(.abbreviated).day().year()))
                    .font(.subheadline.bold())
            } else {
                Text(note.title).font(.subheadline)
            }

            HStack(spacing: 8) {
                if note.openTaskCount > 0 {
                    Label("\(note.openTaskCount)", systemImage: "checkmark.circle")
                        .font(.caption2)
                        .foregroundStyle(.blue)
                }
                Text("\(note.wordCount) words")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 2)
    }
}

private struct DailyNoteDetailView: View {
    let note: Note
    @State private var parsedContent: AttributedString = AttributedString()

    private var displayDate: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        if let date = f.date(from: note.title) {
            return date.formatted(date: .complete, time: .omitted)
        }
        return note.title
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(displayDate)
                        .font(.largeTitle.bold())
                    HStack(spacing: 12) {
                        Text("\(note.wordCount) words")
                        if note.openTaskCount > 0 {
                            Label("\(note.openTaskCount) open tasks", systemImage: "checkmark.circle")
                                .foregroundStyle(.blue)
                        }
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }

                Divider()

                Text(parsedContent)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(28)
        }
        .task(id: note.id) {
            parsedContent = (try? AttributedString(markdown: note.content,
                options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)))
                ?? AttributedString(note.content)
        }
    }
}
