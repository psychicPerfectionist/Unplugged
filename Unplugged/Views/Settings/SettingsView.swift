import SwiftUI
import LocalAuthentication

struct SettingsView: View {
    @EnvironmentObject private var settingsVM: SettingsViewModel
    @EnvironmentObject private var pluggieVM: PluggieViewModel
    @State private var isUnlocked = false
    @State private var showBiometricPrompt = false

    var body: some View {
        NavigationStack {
            List {
                limitSection
                notificationsSection
                securitySection
                accountSection
            }
            .navigationTitle("Settings")
            .task { authenticateIfNeeded() }
        }
    }

    private var limitSection: some View {
        Section("Daily Limit") {
            if isUnlocked || !settingsVM.isBiometricEnabled {
                Stepper(
                    "\(settingsVM.dailyLimitSeconds / 3600)h \((settingsVM.dailyLimitSeconds % 3600) / 60)m",
                    onIncrement: { settingsVM.dailyLimitSeconds += 1800 },
                    onDecrement: { settingsVM.dailyLimitSeconds = max(1800, settingsVM.dailyLimitSeconds - 1800) }
                )
                .onChange(of: settingsVM.dailyLimitSeconds) { settingsVM.save() }
            } else {
                Button("Unlock to change limit") { authenticateIfNeeded() }
            }
        }
    }

    private var notificationsSection: some View {
        Section("Notifications") {
            Picker("Reminder interval", selection: $settingsVM.notificationIntervalMinutes) {
                Text("15 min").tag(15)
                Text("30 min").tag(30)
                Text("1 hour").tag(60)
                Text("2 hours").tag(120)
            }
            .onChange(of: settingsVM.notificationIntervalMinutes) { settingsVM.save() }

            NavigationLink("Manage Reminders") {
                RemindersPlaceholderView()
            }
        }
    }

    private var securitySection: some View {
        Section("Security") {
            Toggle("Biometric Lock", isOn: $settingsVM.isBiometricEnabled)
                .onChange(of: settingsVM.isBiometricEnabled) { settingsVM.save() }

            NavigationLink("Block Apps") {
                AppBlockingView()
            }
        }
    }

    private var accountSection: some View {
        Section {
            Button("Delete Account", role: .destructive) { }
        }
    }

    private func authenticateIfNeeded() {
        guard settingsVM.isBiometricEnabled else { isUnlocked = true; return }
        Task { isUnlocked = await BiometricService.shared.authenticate() }
    }
}

private struct RemindersPlaceholderView: View {
    var body: some View {
        ContentUnavailableView("Coming Soon", systemImage: "bell.badge")
            .navigationTitle("Reminders")
    }
}

#Preview {
    SettingsView()
        .environmentObject(SettingsViewModel(service: MockScreenTimeService()))
        .environmentObject(PluggieViewModel(service: MockScreenTimeService()))
}
