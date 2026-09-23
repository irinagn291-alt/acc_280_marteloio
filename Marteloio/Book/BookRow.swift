import SwiftUI

/// Role: Book. Edge-to-edge moored row. The whole chrome is the hit target.
struct BookRow: View {
    var book: Book
    var genre: String
    var onHail: () -> Void
    var onFinish: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: Space.md) {
            Button(action: onHail) {
                VStack(alignment: .leading, spacing: Space.xs) {
                    Text(book.title)
                        .font(TypeScale.title)
                        .foregroundStyle(Palette.ink)
                        .lineLimit(2)
                    Text(genre)
                        .font(TypeScale.caption)
                        .foregroundStyle(Palette.muted)
                        .lineLimit(1)
                    if book.isFinished {
                        Text("Finished")
                            .font(TypeScale.caption)
                            .foregroundStyle(Palette.ink)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(HairlineTriggerStyle())
            .disabled(book.isFinished)
            .accessibilityLabel(hailLabel)

            Button(action: onFinish) {
                Text(book.isFinished ? "Landfall" : "Finish")
                    .font(TypeScale.caption.weight(.semibold))
                    .foregroundStyle(book.isFinished ? Palette.muted : Palette.ink)
                    .padding(.horizontal, Space.md)
                    .frame(minWidth: Space.hit, minHeight: Space.hit)
                    .background(Palette.surface)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.chip, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.chip, style: .continuous)
                            .stroke(Palette.ink.opacity(0.15), lineWidth: 1)
                    )
                    .contentShape(Rectangle())
            }
            .buttonStyle(HairlineTriggerStyle())
            .disabled(book.isFinished)
            .accessibilityLabel(book.isFinished ? "Finished, landfall written" : "Mark \(book.title) finished")
        }
        .padding(Space.md)
        .surfaceCard()
    }

    private var hailLabel: String {
        if book.isFinished {
            return "\(book.title), finished"
        }
        return "Hail \(book.title)"
    }
}
