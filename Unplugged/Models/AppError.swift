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
        case .coreDataSave:
            return "Your data couldn't be saved. Please try again."
        case .cloudKitUnavailable:
            return "The leaderboard requires iCloud. Please sign in to iCloud in your device Settings."
        case .cloudKitFetchFailed:
            return "Couldn't load the leaderboard. Check your internet connection and try again."
        case .screenTimePermissionDenied:
            return "Screen Time access is required. Please grant permission in Settings → Screen Time."
        case .biometricFailed:
            return "Biometric authentication failed. Please try again."
        case .notificationPermissionDenied:
            return "Notifications are disabled. Enable them in Settings → Notifications → Unplugged."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .cloudKitUnavailable:
            return "Open Settings → [Your Name] → iCloud and ensure it is signed in."
        case .screenTimePermissionDenied:
            return "Open Settings → Screen Time and allow Unplugged access."
        case .notificationPermissionDenied:
            return "Open Settings → Notifications → Unplugged and enable Allow Notifications."
        default:
            return nil
        }
    }
}
