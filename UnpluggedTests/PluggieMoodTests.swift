import XCTest
@testable import Unplugged

final class PluggieMoodTests: XCTestCase {

    // MARK: - Mood State Transitions (usage % → mood)

    func testThrivingAtZeroPercent() {
        XCTAssertEqual(PluggieMood(healthPercent: 0), .thriving)
    }

    func testThrivingBelow25() {
        XCTAssertEqual(PluggieMood(healthPercent: 24.9), .thriving)
    }

    func testContentAtExactly25() {
        // Boundary: 25 is the start of "content"
        XCTAssertEqual(PluggieMood(healthPercent: 25), .content)
    }

    func testContentBelow50() {
        XCTAssertEqual(PluggieMood(healthPercent: 49.9), .content)
    }

    func testWorriedAtExactly50() {
        XCTAssertEqual(PluggieMood(healthPercent: 50), .worried)
    }

    func testWorriedBelow75() {
        XCTAssertEqual(PluggieMood(healthPercent: 74.9), .worried)
    }

    func testStrugglingAtExactly75() {
        XCTAssertEqual(PluggieMood(healthPercent: 75), .struggling)
    }

    func testStrugglingBelow90() {
        XCTAssertEqual(PluggieMood(healthPercent: 89.9), .struggling)
    }

    func testCriticalAtExactly90() {
        XCTAssertEqual(PluggieMood(healthPercent: 90), .critical)
    }

    func testCriticalBelow100() {
        XCTAssertEqual(PluggieMood(healthPercent: 99.9), .critical)
    }

    func testDeadAtExactly100() {
        XCTAssertEqual(PluggieMood(healthPercent: 100), .dead)
    }

    func testDeadAbove100() {
        // Over-limit values (e.g. if tracked usage exceeds limit) still map to dead
        XCTAssertEqual(PluggieMood(healthPercent: 150), .dead)
    }

    // MARK: - All Cases

    func testAllCasesCount() {
        XCTAssertEqual(PluggieMood.allCases.count, 6)
    }

    // MARK: - Raw Values

    func testRawValues() {
        XCTAssertEqual(PluggieMood.thriving.rawValue,   "thriving")
        XCTAssertEqual(PluggieMood.content.rawValue,    "content")
        XCTAssertEqual(PluggieMood.worried.rawValue,    "worried")
        XCTAssertEqual(PluggieMood.struggling.rawValue, "struggling")
        XCTAssertEqual(PluggieMood.critical.rawValue,   "critical")
        XCTAssertEqual(PluggieMood.dead.rawValue,       "dead")
    }

    func testRoundTripFromRawValue() {
        for mood in PluggieMood.allCases {
            XCTAssertEqual(PluggieMood(rawValue: mood.rawValue), mood)
        }
    }

    // MARK: - Accessibility Labels

    func testAccessibilityLabelThriving() {
        XCTAssertEqual(PluggieMood.thriving.accessibilityLabel, "Thriving")
    }

    func testAccessibilityLabelContent() {
        XCTAssertEqual(PluggieMood.content.accessibilityLabel, "Content")
    }

    func testAccessibilityLabelWorried() {
        XCTAssertEqual(PluggieMood.worried.accessibilityLabel, "Worried")
    }

    func testAccessibilityLabelStruggling() {
        XCTAssertEqual(PluggieMood.struggling.accessibilityLabel, "Struggling")
    }

    func testAccessibilityLabelCritical() {
        XCTAssertEqual(PluggieMood.critical.accessibilityLabel, "Critical")
    }

    func testAccessibilityLabelDead() {
        XCTAssertEqual(PluggieMood.dead.accessibilityLabel, "Dead")
    }

    func testAllCasesHaveNonEmptyAccessibilityLabels() {
        for mood in PluggieMood.allCases {
            XCTAssertFalse(mood.accessibilityLabel.isEmpty, "\(mood) has empty accessibilityLabel")
        }
    }

    // MARK: - Tint Colors (non-nil, all distinct)

    func testAllCasesHaveDistinctTintColors() {
        // Each mood state should have a unique tint color
        let colors = PluggieMood.allCases.map { $0.tintColor.description }
        let unique = Set(colors)
        XCTAssertEqual(unique.count, PluggieMood.allCases.count,
                       "Some mood states share the same tint color")
    }
}
