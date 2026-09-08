import SwiftUI

struct TasksView: View {
    @Environment(AppState.self) private var appState
    @State private var showCompleted = false
    @State private var searchText = ""
    @State private var sortOrder: SortOrder = .note

    private var svc: VaultService { appState.vaultService }

    enum SortOrder: String, CaseIterable {
        case note = "Note"
        case dueDate = "Due Date"
    }

    private var tasks: [ObsidianTask] {
        let base = showCompleted ? svc.completedTasks : svc.openTasks
        let filtered = searchText.isEmpty ? base : base.filter {
            $0.text.localizedCaseInsensitiveContains(searchText) ||
            $0.noteTitle.localizedCaseInsensitiveContains(searchText)
        }
        switch sortOrder {
        case .note:
            return filtered.sorted { $0.noteTitle < $1.noteTitle }
        case .dueDate:
            return filtered.sorted {
                switch ($0.dueDate, $1.dueDate) {
                case let (a?, b?): return a < b
                case (_?, nil):   return true
                case (nil, _?):   return false
                case (nil, nil):  return $0.noteTitle < $1.noteTitle
                }
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar strip
            HStack(spacing: 16) {
                Picker("", selection: $showCompleted) {
                    Text("Open  (\(svc.openTasks.count))").tag(false)
                    Text("Done  (\(svc.completedTasks.count))").tag(true)
                }
                .pickerStyle(.segmented)
                .frame(width: 260)

                Spacer()

                Picker("Sort", selection: $sortOrder) {
                    ForEach(SortOrder.allCases, id: \.self) { Text($0.rawValue) }
                }
                .pickerStyle(.menu)
                .frame(width: 120)

                HStack {
                    Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                    TextField("Search…", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(.background.tertiary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .frame(width: 200)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(.bar)

            Divider()

            if tasks.isEmpty {
                ContentUnavailableView(
                    showCompleted ? "No Completed Tasks" : "All Caught Up!",
                    systemImage: showCompleted ? "checkmark.circle" : "party.popper",
                    description: Text(showCompleted ? "Complete some tasks to see them here." : "No open tasks match your search.")
                )
            } else {
                List(tasks) { task in
                    TaskRow(task: task, compact: false)
                        .listRowSeparator(.visible)
                        .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Tasks")
    }
}
