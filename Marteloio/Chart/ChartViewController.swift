import UIKit

/// Role: Chart. Hosts the portolan collection view. Taps become Bear intents in ChartSession.
@MainActor
final class ChartViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    var onBear: ((Island.ID) -> Void)?

    private let layout = PortolanFlowLayout()
    private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
    private var snapshot: ChartCanvasSnapshot = .empty

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        collectionView.backgroundColor = .clear
        collectionView.isScrollEnabled = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.delaysContentTouches = false
        collectionView.register(IslandCell.self, forCellWithReuseIdentifier: IslandCell.reuse)
        layout.register(RhumbDecorationView.self, forDecorationViewOfKind: RhumbDecorationView.kind)
        layout.register(WindroseDecorationView.self, forDecorationViewOfKind: WindroseDecorationView.kind)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    func apply(_ snapshot: ChartCanvasSnapshot) {
        loadViewIfNeeded()
        let previous = self.snapshot.islands.map(\.id)
        let next = snapshot.islands.map(\.id)
        self.snapshot = snapshot
        layout.snapshot = snapshot
        if previous != next {
            collectionView.reloadData()
        } else {
            collectionView.collectionViewLayout.invalidateLayout()
            for cell in collectionView.visibleCells {
                guard let island = cell as? IslandCell,
                      let path = collectionView.indexPath(for: island),
                      let item = snapshot.item(at: path.item)
                else { continue }
                island.apply(item)
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        snapshot.islands.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: IslandCell.reuse,
            for: indexPath
        )
        if let island = cell as? IslandCell, let item = snapshot.item(at: indexPath.item) {
            island.apply(item)
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let island = snapshot.islands[safe: indexPath.item] else { return }
        onBear?(island.id)
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
