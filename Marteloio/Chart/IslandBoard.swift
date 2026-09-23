import SwiftUI

/// Role: Chart. Home archipelago. Each genre is a Button with page fill, not a map glyph.
struct IslandBoard: View {
    var snapshot: ChartCanvasSnapshot
    var onSelect: (Island.ID) -> Void
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    var body: some View {
        let items = orderedItems
        let columns = gridColumns
        LazyVGrid(columns: columns, alignment: .leading, spacing: Space.md) {
            ForEach(Array(items.enumerated()), id: \.element.island.id) { index, item in
                IslandCard(item: item, capacity: Self.capacity) {
                    onSelect(item.island.id)
                }
                .gridCellColumns(span(for: item, columns: columns.count))
                .opacity(appeared || reduceMotion ? 1 : 0)
                .animation(
                    reduceMotion
                        ? .easeInOut(duration: 0.2)
                        : Motion.standard.delay(Motion.delay(for: index, reduceMotion: reduceMotion)),
                    value: appeared
                )
            }
        }
        .onAppear { appeared = true }
    }

    static let capacity = IslandFill.pagesPerTile * IslandFill.tilesPerIsland

    private var gridColumns: [GridItem] {
        if sizeClass == .regular {
            return [
                GridItem(.flexible(), spacing: Space.md),
                GridItem(.flexible(), spacing: Space.md),
            ]
        }
        return [GridItem(.flexible())]
    }

    private var orderedItems: [IslandItem] {
        snapshot.islands
            .map { snapshot.item(for: $0) }
            .sorted { left, right in
                if left.state == .hailed && right.state != .hailed { return true }
                if right.state == .hailed && left.state != .hailed { return false }
                if left.pages != right.pages { return left.pages > right.pages }
                return left.island.genre.localizedCaseInsensitiveCompare(right.island.genre) == .orderedAscending
            }
    }

    private func span(for item: IslandItem, columns: Int) -> Int {
        item.state == .hailed ? max(1, columns) : 1
    }
}

/// Role: Chart. One genre plate. Name, page hero, fill, status in its own slot.
struct IslandCard: View {
    var item: IslandItem
    var capacity: Int
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Space.sm) {
                HStack(alignment: .firstTextBaseline, spacing: Space.sm) {
                    Text(item.island.genre)
                        .font(TypeScale.title)
                        .foregroundStyle(Palette.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                    Spacer(minLength: Space.sm)
                    Text(statusText)
                        .font(TypeScale.body)
                        .foregroundStyle(Palette.muted)
                        .lineLimit(1)
                        .layoutPriority(1)
                }

                Text(heroText)
                    .font(TypeScale.display)
                    .foregroundStyle(Palette.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text(ratioText)
                    .font(TypeScale.tabular)
                    .foregroundStyle(Palette.accent)
                    .lineLimit(1)

                fillTrack
            }
            .padding(Space.md)
            .frame(maxWidth: .infinity, minHeight: Space.hit * 2, alignment: .topLeading)
            .background(Palette.surface)
            .clipShape(RoundedRectangle(cornerRadius: Radius.surface, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.surface, style: .continuous)
                    .stroke(Palette.ink.opacity(item.state == .hailed ? 0.55 : 0.12), lineWidth: item.state == .hailed ? 2 : 1)
            )
            .shadow(color: Elevation.shadowColor(), radius: Elevation.radius, x: 0, y: Elevation.y)
            .contentShape(RoundedRectangle(cornerRadius: Radius.surface, style: .continuous))
        }
        .buttonStyle(HairlineTriggerStyle())
        .accessibilityLabel(accessibilityText)
        .accessibilityHint(hintText)
    }

    private var goal: Int {
        if item.state == .hailed, let started = item.runRemainder {
            return max(started, 1)
        }
        return max(capacity, 1)
    }

    private var shownPages: Int {
        if item.state == .hailed, let remainder = item.runRemainder {
            return remainder
        }
        return item.pages
    }

    private var heroText: String {
        if item.state == .hailed {
            return "\(ChartNumbers.pages(shownPages)) pages left"
        }
        return "\(ChartNumbers.pages(item.pages)) pages"
    }

    private var ratioText: String {
        "\(ChartNumbers.pages(shownPages)) / \(ChartNumbers.pages(goal))"
    }

    private var statusText: String {
        switch item.state {
        case .hailed:
            return "Open"
        case .solid:
            if let cost = item.reachCost {
                return "Spend \(ChartNumbers.pages(cost))"
            }
            return "Ready"
        case .hatched:
            return item.hasLandfall ? "Reached" : "Later"
        }
    }

    private var fillTrack: some View {
        GeometryReader { geo in
            let fraction = min(1, CGFloat(shownPages) / CGFloat(goal))
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Palette.ink.opacity(0.1))
                Capsule()
                    .fill(Palette.accent)
                    .frame(width: max(Space.xs, geo.size.width * fraction))
            }
        }
        .frame(height: Space.sm)
        .accessibilityHidden(true)
    }

    private var accessibilityText: String {
        "\(item.island.genre), \(heroText), \(statusText)"
    }

    private var hintText: String {
        switch item.state {
        case .solid:
            return "Places today's pages on this genre"
        case .hailed:
            return "Opens the page budget for this session"
        case .hatched:
            return "Too far for the pages left today"
        }
    }
}
