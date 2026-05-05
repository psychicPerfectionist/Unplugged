import SwiftUI

struct DayDetailSheet: View {
    let record: DayRecord

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                statusBadge
                statsGrid
                Spacer()
            }
            .padding()
            .navigationTitle(record.date.formatted(.dateTime.month(.wide).day().year()))
            .navigationBarTitleDisplayMode(.inline)
            .presentationDetents([.medium])
        }
    }

    private var statusBadge: some View {
        Label(
            record.survived ? "Survived" : "Failed",
            systemImage: record.survived ? "checkmark.seal.fill" : "xmark.seal.fill"
        )
        .font(.title2.bold())
        .foregroundStyle(record.survived ? Color(hex: "#4CAF50") : Color(hex: "#9E9E9E"))
    }

    private var statsGrid: some View {
        Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 12) {
            GridRow {
                statLabel("Screen time used")
                statValue(record.totalUsageSeconds.formattedDuration)
            }
            Divider()
            GridRow {
                statLabel("Daily limit")
                statValue(record.limitSeconds.formattedDuration)
            }
            Divider()
            GridRow {
                statLabel("Over/Under")
                let diff = record.limitSeconds - record.totalUsageSeconds
                statValue(diff >= 0 ? "-\(diff.formattedDuration)" : "+\(abs(diff).formattedDuration)")
                    .foregroundStyle(diff >= 0 ? Color(hex: "#4CAF50") : Color(hex: "#F44336"))
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private func statLabel(_ text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .gridColumnAlignment(.leading)
    }

    private func statValue(_ text: String) -> some View {
        Text(text)
            .font(.subheadline.bold())
            .gridColumnAlignment(.trailing)
    }
}

private extension Int64 {
    var formattedDuration: String {
        let h = self / 3600
        let m = (self % 3600) / 60
        return h > 0 ? "\(h)h \(m)m" : "\(m)m"
    }
}
