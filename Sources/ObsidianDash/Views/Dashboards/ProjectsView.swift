import SwiftUI

struct ProjectsView: View {
    @Environment(AppState.self) private var appState
    @State private var groupBy: GroupBy = .folder
    @State private var searchText = ""
    @State private var selectedNote: Note?

    private var svc: VaultService { appState.vaultService }

    enum GroupBy: String, CaseIterable {
        case folder = "Folder"
        case tag    = "Tag"
    }

    private var groups: [(key: String, notes: [Note])] {
        let allNotes = searchText.isEmpty ? svc.notes : svc.notes.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
        }

        switch groupBy {
        case .folder:
            return Dictionary(grouping: allNotes) { note -> String in
                let top = note.folder.split(separator: "/").first.map(String.init)
                return top ?? (note.folder.isEmpty ? "Root" : note.folder)
            }
            .map { (key: $0.key.isEmpty ? "Root" : $0.key, notes: $0.value.sorted { $0.title < $1.title }) }
            .sorted { $0.key < $1.key }

        case .tag:
            var tagGroups: [String: [Note]] = [:]
            for note in allNotes {
                if note.tags.isEmpty {
                    tagGroups["(untagged)", default: []].append(note)
                } else {
                    for tag in note.tags {
                        tagGroups[tag, default: []].append(note)
                    }
                }
            }
            return tagGroups
                .map { (key: $0.key, notes: $0.value.sorted { $0.title < $1.title }) }
                .sorted { $0.key < $1.key }
        }
    }

    var body: some View {
        HSplitView {
            // Left: grouped note list
            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    HStack {
                        Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                        TextField("Search…", text: $searchText).textFieldStyle(.plain)
                    }
                    .padding(.horizontal, 8).padding(.vertical, 5)
                    .background(.background.tertiary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                    Picker("", selection: $groupBy) {
                        ForEach(GroupBy.allCases, id: \.self) { Text($0.rawValue) }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 140)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(.bar)

                Divider()

                List(selection: $selectedNote) {
                    ForEach(groups, id: \.key) { group in
                        Section {
                            ForEach(group.notes) { note in
                                NoteRow(note: note)
                                    .tag(note)
                            }
                        } header: {
                            HStack {
                                Text(group.key)
                                    .font(.caption.bold())
                                    .foregroundStyle(.secondary)
                                    .textCase(.uppercase)
                                Spacer()
                                Text("\(group.notes.count)")
                                    .font(.caption2.monospacedDigit())
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                }
                .listStyle(.sidebar)
            }
            .frame(minWidth: 220, idealWidth: 280, maxWidth: 360)

            // Right: note detail or placeholder
            if let note = selectedNote {
                NoteDetailView(note: note)
            } else {
                ContentUnavailableView("Select a Note", systemImage: "doc.text")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle("Projects")
    }
}

private struct NoteDetailView: View {
    let note: Note
    @State private var parsedContent: AttributedString = AttributedString()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(note.title)
                        .font(.largeTitle.bold())

                    HStack(spacing: 12) {
                        if !note.folder.isEmpty {
                            Label(note.folder, systemImage: "folder")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Text(note.modificationDate.formatted(date: .abbreviated, time: .shortened))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    if !note.tags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(note.tags, id: \.self) { tag in
                                    Text("#\(tag)")
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(.purple.opacity(0.1))
                                        .foregroundStyle(.purple)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }
                }

                if !note.tasks.isEmpty {
                    Divider()
                    Text("Tasks")
                        .font(.headline)
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(note.tasks) { task in
                            TaskRow(task: task, compact: false)
                        }
                    }
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
