import Foundation

struct FriendEntry: Identifiable, Comparable {
    var id: String
    var displayName: String
    var healthPercent: Double
    var isDead: Bool
    var iCloudRecordID: String

    var mood: PluggieMood { PluggieMood(healthPercent: healthPercent) }

    static func < (lhs: FriendEntry, rhs: FriendEntry) -> Bool {
        if lhs.isDead != rhs.isDead { return !lhs.isDead }
        return lhs.healthPercent < rhs.healthPercent
    }
}
