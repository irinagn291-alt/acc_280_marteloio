import SwiftUI

/// Role: Chart. Home. Reading log over the genre shelf. Sheets stack over the board.
struct ChartScreen: View {
    @Bindable var session: ChartSession
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showSuccess = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if session.record.books.isEmpty {
                    ChartEmptyState {
                        session.presented = .shelf
                    }
                } else {
                    populated
                }
            }
            .background(Palette.background.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        session.presented = .logbook
                    } label: {
                        Text("Days")
                            .font(TypeScale.body)
                            .foregroundStyle(Palette.ink)
                            .frame(minWidth: Space.hit, minHeight: Space.hit)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(HairlineTriggerStyle())
                    .accessibilityLabel("Open daily reading log")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        session.presented = .settings
                    } label: {
                        Image(systemName: "gearshape")
                            .font(TypeScale.body)
                            .foregroundStyle(Palette.ink)
                            .frame(width: Space.hit, height: Space.hit)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(HairlineTriggerStyle())
                    .accessibilityLabel("Settings")
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .fullScreenCover(item: $session.presented) { surface in
            sheet(for: surface)
        }
        .overlay {
            if showSuccess {
                Image("mrt_SuccessMark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 96, height: 96)
                    .accessibilityHidden(true)
                    .transition(.opacity)
            }
        }
        .animation(reduceMotion ? .easeInOut(duration: 0.2) : Motion.standard, value: showSuccess)
    }

    private var populated: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Space.md) {
                header
                IslandBoard(snapshot: session.canvas) { islandID in
                    Task { await select(islandID) }
                }
            }
            .padding(.horizontal, Space.md)
            .padding(.top, Space.sm)
            .padding(.bottom, Space.md)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Button(primaryTitle) {
                Task { await performPrimary() }
            }
            .buttonStyle(PrimaryButtonStyle(isLoading: session.isWorking))
            .disabled(session.isWorking)
            .accessibilityLabel(primaryTitle)
            .padding(.horizontal, Space.md)
            .padding(.vertical, Space.sm)
            .background(Palette.background.ignoresSafeArea(edges: .bottom))
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Space.sm) {
            Text(headline)
                .font(TypeScale.display)
                .foregroundStyle(Palette.ink)
                .fixedSize(horizontal: false, vertical: true)

            Text(prompt)
                .font(TypeScale.body)
                .foregroundStyle(Palette.muted)
                .fixedSize(horizontal: false, vertical: true)

            if let refusal = session.lastRefusal {
                Text(refusalCopy(refusal))
                    .font(TypeScale.body)
                    .foregroundStyle(Palette.ink)
            }

            if let warning = session.warning {
                errorBanner(warning)
            }
            if let issue = session.writeIssue {
                writeBanner(issue)
            }
            if Shoal.blocksBear(session.record) {
                Text("Add another genre before you can place pages.")
                    .font(TypeScale.body)
                    .foregroundStyle(Palette.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(Space.md)
                    .surfaceCard()
            }
        }
    }

    @ViewBuilder
    private func sheet(for surface: ChartSurface) -> some View {
        switch surface {
        case .shelf:
            ShelfSheet(session: session)
        case .logbook:
            LogbookSheet(session: session)
        case .settings:
            SettingsSheet(session: session)
        case .reach:
            RhumbReachSheet(session: session)
        }
    }

    private var todayPages: Int {
        let today = Daykey.of(Date())
        return session.record.marks.reduce(0) { total, mark in
            if case .fix(let fix) = mark, fix.daykey == today {
                return total + fix.pages
            }
            return total
        }
    }

    private var headline: String {
        if Shoal.blocksBear(session.record) {
            return "Need one more genre"
        }
        return "Reading log. \(ChartNumbers.pages(todayPages)) pages today"
    }

    private var prompt: String {
        if Shoal.blocksBear(session.record) {
            return "Open Settings and add a second genre, then log pages."
        }
        switch session.record.phase {
        case .hailed:
            if let run = session.record.run, let origin = session.record.island(run.originIslandID) {
                return "\(origin.genre) has \(ChartNumbers.pages(run.remainder)) pages ready. Tap a genre card to place them, or log another book."
            }
            return "Tap a genre card to place today's pages."
        case .bound:
            return "Today's pages are placed. Log another book to start again."
        case .moored:
            return "Tap Log pages, pick a book, and write what you read."
        }
    }

    private var primaryTitle: String {
        "Log pages"
    }

    private func errorBanner(_ warning: StoreWarning) -> some View {
        VStack(alignment: .leading, spacing: Space.sm) {
            Text(warningCopy(warning))
                .font(TypeScale.body)
                .foregroundStyle(Palette.ink)
            Button("Retry") {
                Task { await session.start() }
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding(Space.md)
        .surfaceCard()
    }

    private func writeBanner(_ issue: String) -> some View {
        VStack(alignment: .leading, spacing: Space.sm) {
            Text("The last save did not finish. Your chart is still in memory.")
                .font(TypeScale.body)
                .foregroundStyle(Palette.ink)
            Text(issue)
                .font(TypeScale.caption)
                .foregroundStyle(Palette.muted)
            Button("Save again") {
                Task { await session.flush() }
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding(Space.md)
        .surfaceCard()
    }

    private func warningCopy(_ warning: StoreWarning) -> String {
        switch warning {
        case .recoveredFromBackup:
            return "The last chart file was restored from a backup."
        case .startedFresh:
            return "The saved chart could not be read, so a fresh chart was opened."
        }
    }

    private func refusalCopy(_ refusal: FoldRefusal) -> String {
        switch refusal {
        case .secondHail:
            return "A session is still open. Place those pages before you log again."
        case .bearWhileMoored:
            return "Log a book first. There are no pages to place yet."
        case .bearWhileBound:
            return "This session has no pages left. Log another book."
        case .sameIsland:
            return "Pick a different genre from the one you started on."
        case .finishedBook:
            return "That book is finished. Pick one still on the shelf."
        case .unknownBook, .unknownIsland:
            return "That book is missing. Open the shelf and add it again."
        case .invalidPages:
            return "Pages need to be a number above zero."
        case .invalidMinutes:
            return "Minutes cannot be below zero."
        case .shoal:
            return "Two genres are needed before you can place pages."
        case .alreadyLuffed:
            return "That genre is too far for the pages left today."
        case .emptyTitle:
            return "A book needs a title before it can sit on the shelf."
        case .emptyGenre:
            return "A genre needs a name."
        }
    }

    private func performPrimary() async {
        session.presented = .shelf
    }

    private func select(_ islandID: Island.ID) async {
        if session.record.phase == .hailed, session.record.run?.originIslandID == islandID {
            session.presented = .reach
            return
        }
        if session.record.phase != .hailed {
            session.presented = .shelf
            return
        }
        let result = await session.apply(.bear(islandID: islandID), celebrate: true)
        if result.accepted, case .rhumb = result.mark {
            flashSuccess()
        }
    }

    private func flashSuccess() {
        showSuccess = true
        Task {
            try? await Task.sleep(nanoseconds: 700_000_000)
            await MainActor.run { showSuccess = false }
        }
    }
}
