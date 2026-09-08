import SwiftUI

struct EventRow: View {
    let event: CalendarEvent

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(event.type.color.opacity(0.15))
                    .frame(width: 34, height: 34)
                Image(systemName: event.type.icon)
                    .font(.footnote.bold())
                    .foregroundStyle(event.type.color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(.subheadline)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text(event.type.label)
                        .font(.caption)
                        .foregroundStyle(event.type.color)
                    Text("·")
                        .foregroundStyle(.tertiary)
                    Text(event.nextOccurrence.formatted(.dateTime.month(.abbreviated).day()))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            daysLabel
        }
    }

    @ViewBuilder
    private var daysLabel: some View {
        let days = event.daysUntilNextOccurrence
        Group {
            if days == 0 {
                Text("Today!")
                    .font(.caption.bold())
                    .foregroundStyle(.pink)
            } else if days == 1 {
                Text("Tomorrow")
                    .font(.caption.bold())
                    .foregroundStyle(.orange)
            } else if days <= 7 {
                Text("in \(days)d")
                    .font(.caption.bold())
                    .foregroundStyle(.orange)
            } else {
                Text("in \(days)d")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
