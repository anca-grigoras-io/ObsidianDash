import SwiftUI

struct CalendarDashboardView: View {
    @Environment(AppState.self) private var appState
    @State private var displayedMonth = Date.now
    @State private var selectedDate: Date? = Date.now

    private var svc: VaultService { appState.vaultService }

    private var eventsOnSelectedDate: [CalendarEvent] {
        guard let date = selectedDate else { return [] }
        return svc.calendarEvents.filter { event in
            let cal = Calendar.current
            let ec = cal.dateComponents([.month, .day], from: event.originalDate)
            let dc = cal.dateComponents([.month, .day], from: date)
            return ec.month == dc.month && ec.day == dc.day
        }
    }

    private var eventsThisMonth: [CalendarEvent] {
        let cal = Calendar.current
        let month = cal.component(.month, from: displayedMonth)
        return svc.calendarEvents
            .filter { event in
                let comps = cal.dateComponents([.month], from: event.originalDate)
                return comps.month == month
            }
            .map { event in
                // return event with occurrence for the displayed year
                event
            }
            .sorted { $0.daysUntilNextOccurrence < $1.daysUntilNextOccurrence }
    }

    var body: some View {
        HSplitView {
            // Left: month calendar + month event list
            VStack(alignment: .leading, spacing: 0) {
                MonthCalendarView(
                    displayedMonth: $displayedMonth,
                    selectedDate: $selectedDate,
                    events: svc.calendarEvents
                )
                .padding(.horizontal, 16)
                .padding(.top, 16)

                Divider().padding(.top, 12)

                Text("This month")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 6)

                if eventsThisMonth.isEmpty {
                    Text("No events this month")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 16)
                } else {
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(eventsThisMonth) { event in
                                EventRow(event: event)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(.background.secondary, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                                    .padding(.horizontal, 12)
                            }
                        }
                        .padding(.bottom, 16)
                    }
                }

                Spacer()
            }
            .frame(minWidth: 280, idealWidth: 320, maxWidth: 360)

            // Right: selected-day events
            VStack(alignment: .leading, spacing: 0) {
                if let date = selectedDate {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(date.formatted(.dateTime.weekday(.wide).month(.wide).day().year()))
                            .font(.title2.bold())
                        Text("\(eventsOnSelectedDate.count) event\(eventsOnSelectedDate.count == 1 ? "" : "s")")
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .padding(.bottom, 16)
                }

                Divider()

                if eventsOnSelectedDate.isEmpty {
                    ContentUnavailableView(
                        "No Events",
                        systemImage: "calendar",
                        description: Text("No birthdays or anniversaries on this day.")
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(eventsOnSelectedDate) { event in
                                EventDetailCard(event: event)
                                    .padding(.horizontal, 20)
                            }
                        }
                        .padding(.vertical, 20)
                    }
                }
            }
        }
        .navigationTitle("Calendar")
    }
}

// MARK: - Month Calendar

private struct MonthCalendarView: View {
    @Binding var displayedMonth: Date
    @Binding var selectedDate: Date?
    let events: [CalendarEvent]

    private let cal = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 7)
    private let weekdaySymbols = ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]

    private var daysInGrid: [Date?] {
        guard let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: displayedMonth)),
              let range = cal.range(of: .day, in: .month, for: displayedMonth) else { return [] }

        let firstWeekday = cal.component(.weekday, from: monthStart)
        let offset = ((firstWeekday - 2) + 7) % 7
        var days: [Date?] = Array(repeating: nil, count: offset)

        for day in range {
            if let d = cal.date(byAdding: .day, value: day - 1, to: monthStart) {
                days.append(d)
            }
        }
        // Pad to full weeks
        while days.count % 7 != 0 { days.append(nil) }
        return days
    }

    private func eventCount(on date: Date) -> Int {
        events.filter { event in
            let ec = cal.dateComponents([.month, .day], from: event.originalDate)
            let dc = cal.dateComponents([.month, .day], from: date)
            return ec.month == dc.month && ec.day == dc.day
        }.count
    }

    var body: some View {
        VStack(spacing: 10) {
            // Month header
            HStack {
                Button { shift(-1) } label: {
                    Image(systemName: "chevron.left").font(.subheadline.bold())
                }
                .buttonStyle(.plain)

                Text(displayedMonth.formatted(.dateTime.month(.wide).year()))
                    .font(.headline)
                    .frame(maxWidth: .infinity)

                Button { shift(1) } label: {
                    Image(systemName: "chevron.right").font(.subheadline.bold())
                }
                .buttonStyle(.plain)
            }

            // Weekday header
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(weekdaySymbols, id: \.self) { day in
                    Text(day)
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Day cells
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(Array(daysInGrid.enumerated()), id: \.offset) { _, date in
                    if let date {
                        DayCell(
                            date: date,
                            isToday: cal.isDateInToday(date),
                            isSelected: selectedDate.map { cal.isDate($0, inSameDayAs: date) } ?? false,
                            eventCount: eventCount(on: date)
                        )
                        .onTapGesture { selectedDate = date }
                    } else {
                        Color.clear.frame(height: 38)
                    }
                }
            }
        }
    }

    private func shift(_ amount: Int) {
        if let d = cal.date(byAdding: .month, value: amount, to: displayedMonth) {
            displayedMonth = d
        }
    }
}

private struct DayCell: View {
    let date: Date
    let isToday: Bool
    let isSelected: Bool
    let eventCount: Int

    var body: some View {
        ZStack {
            Circle()
                .fill(isSelected ? Color.purple : isToday ? Color.purple.opacity(0.15) : Color.clear)
                .frame(width: 34, height: 34)

            VStack(spacing: 2) {
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.subheadline)
                    .foregroundStyle(isSelected ? .white : .primary)

                if eventCount > 0 {
                    HStack(spacing: 2) {
                        ForEach(0..<min(eventCount, 3), id: \.self) { _ in
                            Circle()
                                .fill(isSelected ? Color.white : Color.orange)
                                .frame(width: 4, height: 4)
                        }
                    }
                }
            }
        }
        .frame(height: 42)
        .contentShape(Rectangle())
    }
}

// MARK: - Event detail card

private struct EventDetailCard: View {
    let event: CalendarEvent

    private var yearsCount: Int? {
        let cal = Calendar.current
        let years = cal.dateComponents([.year], from: event.originalDate, to: Date()).year
        return years.map { $0 > 0 ? $0 + 1 : $0 }
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(event.type.color.opacity(0.15))
                    .frame(width: 52, height: 52)
                Image(systemName: event.type.icon)
                    .font(.title3.bold())
                    .foregroundStyle(event.type.color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.headline)
                Text(event.type.label)
                    .font(.subheadline)
                    .foregroundStyle(event.type.color)
                if let years = yearsCount, years > 0 {
                    Text("Turning \(years) this year")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(16)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
