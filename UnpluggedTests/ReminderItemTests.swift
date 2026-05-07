import XCTest
@testable import Unplugged

final class ReminderItemTests: XCTestCase {

    override func tearDown() {
        // Clean up any persisted reminder items after each test
        ReminderItem.saveAll([])
        super.tearDown()
    }

    // MARK: - displayTime: 12-hour formatting

    func testMidnightFormatsAs12AM() {
        let item = ReminderItem(hour: 0, minute: 0)
        XCTAssertEqual(item.displayTime, "12:00 AM")
    }

    func testNoonFormatsAs12PM() {
        let item = ReminderItem(hour: 12, minute: 0)
        XCTAssertEqual(item.displayTime, "12:00 PM")
    }

    func test1PMFormatsCorrectly() {
        let item = ReminderItem(hour: 13, minute: 30)
        XCTAssertEqual(item.displayTime, "1:30 PM")
    }

    func test11PMFormatsCorrectly() {
        let item = ReminderItem(hour: 23, minute: 59)
        XCTAssertEqual(item.displayTime, "11:59 PM")
    }

    func test9AMFormatsCorrectly() {
        let item = ReminderItem(hour: 9, minute: 5)
        XCTAssertEqual(item.displayTime, "9:05 AM")
    }

    func test11AMFormatsCorrectly() {
        let item = ReminderItem(hour: 11, minute: 0)
        XCTAssertEqual(item.displayTime, "11:00 AM")
    }

    func testMinutePaddedWithLeadingZero() {
        let item = ReminderItem(hour: 8, minute: 5)
        XCTAssertTrue(item.displayTime.contains("05"),
                      "Single-digit minute should be zero-padded, got \(item.displayTime)")
    }

    func testMinuteNotPaddedWhenTwoDigits() {
        let item = ReminderItem(hour: 8, minute: 30)
        XCTAssertEqual(item.displayTime, "8:30 AM")
    }

    // MARK: - notificationID

    func testNotificationIDFormat() {
        let item = ReminderItem(id: "abc-123", hour: 8, minute: 0)
        XCTAssertEqual(item.notificationID, "com.unplugged.custom.abc-123")
    }

    func testNotificationIDUsesItemID() {
        let id = UUID().uuidString
        let item = ReminderItem(id: id, hour: 8, minute: 0)
        XCTAssertTrue(item.notificationID.hasSuffix(id))
    }

    func testTwoItemsHaveDistinctNotificationIDs() {
        let a = ReminderItem(hour: 8, minute: 0)
        let b = ReminderItem(hour: 9, minute: 0)
        XCTAssertNotEqual(a.notificationID, b.notificationID)
    }

    // MARK: - Codable round-trip

    func testCodablePreservesAllFields() throws {
        let original = ReminderItem(id: "fixed", label: "Morning check", hour: 8, minute: 30)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ReminderItem.self, from: data)

        XCTAssertEqual(decoded.id,     original.id)
        XCTAssertEqual(decoded.label,  original.label)
        XCTAssertEqual(decoded.hour,   original.hour)
        XCTAssertEqual(decoded.minute, original.minute)
    }

    func testCodableWithEmptyLabel() throws {
        let original = ReminderItem(id: "x", label: "", hour: 20, minute: 0)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ReminderItem.self, from: data)
        XCTAssertEqual(decoded.label, "")
    }

    // MARK: - UserDefaults persistence

    func testSaveAndLoadAllRoundTrip() {
        let items = [
            ReminderItem(id: "a", label: "Morning", hour: 8,  minute: 0),
            ReminderItem(id: "b", label: "Evening", hour: 20, minute: 0)
        ]
        ReminderItem.saveAll(items)
        let loaded = ReminderItem.loadAll()

        XCTAssertEqual(loaded.count, 2)
        XCTAssertEqual(loaded[0].id, "a")
        XCTAssertEqual(loaded[1].id, "b")
    }

    func testSaveAllEmptyArrayClearsStorage() {
        ReminderItem.saveAll([ReminderItem(hour: 9, minute: 0)])
        ReminderItem.saveAll([])
        XCTAssertTrue(ReminderItem.loadAll().isEmpty)
    }

    func testLoadAllReturnsEmptyWhenKeyMissing() {
        UserDefaults.standard.removeObject(forKey: "reminderItems")
        XCTAssertTrue(ReminderItem.loadAll().isEmpty)
    }

    func testSavedLabelIsPreservedAfterLoad() {
        let item = ReminderItem(id: "z", label: "Lunch break", hour: 12, minute: 0)
        ReminderItem.saveAll([item])
        let loaded = ReminderItem.loadAll()
        XCTAssertEqual(loaded.first?.label, "Lunch break")
    }

    // MARK: - Default UUID generation

    func testDefaultIDIsUnique() {
        let a = ReminderItem(hour: 8, minute: 0)
        let b = ReminderItem(hour: 8, minute: 0)
        XCTAssertNotEqual(a.id, b.id)
    }
}
