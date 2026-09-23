import SwiftUI

/// Role: Chart. Full-page empty water. One headline, one line, one full-width CTA.
struct ChartEmptyState: View {
    var action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Space.md) {
            Image("mrt_EmptyHome")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 240, maxHeight: 240)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityHidden(true)

            Text("The water is empty")
                .font(TypeScale.display)
                .foregroundStyle(Palette.ink)
                .fixedSize(horizontal: false, vertical: true)

            Text("Place the first book, then log the pages you read.")
                .font(TypeScale.body)
                .foregroundStyle(Palette.muted)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: Space.md)

            Button("Log pages", action: action)
                .buttonStyle(PrimaryButtonStyle())
                .accessibilityLabel("Log pages")
        }
        .padding(.horizontal, Space.md)
        .padding(.vertical, Space.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Palette.background)
    }
}
