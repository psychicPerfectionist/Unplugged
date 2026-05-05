import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var pluggieVM: PluggieViewModel

    var body: some View {
        ZStack(alignment: .bottom) {
            RoomBackground(mood: pluggieVM.mood)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                Spacer()

                PluggieView()
                    .frame(height: 260)
                    .padding(.horizontal, 40)

                Spacer()

                StatsCard(
                    mood:             pluggieVM.mood,
                    healthPercent:    pluggieVM.healthPercent,
                    usedSeconds:      pluggieVM.currentUsageSeconds,
                    limitSeconds:     pluggieVM.dailyLimitSeconds,
                    remainingSeconds: pluggieVM.remainingSeconds,
                    isBlocking:       pluggieVM.isBlockingActive
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }
        }
        .navigationBarHidden(true)
    }

    private var topBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Unplugged")
                    .font(.title2.bold())
                    .foregroundStyle(.primary)
                Text(Date(), format: .dateTime.weekday(.wide).month().day())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HealthBadge(healthPercent: pluggieVM.healthPercent, mood: pluggieVM.mood)
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Room Background
// ─────────────────────────────────────────────────────────────────────────────

private struct RoomBackground: View {
    let mood: PluggieMood

    var wallColor: Color {
        switch mood {
        case .thriving:   return Color(hex: "#E8F5E9")
        case .content:    return Color(hex: "#F1F8E9")
        case .worried:    return Color(hex: "#FFFDE7")
        case .struggling: return Color(hex: "#FFF3E0")
        case .critical:   return Color(hex: "#FFEBEE")
        case .dead:       return Color(hex: "#F5F5F5")
        }
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                // Wall
                wallColor
                    .animation(.easeInOut(duration: 1.5), value: mood)

                // Floor
                RoundedRectangle(cornerRadius: 0)
                    .fill(Color(hex: "#D7CCC8").opacity(0.6))
                    .frame(height: geo.size.height * 0.28)

                // Skirting board
                Rectangle()
                    .fill(Color(hex: "#BCAAA4").opacity(0.5))
                    .frame(height: 6)
                    .offset(y: -(geo.size.height * 0.28))

                // Window
                window
                    .frame(width: 90, height: 110)
                    .position(x: geo.size.width * 0.82, y: geo.size.height * 0.25)

                // Bookshelf
                bookshelf
                    .frame(width: 60, height: 70)
                    .position(x: geo.size.width * 0.12, y: geo.size.height * 0.68)

                // Plant
                plant
                    .frame(width: 38, height: 52)
                    .position(x: geo.size.width * 0.88, y: geo.size.height * 0.72)
            }
        }
    }

    private var window: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(hex: "#B3E5FC").opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color(hex: "#8D6E63").opacity(0.5), lineWidth: 3)
                )
            // Cross frame
            Rectangle()
                .fill(Color(hex: "#8D6E63").opacity(0.4))
                .frame(width: 2)
            Rectangle()
                .fill(Color(hex: "#8D6E63").opacity(0.4))
                .frame(height: 2)
            // Curtains
            HStack {
                Rectangle()
                    .fill(mood.tintColor.opacity(0.25))
                    .frame(width: 14)
                Spacer()
                Rectangle()
                    .fill(mood.tintColor.opacity(0.25))
                    .frame(width: 14)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private var bookshelf: some View {
        VStack(spacing: 2) {
            // Shelf top
            Rectangle().fill(Color(hex: "#8D6E63")).frame(height: 4)
            // Books
            HStack(spacing: 2) {
                book(Color(hex: "#EF9A9A"), width: 8, height: 28)
                book(Color(hex: "#A5D6A7"), width: 6, height: 24)
                book(Color(hex: "#90CAF9"), width: 9, height: 30)
                book(Color(hex: "#FFE082"), width: 7, height: 22)
                book(Color(hex: "#CE93D8"), width: 8, height: 26)
            }
            .padding(.horizontal, 4)
            // Shelf bottom
            Rectangle().fill(Color(hex: "#8D6E63")).frame(height: 4)
        }
    }

    private func book(_ color: Color, width: CGFloat, height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(color.opacity(0.8))
            .frame(width: width, height: height)
    }

    private var plant: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(Color(hex: "#A5D6A7").opacity(0.9))
                    .frame(width: 28, height: 24)
                    .offset(x: -5, y: 2)
                Circle()
                    .fill(Color(hex: "#81C784").opacity(0.9))
                    .frame(width: 24, height: 22)
                    .offset(x: 4, y: 0)
                Circle()
                    .fill(Color(hex: "#66BB6A").opacity(0.9))
                    .frame(width: 20, height: 18)
                    .offset(y: -4)
            }
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(hex: "#8D6E63"))
                .frame(width: 22, height: 18)
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Health Badge
// ─────────────────────────────────────────────────────────────────────────────

private struct HealthBadge: View {
    let healthPercent: Double
    let mood: PluggieMood

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.15), lineWidth: 4)
                .frame(width: 48, height: 48)

            Circle()
                .trim(from: 0, to: CGFloat(max(0, 1 - healthPercent / 100)))
                .stroke(
                    mood.tintColor,
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .frame(width: 48, height: 48)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.6), value: healthPercent)

            Text("\(Int(100 - healthPercent))%")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(mood.tintColor)
        }
        .accessibilityLabel("Health \(Int(100 - healthPercent)) percent")
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Stats Card
// ─────────────────────────────────────────────────────────────────────────────

private struct StatsCard: View {
    let mood: PluggieMood
    let healthPercent: Double
    let usedSeconds: Int
    let limitSeconds: Int
    let remainingSeconds: Int
    let isBlocking: Bool

    var body: some View {
        VStack(spacing: 14) {
            if isBlocking {
                blockingBanner
            }

            moodLabel
            healthBar
            timeRow
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(mood.tintColor.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
    }

    private var blockingBanner: some View {
        HStack(spacing: 6) {
            Image(systemName: "lock.shield.fill")
                .foregroundStyle(Color(hex: "#5C6BC0"))
            Text("App Blocking Active — timer paused")
                .font(.caption.bold())
                .foregroundStyle(Color(hex: "#5C6BC0"))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(hex: "#E8EAF6"), in: Capsule())
    }

    private var moodLabel: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(mood.tintColor)
                .frame(width: 10, height: 10)
            Text("Pluggie is \(mood.accessibilityLabel.lowercased())")
                .font(.subheadline.bold())
                .foregroundStyle(.primary)
            Spacer()
        }
    }

    private var healthBar: some View {
        VStack(alignment: .leading, spacing: 6) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.secondary.opacity(0.15))
                        .frame(height: 10)

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [mood.tintColor.opacity(0.7), mood.tintColor],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: geo.size.width * CGFloat(max(0, 1 - healthPercent / 100)),
                            height: 10
                        )
                        .animation(.easeInOut(duration: 0.6), value: healthPercent)
                }
            }
            .frame(height: 10)
        }
    }

    private var timeRow: some View {
        HStack {
            timePill(
                label: "Used",
                value: usedSeconds.hhmm,
                icon: "clock"
            )
            Divider().frame(height: 30)
            timePill(
                label: "Limit",
                value: limitSeconds.hhmm,
                icon: "flag.fill"
            )
            Divider().frame(height: 30)
            timePill(
                label: "Left",
                value: remainingSeconds.hhmm,
                icon: "hourglass.bottomhalf.filled",
                tinted: true
            )
        }
    }

    private func timePill(
        label: String,
        value: String,
        icon: String,
        tinted: Bool = false
    ) -> some View {
        VStack(spacing: 3) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(tinted ? mood.tintColor : .secondary)
            Text(value)
                .font(.system(.subheadline, design: .rounded).bold())
                .foregroundStyle(tinted ? mood.tintColor : .primary)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Helpers
// ─────────────────────────────────────────────────────────────────────────────

extension Int {
    var hhmm: String {
        let h = self / 3600
        let m = (self % 3600) / 60
        let s = self % 60
        if h > 0  { return "\(h)h \(m)m" }
        if m > 0  { return "\(m)m \(s)s" }
        return "\(s)s"
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Preview
// ─────────────────────────────────────────────────────────────────────────────

#Preview("Thriving") {
    HomeView()
        .environmentObject(PluggieViewModel(
            service: MockScreenTimeService(startUsageSeconds: 0, limitSeconds: 3600, ticksPerSecond: 0)
        ))
}

#Preview("Worried") {
    HomeView()
        .environmentObject(PluggieViewModel(
            service: MockScreenTimeService(startUsageSeconds: 1980, limitSeconds: 3600, ticksPerSecond: 0)
        ))
}

#Preview("Critical") {
    HomeView()
        .environmentObject(PluggieViewModel(
            service: MockScreenTimeService(startUsageSeconds: 3300, limitSeconds: 3600, ticksPerSecond: 0)
        ))
}

#Preview("Dead") {
    HomeView()
        .environmentObject(PluggieViewModel(
            service: MockScreenTimeService(startUsageSeconds: 3600, limitSeconds: 3600, ticksPerSecond: 0)
        ))
}
