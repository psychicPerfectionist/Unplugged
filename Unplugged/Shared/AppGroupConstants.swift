import Foundation

enum AppGroupConstants {
    static let suiteName = "group.com.unplugged"

    enum UserDefaultsKeys {
        static let currentHealthPercent  = "currentHealthPercent"
        static let pluggieMoodRawValue   = "pluggieMoodRawValue"
        static let dailyLimitSeconds     = "dailyLimitSeconds"
        static let currentUsageSeconds   = "currentUsageSeconds"
        static let lastResetDate         = "lastResetDate"
        static let isBlockingActive      = "isBlockingActive"
        static let currentStreak         = "currentStreak"
        static let bestStreak            = "bestStreak"
    }

    static var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: suiteName) ?? .standard
    }
}
