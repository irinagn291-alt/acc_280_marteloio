import SwiftUI

/// Role: Design. Chart-locked sheets. Large for destinations, medium for Hail on Shelf.
enum SheetStack {
    @ViewBuilder
    static func large<Content: View>(_ content: Content) -> some View {
        content
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationBackground(Palette.surface)
    }

    @ViewBuilder
    static func hail<Content: View>(_ content: Content) -> some View {
        content
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .presentationBackground(Palette.surface)
    }

    static func closeButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .foregroundStyle(Palette.ink)
                .frame(width: Space.hit, height: Space.hit)
                .contentShape(Rectangle())
        }
        .buttonStyle(HairlineTriggerStyle())
        .accessibilityLabel("Close")
    }
}
