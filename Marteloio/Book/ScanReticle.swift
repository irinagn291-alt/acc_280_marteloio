import SwiftUI

/// Role: Book. Drawn reticle. Scanner frames are a Path, not a generated plate.
struct ScanReticle: Shape {
    func path(in rect: CGRect) -> Path {
        let inset = rect.insetBy(dx: Space.md, dy: Space.md)
        let arm = Space.lg
        var path = Path()
        let corners: [(CGPoint, CGPoint, CGPoint)] = [
            (CGPoint(x: inset.minX, y: inset.minY + arm), CGPoint(x: inset.minX, y: inset.minY), CGPoint(x: inset.minX + arm, y: inset.minY)),
            (CGPoint(x: inset.maxX - arm, y: inset.minY), CGPoint(x: inset.maxX, y: inset.minY), CGPoint(x: inset.maxX, y: inset.minY + arm)),
            (CGPoint(x: inset.maxX, y: inset.maxY - arm), CGPoint(x: inset.maxX, y: inset.maxY), CGPoint(x: inset.maxX - arm, y: inset.maxY)),
            (CGPoint(x: inset.minX + arm, y: inset.maxY), CGPoint(x: inset.minX, y: inset.maxY), CGPoint(x: inset.minX, y: inset.maxY - arm)),
        ]
        for corner in corners {
            path.move(to: corner.0)
            path.addLine(to: corner.1)
            path.addLine(to: corner.2)
        }
        return path
    }
}
