import UIKit

/// Role: Chart. Layout payload for one inked rhumb. Weight and bearing travel with the frame.
final class RhumbLayoutAttributes: UICollectionViewLayoutAttributes {
    nonisolated(unsafe) var weight: Int = 1
    nonisolated(unsafe) var bearing: Bearing = .n
    nonisolated(unsafe) var start: CGPoint = .zero
    nonisolated(unsafe) var end: CGPoint = .zero

    override func copy(with zone: NSZone? = nil) -> Any {
        let copied = super.copy(with: zone)
        guard let copy = copied as? RhumbLayoutAttributes else { return copied }
        copy.weight = weight
        copy.bearing = bearing
        copy.start = start
        copy.end = end
        return copy
    }

    override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? RhumbLayoutAttributes else { return false }
        guard super.isEqual(other) else { return false }
        let sameWeight = other.weight == weight
        let sameBearing = other.bearing == bearing
        let sameStart = other.start == start
        let sameEnd = other.end == end
        return sameWeight && sameBearing && sameStart && sameEnd
    }
}
