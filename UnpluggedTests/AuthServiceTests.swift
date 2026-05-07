import XCTest
@testable import Unplugged

/// Tests for AuthService's email/password flows, sign-out, and account deletion.
/// Uses the real Keychain (test host runs inside the Unplugged.app process).
/// Each test creates and then deletes its own test account to stay isolated.
final class AuthServiceTests: XCTestCase {

    let auth = AuthService.shared

    // Use a test-specific email suffix so we don't collide with real accounts
    private func email(_ name: String) -> String { "\(name)_unittest@unplugged.test" }

    override func setUp() {
        super.setUp()
        auth.deleteAccount()
    }

    override func tearDown() {
        auth.deleteAccount()
        super.tearDown()
    }

    // MARK: - isAuthenticated / currentUser when no account exists

    func testIsNotAuthenticatedInitially() {
        XCTAssertFalse(auth.isAuthenticated)
    }

    func testCurrentUserIsNilWhenNotAuthenticated() {
        XCTAssertNil(auth.currentUser)
    }

    // MARK: - signUp

    func testSignUpReturnsProfileWithCorrectDisplayName() throws {
        let profile = try auth.signUp(displayName: "Alice",
                                      email: email("alice"), password: "pass1")
        XCTAssertEqual(profile.displayName, "Alice")
    }

    func testSignUpReturnsNonEmptyID() throws {
        let profile = try auth.signUp(displayName: "Bob",
                                      email: email("bob"), password: "pass1")
        XCTAssertFalse(profile.id.isEmpty)
    }

    func testSignUpSetsAuthenticatedToTrue() throws {
        _ = try auth.signUp(displayName: "Carol",
                            email: email("carol"), password: "pass1")
        XCTAssertTrue(auth.isAuthenticated)
    }

    func testSignUpCurrentUserMatchesReturnedProfile() throws {
        let profile = try auth.signUp(displayName: "Dave",
                                      email: email("dave"), password: "pass1")
        XCTAssertEqual(auth.currentUser?.displayName, profile.displayName)
    }

    func testSignUpDuplicateEmailThrowsUserAlreadyExists() throws {
        _ = try auth.signUp(displayName: "Eve", email: email("eve"), password: "pass1")

        do {
            _ = try auth.signUp(displayName: "Eve2", email: email("eve"), password: "pass2")
            XCTFail("Expected userAlreadyExists")
        } catch AuthError.userAlreadyExists {
            // Expected path
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testSignUpNormalisesEmailToLowercase() throws {
        _ = try auth.signUp(displayName: "Frank",
                            email: "FRANK_UNITTEST@UNPLUGGED.TEST", password: "pass1")
        // Should be able to sign in with lowercase version
        let profile = try auth.signInWithEmail(email: "frank_unittest@unplugged.test",
                                               password: "pass1")
        XCTAssertEqual(profile.displayName, "Frank")
    }

    func testSignUpTrimsWhitespaceFromEmail() throws {
        _ = try auth.signUp(displayName: "Grace",
                            email: "  \(email("grace"))  ", password: "pass1")
        let profile = try auth.signInWithEmail(email: email("grace"), password: "pass1")
        XCTAssertEqual(profile.displayName, "Grace")
    }

    // MARK: - signInWithEmail

    func testSignInWithCorrectCredentialsSucceeds() throws {
        _ = try auth.signUp(displayName: "Heidi", email: email("heidi"), password: "secret")
        auth.signOut()

        let profile = try auth.signInWithEmail(email: email("heidi"), password: "secret")
        XCTAssertEqual(profile.displayName, "Heidi")
    }

    func testSignInSetsAuthenticatedToTrue() throws {
        _ = try auth.signUp(displayName: "Ivan", email: email("ivan"), password: "pass1")
        auth.signOut()

        _ = try auth.signInWithEmail(email: email("ivan"), password: "pass1")
        XCTAssertTrue(auth.isAuthenticated)
    }

    func testSignInWithWrongPasswordThrowsInvalidCredentials() throws {
        _ = try auth.signUp(displayName: "Judy", email: email("judy"), password: "correct")
        auth.signOut()

        do {
            _ = try auth.signInWithEmail(email: email("judy"), password: "wrong")
            XCTFail("Expected invalidCredentials")
        } catch AuthError.invalidCredentials {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testSignInWithUnknownEmailThrowsUserNotFound() {
        do {
            _ = try auth.signInWithEmail(email: "nobody@unplugged.test", password: "pass")
            XCTFail("Expected userNotFound")
        } catch AuthError.userNotFound {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - resetPassword

    func testResetPasswordAllowsSignInWithNewPassword() throws {
        _ = try auth.signUp(displayName: "Karl", email: email("karl"), password: "old")
        auth.signOut()

        try auth.resetPassword(email: email("karl"), newPassword: "new")
        let profile = try auth.signInWithEmail(email: email("karl"), password: "new")
        XCTAssertEqual(profile.displayName, "Karl")
    }

    func testResetPasswordPreventsSignInWithOldPassword() throws {
        _ = try auth.signUp(displayName: "Lara", email: email("lara"), password: "old")
        auth.signOut()

        try auth.resetPassword(email: email("lara"), newPassword: "new")

        do {
            _ = try auth.signInWithEmail(email: email("lara"), password: "old")
            XCTFail("Expected invalidCredentials after password reset")
        } catch AuthError.invalidCredentials {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testResetPasswordForUnknownEmailThrowsUserNotFound() {
        do {
            try auth.resetPassword(email: "nobody@unplugged.test", newPassword: "new")
            XCTFail("Expected userNotFound")
        } catch AuthError.userNotFound {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - signOut

    func testSignOutClearsIsAuthenticated() throws {
        _ = try auth.signUp(displayName: "Mike", email: email("mike"), password: "pass1")
        auth.signOut()
        XCTAssertFalse(auth.isAuthenticated)
    }

    func testSignOutClearsCurrentUser() throws {
        _ = try auth.signUp(displayName: "Nina", email: email("nina"), password: "pass1")
        auth.signOut()
        XCTAssertNil(auth.currentUser)
    }

    func testSignOutPreservesCredentialsForReLogin() throws {
        _ = try auth.signUp(displayName: "Otto", email: email("otto"), password: "pass1")
        auth.signOut()

        // Credentials should still work after sign out
        let profile = try auth.signInWithEmail(email: email("otto"), password: "pass1")
        XCTAssertEqual(profile.displayName, "Otto")
    }

    // MARK: - deleteAccount

    func testDeleteAccountClearsIsAuthenticated() throws {
        _ = try auth.signUp(displayName: "Pam", email: email("pam"), password: "pass1")
        auth.deleteAccount()
        XCTAssertFalse(auth.isAuthenticated)
    }

    func testDeleteAccountClearsCurrentUser() throws {
        _ = try auth.signUp(displayName: "Quinn", email: email("quinn"), password: "pass1")
        auth.deleteAccount()
        XCTAssertNil(auth.currentUser)
    }

    func testDeleteAccountPreventsReLogin() throws {
        _ = try auth.signUp(displayName: "Rob", email: email("rob"), password: "pass1")
        auth.deleteAccount()

        do {
            _ = try auth.signInWithEmail(email: email("rob"), password: "pass1")
            XCTFail("Expected userNotFound after account deletion")
        } catch AuthError.userNotFound {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testDeleteAccountIsIdempotent() throws {
        _ = try auth.signUp(displayName: "Sam", email: email("sam"), password: "pass1")
        auth.deleteAccount()
        // Should not crash on second call
        auth.deleteAccount()
        XCTAssertFalse(auth.isAuthenticated)
    }
}
