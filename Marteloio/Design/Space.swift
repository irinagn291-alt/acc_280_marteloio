import CoreGraphics

/// Role: Design. One 8 pt unit. Views use these steps, never ad-hoc padding.
enum Space {
    static let unit: CGFloat = 8
    static let xs: CGFloat = unit / 2
    static let sm: CGFloat = unit
    static let md: CGFloat = unit * 2
    static let lg: CGFloat = unit * 3
    static let xl: CGFloat = unit * 4
    static let xxl: CGFloat = unit * 6
    static let hit: CGFloat = 44
}
