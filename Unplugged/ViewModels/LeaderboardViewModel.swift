import Foundation
import Combine

@MainActor
final class LeaderboardViewModel: ObservableObject {
    @Published private(set) var entries: [FriendEntry] = []
    @Published private(set) var isLoading: Bool = false
    @Published var error: AppError?

    private var liveUpdateObserver: Any?

    init() {
        liveUpdateObserver = NotificationCenter.default.addObserver(
            forName: .cloudKitLeaderboardDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.refresh()
            }
        }
    }

    deinit {
        if let observer = liveUpdateObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    func refresh() async {
        isLoading = true
        defer { isLoading = false }
        do {
            async let fetchEntries  = CloudKitService.shared.fetchLeaderboard()
            async let setupSubscription: Void = CloudKitService.shared.subscribeToLeaderboardChanges()
            entries = try await fetchEntries
            try await setupSubscription
        } catch {
            self.error = .cloudKitFetchFailed(error)
        }
    }

    func addFriend(iCloudID: String) async {
        do {
            try await CloudKitService.shared.addFriend(iCloudID: iCloudID)
            await refresh()
        } catch {
            self.error = .cloudKitFetchFailed(error)
        }
    }
}
