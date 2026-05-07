import XCTest
@testable import Unplugged

@MainActor
final class SettingsViewModelTests: XCTestCase {

    var vm: SettingsViewModel!
    var service: MockScreenTimeService!

    override func setUp() async throws {
        try await super.setUp()
        UserDefaults.standard.removeObject(forKey: "onboardingComplete")
        UserDefaults.standard.removeObject(forKey: "reminderItems")
        AuthService.shared.deleteAccount()

        service = MockScreenTimeService(limitSeconds: 3600, ticksPerSecond: 0)
        vm = SettingsViewModel(service: service)
    }

    override func tearDown() async throws {
        UserDefaults.standard.removeObject(forKey: "onboardingComplete")
        UserDefaults.standard.removeObject(forKey: "reminderItems")
        AuthService.shared.deleteAccount()
        vm = nil
        service = nil
        try await super.tearDown()
    }

    // MARK: - Onboarding

    func testInitialOnboardingIsFalseWhenKeyMissing() async throws {
        XCTAssertFalse(vm.isOnboardingComplete)
    }

    func testCompleteOnboardingSetsFlag() async throws {
        vm.completeOnboarding()
        XCTAssertTrue(vm.isOnboardingComplete)
    }

    func testCompleteOnboardingPersistsToUserDefaults() async throws {
        vm.completeOnboarding()
        XCTAssertTrue(UserDefaults.standard.bool(forKey: "onboardingComplete"))
    }

    func testNewVMReadsPersistedOnboardingState() async throws {
        vm.completeOnboarding()
        let newVM = SettingsViewModel(service: service)
        XCTAssertTrue(newVM.isOnboardingComplete)
    }

    // MARK: - Authentication state

    func testInitialAuthenticationStateMatchesAuthService() async throws {
        XCTAssertFalse(vm.isAuthenticated)
    }

    func testMarkAuthenticatedSetsFlag() async throws {
        vm.markAuthenticated()
        XCTAssertTrue(vm.isAuthenticated)
    }

    func testSignOutClearsAuthenticationFlag() async throws {
        vm.markAuthenticated()
        vm.signOut()
        XCTAssertFalse(vm.isAuthenticated)
    }

    // MARK: - Daily limit initialisation

    func testInitialDailyLimitMatchesService() async throws {
        XCTAssertEqual(vm.dailyLimitSeconds, service.dailyLimitSeconds)
    }

    func testDailyLimitCanBeUpdated() async throws {
        vm.dailyLimitSeconds = 7200
        XCTAssertEqual(vm.dailyLimitSeconds, 7200)
    }

    // MARK: - Delete account

    func testDeleteAccountClearsOnboardingFlag() async throws {
        vm.completeOnboarding()
        vm.deleteAccount()
        XCTAssertFalse(vm.isOnboardingComplete)
    }

    func testDeleteAccountClearsAuthenticationFlag() async throws {
        vm.markAuthenticated()
        vm.deleteAccount()
        XCTAssertFalse(vm.isAuthenticated)
    }

    func testDeleteAccountRemovesOnboardingFromUserDefaults() async throws {
        vm.completeOnboarding()
        vm.deleteAccount()
        XCTAssertFalse(UserDefaults.standard.bool(forKey: "onboardingComplete"))
    }

    func testDeleteAccountRemovesRemindersFromUserDefaults() async throws {
        let item = ReminderItem(id: "x", label: "Test", hour: 8, minute: 0)
        ReminderItem.saveAll([item])

        vm.deleteAccount()

        XCTAssertTrue(ReminderItem.loadAll().isEmpty)
    }

    func testDeleteAccountPreventsReloginViaAuthService() async throws {
        _ = try AuthService.shared.signUp(displayName: "Test", email: "del@test.com", password: "pass")
        vm.markAuthenticated()
        vm.deleteAccount()

        XCTAssertFalse(AuthService.shared.isAuthenticated)
    }

    // MARK: - Notification interval

    func testDefaultNotificationIntervalIs30() async throws {
        XCTAssertEqual(vm.notificationIntervalMinutes, 30)
    }

    func testNotificationIntervalCanBeUpdated() async throws {
        vm.notificationIntervalMinutes = 60
        XCTAssertEqual(vm.notificationIntervalMinutes, 60)
    }
}
