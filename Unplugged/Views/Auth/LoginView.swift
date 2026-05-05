import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @EnvironmentObject private var settingsVM: SettingsViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var showSignUp = false
    @State private var authError: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 28) {
                Spacer()
                logo
                emailFields
                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = [.fullName, .email]
                } onCompletion: { result in
                    handleAppleSignIn(result)
                }
                .signInWithAppleButtonStyle(.black)
                .frame(height: 52)
                .cornerRadius(12)

                Button("Forgot password?") { }
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Spacer()

                Button("Don't have an account? Sign Up") { showSignUp = true }
                    .font(.footnote)
            }
            .padding(.horizontal, 32)
            .navigationDestination(isPresented: $showSignUp) { SignUpView() }
            .alert("Sign In Failed", isPresented: .constant(authError != nil), actions: {
                Button("OK") { authError = nil }
            }, message: {
                Text(authError ?? "")
            })
        }
    }

    private var logo: some View {
        VStack(spacing: 8) {
            Circle()
                .fill(Color(hex: "#4CAF50").opacity(0.15))
                .frame(width: 80, height: 80)
                .overlay(Text("🌿").font(.system(size: 40)))
            Text("Unplugged")
                .font(.largeTitle.bold())
        }
    }

    private var emailFields: some View {
        VStack(spacing: 12) {
            TextField("Email", text: $email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))

            SecureField("Password", text: $password)
                .textContentType(.password)
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))

            Button("Sign In") { signIn() }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(hex: "#4CAF50"), in: RoundedRectangle(cornerRadius: 12))
                .foregroundStyle(.white)
                .font(.headline)
        }
    }

    private func signIn() {
        do {
            _ = try AuthService.shared.signInWithEmail(email: email, password: password)
            HapticsService.shared.notifySuccess()
            settingsVM.markAuthenticated()
        } catch {
            authError = error.localizedDescription
        }
    }

    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
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
    LoginView()
        .environmentObject(SettingsViewModel(service: MockScreenTimeService()))
}
