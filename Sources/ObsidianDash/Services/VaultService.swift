import SwiftUI
import AppKit

@MainActor
@Observable
final class VaultService {

    var notes: [Note] = []
    var isLoading = false
    var lastScanDate: Date?
    var errorMessage: String?

    var vaultURL: URL? {
        didSet {
            if let url = vaultURL {
                UserDefaults.standard.set(url.path, forKey: "vaultPath")
            } else {
                UserDefaults.standard.removeObject(forKey: "vaultPath")
            }
        }
    }

    var hasVault: Bool { vaultURL != nil }

    var openTasks: [ObsidianTask] {
        notes.flatMap(\.tasks).filter { !$0.isCompleted }
    }

    var completedTasks: [ObsidianTask] {
        notes.flatMap(\.tasks).filter(\.isCompleted)
    }

    var calendarEvents: [CalendarEvent] {
        notes.flatMap(\.calendarEvents)
    }

    var notesByFolder: [(folder: String, notes: [Note])] {
        let grouped = Dictionary(grouping: notes) { $0.folder }
        return grouped
            .map { (folder: $0.key, notes: $0.value.sorted { $0.title < $1.title }) }
            .sorted { $0.folder < $1.folder }
    }

    var dailyNotes: [Note] {
        notes.filter(\.isDailyNote)
            .sorted { $0.title > $1.title }
    }

    var allTags: [String: Int] {
        var counts: [String: Int] = [:]
        for note in notes {
            for tag in note.tags { counts[tag, default: 0] += 1 }
        }
        return counts
    }

    init() {
        if let saved = UserDefaults.standard.string(forKey: "vaultPath") {
            vaultURL = URL(filePath: saved)
        }
    }

    func selectVault() async {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.title = "Select Obsidian Vault"
        panel.message = "Choose your Obsidian vault folder"
        panel.prompt = "Select Vault"

        let result = await withCheckedContinuation { cont in
            panel.begin { cont.resume(returning: $0) }
        }

        if result == .OK, let url = panel.url {
            vaultURL = url
            await scanVault()
        }
    }

    func scanVault() async {
        guard let vaultURL else { return }
        isLoading = true
        errorMessage = nil

        let url = vaultURL
        let scanned: [Note] = await Task.detached(priority: .userInitiated) {
            (try? VaultScanner.scan(at: url)) ?? []
        }.value

        notes = scanned
        lastScanDate = Date()
        isLoading = false
    }
}

enum VaultScanner {
    static func scan(at vaultURL: URL) throws -> [Note] {
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(
            at: vaultURL,
            includingPropertiesForKeys: [.creationDateKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else { return [] }

        var notes: [Note] = []
        for case let url as URL in enumerator {
            guard url.pathExtension.lowercased() == "md" else { continue }
            guard !url.path.contains("/.obsidian/") else { continue }
            if let note = try? MarkdownParser.parseNote(at: url, vaultURL: vaultURL) {
                notes.append(note)
            }
        }
        return notes
    }
}
