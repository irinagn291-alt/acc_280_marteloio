import SwiftUI

/// Role: Session. Locale-aware integer field. Negative and non-numeric values are rejected live.
struct PagesEntryField: View {
    var title: String
    @Binding var text: String
    var allowsZero: Bool

    var parsed: Int? {
        Self.parse(text, allowsZero: allowsZero)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Space.xs) {
            Text(title)
                .font(TypeScale.caption)
                .foregroundStyle(Palette.muted)
            TextField(title, text: $text)
                .keyboardType(.numberPad)
                .font(TypeScale.tabular)
                .padding(Space.md)
                .frame(minHeight: Space.hit)
                .background(Palette.surface)
                .clipShape(RoundedRectangle(cornerRadius: Radius.chip, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.chip, style: .continuous)
                        .stroke(Palette.ink.opacity(0.12), lineWidth: 1)
                )
                .onChange(of: text) { _, next in
                    text = Self.sanitized(next)
                }
            if !text.isEmpty, parsed == nil {
                Text("Enter a whole number\(allowsZero ? "" : " above zero").")
                    .font(TypeScale.caption)
                    .foregroundStyle(Palette.ink)
            }
        }
    }

    static func sanitized(_ raw: String) -> String {
        raw.filter(\.isNumber)
    }

    static func parse(_ raw: String, allowsZero: Bool) -> Int? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        guard let number = formatter.number(from: trimmed) else { return nil }
        let value = number.intValue
        if value < 0 { return nil }
        if value == 0, !allowsZero { return nil }
        return value
    }
}
