import SwiftUI

struct TaskRow: View {
    let task: ObsidianTask
    var compact: Bool = false

    var body: some View {
        HStack(alignment: compact ? .center : .top, spacing: 10) {
            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(compact ? .subheadline : .body)
                .foregroundStyle(task.isCompleted ? .green : task.isOverdue ? .red : .secondary)

            VStack(alignment: .leading, spacing: compact ? 0 : 4) {
                Text(task.text)
                    .font(compact ? .subheadline : .body)
                    .strikethrough(task.isCompleted, color: .secondary)
                    .foregroundStyle(task.isCompleted ? .secondary : .primary)
                    .lineLimit(compact ? 1 : 4)

                if !compact {
                    HStack(spacing: 10) {
                        Label(task.noteTitle, systemImage: "doc.text")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)

                        if let due = task.dueDate {
                            Label(due.formatted(date: .abbreviated, time: .omitted),
                                  systemImage: "calendar")
                                .font(.caption)
                                .foregroundStyle(task.isOverdue ? .red : .secondary)
                        }
                    }
                }
            }

            Spacer()
        }
    }
}
