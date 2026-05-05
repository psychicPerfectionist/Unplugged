import Foundation
import Combine

@MainActor
final class LeaderboardViewModel: ObservableObject {
    enum State {
        case idle
        case loading
        case unavailable   // iCloud not signed in
        case empty         // iCloud works but no friends yet
        case loaded([FriendEntry])
        case error(String)
    }

    @Published private(set) var state: State = .idle

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

    // Legacy accessor for views that bind to entries array
    var entries: [FriendEntry] {
        if case .loaded(let e) = state { return e }
        return []
    }

    var isLoading: Bool {
        if case .loading = state { return true }
        return false
    }

    func refresh() async {
        state = .loading
        do {
            let fetched = try await CloudKitService.shared.fetchLeaderboard()
            try? await CloudKitService.shared.subscribeToLeaderboardChanges()
            state = fetched.isEmpty ? .empty : .loaded(fetched)
        } catch AppError.cloudKitUnavailable {
            state = .unavailable
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    func addFriend(iCloudID: String) async {
        do {
            try await CloudKitService.shared.addFriend(iCloudID: iCloudID)
            await refresh()
        } catch {
            state = .error(error.localizedDescription)
        }
    }
}
