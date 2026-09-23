import SwiftUI

extension Color {
    init(hex: String, fallback: Color = Color("AccentColor")) {
        var sanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if sanitized.hasPrefix("#") {
            sanitized.removeFirst()
        }
        guard sanitized.count == 6, let value = UInt64(sanitized, radix: 16) else {
            self = fallback
            return
        }
        let red = Double((value & 0xFF00_00) >> 16) / 255.0
        let green = Double((value & 0x00FF_00) >> 8) / 255.0
        let blue = Double(value & 0x0000_FF) / 255.0
        self = Color(.sRGB, red: red, green: green, blue: blue, opacity: 1)
    }
}
