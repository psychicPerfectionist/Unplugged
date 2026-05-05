import SwiftUI

@main
struct UnpluggedApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    private let screenTimeService: any ScreenTimeServiceProtocol = {
        #if targetEnvironment(simulator)
        return MockScreenTimeService(startUsageSeconds: 0, limitSeconds: 3600, ticksPerSecond: 10)
        #else
        return RealScreenTimeService()
        #endif
    }()

    var body: some Scene {
        WindowGroup {
            AppRoot(service: screenTimeService)
                .environment(\.managedObjectContext, CoreDataStack.shared.viewContext)
        }
    }
}

// Isolated so @StateObject can receive the service at first init.
private struct AppRoot: View {
    let service: any ScreenTimeServiceProtocol

    @StateObject private var pluggieVM: PluggieViewModel
    @StateObject private var settingsVM: SettingsViewModel
    @StateObject private var historyVM: HistoryViewModel

    init(service: any ScreenTimeServiceProtocol) {
        self.service  = service
        let history   = HistoryViewModel()
        _historyVM    = StateObject(wrappedValue: history)
        _pluggieVM    = StateObject(wrappedValue: PluggieViewModel(service: service, historyVM: history))
        _settingsVM   = StateObject(wrappedValue: SettingsViewModel(service: service))
    }

    var body: some View {
        ContentRootView()
            .environmentObject(pluggieVM)
            .environmentObject(settingsVM)
            .environmentObject(historyVM)
            .environment(\.screenTimeService, service)
            .task { await NotificationService.shared.requestPermission() }
    }
}

private struct ContentRootView: View {
    @EnvironmentObject private var settingsVM: SettingsViewModel

    var body: some View {
        if !settingsVM.isAuthenticated {
            LoginView()
        } else if !settingsVM.isOnboardingComplete {
            OnboardingView()
        } else {
            MainTabView()
        }
    }
}

private struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Home",    systemImage: "house.fill") }

            LeaderboardView()
                .tabItem { Label("Friends", systemImage: "trophy.fill") }

            HistoryView()
                .tabItem { Label("History", systemImage: "calendar") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(Color(hex: "#4CAF50"))
    }
}
