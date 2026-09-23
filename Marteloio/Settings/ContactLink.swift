import SwiftUI

/// Role: Settings. Support page on the app domain. Not a product shell.
enum ContactLink {
    /// Programmer constant. Contact page on marteloio-chart.pro.
    static let url = URL(string: "https://marteloio-chart.pro/contact-us")!
    /// Programmer constant. Catalog credit.
    static let catalog = URL(string: "https://openlibrary.org")!
}

struct ContactLinkButton: View {
    var body: some View {
        Link(destination: ContactLink.url) {
            Text("Contact")
                .font(TypeScale.body.weight(.semibold))
                .foregroundStyle(Palette.surface)
                .frame(maxWidth: .infinity, minHeight: Space.hit)
                .background(Palette.accent)
                .clipShape(Capsule())
                .contentShape(Capsule())
        }
        .accessibilityLabel("Contact Marteloio")
    }
}
