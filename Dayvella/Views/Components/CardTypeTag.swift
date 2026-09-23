import SwiftUI

struct CardTypeTag: View {
    let text: String
    var tint: Color = Color(hex: "#00E5FF")
    var textColorOverride: Color?
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 11, weight: .black, design: .monospaced))
            .kerning(1.3)
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .foregroundStyle(textColor)
            .background(tagBackground)
    }

    private var tagBackground: some View {
        Capsule(style: .continuous)
            .fill(Color(UIColor.tertiarySystemGroupedBackground))
            .overlay(
                Capsule(style: .continuous)
                    .fill(tint.opacity(colorScheme == .dark ? 0.12 : 0.075))
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(tint.opacity(colorScheme == .dark ? 0.24 : 0.16), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.08 : 0.025), radius: 4, x: 0, y: 2)
    }

    private var textColor: Color {
        textColorOverride ?? .primary
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    CardTypeTag(text: "Cumulative")
        .padding()
        .background(Color(UIColor.systemGroupedBackground))
        }
