// UnpluggedWidget — WidgetKit Extension
//
// SETUP: In Xcode create the target manually:
//   File → New Target → Widget Extension → Name: "UnpluggedWidget"
//   Team: same as main Unplugged target
//   Include Configuration App Intent: No
//   Delete the auto-generated files; add this file + WidgetEntry.swift instead.
//
//   In the new target's capabilities, add:
//   - App Groups → "group.com.unplugged"
//
//   Add PluggieState.swift (PluggieMood enum + Color extension) and
//   AppGroupConstants.swift to the widget target's "Compile Sources".
//
//   In the main Unplugged target's PluggieViewModel.syncToSharedDefaults(),
//   call WidgetCenter.shared.reloadAllTimelines() after writing to shared defaults.

import WidgetKit
import SwiftUI

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Timeline Provider
// ─────────────────────────────────────────────────────────────────────────────

struct PluggieTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> PluggieWidgetEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (PluggieWidgetEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PluggieWidgetEntry>) -> Void) {
        let entry    = currentEntry()
        let refresh  = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(refresh))
        completion(timeline)
    }

    private func currentEntry() -> PluggieWidgetEntry {
        let defaults = UserDefaults(suiteName: AppGroupConstants.suiteName) ?? .standard
        let hp       = defaults.double(forKey: AppGroupConstants.UserDefaultsKeys.currentHealthPercent)
        let mood     = defaults.string(forKey: AppGroupConstants.UserDefaultsKeys.pluggieMoodRawValue) ?? "thriving"
        let used     = defaults.integer(forKey: AppGroupConstants.UserDefaultsKeys.currentUsageSeconds)
        let limit    = defaults.integer(forKey: AppGroupConstants.UserDefaultsKeys.dailyLimitSeconds)
        return PluggieWidgetEntry(
            date: Date(),
            healthPercent: hp,
            moodRawValue: mood,
            usedSeconds: used,
            limitSeconds: max(limit, 1)
        )
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Widget View
// ─────────────────────────────────────────────────────────────────────────────

struct UnpluggedWidgetEntryView: View {
    let entry: PluggieWidgetEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .systemSmall:  smallView
        default:            mediumView
        }
    }

    // MARK: Small (health ring + mood emoji)

    private var smallView: some View {
        ZStack {
            entry.mood.tintColor.opacity(0.12)
            VStack(spacing: 6) {
                healthRing(size: 64, lineWidth: 6)
                Text(entry.mood.accessibilityLabel)
                    .font(.caption2.bold())
                    .foregroundStyle(entry.mood.tintColor)
            }
            .padding(12)
        }
        .containerBackground(for: .widget) { entry.mood.tintColor.opacity(0.08) }
    }

    // MARK: Medium (ring + usage stats)

    private var mediumView: some View {
        HStack(spacing: 16) {
            healthRing(size: 80, lineWidth: 8)
            VStack(alignment: .leading, spacing: 6) {
                Text("Pluggie is \(entry.mood.accessibilityLabel.lowercased())")
                    .font(.headline.bold())
                    .foregroundStyle(entry.mood.tintColor)
                statRow(label: "Used",  value: entry.usedSeconds.hhmm)
                statRow(label: "Limit", value: entry.limitSeconds.hhmm)
                statRow(label: "Left",  value: max(0, entry.limitSeconds - entry.usedSeconds).hhmm)
            }
            Spacer()
        }
        .padding(16)
        .containerBackground(for: .widget) { entry.mood.tintColor.opacity(0.08) }
    }

    private func healthRing(size: CGFloat, lineWidth: CGFloat) -> some View {
        ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.15), lineWidth: lineWidth)
                .frame(width: size, height: size)

            Circle()
                .trim(from: 0, to: CGFloat(max(0, 1 - entry.healthPercent / 100)))
                .stroke(entry.mood.tintColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))

            Text("\(Int(100 - entry.healthPercent))%")
                .font(.system(size: size * 0.22, weight: .bold, design: .rounded))
                .foregroundStyle(entry.mood.tintColor)
        }
    }

    private func statRow(label: String, value: String) -> some View {
        HStack(spacing: 4) {
            Text(label + ":")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption.bold())
                .foregroundStyle(.primary)
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Widget
// ─────────────────────────────────────────────────────────────────────────────

@main
struct UnpluggedWidget: Widget {
    let kind = "UnpluggedWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PluggieTimelineProvider()) { entry in
            UnpluggedWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Pluggie Health")
        .description("See Pluggie's current health and your screen time at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Helpers
// ─────────────────────────────────────────────────────────────────────────────

private extension Int {
    var hhmm: String {
        let h = self / 3600
        let m = (self % 3600) / 60
        if h > 0 { return "\(h)h \(m)m" }
        return "\(m)m"
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Previews
// ─────────────────────────────────────────────────────────────────────────────

#Preview("Small – Thriving", as: .systemSmall) {
    UnpluggedWidget()
} timeline: {
    PluggieWidgetEntry.placeholder
}

#Preview("Medium – Critical", as: .systemMedium) {
    UnpluggedWidget()
} timeline: {
    PluggieWidgetEntry(
        date: Date(),
        healthPercent: 92,
        moodRawValue: "critical",
        usedSeconds: 3312,
        limitSeconds: 3600
    )
}
