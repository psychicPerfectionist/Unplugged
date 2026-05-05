import SwiftUI
import AuthenticationServices

struct SignUpView: View {
    @EnvironmentObject private var settingsVM: SettingsViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var displayName  = ""
    @State private var email        = ""
    @State private var password     = ""
    @State private var confirmPass  = ""
    @State private var isLoading    = false
    @State private var errorMessage: String?

    // Inline validation
    private var nameError: String? {
        guard !displayName.isEmpty else { return nil }
        return displayName.count >= 2 ? nil : "Name must be at least 2 characters."
    }
    private var emailError: String? {
        guard !email.isEmpty else { return nil }
        return email.contains("@") && email.contains(".") ? nil : "Enter a valid email address."
    }
    private var passwordError: String? {
        guard !password.isEmpty else { return nil }
        return password.count >= 6 ? nil : "Password must be at least 6 characters."
    }
    private var confirmError: String? {
        guard !confirmPass.isEmpty else { return nil }
        return confirmPass == password ? nil : "Passwords do not match."
    }
    private var canSubmit: Bool {
        !displayName.isEmpty && displayName.count >= 2 &&
        !email.isEmpty && email.contains("@") &&
        password.count >= 6 && confirmPass == password &&
        !isLoading
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                Spacer(minLength: 16)
                header
                fields
                appleSignUp
                Spacer(minLength: 8)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
        .navigationTitle("Create Account")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Sign Up Failed", isPresented: .constant(errorMessage != nil), actions: {
            Button("OK") { errorMessage = nil }
        }, message: {
            Text(errorMessage ?? "")
        })
    }

    // MARK: - Subviews

    private var header: some View {
        VStack(spacing: 8) {
            Text("Welcome to Unplugged")
                .font(.title2.bold())
            Text("Create an account to get started.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var fields: some View {
        VStack(spacing: 12) {
            validatedField(
                placeholder: "Display Name",
                text: $displayName,
                contentType: .name,
                error: nameError
            )

            validatedField(
                placeholder: "Email",
                text: $email,
                contentType: .emailAddress,
                keyboard: .emailAddress,
                error: emailError
            )

            VStack(alignment: .leading, spacing: 4) {
                SecureField("Password (min 6 characters)", text: $password)
                    .textContentType(.newPassword)
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                if let err = passwordError {
                    Text(err).font(.caption).foregroundStyle(.red).padding(.leading, 4)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                SecureField("Confirm Password", text: $confirmPass)
                    .textContentType(.newPassword)
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                if let err = confirmError {
                    Text(err).font(.caption).foregroundStyle(.red).padding(.leading, 4)
                }
            }

            Button {
                signUp()
            } label: {
                Group {
                    if isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text("Create Account").font(.headline)
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

    private var appleSignUp: some View {
        VStack(spacing: 12) {
            HStack {
                Rectangle().frame(height: 1).foregroundStyle(.secondary.opacity(0.3))
                Text("or").font(.caption).foregroundStyle(.secondary)
                Rectangle().frame(height: 1).foregroundStyle(.secondary.opacity(0.3))
            }

            SignInWithAppleButton(.signUp) { request in
                request.requestedScopes = [.fullName, .email]
            } onCompletion: { result in
                handleAppleSignUp(result)
            }
            .signInWithAppleButtonStyle(.black)
            .frame(height: 52)
            .cornerRadius(12)

            Button("Already have an account? Sign In") { dismiss() }
                .font(.subheadline)
                .foregroundStyle(Color(hex: "#4CAF50"))
        }
    }

    @ViewBuilder
    private func validatedField(
        placeholder: String,
        text: Binding<String>,
        contentType: UITextContentType,
        keyboard: UIKeyboardType = .default,
        error: String?
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            TextField(placeholder, text: text)
                .textContentType(contentType)
                .keyboardType(keyboard)
                .autocapitalization(keyboard == .emailAddress ? .none : .words)
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            if let err = error {
                Text(err).font(.caption).foregroundStyle(.red).padding(.leading, 4)
            }
        }
    }

    // MARK: - Actions

    private func signUp() {
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isLoading = false
            do {
                _ = try AuthService.shared.signUp(
                    displayName: displayName.trimmingCharacters(in: .whitespaces),
                    email: email.lowercased().trimmingCharacters(in: .whitespaces),
                    password: password
                )
                HapticsService.shared.notifySuccess()
                settingsVM.markAuthenticated()
            } catch {
                errorMessage = error.localizedDescription
            }
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
                errorMessage = error.localizedDescription
            }
        case .failure(let error):
            let nsError = error as NSError
            if nsError.code == ASAuthorizationError.canceled.rawValue { return }
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack { SignUpView() }
        .environmentObject(SettingsViewModel(service: MockScreenTimeService()))
}
