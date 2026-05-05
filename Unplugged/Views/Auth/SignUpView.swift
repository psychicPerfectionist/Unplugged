import SwiftUI
import AuthenticationServices

struct SignUpView: View {
    @EnvironmentObject private var settingsVM: SettingsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var displayName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var authError: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                Spacer(minLength: 32)
                Text("Create Account")
                    .font(.largeTitle.bold())

                fields

                SignInWithAppleButton(.signUp) { request in
                    request.requestedScopes = [.fullName, .email]
                } onCompletion: { result in
                    handleAppleSignUp(result)
                }
                .signInWithAppleButtonStyle(.black)
                .frame(height: 52)
                .cornerRadius(12)

                Button("Already have an account? Sign In") { dismiss() }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 32)
        }
        .navigationTitle("Sign Up")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Sign Up Failed", isPresented: .constant(authError != nil), actions: {
            Button("OK") { authError = nil }
        }, message: {
            Text(authError ?? "")
        })
    }

    private var fields: some View {
        VStack(spacing: 12) {
            TextField("Display Name", text: $displayName)
                .textContentType(.name)
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))

            TextField("Email", text: $email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))

            SecureField("Password", text: $password)
                .textContentType(.newPassword)
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))

            Button("Create Account") { signUp() }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(hex: "#4CAF50"), in: RoundedRectangle(cornerRadius: 12))
                .foregroundStyle(.white)
                .font(.headline)
        }
    }

    private func signUp() {
        do {
            _ = try AuthService.shared.signUp(displayName: displayName, email: email, password: password)
            HapticsService.shared.notifySuccess()
            settingsVM.markAuthenticated()
        } catch {
            authError = error.localizedDescription
        }
    }

    private func handleAppleSignUp(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            do {
                _ = try AuthService.shared.signInWithApple(authorization)
                HapticsService.shared.notifySuccess()
                settingsVM.markAuthenticated()
            } catch {
                authError = error.localizedDescription
            }
        case .failure(let error):
            authError = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack { SignUpView() }
        .environmentObject(SettingsViewModel(service: MockScreenTimeService()))
}
