import UIKit

/// Role: Chart. Paper-cut genre plate. Solid, hatched and hailed are drawn as shape, not tint.
final class IslandCell: UICollectionViewCell {
    static let reuse = "IslandCell"

    private let plate = IslandPlateView()
    private let nameLabel = UILabel()
    private let pagesLabel = UILabel()
    private let costLabel = UILabel()
    private let badge = RunBadgeView()
    private let ring = UIImageView()
    private var item: IslandItem?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        isAccessibilityElement = true

        plate.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(plate)

        nameLabel.font = TypeScale.uiTitle3()
        nameLabel.textColor = InkColor.ink
        nameLabel.adjustsFontForContentSizeCategory = true
        nameLabel.numberOfLines = 2
        nameLabel.lineBreakMode = .byTruncatingTail
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        pagesLabel.font = TypeScale.uiTabular(.caption1)
        pagesLabel.textColor = InkColor.ink
        pagesLabel.adjustsFontForContentSizeCategory = true
        pagesLabel.translatesAutoresizingMaskIntoConstraints = false

        costLabel.font = TypeScale.uiTabular(.caption2)
        costLabel.textColor = InkColor.muted
        costLabel.adjustsFontForContentSizeCategory = true
        costLabel.translatesAutoresizingMaskIntoConstraints = false

        badge.translatesAutoresizingMaskIntoConstraints = false
        badge.isHidden = true

        ring.image = UIImage(named: "mrt_LandfallRing")
        ring.contentMode = .scaleAspectFit
        ring.isUserInteractionEnabled = false
        ring.translatesAutoresizingMaskIntoConstraints = false
        ring.isHidden = true
        ring.accessibilityIgnoresInvertColors = true

        contentView.addSubview(nameLabel)
        contentView.addSubview(pagesLabel)
        contentView.addSubview(costLabel)
        contentView.addSubview(badge)
        contentView.addSubview(ring)

        NSLayoutConstraint.activate([
            plate.topAnchor.constraint(equalTo: contentView.topAnchor),
            plate.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            plate.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            plate.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Space.sm),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Space.sm),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Space.sm),

            pagesLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: Space.xs),
            pagesLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            pagesLabel.trailingAnchor.constraint(lessThanOrEqualTo: nameLabel.trailingAnchor),

            costLabel.topAnchor.constraint(equalTo: pagesLabel.bottomAnchor),
            costLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            costLabel.trailingAnchor.constraint(lessThanOrEqualTo: nameLabel.trailingAnchor),

            badge.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Space.xs),
            badge.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Space.xs),
            badge.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Space.xs),
            badge.heightAnchor.constraint(greaterThanOrEqualToConstant: Space.hit / 2),

            ring.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Space.xs),
            ring.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Space.xs),
            ring.widthAnchor.constraint(equalToConstant: Space.lg),
            ring.heightAnchor.constraint(equalToConstant: Space.lg),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        return nil
    }

    override func preferredLayoutAttributesFitting(
        _ layoutAttributes: UICollectionViewLayoutAttributes
    ) -> UICollectionViewLayoutAttributes {
        layoutAttributes
    }

    func apply(_ item: IslandItem) {
        self.item = item
        nameLabel.text = item.island.genre
        pagesLabel.text = ChartNumbers.pages(item.pages)
        if let cost = item.reachCost {
            costLabel.text = ChartNumbers.pages(cost)
            costLabel.isHidden = false
        } else {
            costLabel.text = nil
            costLabel.isHidden = true
        }
        plate.state = item.state
        badge.isHidden = item.state != .hailed
        if let remainder = item.runRemainder {
            badge.apply(pages: remainder)
        }
        ring.isHidden = !item.hasLandfall
        ring.isAccessibilityElement = false
        accessibilityLabel = spokenLabel(item)
        accessibilityTraits = .button
        accessibilityHint = hint(item)
    }

    private func spokenLabel(_ item: IslandItem) -> String {
        var parts = [item.island.genre, "\(ChartNumbers.pages(item.pages)) pages"]
        switch item.state {
        case .hailed:
            if let remainder = item.runRemainder {
                parts.append("hailed, run \(ChartNumbers.pages(remainder)) pages")
            } else {
                parts.append("hailed")
            }
        case .solid:
            if let cost = item.reachCost {
                parts.append("reachable, costs \(ChartNumbers.pages(cost)) pages")
            } else {
                parts.append("reachable")
            }
        case .hatched:
            parts.append("hatched")
        }
        if item.hasLandfall {
            parts.append("landfall")
        }
        return parts.joined(separator: ", ")
    }

    private func hint(_ item: IslandItem) -> String? {
        switch item.state {
        case .solid:
            return "Bears a rhumb to this island"
        case .hatched:
            return "Writes a luff if the Run cannot pay"
        case .hailed:
            return nil
        }
    }
}

/// Role: Chart. Filled plate plus hatch. Colour is never the only state.
final class IslandPlateView: UIView {
    var state: IslandPlateState = .hatched {
        didSet { setNeedsDisplay() }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        isOpaque = false
        backgroundColor = .clear
        layer.shadowColor = Elevation.uiShadowColor().cgColor
        layer.shadowOpacity = 1
        layer.shadowRadius = Elevation.radius
        layer.shadowOffset = CGSize(width: 0, height: Elevation.y)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        return nil
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        let plate = rect.insetBy(dx: 1, dy: 1)
        let path = UIBezierPath(roundedRect: plate, cornerRadius: Radius.surface)
        context.addPath(path.cgPath)
        context.setFillColor(InkColor.surface.cgColor)
        context.fillPath()

        context.addPath(path.cgPath)
        context.setStrokeColor(InkColor.ink.withAlphaComponent(state == .hailed ? 0.9 : 0.35).cgColor)
        context.setLineWidth(state == .hailed ? 2 : 1)
        context.strokePath()

        if state == .hatched {
            context.saveGState()
            context.addPath(path.cgPath)
            context.clip()
            context.setStrokeColor(InkColor.ink.withAlphaComponent(0.28).cgColor)
            context.setLineWidth(1)
            var x = plate.minX - plate.height
            while x < plate.maxX {
                context.move(to: CGPoint(x: x, y: plate.maxY))
                context.addLine(to: CGPoint(x: x + plate.height, y: plate.minY))
                x += 6
            }
            context.strokePath()
            context.restoreGState()
        }

        if state == .solid {
            let mark = CGRect(x: plate.maxX - Space.md - 4, y: plate.minY + Space.sm, width: Space.sm, height: Space.sm)
            context.setFillColor(InkColor.accent.cgColor)
            context.fillEllipse(in: mark)
            context.setStrokeColor(InkColor.ink.cgColor)
            context.setLineWidth(1)
            context.strokeEllipse(in: mark)
        }
    }
}
