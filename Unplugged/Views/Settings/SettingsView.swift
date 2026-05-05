    import SwiftUI
import LocalAuthentication

struct SettingsView: View {
    @EnvironmentObject private var settingsVM: SettingsViewModel
    @EnvironmentObject private var pluggieVM:  PluggieViewModel

    @State private var isUnlocked         = false
    @State private var showDeleteConfirm  = false

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
            .confirmationDialog(
                "Delete Account",
                isPresented: $showDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("Delete Account & All Data", role: .destructive) {
                    settingsVM.deleteAccount()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete your account, history, and settings. This cannot be undone.")
            }
        }
    }

    // MARK: - Sections

    private var limitSection: some View {
        Section {
            if isUnlocked || !settingsVM.isBiometricEnabled {
                Stepper(value: $settingsVM.dailyLimitSeconds, in: 1800...86400, step: 1800) {
                    Label(formattedLimit, systemImage: "timer")
                }
                .onChange(of: settingsVM.dailyLimitSeconds) { settingsVM.save() }
            } else {
                Button {
                    authenticateIfNeeded()
                } label: {
                    Label("Unlock to change limit", systemImage: "lock.fill")
                        .foregroundStyle(Color(hex: "#4CAF50"))
                }
            }
        } header: {
            Text("Daily Limit")
        } footer: {
            Text("Biometric lock prevents accidental or impulsive changes to your limit.")
        }
    }

    private var notificationsSection: some View {
        Section("Notifications") {
            Picker(selection: $settingsVM.notificationIntervalMinutes) {
                Text("Off").tag(0)
                Text("15 min").tag(15)
                Text("30 min").tag(30)
                Text("1 hour").tag(60)
                Text("2 hours").tag(120)
            } label: {
                Label("Interval reminder", systemImage: "bell")
            }
            .onChange(of: settingsVM.notificationIntervalMinutes) { settingsVM.save() }

            NavigationLink {
                UsageRemindersView()
            } label: {
                Label("Custom Reminders", systemImage: "calendar.badge.clock")
            }
        }
    }

    private var securitySection: some View {
        Section("Security") {
            Toggle(isOn: $settingsVM.isBiometricEnabled) {
                Label("Biometric Lock", systemImage: biometricIcon)
            }
            .onChange(of: settingsVM.isBiometricEnabled) {
                settingsVM.save()
                if settingsVM.isBiometricEnabled { authenticateIfNeeded() }
            }

            NavigationLink {
                AppBlockingView()
            } label: {
                Label("Block Apps", systemImage: "hand.raised.fill")
            }
        }
    }

    private var accountSection: some View {
        Section {
            if let user = AuthService.shared.currentUser {
                HStack {
                    Label(user.displayName, systemImage: "person.crop.circle")
                    Spacer()
                    Text("Signed in")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Button {
                settingsVM.signOut()
            } label: {
                Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    .foregroundStyle(.primary)
            }

            Button(role: .destructive) {
                showDeleteConfirm = true
            } label: {
                Label("Delete Account", systemImage: "trash")
            }
        } header: {
            Text("Account")
        }
    }

    // MARK: - Helpers

    private var formattedLimit: String {
        let h = settingsVM.dailyLimitSeconds / 3600
        let m = (settingsVM.dailyLimitSeconds % 3600) / 60
        if h > 0 && m > 0 { return "\(h)h \(m)m" }
        if h > 0 { return "\(h)h" }
        return "\(m)m"
    }

    private var biometricIcon: String {
        BiometricService.shared.isAvailable ? "faceid" : "lock"
    }

    private func authenticateIfNeeded() {
        guard settingsVM.isBiometricEnabled else { isUnlocked = true; return }
        Task { isUnlocked = await BiometricService.shared.authenticate() }
    }
}

#Preview {
    SettingsView()
        .environmentObject(SettingsViewModel(service: MockScreenTimeService()))
        .environmentObject(PluggieViewModel(service: MockScreenTimeService()))
}
