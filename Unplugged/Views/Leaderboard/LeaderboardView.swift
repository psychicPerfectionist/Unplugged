import SwiftUI

struct LeaderboardView: View {
    @StateObject private var vm = LeaderboardViewModel()

    var body: some View {
        NavigationStack {
            Group {
                switch vm.state {
                case .idle, .loading:
                    loadingView

                case .unavailable:
                    unavailableView

                case .empty:
                    emptyView

                case .loaded(let entries):
                    leaderboardList(entries)

                case .error(let message):
                    errorView(message)
                }
            }
            .navigationTitle("Leaderboard")
            .task { await vm.refresh() }
            .refreshable { await vm.refresh() }
        }
    }

    // MARK: - State Views

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading leaderboard…")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var unavailableView: some View {
        ContentUnavailableView {
            Label("iCloud Not Available", systemImage: "icloud.slash")
        } description: {
            Text("Sign in to iCloud on your device to connect with friends and see the leaderboard.")
        } actions: {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(hex: "#4CAF50"))
        }
    }

    private var emptyView: some View {
        ContentUnavailableView {
            Label("No Friends Yet", systemImage: "person.2.slash")
        } description: {
            Text("Once you and your friends are signed in to iCloud, you'll appear on each other's leaderboard automatically.")
        }
    }

    private func errorView(_ message: String) -> some View {
        ContentUnavailableView {
            Label("Couldn't Load", systemImage: "wifi.exclamationmark")
        } description: {
            Text(message)
        } actions: {
            Button("Try Again") {
                Task { await vm.refresh() }
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(hex: "#4CAF50"))
        }
    }

    // MARK: - Loaded List

    private func leaderboardList(_ entries: [FriendEntry]) -> some View {
        List {
            if entries.count >= 3 {
                podiumSection(entries)
            }
            Section("Rankings") {
                ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                    LeaderboardRow(rank: index + 1, entry: entry)
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func podiumSection(_ entries: [FriendEntry]) -> some View {
        Section {
            HStack(alignment: .bottom, spacing: 16) {
                podiumPill(rank: 2, entry: entries[1])
                podiumPill(rank: 1, entry: entries[0])
                podiumPill(rank: 3, entry: entries[2])
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical)
        }
        .listRowBackground(Color.clear)
        .listRowInsets(.init())
    }

    private func podiumPill(rank: Int, entry: FriendEntry) -> some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(entry.mood.tintColor.opacity(0.2))
                    .frame(width: rank == 1 ? 64 : 52, height: rank == 1 ? 64 : 52)
                Text(String(entry.displayName.prefix(1)))
                    .font(rank == 1 ? .title2.bold() : .headline)
                    .foregroundStyle(entry.mood.tintColor)
                if entry.isDead {
                    Image(systemName: "skull.fill")
                        .font(.caption)
                        .foregroundStyle(.white)
                        .padding(4)
                        .background(Color.gray, in: Circle())
                        .offset(x: 20, y: -20)
                }
            }
            Text(entry.displayName)
                .font(.caption2.bold())
                .lineLimit(1)
            Text("\(Int(100 - entry.healthPercent))%")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Rank \(rank): \(entry.displayName), \(Int(100 - entry.healthPercent))% health")
    }
}

// MARK: - Row

private struct LeaderboardRow: View {
    let rank: Int
    let entry: FriendEntry

    var body: some View {
        HStack(spacing: 12) {
            Text("\(rank)")
                .font(.headline.monospacedDigit())
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
                Text(entry.isDead ? "Dead" : entry.mood.accessibilityLabel)
                    .font(.caption)
                    .foregroundStyle(entry.isDead ? .secondary : entry.mood.tintColor)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(100 - entry.healthPercent))%")
                    .font(.subheadline.bold())
                    .foregroundStyle(entry.isDead ? .secondary : entry.mood.tintColor)
                if entry.isDead {
                    Image(systemName: "skull.fill")
                        .foregroundStyle(.secondary)
                        .font(.caption2)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Rank \(rank), \(entry.displayName), \(Int(100 - entry.healthPercent))% health\(entry.isDead ? ", dead" : "")")
    }
}

#Preview {
    LeaderboardView()
}
