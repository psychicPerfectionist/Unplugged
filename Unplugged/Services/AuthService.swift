import AuthenticationServices
import CryptoKit
import Foundation
import Security

enum AuthError: LocalizedError {
    case invalidCredentials
    case userNotFound
    case userAlreadyExists
    case keychainError(OSStatus)
    case appleSignInFailed(Error)
    case missingCredential

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Incorrect email or password. Please try again."
        case .userNotFound:
            return "No account found for that email address. Please check and try again."
        case .userAlreadyExists:
            return "An account with that email already exists. Try signing in instead."
        case .keychainError(let s):
            return "A secure storage error occurred (code \(s)). Please try again."
        case .appleSignInFailed(let e):
            return "Apple Sign-In failed: \(e.localizedDescription)"
        case .missingCredential:
            return "Could not read your Apple ID credential. Please try again."
        }
    }
}

final class AuthService {
    static let shared = AuthService()
    private init() {}

    // MARK: - Public API

    var isAuthenticated: Bool {
        readString(key: .userID) != nil
    }

    var currentUser: UserProfile? {
        guard let id = readString(key: .userID),
              let name = readString(key: .displayName) else { return nil }
        return UserProfile(id: id, displayName: name)
    }

    func signInWithApple(_ authorization: ASAuthorization) throws -> UserProfile {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential
        else { throw AuthError.missingCredential }

        let userID = credential.user

        // Apple only sends fullName on first sign-in; preserve existing name on subsequent logins
        let name: String
        if let fullName = credential.fullName,
           let given = fullName.givenName, !given.isEmpty {
            let full = [given, fullName.familyName].compactMap { $0 }.joined(separator: " ")
            name = full
            save(string: name, key: .displayName)
        } else {
            name = readString(key: .displayName) ?? "Pluggie User"
        }

        save(string: userID, key: .userID)
        if readString(key: .displayName) == nil {
            save(string: name, key: .displayName)
        }

        return UserProfile(id: userID, displayName: name)
    }

    func signInWithEmail(email: String, password: String) throws -> UserProfile {
        let cleanEmail = email.lowercased().trimmingCharacters(in: .whitespaces)
        guard let storedHash = readString(key: .passwordHash(email: cleanEmail)) else {
            throw AuthError.userNotFound
        }
        guard hash(password) == storedHash else {
            throw AuthError.invalidCredentials
        }
        let name   = readString(key: .displayNameForEmail(email: cleanEmail)) ?? cleanEmail
        let userID = "email-\(cleanEmail)"
        save(string: userID,      key: .userID)
        save(string: name,        key: .displayName)
        save(string: cleanEmail,  key: .lastEmail)
        return UserProfile(id: userID, displayName: name)
    }

    func signUp(displayName: String, email: String, password: String) throws -> UserProfile {
        let cleanEmail = email.lowercased().trimmingCharacters(in: .whitespaces)
        if readString(key: .passwordHash(email: cleanEmail)) != nil {
            throw AuthError.userAlreadyExists
        }
        save(string: hash(password), key: .passwordHash(email: cleanEmail))
        save(string: displayName,    key: .displayNameForEmail(email: cleanEmail))
        let userID = "email-\(cleanEmail)"
        save(string: userID,      key: .userID)
        save(string: displayName, key: .displayName)
        save(string: cleanEmail,  key: .lastEmail)
        return UserProfile(id: userID, displayName: displayName)
    }

    func resetPassword(email: String, newPassword: String) throws {
        let cleanEmail = email.lowercased().trimmingCharacters(in: .whitespaces)
        guard readString(key: .passwordHash(email: cleanEmail)) != nil else {
            throw AuthError.userNotFound
        }
        save(string: hash(newPassword), key: .passwordHash(email: cleanEmail))
    }

    func signOut() {
        delete(key: .userID)
        delete(key: .displayName)
        // Preserve credentials so user can sign back in
    }

    func deleteAccount() {
        // Remove credentials for email-based accounts
        if let email = readString(key: .lastEmail) {
            delete(key: .passwordHash(email: email))
            delete(key: .displayNameForEmail(email: email))
        }
        delete(key: .userID)
        delete(key: .displayName)
        delete(key: .lastEmail)
    }

    // MARK: - Keychain Keys

    private enum KeychainKey {
        case userID
        case displayName
        case lastEmail
        case passwordHash(email: String)
        case displayNameForEmail(email: String)

        var value: String {
            switch self {
            case .userID:                       return "com.unplugged.userID"
            case .displayName:                  return "com.unplugged.displayName"
            case .lastEmail:                    return "com.unplugged.lastEmail"
            case .passwordHash(let e):          return "com.unplugged.pw.\(e)"
            case .displayNameForEmail(let e):   return "com.unplugged.name.\(e)"
            }
        }
    }

    // MARK: - Keychain Helpers

    private func save(string: String, key: KeychainKey) {
        guard let data = string.data(using: .utf8) else { return }
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrAccount: key.value,
            kSecValueData:   data
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    private func readString(key: KeychainKey) -> String? {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrAccount: key.value,
            kSecReturnData:  true,
            kSecMatchLimit:  kSecMatchLimitOne
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func delete(key: KeychainKey) {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrAccount: key.value
        ]
        SecItemDelete(query as CFDictionary)
    }

    private func hash(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8)).map { String(format: "%02x", $0) }.joined()
    }
}
