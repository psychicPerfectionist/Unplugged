import Foundation

struct UserProfile: Identifiable, Codable {
    var id: String
    var displayName: String
    var avatarURL: URL?
    var iCloudRecordID: String?

    init(id: String = UUID().uuidString, displayName: String) {
        self.id = id
        self.displayName = displayName
    }
}
