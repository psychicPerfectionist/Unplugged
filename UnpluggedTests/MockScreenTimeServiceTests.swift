import XCTest
@testable import Unplugged

final class MockScreenTimeServiceTests: XCTestCase {

    // MARK: - Initial State

    func testDefaultInitialUsageIsZero() {
        let service = MockScreenTimeService(ticksPerSecond: 0)
        XCTAssertEqual(service.currentUsageSeconds, 0)
    }

    func testCustomInitialUsage() {
        let service = MockScreenTimeService(startUsageSeconds: 500, limitSeconds: 3600, ticksPerSecond: 0)
        XCTAssertEqual(service.currentUsageSeconds, 500)
    }

    func testDefaultLimitIsOneHour() {
        let service = MockScreenTimeService(ticksPerSecond: 0)
        XCTAssertEqual(service.dailyLimitSeconds, 3600)
    }

    func testCustomLimit() {
        let service = MockScreenTimeService(limitSeconds: 7200, ticksPerSecond: 0)
        XCTAssertEqual(service.dailyLimitSeconds, 7200)
    }

    // MARK: - setDailyLimit

    func testSetDailyLimitUpdatesProperty() {
        let service = MockScreenTimeService(limitSeconds: 3600, ticksPerSecond: 0)
        service.setDailyLimit(7200)
        XCTAssertEqual(service.dailyLimitSeconds, 7200)
    }

    func testSetDailyLimitToZero() {
        let service = MockScreenTimeService(limitSeconds: 3600, ticksPerSecond: 0)
        service.setDailyLimit(0)
        XCTAssertEqual(service.dailyLimitSeconds, 0)
    }

    func testSetDailyLimitPreservesUsage() {
        let service = MockScreenTimeService(startUsageSeconds: 900, limitSeconds: 3600, ticksPerSecond: 0)
        service.setDailyLimit(7200)
        XCTAssertEqual(service.currentUsageSeconds, 900)
    }

    // MARK: - blockApps

    func testBlockAppsDoesNotCrash() {
        let service = MockScreenTimeService(ticksPerSecond: 0)
        service.blockApps(["com.example.SomeApp"])
    }

    func testBlockAppsWithEmptySet() {
        let service = MockScreenTimeService(ticksPerSecond: 0)
        service.blockApps([])
    }

    // MARK: - Protocol conformance

    func testConformsToScreenTimeServiceProtocol() {
        let service: any ScreenTimeServiceProtocol = MockScreenTimeService(ticksPerSecond: 0)
        XCTAssertNotNil(service)
    }

    func testProtocolCurrentUsageSecondsAccessible() {
        let service: any ScreenTimeServiceProtocol = MockScreenTimeService(
            startUsageSeconds: 300, limitSeconds: 3600, ticksPerSecond: 0)
        XCTAssertEqual(service.currentUsageSeconds, 300)
    }

    func testProtocolDailyLimitSecondsAccessible() {
        let service: any ScreenTimeServiceProtocol = MockScreenTimeService(
            limitSeconds: 1800, ticksPerSecond: 0)
        XCTAssertEqual(service.dailyLimitSeconds, 1800)
    }
}
