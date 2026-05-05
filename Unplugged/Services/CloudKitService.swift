import CloudKit
import Foundation

final class CloudKitService {
    static let shared = CloudKitService()

    private let container = CKContainer.default()
    private var publicDB: CKDatabase { container.publicCloudDatabase }
    private var privateDB: CKDatabase { container.privateCloudDatabase }

    private init() {}

    // MARK: - Leaderboard Fetch

    func fetchLeaderboard() async throws -> [FriendEntry] {
        guard try await container.accountStatus() == .available else {
            throw AppError.cloudKitUnavailable
        }

        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "LeaderboardEntry", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "healthPercent", ascending: false)]

        let (results, _) = try await publicDB.records(matching: query, resultsLimit: 50)

        return results.compactMap { _, result in
            guard let record = try? result.get() else { return nil }
            return FriendEntry(
                id: record.recordID.recordName,
                displayName: record["displayName"] as? String ?? "Unknown",
                healthPercent: record["healthPercent"] as? Double ?? 0,
                isDead: record["isDead"] as? Bool ?? false,
                iCloudRecordID: record.recordID.recordName
            )
        }
    }

    // MARK: - Upsert My Entry

    /// Saves or updates the current user's leaderboard entry using a stable record name
    /// based on the user's iCloud record ID — prevents duplicate entries per user.
    func upsertMyEntry(healthPercent: Double, isDead: Bool, displayName: String) async throws {
        guard try await container.accountStatus() == .available else {
            throw AppError.cloudKitUnavailable
        }

        let recordName = try await myRecordName()
        let recordID   = CKRecord.ID(recordName: recordName)

        // Fetch existing or create new
        let record: CKRecord
        do {
            record = try await publicDB.record(for: recordID)
        } catch let error as CKError where error.code == .unknownItem {
            record = CKRecord(recordType: "LeaderboardEntry", recordID: recordID)
        }

        record["healthPercent"] = healthPercent as CKRecordValue
        record["isDead"]        = isDead as CKRecordValue
        record["displayName"]   = displayName as CKRecordValue
        record["updatedAt"]     = Date() as CKRecordValue

        try await publicDB.save(record)
    }

    // MARK: - Friend Connections

    func addFriend(iCloudID: String) async throws {
        guard try await container.accountStatus() == .available else {
            throw AppError.cloudKitUnavailable
        }
        let record = CKRecord(recordType: "FriendConnection")
        record["friendID"] = iCloudID as CKRecordValue
        try await privateDB.save(record)
    }

    // MARK: - Death Broadcast

    func broadcastDeath() async {
        guard let name = AuthService.shared.currentUser?.displayName else { return }
        try? await upsertMyEntry(healthPercent: 100, isDead: true, displayName: name)
    }

    // MARK: - Real-time Subscription

    /// Creates a server-side subscription so the device receives a silent push
    /// whenever any LeaderboardEntry is updated. Idempotent — safe to call every launch.
    func subscribeToLeaderboardChanges() async throws {
        guard try await container.accountStatus() == .available else { return }

        let subscriptionID = "leaderboard-all-changes"

        do {
            // Check if subscription already exists
            _ = try await publicDB.subscription(for: subscriptionID)
        } catch let error as CKError where error.code == .unknownItem {
            // Create it
            let predicate    = NSPredicate(value: true)
            let subscription = CKQuerySubscription(
                recordType: "LeaderboardEntry",
                predicate: predicate,
                subscriptionID: subscriptionID,
                options: [.firesOnRecordCreation, .firesOnRecordUpdate, .firesOnRecordDeletion]
            )
            let notification = CKSubscription.NotificationInfo()
            notification.shouldSendContentAvailable = true  // silent push
            subscription.notificationInfo = notification

            try await publicDB.save(subscription)
        }
    }

    // MARK: - Remote Notification Handler

    func handleRemoteNotification(_ userInfo: [AnyHashable: Any]) async {
        NotificationCenter.default.post(name: .cloudKitLeaderboardDidChange, object: nil)
    }

    // MARK: - Private Helpers

    private func myRecordName() async throws -> String {
        let accountID = try await container.userRecordID()
        return "leaderboard-\(accountID.recordName)"
    }
}

extension Notification.Name {
    static let cloudKitLeaderboardDidChange = Notification.Name("cloudKitLeaderboardDidChange")
}
