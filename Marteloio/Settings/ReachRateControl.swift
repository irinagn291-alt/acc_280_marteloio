import SwiftUI

/// Role: Settings. Pages per chart cell. Tabular readout of the reach rate.
struct ReachRateControl: View {
    var rate: Int
    var onChange: (Int) -> Void

    var body: some View {
        HStack(spacing: Space.md) {
            Button {
                onChange(max(1, rate - 1))
            } label: {
                Image(systemName: "minus")
                    .frame(width: Space.hit, height: Space.hit)
                    .contentShape(Rectangle())
            }
            .buttonStyle(HairlineTriggerStyle())
            .accessibilityLabel("Decrease pages per cell")

            VStack(spacing: Space.xs) {
                Text(ChartNumbers.pages(rate))
                    .font(TypeScale.tabular)
                    .foregroundStyle(Palette.ink)
                Text("pages per cell")
                    .font(TypeScale.caption)
                    .foregroundStyle(Palette.muted)
            }
            .frame(maxWidth: .infinity)

            Button {
                onChange(min(100, rate + 1))
            } label: {
                Image(systemName: "plus")
                    .frame(width: Space.hit, height: Space.hit)
                    .contentShape(Rectangle())
            }
            .buttonStyle(HairlineTriggerStyle())
            .accessibilityLabel("Increase pages per cell")
        }
        .padding(Space.md)
        .surfaceCard()
    }
}
