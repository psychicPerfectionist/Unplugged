import XCTest
@testable import Unplugged

@MainActor
final class SettingsViewModelTests: XCTestCase {

    var vm: SettingsViewModel!
    var service: MockScreenTimeService!

    override func setUp() {
        super.setUp()
        // Reset all persisted state
        UserDefaults.standard.removeObject(forKey: "onboardingComplete")
        UserDefaults.standard.removeObject(forKey: "reminderItems")
        AuthService.shared.deleteAccount()

        service = MockScreenTimeService(limitSeconds: 3600, ticksPerSecond: 0)
        vm = SettingsViewModel(service: service)
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "onboardingComplete")
        UserDefaults.standard.removeObject(forKey: "reminderItems")
        AuthService.shared.deleteAccount()
        vm = nil
        service = nil
        super.tearDown()
    }

    // MARK: - Onboarding

    func testInitialOnboardingIsFalseWhenKeyMissing() {
        XCTAssertFalse(vm.isOnboardingComplete)
    }

    func testCompleteOnboardingSetsFlag() {
        vm.completeOnboarding()
        XCTAssertTrue(vm.isOnboardingComplete)
    }

    func testCompleteOnboardingPersistsToUserDefaults() {
        vm.completeOnboarding()
        XCTAssertTrue(UserDefaults.standard.bool(forKey: "onboardingComplete"))
    }

    func testNewVMReadsPersistedOnboardingState() {
        vm.completeOnboarding()
        let newVM = SettingsViewModel(service: service)
        XCTAssertTrue(newVM.isOnboardingComplete)
    }

    // MARK: - Authentication state

    func testInitialAuthenticationStateMatchesAuthService() {
        XCTAssertFalse(vm.isAuthenticated)
    }

    func testMarkAuthenticatedSetsFlag() {
        vm.markAuthenticated()
        XCTAssertTrue(vm.isAuthenticated)
    }

    func testSignOutClearsAuthenticationFlag() {
        vm.markAuthenticated()
        vm.signOut()
        XCTAssertFalse(vm.isAuthenticated)
    }

    // MARK: - Daily limit initialisation

    func testInitialDailyLimitMatchesService() {
        XCTAssertEqual(vm.dailyLimitSeconds, service.dailyLimitSeconds)
    }

    func testDailyLimitCanBeUpdated() {
        vm.dailyLimitSeconds = 7200
        XCTAssertEqual(vm.dailyLimitSeconds, 7200)
    }

    // MARK: - Delete account

    func testDeleteAccountClearsOnboardingFlag() {
        vm.completeOnboarding()
        vm.deleteAccount()
        XCTAssertFalse(vm.isOnboardingComplete)
    }

    func testDeleteAccountClearsAuthenticationFlag() {
        vm.markAuthenticated()
        vm.deleteAccount()
        XCTAssertFalse(vm.isAuthenticated)
    }

    func testDeleteAccountRemovesOnboardingFromUserDefaults() {
        vm.completeOnboarding()
        vm.deleteAccount()
        XCTAssertFalse(UserDefaults.standard.bool(forKey: "onboardingComplete"))
    }

    func testDeleteAccountRemovesRemindersFromUserDefaults() {
        let item = ReminderItem(id: "x", label: "Test", hour: 8, minute: 0)
        ReminderItem.saveAll([item])

        vm.deleteAccount()

        XCTAssertTrue(ReminderItem.loadAll().isEmpty)
    }

    func testDeleteAccountPreventsReloginViaAuthService() throws {
        _ = try AuthService.shared.signUp(displayName: "Test", email: "del@test.com", password: "pass")
        vm.markAuthenticated()
        vm.deleteAccount()

        XCTAssertFalse(AuthService.shared.isAuthenticated)
    }

    // MARK: - Notification interval

    func testDefaultNotificationIntervalIs30() {
        XCTAssertEqual(vm.notificationIntervalMinutes, 30)
    }

    func testNotificationIntervalCanBeUpdated() {
        vm.notificationIntervalMinutes = 60
        XCTAssertEqual(vm.notificationIntervalMinutes, 60)
    }
}
