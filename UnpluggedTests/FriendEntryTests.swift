import XCTest
@testable import Unplugged

final class FriendEntryTests: XCTestCase {

    // MARK: - Comparable sorting

    func testAliveSortedBeforeDead() {
        let alive = FriendEntry(id: "1", displayName: "Alice",
                                healthPercent: 80, isDead: false, iCloudRecordID: "r1")
        let dead  = FriendEntry(id: "2", displayName: "Bob",
                                healthPercent: 50, isDead: true,  iCloudRecordID: "r2")
        // Alive entry should come first (is "less than")
        XCTAssertLessThan(alive, dead)
    }

    func testDeadSortedAfterAlive() {
        let alive = FriendEntry(id: "1", displayName: "Alice",
                                healthPercent: 80, isDead: false, iCloudRecordID: "r1")
        let dead  = FriendEntry(id: "2", displayName: "Bob",
                                healthPercent: 50, isDead: true,  iCloudRecordID: "r2")
        XCTAssertGreaterThan(dead, alive)
    }

    func testLowerUsageSortedFirstAmongAlive() {
        // Lower healthPercent = less usage = better rank
        let better = FriendEntry(id: "1", displayName: "Alice",
                                 healthPercent: 10, isDead: false, iCloudRecordID: "r1")
        let worse  = FriendEntry(id: "2", displayName: "Bob",
                                 healthPercent: 60, isDead: false, iCloudRecordID: "r2")
        XCTAssertLessThan(better, worse)
    }

    func testHigherUsageSortedLastAmongAlive() {
        let better = FriendEntry(id: "1", displayName: "Alice",
                                 healthPercent: 10, isDead: false, iCloudRecordID: "r1")
        let worse  = FriendEntry(id: "2", displayName: "Bob",
                                 healthPercent: 70, isDead: false, iCloudRecordID: "r2")
        XCTAssertGreaterThan(worse, better)
    }

    func testSortedArrayProducesCorrectLeaderboardOrder() {
        let entries: [FriendEntry] = [
            FriendEntry(id: "1", displayName: "Dead",   healthPercent: 100, isDead: true,  iCloudRecordID: "r1"),
            FriendEntry(id: "2", displayName: "Worst",  healthPercent: 80,  isDead: false, iCloudRecordID: "r2"),
            FriendEntry(id: "3", displayName: "Best",   healthPercent: 5,   isDead: false, iCloudRecordID: "r3"),
            FriendEntry(id: "4", displayName: "Middle", healthPercent: 40,  isDead: false, iCloudRecordID: "r4"),
        ]
        let sorted = entries.sorted()

        XCTAssertEqual(sorted[0].displayName, "Best")
        XCTAssertEqual(sorted[1].displayName, "Middle")
        XCTAssertEqual(sorted[2].displayName, "Worst")
        XCTAssertEqual(sorted[3].displayName, "Dead")
    }

    func testTwoDeadEntriesSortByHealthPercent() {
        let lessUsage = FriendEntry(id: "1", displayName: "A",
                                    healthPercent: 100, isDead: true, iCloudRecordID: "r1")
        let moreUsage = FriendEntry(id: "2", displayName: "B",
                                    healthPercent: 100, isDead: true, iCloudRecordID: "r2")
        // Equal health percent: not less than each other
        XCTAssertFalse(lessUsage < moreUsage)
        XCTAssertFalse(moreUsage < lessUsage)
    }

    // MARK: - Mood derivation

    func testMoodDerivedFromHealthPercentThriving() {
        let entry = FriendEntry(id: "1", displayName: "U",
                                healthPercent: 10, isDead: false, iCloudRecordID: "r1")
        XCTAssertEqual(entry.mood, .thriving)
    }

    func testMoodDerivedFromHealthPercentContent() {
        let entry = FriendEntry(id: "1", displayName: "U",
                                healthPercent: 30, isDead: false, iCloudRecordID: "r1")
        XCTAssertEqual(entry.mood, .content)
    }

    func testMoodDerivedFromHealthPercentDead() {
        let entry = FriendEntry(id: "1", displayName: "U",
                                healthPercent: 100, isDead: true, iCloudRecordID: "r1")
        XCTAssertEqual(entry.mood, .dead)
    }

    func testMoodIsConsistentWithPluggieMood() {
        let testCases: [(Double, PluggieMood)] = [
            (0, .thriving), (24.9, .thriving),
            (25, .content), (49.9, .content),
            (50, .worried), (74.9, .worried),
            (75, .struggling), (89.9, .struggling),
            (90, .critical), (99.9, .critical),
            (100, .dead)
        ]
        for (hp, expected) in testCases {
            let entry = FriendEntry(id: "x", displayName: "x",
                                    healthPercent: hp, isDead: hp >= 100, iCloudRecordID: "x")
            XCTAssertEqual(entry.mood, expected,
                           "healthPercent \(hp) should produce \(expected) but got \(entry.mood)")
        }
    }

    // MARK: - Identifiable

    func testIdentifiableUsesID() {
        let entry = FriendEntry(id: "unique-id", displayName: "U",
                                healthPercent: 50, isDead: false, iCloudRecordID: "r")
        XCTAssertEqual(entry.id, "unique-id")
    }
}
