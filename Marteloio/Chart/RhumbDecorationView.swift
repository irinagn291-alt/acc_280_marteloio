import UIKit

/// Role: Chart. One inked rhumb. Hairline that gains weight. Never a second colour.
final class RhumbDecorationView: UICollectionReusableView {
    static let kind = PortolanFlowLayout.rhumbKind

    private var start: CGPoint = .zero
    private var end: CGPoint = .zero
    private var weight: Int = 1

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
        guard let rhumb = layoutAttributes as? RhumbLayoutAttributes else { return }
        start = rhumb.start
        end = rhumb.end
        weight = rhumb.weight
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        let hairline = 1 / max(contentScaleFactor, 1)
        let width = hairline * CGFloat(2 + max(0, weight) * 2)
        context.setStrokeColor(InkColor.ink.cgColor)
        context.setLineWidth(width)
        context.setLineCap(.round)
        context.move(to: start)
        context.addLine(to: end)
        context.strokePath()
    }
}
