import SwiftUI

/// Role: Session. Medium sheet on Shelf. Hail seats a Fix and writes the Run.
struct HailSheet: View {
    @Bindable var session: ChartSession
    var book: Book
    @Environment(\.dismiss) private var dismiss
    @State private var pagesText = ""
    @State private var minutesText = ""
    @FocusState private var focus: Field?

    private enum Field {
        case pages
        case minutes
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Space.lg) {
                    Text(book.title)
                        .font(TypeScale.display)
                        .foregroundStyle(Palette.ink)
                    Text(session.record.island(book.islandID)?.genre ?? "Island")
                        .font(TypeScale.body)
                        .foregroundStyle(Palette.muted)

                    if session.record.phase == .hailed {
                        Text("A Run is still open. Bear it before you Hail again.")
                            .font(TypeScale.body)
                            .foregroundStyle(Palette.ink)
                            .padding(Space.md)
                            .surfaceCard()
                    }

                    PagesEntryField(title: "Pages read", text: $pagesText, allowsZero: false)
                        .focused($focus, equals: .pages)
                    PagesEntryField(title: "Minutes", text: $minutesText, allowsZero: true)
                        .focused($focus, equals: .minutes)

                    if let minutes = PagesEntryField.parse(minutesText, allowsZero: true), minutes > 0 {
                        let suggested = IslandFill.pages(fromMinutes: minutes, pace: session.record.readingPace)
                        Text("About \(ChartNumbers.pages(suggested)) pages at your pace.")
                            .font(TypeScale.caption)
                            .foregroundStyle(Palette.muted)
                    }

                    if let refusal = session.lastRefusal {
                        Text(hailRefusal(refusal))
                            .font(TypeScale.body)
                            .foregroundStyle(Palette.ink)
                    }

                    Button("Hail") {
                        Task { await hail() }
                    }
                    .buttonStyle(PrimaryButtonStyle(isLoading: session.isWorking))
                    .disabled(!canHail)
                    .accessibilityLabel("Hail this session")
                }
                .padding(Space.md)
            }
            .background(Palette.background)
            .scrollDismissesKeyboard(.interactively)
            .onTapGesture { focus = nil }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .frame(width: Space.hit, height: Space.hit)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(HairlineTriggerStyle())
                    .accessibilityLabel("Close Hail")
                }
            }
        }
    }

    private var canHail: Bool {
        PagesEntryField.parse(pagesText, allowsZero: false) != nil
            && PagesEntryField.parse(minutesText.isEmpty ? "0" : minutesText, allowsZero: true) != nil
            && !session.isWorking
            && session.record.phase != .hailed
            && !book.isFinished
    }

    private func hail() async {
        guard let pages = PagesEntryField.parse(pagesText, allowsZero: false) else { return }
        let minutes = PagesEntryField.parse(minutesText.isEmpty ? "0" : minutesText, allowsZero: true) ?? 0
        let result = await session.apply(
            .hail(bookID: book.id, pages: pages, minutes: minutes),
            celebrate: true
        )
        if result.accepted {
            session.hailBook = nil
        }
    }

    private func hailRefusal(_ refusal: FoldRefusal) -> String {
        switch refusal {
        case .secondHail:
            return "A Run is still open. Bear it before you Hail again."
        case .finishedBook:
            return "That book is finished."
        case .invalidPages:
            return "Pages need to be a number above zero."
        case .invalidMinutes:
            return "Minutes cannot be below zero."
        default:
            return "This Hail could not be written. Try another book."
        }
    }
}
