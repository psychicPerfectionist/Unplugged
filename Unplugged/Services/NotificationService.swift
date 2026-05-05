import UserNotifications
import Foundation

final class NotificationService: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationService()

    private override init() {}

    func requestPermission() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        )) ?? false
    }

    /// Schedules a recurring reminder at the given interval.
    /// Pass 0 to cancel all pending reminders.
    func scheduleReminder(intervalMinutes: Int) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["com.unplugged.reminder"]
        )
        guard intervalMinutes > 0 else { return }

        let content = UNMutableNotificationContent()
        content.title = "Unplugged Reminder"
        content.body  = "Check your screen time usage."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(intervalMinutes * 60),
            repeats: true
        )
        let request = UNNotificationRequest(
            identifier: "com.unplugged.reminder",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    /// Fires immediately when usage hits ~90% of the daily limit.
    func fireNearDeathWarning(percent: Int) {
        let content = UNMutableNotificationContent()
        content.title = "⚠️ Pluggie is struggling!"
        content.body  = "You've used \(percent)% of your daily limit. Pluggie needs your help!"
        content.sound = .default
        content.interruptionLevel = .timeSensitive

        let request = UNNotificationRequest(
            identifier: "com.unplugged.nearDeath",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    /// Fires immediately when usage reaches 100% — Pluggie dies.
    func fireDeath() {
        let content = UNMutableNotificationContent()
        content.title = "💀 Pluggie has died!"
        content.body  = "You exceeded your daily screen time limit. Your friends have been notified."
        content.sound = UNNotificationSound.defaultCritical
        content.interruptionLevel = .critical

        let request = UNNotificationRequest(
            identifier: "com.unplugged.death",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Delegate

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
