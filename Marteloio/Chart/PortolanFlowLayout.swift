import UIKit

/// Role: Chart. Flow subclass that ignores line wrap and sits each island on the fixed grid.
final class PortolanFlowLayout: UICollectionViewFlowLayout {
    var snapshot: ChartCanvasSnapshot = .empty

    private var cellAttributes: [IndexPath: UICollectionViewLayoutAttributes] = [:]
    private var rhumbAttributes: [IndexPath: RhumbLayoutAttributes] = [:]
    private var windroseAttributes: UICollectionViewLayoutAttributes?
    private var cachedSize: CGSize = .zero

    static let windroseKind = "mrt.windrose"
    static let rhumbKind = "mrt.rhumb"

    override func prepare() {
        super.prepare()
        minimumLineSpacing = 0
        minimumInteritemSpacing = 0
        sectionInset = .zero
        scrollDirection = .vertical

        guard let collectionView else { return }
        let bounds = collectionView.bounds
        guard bounds.width > 0, bounds.height > 0 else { return }
        cachedSize = bounds.size

        let inset = Space.md
        let usable = bounds.insetBy(dx: inset, dy: inset)
        let size = max(2, snapshot.gridSize)
        let cellW = usable.width / CGFloat(size)
        let cellH = usable.height / CGFloat(size)

        var cells: [IndexPath: UICollectionViewLayoutAttributes] = [:]
        var centers: [Island.ID: CGPoint] = [:]

        for (index, island) in snapshot.islands.enumerated() {
            let path = IndexPath(item: index, section: 0)
            let column = min(max(island.coordinate.column, 0), size - 1)
            let row = min(max(island.coordinate.row, 0), size - 1)
            let frame = CGRect(
                x: usable.minX + CGFloat(column) * cellW,
                y: usable.minY + CGFloat(row) * cellH,
                width: cellW,
                height: cellH
            )
            let attributes = UICollectionViewLayoutAttributes(forCellWith: path)
            attributes.frame = frame.insetBy(dx: Space.xs, dy: Space.xs)
            attributes.zIndex = 2
            cells[path] = attributes
            centers[island.id] = CGPoint(x: frame.midX, y: frame.midY)
        }
        cellAttributes = cells

        let rose = UICollectionViewLayoutAttributes(
            forDecorationViewOfKind: Self.windroseKind,
            with: IndexPath(item: 0, section: 0)
        )
        rose.frame = bounds
        rose.zIndex = 0
        windroseAttributes = rose

        var rhumbs: [IndexPath: RhumbLayoutAttributes] = [:]
        for (index, rhumb) in snapshot.rhumbs.enumerated() {
            guard let start = centers[rhumb.pair.low], let end = centers[rhumb.pair.high] else { continue }
            let path = IndexPath(item: index, section: 0)
            let attributes = RhumbLayoutAttributes(
                forDecorationViewOfKind: Self.rhumbKind,
                with: path
            )
            attributes.frame = bounds
            attributes.zIndex = 1
            attributes.weight = max(1, rhumb.weight)
            attributes.bearing = rhumb.bearing
            attributes.start = start
            attributes.end = end
            rhumbs[path] = attributes
        }
        rhumbAttributes = rhumbs
    }

    override var collectionViewContentSize: CGSize {
        cachedSize
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var result: [UICollectionViewLayoutAttributes] = []
        if let windroseAttributes, windroseAttributes.frame.intersects(rect) {
            result.append(windroseAttributes)
        }
        for attributes in rhumbAttributes.values where attributes.frame.intersects(rect) {
            result.append(attributes)
        }
        for attributes in cellAttributes.values where attributes.frame.intersects(rect) {
            result.append(attributes)
        }
        return result
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        cellAttributes[indexPath]
    }

    override func layoutAttributesForDecorationView(
        ofKind elementKind: String,
        at indexPath: IndexPath
    ) -> UICollectionViewLayoutAttributes? {
        if elementKind == Self.windroseKind {
            return windroseAttributes
        }
        if elementKind == Self.rhumbKind {
            return rhumbAttributes[indexPath]
        }
        return nil
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        newBounds.size != cachedSize
    }

    override func initialLayoutAttributesForAppearingDecorationElement(
        ofKind elementKind: String,
        at decorationIndexPath: IndexPath
    ) -> UICollectionViewLayoutAttributes? {
        let attributes = layoutAttributesForDecorationView(ofKind: elementKind, at: decorationIndexPath)
        attributes?.alpha = 0
        return attributes
    }

    override func finalLayoutAttributesForDisappearingDecorationElement(
        ofKind elementKind: String,
        at decorationIndexPath: IndexPath
    ) -> UICollectionViewLayoutAttributes? {
        let attributes = layoutAttributesForDecorationView(ofKind: elementKind, at: decorationIndexPath)
        attributes?.alpha = 0
        return attributes
    }
}
