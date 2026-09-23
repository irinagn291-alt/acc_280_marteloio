import SwiftUI

/// Role: Design. Full-width filled capsule. Pressed, disabled and loading are visible.
struct PrimaryButtonStyle: ButtonStyle {
    var isLoading: Bool = false
    var isDestructive: Bool = false

    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: Space.sm) {
            if isLoading {
                ProgressView()
                    .tint(Palette.surface)
            }
            configuration.label
                .font(TypeScale.body.weight(.semibold))
        }
        .foregroundStyle(Palette.surface)
        .frame(maxWidth: .infinity, minHeight: Space.hit)
        .padding(.horizontal, Space.md)
        .background(fill(isPressed: configuration.isPressed))
        .clipShape(Capsule())
        .scaleEffect(configuration.isPressed ? 0.98 : 1)
        .opacity(isEnabled ? 1 : 0.45)
        .contentShape(Capsule())
        .animation(Motion.standard, value: configuration.isPressed)
    }

    private func fill(isPressed: Bool) -> Color {
        let base = isDestructive ? Palette.ink : Palette.accent
        return isPressed ? base.opacity(0.82) : base
    }
}

struct HairlineTriggerStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(isEnabled ? (configuration.isPressed ? 0.55 : 1) : 0.35)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(Motion.standard, value: configuration.isPressed)
            .animation(Motion.standard, value: isEnabled)
    }
}
