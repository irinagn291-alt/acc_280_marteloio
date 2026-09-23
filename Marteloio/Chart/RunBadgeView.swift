import UIKit

/// Role: Chart. Oversized tabular Run numeral. The one display moment on the plate.
final class RunBadgeView: UIView {
    private let face = UIImageView()
    private let value = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        isOpaque = false
        backgroundColor = InkColor.surface
        layer.cornerRadius = Radius.chip
        layer.masksToBounds = true
        layer.borderWidth = 1
        layer.borderColor = InkColor.ink.withAlphaComponent(0.2).cgColor

        face.image = UIImage(named: "mrt_RunBadge")
        face.contentMode = .scaleAspectFill
        face.clipsToBounds = true
        face.alpha = 0.35
        face.isUserInteractionEnabled = false
        face.translatesAutoresizingMaskIntoConstraints = false

        value.font = TypeScale.uiRunNumeral()
        value.textColor = InkColor.ink
        value.textAlignment = .center
        value.adjustsFontForContentSizeCategory = true
        value.adjustsFontSizeToFitWidth = true
        value.minimumScaleFactor = 0.6
        value.translatesAutoresizingMaskIntoConstraints = false

        addSubview(face)
        addSubview(value)
        NSLayoutConstraint.activate([
            face.topAnchor.constraint(equalTo: topAnchor),
            face.leadingAnchor.constraint(equalTo: leadingAnchor),
            face.trailingAnchor.constraint(equalTo: trailingAnchor),
            face.bottomAnchor.constraint(equalTo: bottomAnchor),
            value.topAnchor.constraint(equalTo: topAnchor, constant: Space.xs),
            value.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Space.xs),
            value.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Space.xs),
            value.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Space.xs),
        ])
        isAccessibilityElement = false
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        return nil
    }

    func apply(pages: Int) {
        value.text = ChartNumbers.pages(pages)
    }
}
