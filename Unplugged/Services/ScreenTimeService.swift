import Combine
import Foundation
import SwiftUI

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Protocol
// ─────────────────────────────────────────────────────────────────────────────

protocol ScreenTimeServiceProtocol: AnyObject {
    var currentUsageSeconds: Int { get }
    var dailyLimitSeconds: Int { get }
    func setDailyLimit(_ seconds: Int)
    func blockApps(_ apps: Set<String>)
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Mock (Simulator)
// ─────────────────────────────────────────────────────────────────────────────

/// Ticks `ticksPerSecond` simulated seconds every real second.
/// Default 10× speed means a 1-hour limit exhausts in ~6 real minutes —
/// fast enough to walk through all Pluggie states in one session.
final class MockScreenTimeService: ScreenTimeServiceProtocol {
    private(set) var currentUsageSeconds: Int
    private(set) var dailyLimitSeconds: Int

    private let ticksPerSecond: Int
    private var blockedApps: Set<String> = []
    private var cancellable: AnyCancellable?

    init(
        startUsageSeconds: Int = 0,
        limitSeconds: Int = 3600,
        ticksPerSecond: Int = 10
    ) {
        self.currentUsageSeconds = startUsageSeconds
        self.dailyLimitSeconds   = limitSeconds
        self.ticksPerSecond      = ticksPerSecond
        startTicking()
    }

    func setDailyLimit(_ seconds: Int) {
        dailyLimitSeconds = seconds
    }

    func blockApps(_ apps: Set<String>) {
        blockedApps = apps
    }

    private func startTicking() {
        cancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self, self.blockedApps.isEmpty else { return }
                self.currentUsageSeconds = min(
                    self.currentUsageSeconds + self.ticksPerSecond,
                    self.dailyLimitSeconds
                )
            }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Real (Device with FamilyControls entitlement)
// ─────────────────────────────────────────────────────────────────────────────

/// Wraps DeviceActivity / ManagedSettings APIs.
/// These frameworks only activate on a real device with:
///   - com.apple.developer.family-controls entitlement
///   - FamilyControls.AuthorizationCenter approval at runtime
///
/// The DeviceActivityMonitor extension (separate process) writes
/// currentUsageSeconds into the shared App Group defaults; this service reads it.
final class RealScreenTimeService: ScreenTimeServiceProtocol {
    private(set) var currentUsageSeconds: Int = 0
    private(set) var dailyLimitSeconds: Int = 3600

    private var pollTimer: AnyCancellable?

    init() {
        dailyLimitSeconds = AppGroupConstants.sharedDefaults
            .integer(forKey: AppGroupConstants.UserDefaultsKeys.dailyLimitSeconds)
            .nonZeroOr(3600)
        startPollingSharedDefaults()
    }

    func setDailyLimit(_ seconds: Int) {
        dailyLimitSeconds = seconds
        AppGroupConstants.sharedDefaults.set(seconds,
            forKey: AppGroupConstants.UserDefaultsKeys.dailyLimitSeconds)
        // On a real device the DeviceActivitySchedule must also be updated.
        // scheduleDeviceActivity(limitSeconds: seconds)
    }

    func blockApps(_ apps: Set<String>) {
        // Requires ManagedSettings framework + FamilyControls entitlement.
        // On a real device:
        //   let store = ManagedSettingsStore()
        //   store.shield.applicationCategories = apps.isEmpty ? nil : .all()
        // App bundle IDs → ApplicationToken conversion is done via FamilyActivityPicker.
    }

    /// Request FamilyControls authorization at app launch on a real device.
    func requestAuthorization() async throws {
        #if !targetEnvironment(simulator)
        // Uncomment when FamilyControls entitlement is provisioned:
        // try await FamilyControls.AuthorizationCenter.shared.requestAuthorization(for: .individual)
        #endif
    }

    // MARK: - Private

    private func startPollingSharedDefaults() {
        // Poll shared App Group defaults every second so the UI stays in sync
        // with values written by the DeviceActivityMonitor extension.
        pollTimer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.updateFromSharedDefaults() }
    }

    private func updateFromSharedDefaults() {
        currentUsageSeconds = AppGroupConstants.sharedDefaults
            .integer(forKey: AppGroupConstants.UserDefaultsKeys.currentUsageSeconds)
    }
}

private extension Int {
    func nonZeroOr(_ fallback: Int) -> Int { self == 0 ? fallback : self }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Environment
// ─────────────────────────────────────────────────────────────────────────────

private enum ScreenTimeServiceKey: EnvironmentKey {
    static let defaultValue: any ScreenTimeServiceProtocol = MockScreenTimeService()
}

extension EnvironmentValues {
    var screenTimeService: any ScreenTimeServiceProtocol {
        get { self[ScreenTimeServiceKey.self] }
        set { self[ScreenTimeServiceKey.self] = newValue }
    }
}
