import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var settingsVM: SettingsViewModel
    @State private var page = 0

    var body: some View {
        TabView(selection: $page) {
            onboardingPage(
                systemImage: "iphone.slash",
                title: "Take Back Your Time",
                description: "Unplugged turns your screen time into a virtual pet experience.",
                tag: 0
            )
            onboardingPage(
                systemImage: "heart.fill",
                title: "Meet Pluggie",
                description: "Keep Pluggie alive by staying under your daily limit. Exceed it and Pluggie dies.",
                tag: 1
            )

            limitSetupPage
        }
        .tabViewStyle(.page)
        .indexViewStyle(.page(backgroundDisplayMode: .always))
    }

    private func onboardingPage(systemImage: String, title: String, description: String, tag: Int) -> some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: systemImage)
                .font(.system(size: 80))
                .foregroundStyle(Color(hex: "#4CAF50"))
            Text(title)
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
            Text(description)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
            Button("Next") { withAnimation { page += 1 } }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(hex: "#4CAF50"), in: RoundedRectangle(cornerRadius: 14))
                .foregroundStyle(.white)
                .font(.headline)
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
        }
        .tag(tag)
    }

    private var limitSetupPage: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "timer")
                .font(.system(size: 80))
                .foregroundStyle(Color(hex: "#4CAF50"))
            Text("Set Your Daily Limit")
                .font(.largeTitle.bold())

            Text("How long can you be on your phone each day?")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            limitPicker

            Spacer()

            Button("Get Started") {
                settingsVM.save()
                settingsVM.completeOnboarding()
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(hex: "#4CAF50"), in: RoundedRectangle(cornerRadius: 14))
            .foregroundStyle(.white)
            .font(.headline)
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
        .tag(2)
    }

    private var limitPicker: some View {
        HStack {
            Picker("Hours", selection: Binding(
                get: { Int(settingsVM.dailyLimitSeconds / 3600) },
                set: { settingsVM.dailyLimitSeconds = $0 * 3600 + settingsVM.dailyLimitSeconds % 3600 }
            )) {
                ForEach(0..<24, id: \.self) { Text("\($0)h").tag($0) }
            }
            .pickerStyle(.wheel)
            .frame(maxWidth: .infinity)

            Picker("Minutes", selection: Binding(
                get: { Int((settingsVM.dailyLimitSeconds % 3600) / 60) },
                set: { settingsVM.dailyLimitSeconds = (settingsVM.dailyLimitSeconds / 3600) * 3600 + $0 * 60 }
            )) {
                ForEach([0, 15, 30, 45], id: \.self) { Text("\($0)m").tag($0) }
            }
            .pickerStyle(.wheel)
            .frame(maxWidth: .infinity)
        }
        .frame(height: 150)
    }
}

#Preview {
    OnboardingView()
        .environmentObject(SettingsViewModel(service: MockScreenTimeService()))
}
