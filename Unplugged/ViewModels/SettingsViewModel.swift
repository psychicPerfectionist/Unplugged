import Foundation
import Combine
import CoreData

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var isOnboardingComplete: Bool
    @Published var isAuthenticated: Bool
    @Published var dailyLimitSeconds: Int
    @Published var notificationIntervalMinutes: Int
    @Published var isBiometricEnabled: Bool

    private let service: any ScreenTimeServiceProtocol
    private let defaults = AppGroupConstants.sharedDefaults

    init(service: any ScreenTimeServiceProtocol) {
        self.service                 = service
        isOnboardingComplete         = UserDefaults.standard.bool(forKey: "onboardingComplete")
        isAuthenticated              = AuthService.shared.isAuthenticated
        dailyLimitSeconds            = service.dailyLimitSeconds
        notificationIntervalMinutes  = 30
        isBiometricEnabled           = false
        loadFromCoreData()
    }

    func completeOnboarding() {
        isOnboardingComplete = true
        UserDefaults.standard.set(true, forKey: "onboardingComplete")
    }

    func markAuthenticated() {
        isAuthenticated = true
    }

    func signOut() {
        AuthService.shared.signOut()
        isAuthenticated = false
    }

    func deleteAccount() {
        AuthService.shared.deleteAccount()
        CoreDataStack.shared.deleteAllData()
        UserDefaults.standard.removeObject(forKey: "onboardingComplete")
        UserDefaults.standard.removeObject(forKey: "reminderItems")
        defaults.removeObject(forKey: AppGroupConstants.UserDefaultsKeys.dailyLimitSeconds)
        isOnboardingComplete = false
        isAuthenticated = false
    }

    func save() {
        service.setDailyLimit(dailyLimitSeconds)
        defaults.set(dailyLimitSeconds, forKey: AppGroupConstants.UserDefaultsKeys.dailyLimitSeconds)
        NotificationService.shared.scheduleReminder(intervalMinutes: notificationIntervalMinutes)
        saveToCoreData()
    }

    private func loadFromCoreData() {
        let context = CoreDataStack.shared.viewContext
        let request = NSFetchRequest<UserSettings>(entityName: "UserSettings")
        if let s = try? context.fetch(request).first {
            dailyLimitSeconds           = Int(s.dailyLimitSeconds)
            notificationIntervalMinutes = Int(s.notificationInterval)
            isBiometricEnabled          = s.isBiometricEnabled
        }
    }

    private func saveToCoreData() {
        let context = CoreDataStack.shared.viewContext
        let request = NSFetchRequest<UserSettings>(entityName: "UserSettings")
        let entity  = (try? context.fetch(request).first) ?? UserSettings(context: context)
        entity.dailyLimitSeconds    = Int64(dailyLimitSeconds)
        entity.notificationInterval = Int16(notificationIntervalMinutes)
        entity.isBiometricEnabled   = isBiometricEnabled
        CoreDataStack.shared.save()
    }
}
