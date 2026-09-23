import SwiftUI

/// Role: Chart. The one UIKit hero, hosted in SwiftUI. Every other surface stays SwiftUI.
struct ChartRepresentable: UIViewControllerRepresentable {
    var snapshot: ChartCanvasSnapshot
    var onBear: (Island.ID) -> Void

    func makeUIViewController(context: Context) -> ChartViewController {
        let controller = ChartViewController()
        controller.onBear = onBear
        controller.apply(snapshot)
        return controller
    }

    func updateUIViewController(_ controller: ChartViewController, context: Context) {
        controller.onBear = onBear
        controller.apply(snapshot)
    }
}
