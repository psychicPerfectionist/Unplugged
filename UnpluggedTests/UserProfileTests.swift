import XCTest
@testable import Unplugged

final class UserProfileTests: XCTestCase {

    // MARK: - Initialisation

    func testDefaultIDIsGenerated() {
        let profile = UserProfile(displayName: "Alice")
        XCTAssertFalse(profile.id.isEmpty)
    }

    func testTwoDefaultProfilesHaveDistinctIDs() {
        let a = UserProfile(displayName: "Alice")
        let b = UserProfile(displayName: "Alice")
        XCTAssertNotEqual(a.id, b.id)
    }

    func testCustomIDIsPreserved() {
        let profile = UserProfile(id: "custom-123", displayName: "Bob")
        XCTAssertEqual(profile.id, "custom-123")
    }

    func testDisplayNameIsPreserved() {
        let profile = UserProfile(displayName: "Carol")
        XCTAssertEqual(profile.displayName, "Carol")
    }

    func testAvatarURLIsNilByDefault() {
        let profile = UserProfile(displayName: "Dave")
        XCTAssertNil(profile.avatarURL)
    }

    func testICloudRecordIDIsNilByDefault() {
        let profile = UserProfile(displayName: "Eve")
        XCTAssertNil(profile.iCloudRecordID)
    }

    // MARK: - Codable round-trip

    func testCodablePreservesID() throws {
        let original = UserProfile(id: "abc", displayName: "Alice")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(UserProfile.self, from: data)
        XCTAssertEqual(decoded.id, "abc")
    }

    func testCodablePreservesDisplayName() throws {
        let original = UserProfile(id: "abc", displayName: "Alice")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(UserProfile.self, from: data)
        XCTAssertEqual(decoded.displayName, "Alice")
    }

    func testCodableWithNilAvatarURL() throws {
        let original = UserProfile(id: "abc", displayName: "Alice")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(UserProfile.self, from: data)
        XCTAssertNil(decoded.avatarURL)
    }

    func testCodableWithAvatarURL() throws {
        var original = UserProfile(id: "abc", displayName: "Alice")
        original.avatarURL = URL(string: "https://example.com/avatar.png")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(UserProfile.self, from: data)
        XCTAssertEqual(decoded.avatarURL?.absoluteString, "https://example.com/avatar.png")
    }

    func testCodableWithICloudRecordID() throws {
        var original = UserProfile(id: "abc", displayName: "Alice")
        original.iCloudRecordID = "ckrecordid-123"
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(UserProfile.self, from: data)
        XCTAssertEqual(decoded.iCloudRecordID, "ckrecordid-123")
    }

    // MARK: - Identifiable

    func testIdentifiableUsesID() {
        let profile = UserProfile(id: "id-xyz", displayName: "Frank")
        XCTAssertEqual(profile.id, "id-xyz")
    }
}
