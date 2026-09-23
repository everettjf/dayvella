import SwiftUI

struct CardNumberView: View {
    let value: Int
    var label: String = "Days"
    var color: Color = Color(hex: "#00E0A4")
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text("\(value)")
                .font(.system(size: 44, weight: .heavy, design: .monospaced))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .allowsTightening(true)
                .foregroundStyle(textColor)
            Text(label.uppercased())
                .font(.system(.caption2, design: .monospaced).weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .foregroundStyle(secondaryTextColor)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(background)
    }

    private var background: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(Color(UIColor.tertiarySystemGroupedBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(color.opacity(colorScheme == .dark ? 0.11 : 0.065))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(color.opacity(colorScheme == .dark ? 0.22 : 0.14), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.12 : 0.04), radius: 6, x: 0, y: 3)
    }

    private var textColor: Color {
        .primary
    }

    private var secondaryTextColor: Color {
        .secondary
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    CardNumberView(value: 421)
        .padding()
        .background(Color(UIColor.systemGroupedBackground))
        }
