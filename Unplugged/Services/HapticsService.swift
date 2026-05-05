import UIKit

final class HapticsService {
    static let shared = HapticsService()
    private init() {}

    func impactLight()   { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
    func impactMedium()  { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
    func impactHeavy()   { UIImpactFeedbackGenerator(style: .heavy).impactOccurred() }
    func notifySuccess() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    func notifyWarning() { UINotificationFeedbackGenerator().notificationOccurred(.warning) }
    func notifyDeath()   { UINotificationFeedbackGenerator().notificationOccurred(.error) }
}
