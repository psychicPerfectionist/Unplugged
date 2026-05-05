import SwiftUI

struct AppBlockingView: View {
    @EnvironmentObject private var pluggieVM: PluggieViewModel
    @State private var showPicker = false

    var body: some View {
        List {
            Section {
                Toggle("Block selected apps", isOn: Binding(
                    get: { pluggieVM.isBlockingActive },
                    set: {
                        pluggieVM.setBlockingActive($0)
                        HapticsService.shared.impactMedium()
                    }
                ))
            } footer: {
                Text("While app blocking is active, Pluggie's health timer is paused.")
            }

            Section("Selected Apps") {
                Button("Choose Apps…") { showPicker = true }
                    .sheet(isPresented: $showPicker) {
                        FamilyActivityPickerPlaceholder()
                    }
            }
        }
        .navigationTitle("Block Apps")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct FamilyActivityPickerPlaceholder: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Requires Device",
                systemImage: "iphone.slash",
                description: Text("FamilyActivityPicker runs only on a real device with the com.apple.developer.family-controls entitlement.")
            )
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    NavigationStack { AppBlockingView() }
        .environmentObject(PluggieViewModel(service: MockScreenTimeService()))
}
