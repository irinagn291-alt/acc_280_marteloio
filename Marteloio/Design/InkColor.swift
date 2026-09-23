import SwiftUI
import UIKit

/// Role: Design. UIKit face of the palette. Hex still lives only in Palette.
enum InkColor {
    static let background = UIColor(Palette.background)
    static let surface = UIColor(Palette.surface)
    static let ink = UIColor(Palette.ink)
    static let accent = UIColor(Palette.accent)
    static let muted = UIColor(Palette.muted)
}
