import SwiftUI

/// Role: Design. One easing curve. Stagger steps 50 ms, capped at 360 ms.
enum Motion {
    static let duration: Double = 0.28
    static let step: Double = 0.05
    static let cap: Double = 0.36

    static var standard: Animation {
        .easeInOut(duration: duration)
    }

    static func delay(for index: Int, reduceMotion: Bool) -> Double {
        if reduceMotion { return 0 }
        return min(Double(index) * step, cap)
    }
}
