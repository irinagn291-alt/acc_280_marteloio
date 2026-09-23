import SwiftUI

/// Role: Design. One soft drop shadow. Reused wherever a surface sits above another.
enum Elevation {
    static let radius: CGFloat = Space.sm
    static let y: CGFloat = Space.xs

    static func shadowColor() -> Color {
        Palette.ink.opacity(0.12)
    }

    static func uiShadowColor() -> UIColor {
        InkColor.ink.withAlphaComponent(0.12)
    }
}

struct SurfaceCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Palette.surface)
            .clipShape(RoundedRectangle(cornerRadius: Radius.surface, style: .continuous))
            .shadow(color: Elevation.shadowColor(), radius: Elevation.radius, x: 0, y: Elevation.y)
    }
}

extension View {
    func surfaceCard() -> some View {
        modifier(SurfaceCard())
    }
}
