import SwiftUI

/// Role: Logbook. Analytics of marks. Hero is the thickest bearing, then daykey groups.
struct LogbookView: View {
    @Bindable var session: ChartSession

    var body: some View {
        LogbookSheet(session: session)
    }
}

/// Role: Logbook. Analytics of marks. Hero is the thickest bearing, then daykey groups.
struct LogbookSheet: View {
    @Bindable var session: ChartSession
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    var body: some View {
        NavigationStack {
            Group {
                if session.record.marks.isEmpty {
                    empty
                } else {
                    populated
                }
            }
            .background(Palette.background)
            .onAppear { appeared = true }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    SheetStack.closeButton { session.presented = nil }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var empty: some View {
        VStack(alignment: .leading, spacing: Space.md) {
            Image("mrt_EmptyList")
                .resizable()
                .scaledToFit()
                .frame(width: 180, height: 180)
                .accessibilityHidden(true)
            Text("No pages logged yet")
                .font(TypeScale.display)
                .foregroundStyle(Palette.ink)
            Text("Log a book and the days you read will collect here.")
                .font(TypeScale.body)
                .foregroundStyle(Palette.muted)
            Spacer(minLength: Space.md)
            Button("Log pages") {
                session.presented = .shelf
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding(Space.md)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var populated: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Space.lg) {
                Text("Reading log")
                    .font(TypeScale.display)
                    .foregroundStyle(Palette.ink)

                if session.writeIssue != nil {
                    VStack(alignment: .leading, spacing: Space.sm) {
                        Text("The last save did not finish.")
                            .font(TypeScale.body)
                            .foregroundStyle(Palette.ink)
                        Button("Save again") {
                            Task { await session.flush() }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                    .padding(Space.md)
                    .surfaceCard()
                }

                if let summary = BearingSummaryQuery.thickest(in: session.record) {
                    hero(summary)
                }

                pagesStrip

                ForEach(Array(LogbookQuery.groups(from: session.record).enumerated()), id: \.element.daykey) { index, group in
                    dayCard(group)
                        .opacity(appeared || reduceMotion ? 1 : 0)
                        .animation(
                            reduceMotion ? .easeInOut(duration: 0.2) : Motion.standard.delay(Motion.delay(for: index, reduceMotion: reduceMotion)),
                            value: appeared
                        )
                }
            }
            .padding(Space.md)
        }
    }

    private func hero(_ summary: BearingSummary) -> some View {
        VStack(alignment: .leading, spacing: Space.sm) {
            Text("Pages logged")
                .font(TypeScale.body)
                .foregroundStyle(Palette.muted)
            Text(heroValue(summary))
                .font(TypeScale.display)
                .foregroundStyle(Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text("\(ChartNumbers.pages(summary.weight)) visits on this pair")
                .font(TypeScale.tabular)
                .foregroundStyle(Palette.accent)
        }
        .padding(Space.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: Radius.surface, style: .continuous))
        .shadow(color: Elevation.shadowColor(), radius: Elevation.radius, x: 0, y: Elevation.y)
    }

    private var pagesStrip: some View {
        VStack(alignment: .leading, spacing: Space.sm) {
            Text("Pages per island")
                .font(TypeScale.title)
                .foregroundStyle(Palette.ink)
            ForEach(session.record.islands) { island in
                let pages = session.record.pagesOnIsland(island.id)
                HStack {
                    Text(island.genre)
                        .font(TypeScale.body)
                        .foregroundStyle(Palette.ink)
                        .lineLimit(1)
                    Spacer(minLength: Space.sm)
                    Text(ChartNumbers.pages(pages))
                        .font(TypeScale.tabular)
                        .foregroundStyle(Palette.ink)
                }
                .frame(minHeight: Space.hit)
            }
        }
        .padding(Space.md)
        .surfaceCard()
    }

    private func dayCard(_ group: DaykeyGroup) -> some View {
        VStack(alignment: .leading, spacing: Space.sm) {
            Text(ChartNumbers.daykey(group.daykey))
                .font(TypeScale.title)
                .foregroundStyle(Palette.ink)
            FixesView(marks: group.fixes, islandName: islandName)
            RhumbsView(marks: group.rhumbs, islandName: islandName)
            LuffsView(marks: group.luffs, islandName: islandName)
            ForEach(group.landfalls) { mark in
                markRow(title: "Landfall", detail: islandName(mark.islandID))
            }
        }
        .padding(Space.md)
        .surfaceCard()
    }

    private func markRow(title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: Space.xs) {
            Text(title)
                .font(TypeScale.caption)
                .foregroundStyle(Palette.muted)
            Text(detail)
                .font(TypeScale.body)
                .foregroundStyle(Palette.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: Space.hit, alignment: .leading)
    }

    private func islandName(_ id: Island.ID) -> String {
        session.record.island(id)?.genre ?? "Island"
    }

    private func pairName(_ pair: IslandPair) -> String {
        "\(islandName(pair.low)) and \(islandName(pair.high))"
    }

    private func heroValue(_ summary: BearingSummary) -> String {
        "\(ChartNumbers.pages(totalPages)) pages · \(pairName(summary.pair))"
    }

    private var totalPages: Int {
        session.record.marks.reduce(0) { total, mark in
            if case .fix(let fix) = mark {
                return total + fix.pages
            }
            return total
        }
    }
}

struct FixesView: View {
    var marks: [FixMark]
    var islandName: (Island.ID) -> String

    var body: some View {
        ForEach(marks) { mark in
            LogbookMarkLine(
                title: "Fix",
                detail: "\(islandName(mark.islandID)) · \(ChartNumbers.pages(mark.pages)) pages"
            )
        }
    }
}

struct RhumbsView: View {
    var marks: [RhumbMark]
    var islandName: (Island.ID) -> String

    var body: some View {
        ForEach(marks) { mark in
            LogbookMarkLine(
                title: "Rhumb",
                detail: "\(islandName(mark.fromIsland)) to \(islandName(mark.toIsland)) · \(ChartNumbers.pages(mark.cost)) pages"
            )
        }
    }
}

struct LuffsView: View {
    var marks: [LuffMark]
    var islandName: (Island.ID) -> String

    var body: some View {
        ForEach(marks) { mark in
            LogbookMarkLine(
                title: "Luff",
                detail: "\(islandName(mark.islandID)) · needed \(ChartNumbers.pages(mark.cost))"
            )
        }
    }
}

private struct LogbookMarkLine: View {
    var title: String
    var detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: Space.xs) {
            Text(title)
                .font(TypeScale.caption)
                .foregroundStyle(Palette.muted)
            Text(detail)
                .font(TypeScale.body)
                .foregroundStyle(Palette.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: Space.hit, alignment: .leading)
    }
}
