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
        case .invalidCredentials:      return "Incorrect email or password."
        case .userNotFound:            return "No account found for that email."
        case .userAlreadyExists:       return "An account with that email already exists."
        case .keychainError(let s):    return "Keychain error (\(s))."
        case .appleSignInFailed(let e): return "Apple Sign-In failed: \(e.localizedDescription)"
        case .missingCredential:       return "Could not read credential from Apple."
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
        let name: String
        if let fullName = credential.fullName,
           let given = fullName.givenName {
            name = [given, fullName.familyName].compactMap { $0 }.joined(separator: " ")
            save(string: name, key: .displayName)
        } else {
            name = readString(key: .displayName) ?? "Pluggie User"
        }

        save(string: userID, key: .userID)
        save(string: name, key: .displayName)

        return UserProfile(id: userID, displayName: name)
    }

    func signInWithEmail(email: String, password: String) throws -> UserProfile {
        guard let storedHash = readString(key: .passwordHash(email: email)) else {
            throw AuthError.userNotFound
        }
        guard hash(password) == storedHash else {
            throw AuthError.invalidCredentials
        }
        let name = readString(key: .displayNameForEmail(email: email)) ?? email
        let userID = "email-\(email)"
        save(string: userID, key: .userID)
        save(string: name, key: .displayName)
        return UserProfile(id: userID, displayName: name)
    }

    func signUp(displayName: String, email: String, password: String) throws -> UserProfile {
        if readString(key: .passwordHash(email: email)) != nil {
            throw AuthError.userAlreadyExists
        }
        save(string: hash(password), key: .passwordHash(email: email))
        save(string: displayName, key: .displayNameForEmail(email: email))
        let userID = "email-\(email)"
        save(string: userID, key: .userID)
        save(string: displayName, key: .displayName)
        return UserProfile(id: userID, displayName: displayName)
    }

    func signOut() {
        delete(key: .userID)
        delete(key: .displayName)
    }

    // MARK: - Keychain Keys

    private enum KeychainKey {
        case userID
        case displayName
        case passwordHash(email: String)
        case displayNameForEmail(email: String)

        var value: String {
            switch self {
            case .userID:                       return "com.unplugged.userID"
            case .displayName:                  return "com.unplugged.displayName"
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
            kSecClass:            kSecClassGenericPassword,
            kSecAttrAccount:      key.value,
            kSecReturnData:       true,
            kSecMatchLimit:       kSecMatchLimitOne
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
        let digest = SHA256.hash(data: Data(input.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
