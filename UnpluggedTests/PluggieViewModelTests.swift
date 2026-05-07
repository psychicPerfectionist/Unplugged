import XCTest
import Combine
@testable import Unplugged

/// Tests for PluggieViewModel's pure computed properties and state mutations.
/// Uses a frozen MockScreenTimeService (ticksPerSecond: 0) so no timer fires during tests.
/// All methods are async throws — required in Xcode 26 for @MainActor test classes so
/// XCTest's async runner properly awaits each invocation.
@MainActor
final class PluggieViewModelTests: XCTestCase {

    var vm: PluggieViewModel!
    var service: MockScreenTimeService!

    override func setUp() async throws {
        try await super.setUp()
        // Set lastResetDate to today so PluggieViewModel.init never triggers resetForNewDay()
        AppGroupConstants.sharedDefaults.set(
            Date(), forKey: AppGroupConstants.UserDefaultsKeys.lastResetDate)
        service = MockScreenTimeService(startUsageSeconds: 0, limitSeconds: 3600, ticksPerSecond: 0)
        vm = PluggieViewModel(service: service)
    }

    override func tearDown() async throws {
        vm = nil
        service = nil
        try await super.tearDown()
    }

    // MARK: - healthPercent

    func testHealthPercentIsZeroAtStart() async throws {
        XCTAssertEqual(vm.healthPercent, 0.0, accuracy: 0.001)
    }

    func testHealthPercentAt50PercentUsage() async throws {
        let s = MockScreenTimeService(startUsageSeconds: 1800, limitSeconds: 3600, ticksPerSecond: 0)
        let v = PluggieViewModel(service: s)
        XCTAssertEqual(v.healthPercent, 50.0, accuracy: 0.001)
    }

    func testHealthPercentAt100PercentUsage() async throws {
        let s = MockScreenTimeService(startUsageSeconds: 3600, limitSeconds: 3600, ticksPerSecond: 0)
        let v = PluggieViewModel(service: s)
        XCTAssertEqual(v.healthPercent, 100.0, accuracy: 0.001)
    }

    func testHealthPercentCappedAt100WhenUsageExceedsLimit() async throws {
        let s = MockScreenTimeService(startUsageSeconds: 5000, limitSeconds: 3600, ticksPerSecond: 0)
        let v = PluggieViewModel(service: s)
        XCTAssertEqual(v.healthPercent, 100.0, accuracy: 0.001)
    }

    func testHealthPercentIs100WhenLimitIsZero() async throws {
        // Guard clause: avoid division by zero
        vm.setDailyLimit(0)
        XCTAssertEqual(vm.healthPercent, 100.0)
    }

    // MARK: - isDead

    func testIsNotDeadAtZeroUsage() async throws {
        XCTAssertFalse(vm.isDead)
    }

    func testIsNotDeadBelow100Percent() async throws {
        let s = MockScreenTimeService(startUsageSeconds: 3599, limitSeconds: 3600, ticksPerSecond: 0)
        let v = PluggieViewModel(service: s)
        XCTAssertFalse(v.isDead)
    }

    func testIsDeadAtExactly100Percent() async throws {
        let s = MockScreenTimeService(startUsageSeconds: 3600, limitSeconds: 3600, ticksPerSecond: 0)
        let v = PluggieViewModel(service: s)
        XCTAssertTrue(v.isDead)
    }

    func testIsDeadWhenUsageExceedsLimit() async throws {
        let s = MockScreenTimeService(startUsageSeconds: 4000, limitSeconds: 3600, ticksPerSecond: 0)
        let v = PluggieViewModel(service: s)
        XCTAssertTrue(v.isDead)
    }

    // MARK: - remainingSeconds

    func testRemainingSecondsEqualsLimitAtStart() async throws {
        XCTAssertEqual(vm.remainingSeconds, 3600)
    }

    func testRemainingSecondsDecreasesWithUsage() async throws {
        let s = MockScreenTimeService(startUsageSeconds: 900, limitSeconds: 3600, ticksPerSecond: 0)
        let v = PluggieViewModel(service: s)
        XCTAssertEqual(v.remainingSeconds, 2700)
    }

    func testRemainingSecondsIsZeroWhenDead() async throws {
        let s = MockScreenTimeService(startUsageSeconds: 3600, limitSeconds: 3600, ticksPerSecond: 0)
        let v = PluggieViewModel(service: s)
        XCTAssertEqual(v.remainingSeconds, 0)
    }

    func testRemainingSecondsNeverGoesBelowZero() async throws {
        let s = MockScreenTimeService(startUsageSeconds: 9999, limitSeconds: 3600, ticksPerSecond: 0)
        let v = PluggieViewModel(service: s)
        XCTAssertEqual(v.remainingSeconds, 0)
    }

    // MARK: - mood

    func testMoodIsThrivingAtStart() async throws {
        XCTAssertEqual(vm.mood, .thriving)
    }

    func testMoodMatchesExpectedAtEachThreshold() async throws {
        let cases: [(usage: Int, limit: Int, expected: PluggieMood)] = [
            (0,    3600, .thriving),
            (800,  3600, .thriving),    // 22% used
            (900,  3600, .content),     // 25% used
            (1800, 3600, .worried),     // 50% used
            (2700, 3600, .struggling),  // 75% used
            (3240, 3600, .critical),    // 90% used
            (3600, 3600, .dead)         // 100% used
        ]
        for (usage, limit, expected) in cases {
            let s = MockScreenTimeService(startUsageSeconds: usage, limitSeconds: limit, ticksPerSecond: 0)
            let v = PluggieViewModel(service: s)
            XCTAssertEqual(v.mood, expected,
                           "Usage \(usage)/\(limit) should produce \(expected) but got \(v.mood)")
        }
    }

    // MARK: - setDailyLimit

    func testSetDailyLimitUpdatesViewModelProperty() async throws {
        vm.setDailyLimit(7200)
        XCTAssertEqual(vm.dailyLimitSeconds, 7200)
    }

    func testSetDailyLimitPropagatestoService() async throws {
        vm.setDailyLimit(7200)
        XCTAssertEqual(service.dailyLimitSeconds, 7200)
    }

    func testSetDailyLimitChangesHealthPercent() async throws {
        // With 0 usage and a new limit, healthPercent stays 0
        vm.setDailyLimit(7200)
        XCTAssertEqual(vm.healthPercent, 0.0, accuracy: 0.001)
    }

    // MARK: - setBlockingActive

    func testSetBlockingActiveTrueUpdatesFlag() async throws {
        vm.setBlockingActive(true)
        XCTAssertTrue(vm.isBlockingActive)
    }

    func testSetBlockingActiveFalseUpdatesFlag() async throws {
        vm.setBlockingActive(true)
        vm.setBlockingActive(false)
        XCTAssertFalse(vm.isBlockingActive)
    }

    func testBlockingStartsInactive() async throws {
        XCTAssertFalse(vm.isBlockingActive)
    }

    // MARK: - resetForNewDay

    func testResetForNewDayClearsUsage() async throws {
        let s = MockScreenTimeService(startUsageSeconds: 1800, limitSeconds: 3600, ticksPerSecond: 0)
        let v = PluggieViewModel(service: s)
        v.resetForNewDay()
        XCTAssertEqual(v.currentUsageSeconds, 0)
    }

    func testResetForNewDayRestoresFullHealth() async throws {
        let s = MockScreenTimeService(startUsageSeconds: 3600, limitSeconds: 3600, ticksPerSecond: 0)
        let v = PluggieViewModel(service: s)
        v.resetForNewDay()
        XCTAssertEqual(v.healthPercent, 0.0, accuracy: 0.001)
    }

    func testResetForNewDayRestoresThrivingMood() async throws {
        let s = MockScreenTimeService(startUsageSeconds: 3600, limitSeconds: 3600, ticksPerSecond: 0)
        let v = PluggieViewModel(service: s)
        v.resetForNewDay()
        XCTAssertEqual(v.mood, .thriving)
    }
}
