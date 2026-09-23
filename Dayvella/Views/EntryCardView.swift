import SwiftUI
import Combine
import UIKit

struct EntryCardView: View {
    let snapshot: EntrySnapshot
    let updatesLive: Bool
    @State private var now: Date = Date()
    @Environment(\.colorScheme) private var colorScheme

    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    init(snapshot: EntrySnapshot, updatesLive: Bool = true) {
        self.snapshot = snapshot
        self.updatesLive = updatesLive
    }

    private var accent: Color {
        Color(hex: TrendingCardPalettes.resolvedPrimaryHex(for: snapshot.colorHex))
    }

    // Fixed professional colors - not affected by system color scheme
    private var titleColor: Color { palette.primaryTextColor }
    private var secondaryColor: Color { palette.secondaryTextColor }

    private var dateLine: String {
        let date = snapshot.entryType == .countUp ? snapshot.startDate : DayCounter.effectiveTargetDate(for: snapshot, now: now)
        guard let date else { return "--" }
        let formatter = DateFormatters.cardDateFormatter(for: snapshot.timezone)
        return formatter.string(from: date)
    }

    private var dateLabel: String {
        if snapshot.entryType == .countDown && snapshot.repeatRule != .none {
            return "Next Target"
        }
        return snapshot.entryType == .countUp ? "Start Date" : "Target Date"
    }

    private var days: Int { DayCounter.days(for: snapshot, now: now) }

    private var rangeLine: String? {
        guard snapshot.rangeStart != nil || snapshot.rangeEnd != nil else { return nil }
        let formatter = DateFormatters.cardDateFormatter(for: snapshot.timezone)
        let startText = snapshot.rangeStart.map { formatter.string(from: $0) } ?? "--"
        let endText = snapshot.rangeEnd.map { formatter.string(from: $0) } ?? "--"
        return "Range: \(startText) - \(endText)"
    }

    private var repeatLine: String? {
        guard snapshot.entryType == .countDown, snapshot.repeatRule != .none else { return nil }
        return "Repeat: \(snapshot.repeatRule.label)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 14) {
                VStack(alignment: .leading, spacing: 10) {
                    CardTypeTag(text: snapshot.entryType.label,
                             tint: accent,
                             textColorOverride: palette.primaryTextColor)
                    Text(snapshot.title)
                        .font(.system(size: 19, weight: .black, design: .monospaced))
                        .foregroundStyle(titleColor)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    Text("\(dateLabel): \(dateLine)")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundStyle(secondaryColor)
                    if let rangeLine {
                        Text(rangeLine)
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundStyle(secondaryColor)
                    }
                    if let repeatLine {
                        Text(repeatLine)
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundStyle(secondaryColor)
                    }
                }
                Spacer(minLength: 8)
                VStack(alignment: .trailing, spacing: 6) {
                    if let emoji = snapshot.iconEmoji, !emoji.isEmpty {
                        Text(emoji)
                            .font(.system(size: 32))
                            .shadow(color: accent.opacity(0.3), radius: 0, x: 1, y: 1)
                    }
                    CardNumberView(value: days, label: "Days", color: accent)
                }
            }
            if let notes = snapshot.notes, !notes.isEmpty {
                Text(notes)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(secondaryColor)
                    .lineLimit(3)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .background(cardBackground)
        .overlay(pixelFrame)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: cardShadowColor, radius: 14, x: 0, y: 7)
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .onReceive(timer) { date in
            if updatesLive { now = date }
        }
    }

    private var cardBackground: some View {
        let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)
        return ZStack {
            // Main gradient background
            shape.fill(cardBaseGradient)

            // Accent glow overlay
            shape.fill(cardGlowOverlay)

            // Inner border
            shape.stroke(cardInnerStroke, lineWidth: 2)
        }
    }

    private var cardBaseGradient: LinearGradient {
        LinearGradient(
            colors: [palette.top, palette.middle, palette.bottom],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var cardGlowOverlay: LinearGradient {
        LinearGradient(
            colors: [palette.glowStart, palette.glowEnd],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }


    private var cardInnerStroke: Color {
        palette.innerStroke
    }

    private var pixelFrame: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .stroke(palette.frame, lineWidth: 2.4)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(palette.innerStroke.opacity(0.5), lineWidth: 1)
            )
    }

    private var cardShadowColor: Color {
        palette.shadow
    }

    private var palette: CardPalette {
        CardPalette(accent: accent, colorScheme: colorScheme)
    }

}

private struct CardPalette {
    let top: Color
    let middle: Color
    let bottom: Color
    let glowStart: Color
    let glowEnd: Color
    let innerStroke: Color
    let frame: Color
    let shadow: Color
    let primaryTextColor: Color
    let secondaryTextColor: Color

    init(accent: Color, colorScheme: ColorScheme) {
        let uiAccent = UIColor(accent)
        let interfaceStyle: UIUserInterfaceStyle = colorScheme == .dark ? .dark : .light
        let traits = UITraitCollection(userInterfaceStyle: interfaceStyle)
        let groupedSurface = UIColor.secondarySystemGroupedBackground.resolvedColor(with: traits)
        let raisedSurface = UIColor.tertiarySystemGroupedBackground.resolvedColor(with: traits)

        if colorScheme == .dark {
            let middleColor = uiAccent.blended(withFraction: 0.82, of: groupedSurface)
            let topColor = middleColor.blended(withFraction: 0.38, of: raisedSurface)
            let bottomColor = middleColor.blended(withFraction: 0.12, of: .black)

            top = Color(topColor)
            middle = Color(middleColor)
            bottom = Color(bottomColor)
            glowStart = accent.opacity(0.08)
            glowEnd = .clear
            innerStroke = Color.white.opacity(0.07)
            frame = accent.opacity(0.22)
            shadow = Color.black.opacity(0.24)
        } else {
            let middleColor = uiAccent.blended(withFraction: 0.86, of: groupedSurface)
            let topColor = middleColor.blended(withFraction: 0.72, of: raisedSurface)
            let bottomColor = middleColor.blended(withFraction: 0.28, of: groupedSurface)

            top = Color(topColor)
            middle = Color(middleColor)
            bottom = Color(bottomColor)
            glowStart = accent.opacity(0.055)
            glowEnd = .clear
            innerStroke = Color.white.opacity(0.72)
            frame = accent.opacity(0.14)
            shadow = Color.black.opacity(0.07)
        }

        primaryTextColor = Color(UIColor.label)
        secondaryTextColor = Color(UIColor.secondaryLabel)
    }

}

private extension UIColor {
    func blended(withFraction fraction: CGFloat, of color: UIColor) -> UIColor {
        var r1: CGFloat = 0
        var g1: CGFloat = 0
        var b1: CGFloat = 0
        var a1: CGFloat = 0
        getRed(&r1, green: &g1, blue: &b1, alpha: &a1)

        var r2: CGFloat = 0
        var g2: CGFloat = 0
        var b2: CGFloat = 0
        var a2: CGFloat = 0
        color.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)

        let r = r1 + (r2 - r1) * fraction
        let g = g1 + (g2 - g1) * fraction
        let b = b1 + (b2 - b1) * fraction
        let a = a1 + (a2 - a1) * fraction

        return UIColor(red: r, green: g, blue: b, alpha: a)
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    let snapshot = EntrySnapshot(
        id: UUID(),
        title: "Summer Launch",
        entryType: .countDown,
        startDate: nil,
        targetDate: Date().addingTimeInterval(86400 * 32),
        rangeStart: nil,
        rangeEnd: nil,
        outOfRangeBehavior: .zero,
        repeatRule: .monthly,
        timezone: .current,
        colorHex: TrendingCardPalettes.defaultHex,
        iconEmoji: "🌞",
        notes: "Prep campaign materials and shoot bright imagery.",
        isPinned: true,
        isArchived: false
    )
    return EntryCardView(snapshot: snapshot)
        .padding()
        .background(Color(UIColor.systemGroupedBackground))
        }
