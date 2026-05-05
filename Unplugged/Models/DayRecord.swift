import CoreData
import Foundation

@objc(DayRecord)
final class DayRecord: NSManagedObject, Identifiable {
    var id: NSManagedObjectID { objectID }
    @NSManaged var date: Date
    @NSManaged var totalUsageSeconds: Int64
    @NSManaged var limitSeconds: Int64
    @NSManaged var survived: Bool
}

@objc(StreakRecord)
final class StreakRecord: NSManagedObject {
    @NSManaged var currentStreak: Int32
    @NSManaged var bestStreak: Int32
    @NSManaged var lastUpdated: Date
}

@objc(UsageLog)
final class UsageLog: NSManagedObject {
    @NSManaged var timestamp: Date
    @NSManaged var durationSeconds: Int64
    @NSManaged var appBundleID: String?
}

@objc(UserSettings)
final class UserSettings: NSManagedObject {
    @NSManaged var dailyLimitSeconds: Int64
    @NSManaged var notificationInterval: Int16
    @NSManaged var isBiometricEnabled: Bool
    @NSManaged var blockedApps: NSArray?
}
