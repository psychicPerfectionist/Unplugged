import SwiftUI

struct AppBlockingView: View {
    @EnvironmentObject private var pluggieVM: PluggieViewModel

    var body: some View {
        List {
            timerSection
            appSelectionSection
        }
        .navigationTitle("Block Apps")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Timer Pause Toggle

    private var timerSection: some View {
        Section {
            Toggle(isOn: Binding(
                get: { pluggieVM.isBlockingActive },
                set: {
                    pluggieVM.setBlockingActive($0)
                    HapticsService.shared.impactMedium()
                }
            )) {
                Label(
                    pluggieVM.isBlockingActive ? "Timer paused" : "Pause timer",
                    systemImage: pluggieVM.isBlockingActive ? "pause.circle.fill" : "pause.circle"
                )
            }
            .tint(Color(hex: "#5C6BC0"))
        } header: {
            Text("Screen Time Timer")
        } footer: {
            Text("While paused, Pluggie's health stops dropping. Use this when you need focused time without being penalised.")
        }
    }

    // MARK: - App Selection (device-only)

    private var appSelectionSection: some View {
        Section {
            HStack(spacing: 12) {
                Image(systemName: "iphone")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                    .frame(width: 36)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Real Device Required")
                        .font(.subheadline.bold())
                    Text("Selecting specific apps to block uses Apple's Screen Time API, which requires a physical iPhone and the Family Controls entitlement.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)
        } header: {
            Text("Choose Apps to Block")
        } footer: {
            Text("On a real device with the entitlement provisioned, you would see a system picker here to choose exactly which apps get locked.")
        }
    }
}

#Preview {
    NavigationStack { AppBlockingView() }
        .environmentObject(PluggieViewModel(service: MockScreenTimeService()))
}
