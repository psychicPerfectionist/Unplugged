import SwiftUI

enum PluggieMood: String, CaseIterable {
    case thriving   = "thriving"
    case content    = "content"
    case worried    = "worried"
    case struggling = "struggling"
    case critical   = "critical"
    case dead       = "dead"

    init(healthPercent: Double) {
        switch healthPercent {
        case 0..<25:  self = .thriving
        case 25..<50: self = .content
        case 50..<75: self = .worried
        case 75..<90: self = .struggling
        case 90..<100: self = .critical
        default:      self = .dead
        }
    }

    var tintColor: Color {
        switch self {
        case .thriving:   return Color(hex: "#4CAF50")
        case .content:    return Color(hex: "#8BC34A")
        case .worried:    return Color(hex: "#FFEB3B")
        case .struggling: return Color(hex: "#FF9800")
        case .critical:   return Color(hex: "#F44336")
        case .dead:       return Color(hex: "#9E9E9E")
        }
    }

    var accessibilityLabel: String {
        switch self {
        case .thriving:   return "Thriving"
        case .content:    return "Content"
        case .worried:    return "Worried"
        case .struggling: return "Struggling"
        case .critical:   return "Critical"
        case .dead:       return "Dead"
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8)  & 0xFF) / 255
        let b = Double(int & 0xFF)         / 255
        self.init(red: r, green: g, blue: b)
    }
}
