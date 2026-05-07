import XCTest
import CoreData
@testable import Unplugged

/// Tests for HistoryViewModel streak logic and Core Data persistence.
/// Runs inside the app's test host so CoreDataStack.shared is available.
/// Each test clears the database in setUp/tearDown for isolation.
@MainActor
final class HistoryViewModelTests: XCTestCase {

    var vm: HistoryViewModel!

    override func setUp() async throws {
        try await super.setUp()
        CoreDataStack.shared.deleteAllData()
        vm = HistoryViewModel()
        vm.load()
    }

    override func tearDown() async throws {
        CoreDataStack.shared.deleteAllData()
        vm = nil
        try await super.tearDown()
    }

    // MARK: - Helpers

    private func date(daysAgo: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!
    }

    private func saveDay(daysAgo: Int, usage: Int, limit: Int = 3600) {
        vm.saveEndOfDay(date: date(daysAgo: daysAgo),
                        totalUsageSeconds: usage,
                        limitSeconds: limit)
    }

    // MARK: - Load

    func testInitialRecordsIsEmpty() async throws {
        XCTAssertTrue(vm.records.isEmpty)
    }

    func testInitialCurrentStreakIsZero() async throws {
        XCTAssertEqual(vm.currentStreak, 0)
    }

    func testInitialBestStreakIsZero() async throws {
        XCTAssertEqual(vm.bestStreak, 0)
    }

    // MARK: - saveEndOfDay

    func testSaveCreatesRecord() async throws {
        saveDay(daysAgo: 1, usage: 1800)
        vm.load()
        XCTAssertEqual(vm.records.count, 1)
    }

    func testSaveMarksAsSurvivedWhenUnderLimit() async throws {
        saveDay(daysAgo: 1, usage: 1800, limit: 3600)
        vm.load()
        XCTAssertTrue(vm.records.first?.survived ?? false)
    }

    func testSaveMarksAsFailedWhenOverLimit() async throws {
        saveDay(daysAgo: 1, usage: 4000, limit: 3600)
        vm.load()
        XCTAssertFalse(vm.records.first?.survived ?? true)
    }

    func testSaveAtExactLimitCountsAsSurvived() async throws {
        saveDay(daysAgo: 1, usage: 3600, limit: 3600)
        vm.load()
        XCTAssertTrue(vm.records.first?.survived ?? false)
    }

    func testSavePreservesUsageSeconds() async throws {
        saveDay(daysAgo: 1, usage: 2500)
        vm.load()
        XCTAssertEqual(vm.records.first?.totalUsageSeconds, 2500)
    }

    func testSavePreservesLimitSeconds() async throws {
        saveDay(daysAgo: 1, usage: 1800, limit: 5400)
        vm.load()
        XCTAssertEqual(vm.records.first?.limitSeconds, 5400)
    }

    func testSaveOnSameDayUpdatesExistingRecord() async throws {
        saveDay(daysAgo: 1, usage: 1800)
        saveDay(daysAgo: 1, usage: 2400)  // overwrite
        vm.load()
        XCTAssertEqual(vm.records.count, 1)
        XCTAssertEqual(vm.records.first?.totalUsageSeconds, 2400)
    }

    // MARK: - record(for:)

    func testRecordForDateReturnsNilWhenEmpty() async throws {
        XCTAssertNil(vm.record(for: date(daysAgo: 1)))
    }

    func testRecordForDateFindsExistingRecord() async throws {
        let target = date(daysAgo: 1)
        saveDay(daysAgo: 1, usage: 1800)
        vm.load()
        XCTAssertNotNil(vm.record(for: target))
    }

    func testRecordForDateReturnsNilForDifferentDate() async throws {
        saveDay(daysAgo: 2, usage: 1800)
        vm.load()
        XCTAssertNil(vm.record(for: date(daysAgo: 99)))
    }

    // MARK: - Streak: current streak

    func testCurrentStreakIsOneAfterOneSurvivedYesterday() async throws {
        saveDay(daysAgo: 1, usage: 1800)
        XCTAssertEqual(vm.currentStreak, 1)
    }

    func testCurrentStreakIsZeroAfterOneFailedYesterday() async throws {
        saveDay(daysAgo: 1, usage: 4000)
        XCTAssertEqual(vm.currentStreak, 0)
    }

    func testCurrentStreakCountsThreeConsecutiveSurvivedDays() async throws {
        saveDay(daysAgo: 1, usage: 1800)
        saveDay(daysAgo: 2, usage: 1800)
        saveDay(daysAgo: 3, usage: 1800)
        XCTAssertEqual(vm.currentStreak, 3)
    }

    func testCurrentStreakBreaksOnFailedDay() async throws {
        saveDay(daysAgo: 1, usage: 1800)   // survived
        saveDay(daysAgo: 2, usage: 4000)   // failed — breaks streak
        saveDay(daysAgo: 3, usage: 1800)   // survived (before break)
        XCTAssertEqual(vm.currentStreak, 1)
    }

    func testCurrentStreakIsZeroWhenOnlyTodaySaved() async throws {
        // Records for "today" (daysAgo: 0) should not count toward yesterday's streak
        vm.saveEndOfDay(date: Date(), totalUsageSeconds: 1800, limitSeconds: 3600)
        // Streak counts backward from yesterday; today's record doesn't match expectedDate
        XCTAssertEqual(vm.currentStreak, 0)
    }

    func testCurrentStreakBreaksOnMissingDay() async throws {
        // Gap at daysAgo: 2 means streak stops after daysAgo: 1
        saveDay(daysAgo: 1, usage: 1800)
        saveDay(daysAgo: 3, usage: 1800)   // day 2 is missing
        XCTAssertEqual(vm.currentStreak, 1)
    }

    // MARK: - Streak: best streak

    func testBestStreakMatchesCurrentStreakWhenNoPreviousBest() async throws {
        saveDay(daysAgo: 1, usage: 1800)
        saveDay(daysAgo: 2, usage: 1800)
        XCTAssertGreaterThanOrEqual(vm.bestStreak, 2)
    }

    func testBestStreakIsPreservedAfterStreakBreaks() async throws {
        // Build a streak of 3
        saveDay(daysAgo: 1, usage: 1800)
        saveDay(daysAgo: 2, usage: 1800)
        saveDay(daysAgo: 3, usage: 1800)
        let bestAfterStreak = vm.bestStreak

        // Re-initialise with a new VM (simulates restart with same Core Data)
        vm = HistoryViewModel()
        vm.load()

        // Now save a failed day (breaks future streak)
        saveDay(daysAgo: 1, usage: 4000)

        // Best streak should still reflect the historic high
        XCTAssertGreaterThanOrEqual(vm.bestStreak, bestAfterStreak)
    }
}
