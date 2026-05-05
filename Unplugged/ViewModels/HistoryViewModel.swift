import Foundation
import CoreData
import Combine

@MainActor
final class HistoryViewModel: ObservableObject {
    @Published private(set) var records: [DayRecord] = []
    @Published private(set) var currentStreak: Int32 = 0
    @Published private(set) var bestStreak: Int32 = 0
    @Published var selectedRecord: DayRecord?

    private let context = CoreDataStack.shared.viewContext

    // MARK: - Load

    func load() {
        let request = NSFetchRequest<DayRecord>(entityName: "DayRecord")
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        records = (try? context.fetch(request)) ?? []
        loadStreak()
    }

    func record(for date: Date) -> DayRecord? {
        let calendar = Calendar.current
        return records.first { calendar.isDate($0.date, inSameDayAs: date) }
    }

    // MARK: - Save End of Day

    /// Persists one day's usage and updates streak counters.
    /// Called from PluggieViewModel.resetForNewDay() with the previous day's data.
    func saveEndOfDay(date: Date, totalUsageSeconds: Int, limitSeconds: Int) {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)

        // Fetch existing record for the day, or create a new one
        let request = NSFetchRequest<DayRecord>(entityName: "DayRecord")
        request.predicate = NSPredicate(
            format: "date >= %@ AND date < %@",
            dayStart as NSDate,
            calendar.date(byAdding: .day, value: 1, to: dayStart)! as NSDate
        )
        let entity = (try? context.fetch(request).first) ?? DayRecord(context: context)
        entity.date               = dayStart
        entity.totalUsageSeconds  = Int64(totalUsageSeconds)
        entity.limitSeconds       = Int64(limitSeconds)
        entity.survived           = totalUsageSeconds <= limitSeconds

        CoreDataStack.shared.save()
        recalculateStreak()
        load()
    }

    // MARK: - Streak Calculation

    private func recalculateStreak() {
        let request = NSFetchRequest<DayRecord>(entityName: "DayRecord")
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        guard let allRecords = try? context.fetch(request) else { return }

        let calendar = Calendar.current
        var current: Int32 = 0
        var best: Int32    = 0

        // Walk backward from yesterday counting consecutive survived days
        var expectedDate = calendar.startOfDay(
            for: calendar.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        )

        for record in allRecords {
            let recordDay = calendar.startOfDay(for: record.date)
            guard recordDay == expectedDate else { break }
            if record.survived {
                current += 1
                if current > best { best = current }
            } else {
                break
            }
            expectedDate = calendar.date(byAdding: .day, value: -1, to: expectedDate) ?? expectedDate
        }

        // Best streak is the max across all history (not just current run)
        best = max(best, loadBestStreak())

        // Persist to Core Data
        let streakRequest = NSFetchRequest<StreakRecord>(entityName: "StreakRecord")
        let streakEntity = (try? context.fetch(streakRequest).first) ?? StreakRecord(context: context)
        streakEntity.currentStreak = current
        streakEntity.bestStreak    = max(best, streakEntity.bestStreak)
        streakEntity.lastUpdated   = Date()
        CoreDataStack.shared.save()

        // Write to shared defaults for the widget
        AppGroupConstants.sharedDefaults.set(current, forKey: AppGroupConstants.UserDefaultsKeys.currentStreak)
        AppGroupConstants.sharedDefaults.set(streakEntity.bestStreak, forKey: AppGroupConstants.UserDefaultsKeys.bestStreak)

        currentStreak = current
        bestStreak    = streakEntity.bestStreak
    }

    private func loadBestStreak() -> Int32 {
        let request = NSFetchRequest<StreakRecord>(entityName: "StreakRecord")
        return (try? context.fetch(request).first)?.bestStreak ?? 0
    }

    private func loadStreak() {
        let request = NSFetchRequest<StreakRecord>(entityName: "StreakRecord")
        if let streak = try? context.fetch(request).first {
            currentStreak = streak.currentStreak
            bestStreak    = streak.bestStreak
        }
    }
}
