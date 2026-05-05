import UserNotifications
import Foundation

final class NotificationService: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationService()

    private override init() {}

    // MARK: - Permission

    @discardableResult
    func requestPermission() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        )) ?? false
    }

    // MARK: - Interval Reminder (legacy — used by Settings picker)

    /// Replaces any existing interval-based reminder with a new one.
    /// Pass 0 to cancel.
    func scheduleReminder(intervalMinutes: Int) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["com.unplugged.reminder"]
        )
        guard intervalMinutes > 0 else { return }

        let content = UNMutableNotificationContent()
        content.title = "Unplugged Reminder"
        content.body  = "Check in on Pluggie — how's your screen time today?"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(intervalMinutes * 60),
            repeats: true
        )
        UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: "com.unplugged.reminder", content: content, trigger: trigger)
        )
    }

    // MARK: - Time-of-Day Reminders

    func scheduleTimeOfDayReminder(_ item: ReminderItem) {
        let content = UNMutableNotificationContent()
        content.title = "Unplugged"
        content.body  = item.label.isEmpty ? "Check in on Pluggie — how's your screen time?" : item.label
        content.sound = .default

        var components    = DateComponents()
        components.hour   = item.hour
        components.minute = item.minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: item.notificationID, content: content, trigger: trigger)
        )
    }

    func cancelReminder(id: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }

    // MARK: - Health Threshold Notifications

    func fireNearDeathWarning(percent: Int) {
        let content = UNMutableNotificationContent()
        content.title = "⚠️ Pluggie is struggling!"
        content.body  = "You've used \(percent)% of your daily limit. Pluggie needs your help!"
        content.sound = .default
        content.interruptionLevel = .timeSensitive

        UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: "com.unplugged.nearDeath", content: content, trigger: nil)
        )
    }

    func fireDeath() {
        let content = UNMutableNotificationContent()
        content.title = "💀 Pluggie has died!"
        content.body  = "You exceeded your daily screen time limit. Your friends have been notified."
        content.sound = .defaultCritical
        content.interruptionLevel = .critical

        UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: "com.unplugged.death", content: content, trigger: nil)
        )
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
