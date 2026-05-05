import SwiftUI
import Combine
import WidgetKit

@MainActor
final class PluggieViewModel: ObservableObject {
    @Published private(set) var currentUsageSeconds: Int = 0
    @Published private(set) var dailyLimitSeconds: Int    = 3600
    @Published private(set) var isBlockingActive: Bool    = false

    private let service: any ScreenTimeServiceProtocol
    private weak var historyVM: HistoryViewModel?

    private var pollTimer: AnyCancellable?
    private var midnightObserver: Any?

    // Threshold flags — reset each day
    private var notifiedNearDeath = false
    private var notifiedDead      = false

    // CloudKit publish throttle
    private var lastCloudKitPublish = Date.distantPast

    // MARK: - Derived

    var healthPercent: Double {
        guard dailyLimitSeconds > 0 else { return 100 }
        return min(Double(currentUsageSeconds) / Double(dailyLimitSeconds) * 100, 100)
    }
    var mood: PluggieMood     { PluggieMood(healthPercent: healthPercent) }
    var isDead: Bool          { healthPercent >= 100 }
    var remainingSeconds: Int { max(0, dailyLimitSeconds - currentUsageSeconds) }

    // MARK: - Init

    init(service: any ScreenTimeServiceProtocol, historyVM: HistoryViewModel? = nil) {
        self.service    = service
        self.historyVM  = historyVM
        currentUsageSeconds = service.currentUsageSeconds
        dailyLimitSeconds   = service.dailyLimitSeconds
        startPolling()
        observeMidnight()
    }

    deinit {
        if let observer = midnightObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    // MARK: - Public

    func setDailyLimit(_ seconds: Int) {
        service.setDailyLimit(seconds)
        dailyLimitSeconds = seconds
        syncToSharedDefaults()
    }

    func setBlockingActive(_ active: Bool) {
        isBlockingActive = active
        AppGroupConstants.sharedDefaults.set(active,
            forKey: AppGroupConstants.UserDefaultsKeys.isBlockingActive)
    }

    func resetForNewDay() {
        let previousUsage = currentUsageSeconds
        let previousLimit = dailyLimitSeconds

        // Persist the day that just ended before zeroing usage
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        historyVM?.saveEndOfDay(
            date: yesterday,
            totalUsageSeconds: previousUsage,
            limitSeconds: previousLimit
        )

        currentUsageSeconds = 0
        notifiedNearDeath   = false
        notifiedDead        = false

        AppGroupConstants.sharedDefaults.set(0, forKey: AppGroupConstants.UserDefaultsKeys.currentUsageSeconds)
        AppGroupConstants.sharedDefaults.set(Date(), forKey: AppGroupConstants.UserDefaultsKeys.lastResetDate)
        syncToSharedDefaults()
    }

    // MARK: - Private – Polling

    private func startPolling() {
        pollTimer = Timer.publish(every: 0.5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                let newUsage = self.service.currentUsageSeconds
                if newUsage != self.currentUsageSeconds {
                    self.currentUsageSeconds = newUsage
                    self.syncToSharedDefaults()
                    self.checkHealthThresholds()
                }
            }
    }

    // MARK: - Private – Health Thresholds

    private func checkHealthThresholds() {
        let hp = healthPercent

        if hp >= 100 && !notifiedDead {
            notifiedDead = true
            triggerDeathSequence()
            return
        }

        if hp >= 90 && !notifiedNearDeath {
            notifiedNearDeath = true
            NotificationService.shared.fireNearDeathWarning(percent: Int(hp))
            HapticsService.shared.notifyWarning()
        }
    }

    private func triggerDeathSequence() {
        NotificationService.shared.fireDeath()
        HapticsService.shared.notifyDeath()
        Task { await CloudKitService.shared.broadcastDeath() }
    }

    // MARK: - Private – Midnight Reset

    private func observeMidnight() {
        midnightObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.significantTimeChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.checkMidnightReset()
            }
        }
        // Also check immediately at launch in case the app was backgrounded over midnight
        checkMidnightReset()
    }

    private func checkMidnightReset() {
        guard let lastReset = AppGroupConstants.sharedDefaults
                .object(forKey: AppGroupConstants.UserDefaultsKeys.lastResetDate) as? Date
        else {
            // First launch — store today as the last reset date
            AppGroupConstants.sharedDefaults.set(
                Date(), forKey: AppGroupConstants.UserDefaultsKeys.lastResetDate)
            return
        }

        let calendar = Calendar.current
        if !calendar.isDateInToday(lastReset) {
            resetForNewDay()
        }
    }

    // MARK: - Private – Shared Defaults + CloudKit Sync

    private func syncToSharedDefaults() {
        AppGroupConstants.sharedDefaults.set(healthPercent,
            forKey: AppGroupConstants.UserDefaultsKeys.currentHealthPercent)
        AppGroupConstants.sharedDefaults.set(currentUsageSeconds,
            forKey: AppGroupConstants.UserDefaultsKeys.currentUsageSeconds)
        AppGroupConstants.sharedDefaults.set(mood.rawValue,
            forKey: AppGroupConstants.UserDefaultsKeys.pluggieMoodRawValue)

        throttledCloudKitPublish()
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func throttledCloudKitPublish() {
        guard Date().timeIntervalSince(lastCloudKitPublish) > 60 else { return }
        lastCloudKitPublish = Date()
        let hp   = healthPercent
        let dead = isDead
        let name = AuthService.shared.currentUser?.displayName ?? "Anonymous"
        Task {
            try? await CloudKitService.shared.upsertMyEntry(
                healthPercent: hp,
                isDead: dead,
                displayName: name
            )
        }
    }
}
