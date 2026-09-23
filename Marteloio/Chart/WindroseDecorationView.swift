import UIKit

/// Role: Chart. One windrose behind the islands. Redrawn when the layout invalidates.
final class WindroseDecorationView: UICollectionReusableView {
    static let kind = PortolanFlowLayout.windroseKind

    override init(frame: CGRect) {
        super.init(frame: frame)
        isOpaque = false
        backgroundColor = .clear
        isUserInteractionEnabled = false
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        return nil
    }

    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) * 0.42
        context.setStrokeColor(InkColor.ink.withAlphaComponent(0.16).cgColor)
        context.setLineWidth(1)

        for step in 0..<8 {
            let angle = Double(step) * .pi / 4
            let end = CGPoint(
                x: center.x + CGFloat(cos(angle)) * radius,
                y: center.y + CGFloat(sin(angle)) * radius
            )
            context.move(to: center)
            context.addLine(to: end)
        }
        context.strokePath()

        context.setStrokeColor(InkColor.ink.withAlphaComponent(0.1).cgColor)
        context.strokeEllipse(in: CGRect(
            x: center.x - radius * 0.35,
            y: center.y - radius * 0.35,
            width: radius * 0.7,
            height: radius * 0.7
        ))
        context.setFillColor(InkColor.ink.cgColor)
        context.fillEllipse(in: CGRect(x: center.x - 2, y: center.y - 2, width: 4, height: 4))
    }
}
