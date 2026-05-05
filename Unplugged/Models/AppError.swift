import Foundation

enum AppError: LocalizedError {
    case coreDataSave(Error)
    case cloudKitUnavailable
    case cloudKitFetchFailed(Error)
    case screenTimePermissionDenied
    case biometricFailed(Error)
    case notificationPermissionDenied

    var errorDescription: String? {
        switch self {
        case .coreDataSave(let e):       return "Failed to save data: \(e.localizedDescription)"
        case .cloudKitUnavailable:       return "iCloud is not available. Please sign in."
        case .cloudKitFetchFailed(let e): return "Failed to fetch friends: \(e.localizedDescription)"
        case .screenTimePermissionDenied: return "Screen Time access is required."
        case .biometricFailed(let e):    return "Biometric authentication failed: \(e.localizedDescription)"
        case .notificationPermissionDenied: return "Notification permission is required for reminders."
        }
    }
}
