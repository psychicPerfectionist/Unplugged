import SwiftUI

struct LeaderboardView: View {
    @StateObject private var vm = LeaderboardViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if vm.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if vm.entries.isEmpty {
                    ContentUnavailableView(
                        "No Friends Yet",
                        systemImage: "person.2.slash",
                        description: Text("Add friends to see their Pluggie health.")
                    )
                } else {
                    leaderboardList
                }
            }
            .navigationTitle("Leaderboard")
            .task { await vm.refresh() }
            .refreshable { await vm.refresh() }
            .alert("Error", isPresented: Binding(
                get: { vm.error != nil },
                set: { if !$0 { vm.error = nil } }
            )) {
                Button("OK", role: .cancel) { vm.error = nil }
            } message: {
                Text(vm.error?.localizedDescription ?? "")
            }
        }
    }

    private var leaderboardList: some View {
        List {
            if vm.entries.count >= 3 {
                podiumSection
            }
            ForEach(Array(vm.entries.enumerated()), id: \.element.id) { index, entry in
                LeaderboardRow(rank: index + 1, entry: entry)
            }
        }
        .listStyle(.plain)
    }

    private var podiumSection: some View {
        Section {
            HStack(alignment: .bottom, spacing: 16) {
                podiumPill(rank: 2, entry: vm.entries[1])
                podiumPill(rank: 1, entry: vm.entries[0])
                podiumPill(rank: 3, entry: vm.entries[2])
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical)
        }
        .listRowBackground(Color.clear)
        .listRowInsets(.init())
    }

    private func podiumPill(rank: Int, entry: FriendEntry) -> some View {
        VStack(spacing: 6) {
            Circle()
                .fill(entry.mood.tintColor.opacity(0.2))
                .frame(width: rank == 1 ? 64 : 52, height: rank == 1 ? 64 : 52)
                .overlay(
                    Text(String(entry.displayName.prefix(1)))
                        .font(rank == 1 ? .title2.bold() : .headline)
                        .foregroundStyle(entry.mood.tintColor)
                )
            Text(entry.displayName)
                .font(.caption2.bold())
                .lineLimit(1)
            Text("\(Int(100 - entry.healthPercent))%")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

private struct LeaderboardRow: View {
    let rank: Int
    let entry: FriendEntry

    var body: some View {
        HStack(spacing: 12) {
            Text("\(rank)")
                .font(.headline)
                .frame(width: 28)
                .foregroundStyle(.secondary)

            Circle()
                .fill(entry.mood.tintColor.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(String(entry.displayName.prefix(1)))
                        .font(.headline)
                        .foregroundStyle(entry.mood.tintColor)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.displayName).font(.subheadline.bold())
                Text(entry.mood.accessibilityLabel)
                    .font(.caption)
                    .foregroundStyle(entry.mood.tintColor)
            }

            Spacer()

            Text("\(Int(100 - entry.healthPercent))%")
                .font(.subheadline.bold())
                .foregroundStyle(entry.isDead ? .secondary : entry.mood.tintColor)

            if entry.isDead {
                Image(systemName: "skull.fill")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(
            format: NSLocalizedString("a11y.leaderboard.rank", comment: ""),
            rank,
            entry.displayName,
            Int(100 - entry.healthPercent)
        ))
    }
}

#Preview {
    LeaderboardView()
}
