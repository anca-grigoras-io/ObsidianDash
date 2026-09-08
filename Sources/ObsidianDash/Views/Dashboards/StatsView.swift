import SwiftUI
import Charts

struct StatsView: View {
    @Environment(AppState.self) private var appState

    private var svc: VaultService { appState.vaultService }

    // Notes per top-level folder
    private var folderCounts: [(name: String, count: Int)] {
        svc.notesByFolder
            .map { entry in
                let top = entry.folder.split(separator: "/").first.map(String.init) ?? entry.folder
                let display = top.isEmpty ? "Root" : top
                return (name: display, count: entry.notes.count)
            }
            .reduce(into: [(name: String, count: Int)]()) { result, item in
                if let idx = result.firstIndex(where: { $0.name == item.name }) {
                    result[idx].count += item.count
                } else {
                    result.append(item)
                }
            }
            .sorted { $0.count > $1.count }
            .prefix(8)
            .map { $0 }
    }

    // Top tags
    private var topTags: [(tag: String, count: Int)] {
        svc.allTags
            .sorted { $0.value > $1.value }
            .prefix(10)
            .map { (tag: $0.key, count: $0.value) }
    }

    // Notes created per month (last 6 months)
    private var notesPerMonth: [(month: String, count: Int)] {
        let cal = Calendar.current
        let now = Date()
        var buckets: [String: Int] = [:]
        for offset in (0..<6).reversed() {
            if let date = cal.date(byAdding: .month, value: -offset, to: now) {
                let key = date.formatted(.dateTime.year().month(.twoDigits))
                buckets[key] = 0
            }
        }
        for note in svc.notes {
            let key = note.creationDate.formatted(.dateTime.year().month(.twoDigits))
            if buckets[key] != nil { buckets[key]! += 1 }
        }
        return buckets.keys.sorted().map { (month: $0, count: buckets[$0]!) }
    }

    // Task completion
    private var openCount: Int  { svc.openTasks.count }
    private var doneCount: Int  { svc.completedTasks.count }
    private var totalTaskCount: Int { openCount + doneCount }

    var body: some View {
        ScrollView {
            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)],
                spacing: 14
            ) {
                // Notes by folder
                DashboardCard(title: "Notes by Folder", icon: "chart.bar.xaxis", color: .indigo) {
                    if folderCounts.isEmpty {
                        Text("No notes yet").foregroundStyle(.secondary)
                    } else {
                        Chart(folderCounts, id: \.name) { item in
                            BarMark(
                                x: .value("Folder", item.name),
                                y: .value("Notes", item.count)
                            )
                            .foregroundStyle(Color.indigo.gradient)
                            .cornerRadius(4)
                        }
                        .chartXAxis {
                            AxisMarks(values: .automatic) { _ in
                                AxisValueLabel().font(.caption2)
                            }
                        }
                        .frame(height: 180)
                    }
                }

                // Task completion donut
                DashboardCard(title: "Task Completion", icon: "chart.pie.fill", color: .blue) {
                    if totalTaskCount == 0 {
                        Text("No tasks found").foregroundStyle(.secondary)
                    } else {
                        HStack(spacing: 24) {
                            Chart {
                                SectorMark(angle: .value("Done", doneCount), innerRadius: .ratio(0.6))
                                    .foregroundStyle(Color.green.gradient)
                                SectorMark(angle: .value("Open", openCount), innerRadius: .ratio(0.6))
                                    .foregroundStyle(Color.blue.opacity(0.3).gradient)
                            }
                            .frame(width: 120, height: 120)

                            VStack(alignment: .leading, spacing: 10) {
                                legendItem(color: .green, label: "Done", count: doneCount)
                                legendItem(color: .blue.opacity(0.5), label: "Open", count: openCount)
                                if totalTaskCount > 0 {
                                    Text("\(Int(Double(doneCount) / Double(totalTaskCount) * 100))% complete")
                                        .font(.caption.bold())
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 4)
                    }
                }

                // Notes created over time
                DashboardCard(title: "Notes Created (6 months)", icon: "chart.line.uptrend.xyaxis", color: .teal) {
                    if notesPerMonth.allSatisfy({ $0.count == 0 }) {
                        Text("No notes in this period").foregroundStyle(.secondary)
                    } else {
                        Chart(notesPerMonth, id: \.month) { item in
                            LineMark(
                                x: .value("Month", item.month),
                                y: .value("Notes", item.count)
                            )
                            .foregroundStyle(Color.teal.gradient)
                            .interpolationMethod(.catmullRom)
                            AreaMark(
                                x: .value("Month", item.month),
                                y: .value("Notes", item.count)
                            )
                            .foregroundStyle(Color.teal.opacity(0.12).gradient)
                            .interpolationMethod(.catmullRom)
                        }
                        .chartXAxis {
                            AxisMarks(values: .automatic) { _ in
                                AxisValueLabel().font(.caption2)
                            }
                        }
                        .frame(height: 160)
                    }
                }

                // Top tags
                DashboardCard(title: "Top Tags", icon: "tag.fill", color: .purple) {
                    if topTags.isEmpty {
                        Text("No tags found").foregroundStyle(.secondary)
                    } else {
                        Chart(topTags, id: \.tag) { item in
                            BarMark(
                                x: .value("Count", item.count),
                                y: .value("Tag", "#\(item.tag)")
                            )
                            .foregroundStyle(Color.purple.gradient)
                            .cornerRadius(4)
                        }
                        .chartXAxis {
                            AxisMarks { _ in AxisValueLabel().font(.caption2) }
                        }
                        .frame(height: 200)
                    }
                }
            }
            .padding(20)
        }
        .navigationTitle("Statistics")
    }

    private func legendItem(color: Color, label: String, count: Int) -> some View {
        HStack(spacing: 8) {
            Circle().fill(color).frame(width: 10, height: 10)
            Text(label).font(.caption).foregroundStyle(.secondary)
            Spacer()
            Text("\(count)").font(.caption.monospacedDigit())
        }
    }
}
