import SwiftUI

/// Role: Chart. Twist screen. Pages are a budget of distance, visible as costs from the hailed island.
struct RhumbReachSheet: View {
    @Bindable var session: ChartSession

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Space.lg) {
                    Image("mrt_TwistHero")
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 220)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .clipped()
                        .accessibilityHidden(true)

                    Text("Spend pages as distance")
                        .font(TypeScale.display)
                        .foregroundStyle(Palette.ink)

                    Text("A Hail writes a Run. Each chart cell costs \(ChartNumbers.pages(session.record.reachRate)) pages. A far tap writes a luff and keeps the Run.")
                        .font(TypeScale.body)
                        .foregroundStyle(Palette.muted)

                    if let run = session.record.run, let origin = session.record.island(run.originIslandID) {
                        VStack(alignment: .leading, spacing: Space.sm) {
                            Text(origin.genre)
                                .font(TypeScale.title)
                                .foregroundStyle(Palette.ink)
                            Text("\(ChartNumbers.pages(run.remainder)) pages left")
                                .font(TypeScale.tabular)
                                .foregroundStyle(Palette.accent)
                        }
                        .padding(Space.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .surfaceCard()

                        VStack(alignment: .leading, spacing: Space.sm) {
                            ForEach(costs(from: origin, remainder: run.remainder), id: \.island.id) { row in
                                HStack {
                                    Text(row.island.genre)
                                        .font(TypeScale.body)
                                        .foregroundStyle(Palette.ink)
                                        .lineLimit(1)
                                    Spacer(minLength: Space.sm)
                                    Text(ChartNumbers.pages(row.cost))
                                        .font(TypeScale.tabular)
                                        .foregroundStyle(row.payable ? Palette.ink : Palette.muted)
                                }
                                .frame(minHeight: Space.hit)
                            }
                        }
                        .padding(Space.md)
                        .surfaceCard()
                    } else {
                        emptyReach
                    }
                }
                .padding(Space.md)
            }
            .background(Palette.background)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    SheetStack.closeButton { session.presented = nil }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var emptyReach: some View {
        VStack(alignment: .leading, spacing: Space.md) {
            Image("mrt_EmptyList")
                .resizable()
                .scaledToFit()
                .frame(width: 160, height: 160)
                .accessibilityHidden(true)
            Text("No Run on the chart")
                .font(TypeScale.title)
                .foregroundStyle(Palette.ink)
            Text("Hail a book from the Shelf. Those pages become the distance you can bear.")
                .font(TypeScale.body)
                .foregroundStyle(Palette.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func costs(from origin: Island, remainder: Int) -> [(island: Island, cost: Int, payable: Bool)] {
        session.record.islands
            .filter { $0.id != origin.id }
            .map { island in
                let cost = ReachCost.pages(between: origin, and: island, onGrid: session.record.reachRate)
                let hatched = session.hatches.contains(island.id)
                return (island, cost, !hatched && cost > 0 && cost <= remainder)
            }
            .sorted { $0.cost < $1.cost }
    }
}
