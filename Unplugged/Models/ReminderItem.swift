import Foundation

struct ReminderItem: Identifiable, Codable {
    let id: String
    var label: String
    var hour: Int
    var minute: Int

    var notificationID: String { "com.unplugged.custom.\(id)" }

    var displayTime: String {
        let h12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
        let m   = String(format: "%02d", minute)
        return "\(h12):\(m) \(hour >= 12 ? "PM" : "AM")"
    }

    init(id: String = UUID().uuidString, label: String = "", hour: Int, minute: Int) {
        self.id     = id
        self.label  = label
        self.hour   = hour
        self.minute = minute
    }
}

extension ReminderItem {
    static func loadAll() -> [ReminderItem] {
        guard let data = UserDefaults.standard.data(forKey: "reminderItems"),
              let items = try? JSONDecoder().decode([ReminderItem].self, from: data)
        else { return [] }
        return items
    }

    static func saveAll(_ items: [ReminderItem]) {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: "reminderItems")
        }
    }
}
