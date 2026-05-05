import WidgetKit
import SwiftUI

struct PluggieWidgetEntry: TimelineEntry {
    let date: Date
    let healthPercent: Double
    let moodRawValue: String
    let usedSeconds: Int
    let limitSeconds: Int

    var mood: PluggieMood {
        PluggieMood(rawValue: moodRawValue) ?? PluggieMood(healthPercent: healthPercent)
    }

    static let placeholder = PluggieWidgetEntry(
        date: Date(),
        healthPercent: 20,
        moodRawValue: "thriving",
        usedSeconds: 720,
        limitSeconds: 3600
    )
}
