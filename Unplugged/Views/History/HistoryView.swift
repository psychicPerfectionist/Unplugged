import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var vm: HistoryViewModel
    @State private var displayedMonth = Date()

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    streakRow
                    calendarGrid
                    if vm.records.isEmpty {
                        emptyState
                    }
                }
                .padding()
            }
            .navigationTitle("History")
            .onAppear { vm.load() }
            .sheet(item: $vm.selectedRecord) { record in
                DayDetailSheet(record: record)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text("No history yet")
                .font(.headline)
            Text("Each day you use the app, a record is saved here. Green means Pluggie survived, grey means he didn't.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.vertical, 24)
    }

    private var streakRow: some View {
        HStack(spacing: 16) {
            streakPill(label: "Current streak", value: "\(vm.currentStreak) days")
            streakPill(label: "Best streak",    value: "\(vm.bestStreak) days")
        }
    }

    private func streakPill(label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    private var calendarGrid: some View {
        VStack(spacing: 12) {
            monthHeader
            weekdayHeader
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(calendarDays, id: \.self) { date in
                    dayCellView(for: date)
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var monthHeader: some View {
        HStack {
            Button { changeMonth(by: -1) } label: {
                Image(systemName: "chevron.left")
            }
            Spacer()
            Text(displayedMonth, format: .dateTime.year().month(.wide))
                .font(.headline)
            Spacer()
            Button { changeMonth(by: 1) } label: {
                Image(systemName: "chevron.right")
            }
        }
    }

    private var weekdayHeader: some View {
        HStack {
            ForEach(["Su","Mo","Tu","We","Th","Fr","Sa"], id: \.self) { day in
                Text(day)
                    .font(.caption2.bold())
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    @ViewBuilder
    private func dayCellView(for date: Date?) -> some View {
        if let date {
            let record = vm.record(for: date)
            let isToday = calendar.isDateInToday(date)
            Button {
                if let record { vm.selectedRecord = record }
            } label: {
                VStack(spacing: 2) {
                    Text(date, format: .dateTime.day())
                        .font(.caption.bold())
                        .foregroundStyle(isToday ? .white : .primary)

                    Circle()
                        .fill(dotColor(for: record))
                        .frame(width: 6, height: 6)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(isToday ? Color.accentColor : Color.clear,
                            in: RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(dayAccessibilityLabel(date: date, record: record))
        } else {
            Color.clear.frame(maxWidth: .infinity)
        }
    }

    private func dotColor(for record: DayRecord?) -> Color {
        guard let record else { return .clear }
        return record.survived ? Color(hex: "#4CAF50") : Color(hex: "#9E9E9E")
    }

    private func dayAccessibilityLabel(date: Date, record: DayRecord?) -> String {
        let dayStr = date.formatted(.dateTime.month().day())
        if let record {
            return "\(dayStr): \(record.survived ? "survived" : "failed")"
        }
        return dayStr
    }

    private var calendarDays: [Date?] {
        guard let range = calendar.range(of: .day, in: .month, for: displayedMonth),
              let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth))
        else { return [] }

        let firstWeekday = calendar.component(.weekday, from: firstDay) - 1
        var days: [Date?] = Array(repeating: nil, count: firstWeekday)

        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDay) {
                days.append(date)
            }
        }
        return days
    }

    private func changeMonth(by value: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: value, to: displayedMonth) {
            displayedMonth = newMonth
        }
    }
}

#Preview {
    HistoryView()
        .environmentObject(HistoryViewModel())
}
