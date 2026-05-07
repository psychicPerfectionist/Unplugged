import XCTest
@testable import Unplugged

final class AppErrorTests: XCTestCase {

    // MARK: - errorDescription

    func testCoreDataSaveHasDescription() {
        let error = AppError.coreDataSave(NSError(domain: "CD", code: 1))
        XCTAssertNotNil(error.errorDescription)
        XCTAssertFalse(error.errorDescription!.isEmpty)
    }

    func testCloudKitUnavailableHasDescription() {
        XCTAssertNotNil(AppError.cloudKitUnavailable.errorDescription)
        XCTAssertFalse(AppError.cloudKitUnavailable.errorDescription!.isEmpty)
    }

    func testCloudKitFetchFailedHasDescription() {
        let error = AppError.cloudKitFetchFailed(NSError(domain: "CK", code: 2))
        XCTAssertNotNil(error.errorDescription)
        XCTAssertFalse(error.errorDescription!.isEmpty)
    }

    func testScreenTimePermissionDeniedHasDescription() {
        XCTAssertNotNil(AppError.screenTimePermissionDenied.errorDescription)
        XCTAssertFalse(AppError.screenTimePermissionDenied.errorDescription!.isEmpty)
    }

    func testBiometricFailedHasDescription() {
        let error = AppError.biometricFailed(NSError(domain: "LA", code: -1))
        XCTAssertNotNil(error.errorDescription)
        XCTAssertFalse(error.errorDescription!.isEmpty)
    }

    func testNotificationPermissionDeniedHasDescription() {
        XCTAssertNotNil(AppError.notificationPermissionDenied.errorDescription)
        XCTAssertFalse(AppError.notificationPermissionDenied.errorDescription!.isEmpty)
    }

    // MARK: - recoverySuggestion

    func testCloudKitUnavailableHasRecoverySuggestion() {
        XCTAssertNotNil(AppError.cloudKitUnavailable.recoverySuggestion)
    }

    func testScreenTimePermissionDeniedHasRecoverySuggestion() {
        XCTAssertNotNil(AppError.screenTimePermissionDenied.recoverySuggestion)
    }

    func testNotificationPermissionDeniedHasRecoverySuggestion() {
        XCTAssertNotNil(AppError.notificationPermissionDenied.recoverySuggestion)
    }

    func testCoreDataSaveHasNoRecoverySuggestion() {
        let error = AppError.coreDataSave(NSError(domain: "CD", code: 1))
        XCTAssertNil(error.recoverySuggestion)
    }

    func testCloudKitFetchFailedHasNoRecoverySuggestion() {
        let error = AppError.cloudKitFetchFailed(NSError(domain: "CK", code: 2))
        XCTAssertNil(error.recoverySuggestion)
    }

    func testBiometricFailedHasNoRecoverySuggestion() {
        let error = AppError.biometricFailed(NSError(domain: "LA", code: -1))
        XCTAssertNil(error.recoverySuggestion)
    }

    // MARK: - LocalizedError conformance

    func testAllCasesAreThrownAsLocalizedErrors() {
        let errors: [AppError] = [
            .cloudKitUnavailable,
            .cloudKitFetchFailed(NSError(domain: "", code: 0)),
            .screenTimePermissionDenied,
            .biometricFailed(NSError(domain: "", code: 0)),
            .notificationPermissionDenied,
            .coreDataSave(NSError(domain: "", code: 0))
        ]
        for error in errors {
            let localized = error as LocalizedError
            XCTAssertNotNil(localized.errorDescription,
                            "\(error) should have a non-nil errorDescription")
        }
    }
}
