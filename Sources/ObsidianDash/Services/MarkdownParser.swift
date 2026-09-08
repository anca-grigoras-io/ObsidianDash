import Foundation

enum MarkdownParser {

    // MARK: - Entry point

    static func parseNote(at url: URL, vaultURL: URL) throws -> Note {
        let raw = try String(contentsOf: url, encoding: .utf8)
        let (fm, body) = parseFrontmatter(from: raw)

        let fileName = url.deletingPathExtension().lastPathComponent
        let title = fm["title"] ?? fileName

        let relativePath = url.path.replacingOccurrences(of: vaultURL.path, with: "")
        let components = relativePath
            .split(separator: "/")
            .map(String.init)
        let folder = components.dropLast().joined(separator: "/")

        let fmTags = parseTags(from: fm)
        let inlineTags = extractInlineTags(from: body)
        let tags = Array(Set(fmTags + inlineTags)).sorted()

        let tasks = parseTasks(from: body, noteURL: url, noteTitle: title)
        let events = parseCalendarEvents(from: fm, noteURL: url, noteTitle: title)

        let attrs = try? FileManager.default.attributesOfItem(atPath: url.path)
        let created = attrs?[.creationDate] as? Date ?? Date()
        let modified = attrs?[.modificationDate] as? Date ?? Date()

        return Note(
            id: UUID(),
            url: url,
            title: title,
            content: body,
            frontmatter: fm,
            tags: tags,
            tasks: tasks,
            calendarEvents: events,
            creationDate: created,
            modificationDate: modified,
            folder: folder
        )
    }

    // MARK: - Frontmatter

    static func parseFrontmatter(from content: String) -> (frontmatter: [String: String], body: String) {
        let lines = content.components(separatedBy: "\n")
        guard lines.first?.trimmingCharacters(in: .whitespaces) == "---" else {
            return ([:], content)
        }

        var closeIndex = -1
        for i in 1..<lines.count {
            if lines[i].trimmingCharacters(in: .whitespaces) == "---" {
                closeIndex = i
                break
            }
        }
        guard closeIndex > 0 else { return ([:], content) }

        let fmLines = Array(lines[1..<closeIndex])
        let body = lines[(closeIndex + 1)...].joined(separator: "\n")

        var result: [String: String] = [:]
        var idx = 0

        while idx < fmLines.count {
            let line = fmLines[idx]
            guard let colon = line.firstIndex(of: ":") else { idx += 1; continue }

            let key = String(line[..<colon]).trimmingCharacters(in: .whitespaces)
            let rawVal = String(line[line.index(after: colon)...]).trimmingCharacters(in: .whitespaces)

            if rawVal.isEmpty {
                // Possible list on following lines
                var items: [String] = []
                var j = idx + 1
                while j < fmLines.count {
                    let next = fmLines[j].trimmingCharacters(in: .whitespaces)
                    if next.hasPrefix("- ") {
                        items.append(String(next.dropFirst(2)).trimmingCharacters(in: .whitespaces))
                        j += 1
                    } else { break }
                }
                result[key] = items.joined(separator: ",")
                idx = j
            } else if rawVal.hasPrefix("[") && rawVal.hasSuffix("]") {
                let inner = rawVal.dropFirst().dropLast()
                let items = inner.components(separatedBy: ",")
                    .map { $0.trimmingCharacters(in: .whitespaces).trimmingCharacters(in: CharacterSet(charactersIn: "\"'")) }
                result[key] = items.joined(separator: ",")
                idx += 1
            } else {
                result[key] = rawVal.trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
                idx += 1
            }
        }

        return (result, body)
    }

    // MARK: - Tags

    private static func parseTags(from fm: [String: String]) -> [String] {
        guard let raw = fm["tags"] else { return [] }
        return raw.components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    private static func extractInlineTags(from body: String) -> [String] {
        let pattern = #"(?<![/\w])#([a-zA-Z][a-zA-Z0-9_/-]*)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let range = NSRange(body.startIndex..., in: body)
        return regex.matches(in: body, range: range).compactMap { match in
            guard let r = Range(match.range(at: 1), in: body) else { return nil }
            return String(body[r])
        }
    }

    // MARK: - Tasks

    static func parseTasks(from body: String, noteURL: URL, noteTitle: String) -> [ObsidianTask] {
        var tasks: [ObsidianTask] = []
        for line in body.components(separatedBy: "\n") {
            let t = line.trimmingCharacters(in: .whitespaces)
            guard t.hasPrefix("- [") && t.count > 5 else { continue }
            let marker = t.prefix(5)
            guard marker == "- [ ]" || marker == "- [x]" || marker == "- [X]" else { continue }
            let isCompleted = marker != "- [ ]"
            let text = String(t.dropFirst(6)).trimmingCharacters(in: .whitespaces)
            tasks.append(ObsidianTask(
                id: UUID(),
                text: text,
                isCompleted: isCompleted,
                noteURL: noteURL,
                noteTitle: noteTitle,
                dueDate: extractDueDate(from: text)
            ))
        }
        return tasks
    }

    private static func extractDueDate(from text: String) -> Date? {
        let patterns = [
            #"📅\s*(\d{4}-\d{2}-\d{2})"#,
            #"due:\s*(\d{4}-\d{2}-\d{2})"#,
            #"\[due::\s*(\d{4}-\d{2}-\d{2})\]"#
        ]
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               let range = Range(match.range(at: 1), in: text) {
                return formatter.date(from: String(text[range]))
            }
        }
        return nil
    }

    // MARK: - Calendar events

    static func parseCalendarEvents(from fm: [String: String], noteURL: URL, noteTitle: String) -> [CalendarEvent] {
        var events: [CalendarEvent] = []

        let dateKeys: [(String, CalendarEvent.EventType)] = [
            ("birthday", .birthday),
            ("dob", .birthday),
            ("date_of_birth", .birthday),
            ("born", .birthday),
            ("anniversary", .anniversary),
            ("wedding_anniversary", .anniversary),
            ("work_anniversary", .workAnniversary),
        ]

        for (key, type) in dateKeys {
            if let val = fm[key], let date = parseDate(val) {
                events.append(CalendarEvent(
                    id: UUID(),
                    title: noteTitle,
                    type: type,
                    originalDate: date,
                    noteURL: noteURL,
                    noteTitle: noteTitle
                ))
            }
        }

        return events
    }

    private static func parseDate(_ string: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        for format in ["yyyy-MM-dd", "dd/MM/yyyy", "MM/dd/yyyy", "yyyy/MM/dd"] {
            formatter.dateFormat = format
            if let d = formatter.date(from: string) { return d }
        }
        return nil
    }
}
