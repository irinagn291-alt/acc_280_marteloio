import Foundation

/// Role: Run. Who the remainder can still pay. Bound when the cheapest island is out of reach.
enum RunLedger {
    static func cost(
        from origin: Island,
        to target: Island,
        rate: Int
    ) -> Int {
        ReachCost.pages(between: origin, and: target, onGrid: rate)
    }

    static func canPay(_ cost: Int, remainder: Int) -> Bool {
        cost > 0 && cost <= remainder
    }

    static func cheapestCost(
        from originID: Island.ID,
        islands: [Island],
        hatched: Set<Island.ID>,
        rate: Int
    ) -> Int? {
        guard let origin = islands.first(where: { $0.id == originID }) else { return nil }
        let costs = islands.compactMap { island -> Int? in
            guard island.id != originID else { return nil }
            guard !hatched.contains(island.id) else { return nil }
            let value = cost(from: origin, to: island, rate: rate)
            return value > 0 ? value : nil
        }
        return costs.min()
    }

    static func reachable(
        from originID: Island.ID,
        remainder: Int,
        islands: [Island],
        hatched: Set<Island.ID>,
        rate: Int
    ) -> [Island] {
        guard let origin = islands.first(where: { $0.id == originID }) else { return [] }
        return islands.filter { island in
            island.id != originID
                && !hatched.contains(island.id)
                && canPay(cost(from: origin, to: island, rate: rate), remainder: remainder)
        }
    }
}
