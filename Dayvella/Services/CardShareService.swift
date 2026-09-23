import SwiftUI
import UIKit

@MainActor
struct CardShareService {
    struct Payload: Identifiable {
        let id = UUID()
        let image: UIImage
    }

    func render(entry: Entry, colorScheme: ColorScheme) -> Payload? {
        let content = EntryCardView(snapshot: EntrySnapshot(entry: entry), updatesLive: false)
            .frame(width: 420)
            .padding(24)
            .background(Color(UIColor.systemGroupedBackground))
            .environment(\.colorScheme, colorScheme)
        let renderer = ImageRenderer(content: content)
        renderer.scale = 3
        guard let image = renderer.uiImage else { return nil }
        return Payload(image: image)
    }
}
