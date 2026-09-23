import Foundation

/// Role: Rhumb. Bearing from a y-down grid so north is a falling row.
enum RhumbGeometry {
    static func bearing(from origin: GridPoint, to target: GridPoint) -> Bearing {
        let dx = Double(target.column - origin.column)
        let dy = Double(target.row - origin.row)
        if dx == 0, dy == 0 { return .n }
        let radians = atan2(dx, -dy)
        var degrees = radians * 180 / .pi
        if degrees < 0 { degrees += 360 }
        switch degrees {
        case 0..<22.5, 337.5...360: return .n
        case 22.5..<67.5: return .ne
        case 67.5..<112.5: return .e
        case 112.5..<157.5: return .se
        case 157.5..<202.5: return .s
        case 202.5..<247.5: return .sw
        case 247.5..<292.5: return .w
        default: return .nw
        }
    }
}
