import Foundation

/// Role: Rhumb. Small-caps rose text under an inked line.
enum BearingLabel {
    static func text(_ bearing: Bearing) -> String {
        bearing.rawValue.uppercased()
    }
}
