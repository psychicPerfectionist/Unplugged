import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @EnvironmentObject private var settingsVM: SettingsViewModel

    @State private var email        = ""
    @State private var password     = ""
    @State private var isLoading    = false
    @State private var errorMessage: String?
    @State private var showSignUp   = false
    @State private var showForgot   = false

    // Inline validation
    private var emailError: String? {
        guard !email.isEmpty else { return nil }
        return email.contains("@") && email.contains(".") ? nil : "Enter a valid email address."
    }
    private var canSubmit: Bool {
        !email.isEmpty && email.contains("@") && !password.isEmpty && !isLoading
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    Spacer(minLength: 32)
                    logo
                    emailFields
                    appleSignIn
                    forgotPasswordButton
                    Spacer(minLength: 16)
                    signUpFooter
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
            }
            .navigationDestination(isPresented: $showSignUp) { SignUpView() }
            .navigationDestination(isPresented: $showForgot) { ForgotPasswordView() }
            .alert("Sign In Failed", isPresented: .constant(errorMessage != nil), actions: {
                Button("OK") { errorMessage = nil }
            }, message: {
                Text(errorMessage ?? "")
            })
        }
    }

    // MARK: - Subviews

    private var logo: some View {
        VStack(spacing: 12) {
            Circle()
                .fill(Color(hex: "#4CAF50").opacity(0.15))
                .frame(width: 80, height: 80)
                .overlay(Text("🌿").font(.system(size: 40)))
            Text("Unplugged")
                .font(.largeTitle.bold())
            Text("Sign in to keep Pluggie alive")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var emailFields: some View {
        VStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                if let err = emailError {
                    Text(err).font(.caption).foregroundStyle(.red).padding(.leading, 4)
                }
            }

            SecureField("Password", text: $password)
                .textContentType(.password)
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))

            Button {
                signIn()
            } label: {
                Group {
                    if isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text("Sign In").font(.headline)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(canSubmit ? Color(hex: "#4CAF50") : Color.secondary.opacity(0.3),
                            in: RoundedRectangle(cornerRadius: 12))
                .foregroundStyle(.white)
            }
            .disabled(!canSubmit)
        }
    }

    private var appleSignIn: some View {
        VStack(spacing: 12) {
            HStack {
                Rectangle().frame(height: 1).foregroundStyle(.secondary.opacity(0.3))
                Text("or").font(.caption).foregroundStyle(.secondary)
                Rectangle().frame(height: 1).foregroundStyle(.secondary.opacity(0.3))
            }

            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.fullName, .email]
            } onCompletion: { result in
                handleAppleSignIn(result)
            }
            .signInWithAppleButtonStyle(.black)
            .frame(height: 52)
            .cornerRadius(12)
        }
    }

    private var forgotPasswordButton: some View {
        Button("Forgot password?") { showForgot = true }
            .font(.footnote)
            .foregroundStyle(Color(hex: "#4CAF50"))
    }

    private var signUpFooter: some View {
        Button {
            showSignUp = true
        } label: {
            HStack(spacing: 4) {
                Text("Don't have an account?").foregroundStyle(.secondary)
                Text("Sign Up").foregroundStyle(Color(hex: "#4CAF50")).bold()
            }
            .font(.subheadline)
        }
    }

    // MARK: - Actions

    private func signIn() {
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isLoading = false
            do {
                _ = try AuthService.shared.signInWithEmail(email: email, password: password)
                HapticsService.shared.notifySuccess()
                settingsVM.markAuthenticated()
            } catch {
                errorMessage = error.localizedDescription
            }
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
                errorMessage = error.localizedDescription
            }
        case .failure(let error):
            let nsError = error as NSError
            // User cancelled — don't show an error
            if nsError.code == ASAuthorizationError.canceled.rawValue { return }
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(SettingsViewModel(service: MockScreenTimeService()))
}
