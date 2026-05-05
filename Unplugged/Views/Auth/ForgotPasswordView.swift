import SwiftUI

struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var email        = ""
    @State private var newPassword  = ""
    @State private var confirmPass  = ""
    @State private var isLoading    = false
    @State private var errorMessage: String?
    @State private var didSucceed   = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    Spacer(minLength: 16)
                    header
                    fields
                    Spacer(minLength: 8)
                }
                .padding(.horizontal, 32)
            }
            .navigationTitle("Reset Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Reset Successful", isPresented: $didSucceed) {
                Button("Sign In") { dismiss() }
            } message: {
                Text("Your password has been updated. Please sign in with your new password.")
            }
            .alert("Error", isPresented: .constant(errorMessage != nil), actions: {
                Button("OK") { errorMessage = nil }
            }, message: {
                Text(errorMessage ?? "")
            })
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: "lock.rotation")
                .font(.system(size: 56))
                .foregroundStyle(Color(hex: "#4CAF50"))
            Text("Forgot your password?")
                .font(.title2.bold())
            Text("Enter the email address and a new password. This only works for email-based accounts on this device.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var fields: some View {
        VStack(spacing: 12) {
            TextField("Email address", text: $email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))

            SecureField("New password (min 6 characters)", text: $newPassword)
                .textContentType(.newPassword)
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))

            SecureField("Confirm new password", text: $confirmPass)
                .textContentType(.newPassword)
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))

            Button {
                resetPassword()
            } label: {
                Group {
                    if isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text("Reset Password")
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(formIsValid ? Color(hex: "#4CAF50") : Color.secondary.opacity(0.3),
                            in: RoundedRectangle(cornerRadius: 12))
                .foregroundStyle(.white)
            }
            .disabled(!formIsValid || isLoading)
        }
    }

    private var formIsValid: Bool {
        !email.isEmpty && email.contains("@") && newPassword.count >= 6 && !confirmPass.isEmpty
    }

    private func resetPassword() {
        guard newPassword == confirmPass else {
            errorMessage = "Passwords do not match. Please try again."
            return
        }
        isLoading = true
        // Small delay to show loading state
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            isLoading = false
            do {
                try AuthService.shared.resetPassword(email: email, newPassword: newPassword)
                didSucceed = true
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

#Preview {
    ForgotPasswordView()
}
