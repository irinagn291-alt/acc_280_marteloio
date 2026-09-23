import AVFoundation
import SwiftUI
import UIKit

/// Role: Book. Fused scan and title search. Moor picks the island. Hail stacks on top.
struct ShelfView: View {
    @Bindable var session: ChartSession

    var body: some View {
        ShelfSheet(session: session)
    }
}

/// Role: Book. Fused scan and title search. Moor picks the island. Hail stacks on top.
struct ShelfSheet: View {
    @Bindable var session: ChartSession
    @Environment(\.scenePhase) private var scenePhase
    @State private var query = ""
    @State private var selectedIslandID: Island.ID?
    @State private var results: [CatalogTitle] = []
    @State private var isSearching = false
    @State private var searchError: String?
    @State private var searchTask: Task<Void, Never>?
    @State private var cameraStatus = CameraPermission.status
    @State private var manualISBN = ""
    @State private var lookupError: String?
    @State private var isLookingUp = false
    @FocusState private var searchFocused: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Space.lg) {
                    Text("Shelf")
                        .font(TypeScale.display)
                        .foregroundStyle(Palette.ink)

                    Text("Scan a paperback or search by title, then pick the genre island.")
                        .font(TypeScale.body)
                        .foregroundStyle(Palette.muted)

                    scanRegion
                    searchField
                    genrePicker
                    resultList
                    mooredList
                }
                .padding(Space.md)
            }
            .background(Palette.background)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    SheetStack.closeButton { session.presented = nil }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .scrollDismissesKeyboard(.interactively)
            .onTapGesture { searchFocused = false }
            .sheet(item: $session.hailBook) { book in
                SheetStack.hail(HailSheet(session: session, book: book))
            }
            .onAppear {
                cameraStatus = CameraPermission.status
                if results.isEmpty {
                    results = LocalShelf.items()
                }
                if selectedIslandID == nil {
                    selectedIslandID = session.record.islands.first?.id
                }
            }
            .onDisappear {
                searchTask?.cancel()
            }
            .onChange(of: scenePhase) { _, phase in
                if phase != .active {
                    searchTask?.cancel()
                }
            }
            .onChange(of: query) { _, next in
                scheduleSearch(next)
            }
        }
    }

    private var scanActive: Bool {
        scenePhase == .active && cameraStatus == .authorized
    }

    @ViewBuilder
    private var scanRegion: some View {
        VStack(alignment: .leading, spacing: Space.sm) {
            switch cameraStatus {
            case .authorized:
                ZStack {
                    IsbnScanner(isActive: scanActive) { code in
                        Task { await lookup(code) }
                    }
                    ScanReticle()
                        .stroke(Palette.ink, lineWidth: 2)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: Radius.surface, style: .continuous))
                .shadow(color: Elevation.shadowColor(), radius: Elevation.radius, x: 0, y: Elevation.y)
            case .notDetermined:
                VStack(alignment: .leading, spacing: Space.md) {
                    Text("The camera reads a barcode so you can moor a book without typing the number.")
                        .font(TypeScale.body)
                        .foregroundStyle(Palette.ink)
                    Button("Continue") {
                        Task {
                            cameraStatus = await CameraPermission.request()
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
                .padding(Space.md)
                .surfaceCard()
            default:
                VStack(alignment: .leading, spacing: Space.md) {
                    Text("Camera access is off. Title search still works, or open Settings if you want to scan.")
                        .font(TypeScale.body)
                        .foregroundStyle(Palette.ink)
                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
                .padding(Space.md)
                .surfaceCard()
            }

            #if targetEnvironment(simulator)
            simulatorChips
            #endif

            HStack(spacing: Space.sm) {
                TextField("ISBN", text: $manualISBN)
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
                Button("Look up") {
                    Task { await lookup(manualISBN) }
                }
                .buttonStyle(PrimaryButtonStyle(isLoading: isLookingUp))
                .disabled(manualISBN.trimmingCharacters(in: .whitespaces).isEmpty || isLookingUp)
                .frame(maxWidth: 140)
            }
            if let lookupError {
                Text(lookupError)
                    .font(TypeScale.caption)
                    .foregroundStyle(Palette.ink)
            }
        }
    }

    private var searchField: some View {
        VStack(alignment: .leading, spacing: Space.sm) {
            TextField("Search by title", text: $query)
                .font(TypeScale.body)
                .focused($searchFocused)
                .padding(Space.md)
                .frame(minHeight: Space.hit)
                .background(Palette.surface)
                .clipShape(RoundedRectangle(cornerRadius: Radius.surface, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.surface, style: .continuous)
                        .stroke(Palette.ink.opacity(0.12), lineWidth: 1)
                )
                .shadow(color: Elevation.shadowColor(), radius: Elevation.radius, x: 0, y: Elevation.y)
            if isSearching {
                ProgressView()
                    .tint(Palette.accent)
            }
            if let searchError {
                VStack(alignment: .leading, spacing: Space.sm) {
                    Text(searchError)
                        .font(TypeScale.body)
                        .foregroundStyle(Palette.ink)
                    Button("Search again") {
                        scheduleSearch(query)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
                .padding(Space.md)
                .surfaceCard()
            }
        }
    }

    private var genrePicker: some View {
        VStack(alignment: .leading, spacing: Space.sm) {
            Text("Island")
                .font(TypeScale.caption)
                .foregroundStyle(Palette.muted)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Space.sm) {
                    ForEach(session.record.islands) { island in
                        Button {
                            selectedIslandID = island.id
                        } label: {
                            Text(island.genre)
                                .font(TypeScale.caption.weight(.semibold))
                                .foregroundStyle(selectedIslandID == island.id ? Palette.surface : Palette.ink)
                                .padding(.horizontal, Space.md)
                                .frame(minHeight: Space.hit)
                                .background(selectedIslandID == island.id ? Palette.accent : Palette.surface)
                                .clipShape(RoundedRectangle(cornerRadius: Radius.chip, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: Radius.chip, style: .continuous)
                                        .stroke(Palette.ink.opacity(0.12), lineWidth: 1)
                                )
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(HairlineTriggerStyle())
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var resultList: some View {
        let localMode = query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let rows = localMode ? LocalShelf.items() : results
        VStack(alignment: .leading, spacing: Space.sm) {
            Text(localMode ? "Local shelf" : "Catalog")
                .font(TypeScale.title)
                .foregroundStyle(Palette.ink)
            if rows.isEmpty {
                emptyCatalog
            } else {
                ForEach(rows) { title in
                    Button {
                        Task { await moor(title) }
                    } label: {
                        VStack(alignment: .leading, spacing: Space.xs) {
                            Text(title.title)
                                .font(TypeScale.title)
                                .foregroundStyle(Palette.ink)
                                .lineLimit(2)
                            Text(subtitle(title))
                                .font(TypeScale.caption)
                                .foregroundStyle(Palette.muted)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(Space.md)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(HairlineTriggerStyle())
                    .surfaceCard()
                }
            }
        }
    }

    private var emptyCatalog: some View {
        VStack(alignment: .leading, spacing: Space.md) {
            Image("mrt_EmptyList")
                .resizable()
                .scaledToFit()
                .frame(width: 140, height: 140)
                .accessibilityHidden(true)
            Text("Nothing on this search")
                .font(TypeScale.title)
                .foregroundStyle(Palette.ink)
            Text("Try another title, or moor a book from the local shelf.")
                .font(TypeScale.body)
                .foregroundStyle(Palette.muted)
            Button("Use local shelf") {
                query = ""
                results = LocalShelf.items()
                searchError = nil
                searchFocused = true
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private var mooredList: some View {
        VStack(alignment: .leading, spacing: Space.sm) {
            Text("Moored")
                .font(TypeScale.title)
                .foregroundStyle(Palette.ink)
            if session.record.books.isEmpty {
                VStack(alignment: .leading, spacing: Space.sm) {
                    Text("Books you moor will sit here, ready to Hail.")
                        .font(TypeScale.body)
                        .foregroundStyle(Palette.muted)
                    Button("Moor a local title") {
                        if let first = LocalShelf.items().first {
                            Task { await moor(first) }
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(LocalShelf.items().isEmpty)
                }
                .padding(Space.md)
                .surfaceCard()
            } else {
                ForEach(session.record.books) { book in
                    BookRow(
                        book: book,
                        genre: session.record.island(book.islandID)?.genre ?? "Island",
                        onHail: { session.hailBook = book },
                        onFinish: {
                            Task { _ = await session.apply(.finish(bookID: book.id), celebrate: true) }
                        }
                    )
                }
            }
        }
    }

    #if targetEnvironment(simulator)
    private var simulatorChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Space.sm) {
                ForEach(LocalShelf.items()) { title in
                    Button(title.title) {
                        Task { await lookup(title.isbn) }
                    }
                    .font(TypeScale.caption.weight(.semibold))
                    .foregroundStyle(Palette.ink)
                    .padding(.horizontal, Space.md)
                    .frame(minHeight: Space.hit)
                    .background(Palette.surface)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.chip, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.chip, style: .continuous)
                            .stroke(Palette.ink.opacity(0.12), lineWidth: 1)
                    )
                    .contentShape(Rectangle())
                    .buttonStyle(HairlineTriggerStyle())
                }
            }
        }
        .accessibilityLabel("Simulator ISBN chips")
    }
    #endif

    private func subtitle(_ title: CatalogTitle) -> String {
        let author = title.author.isEmpty ? "Unknown author" : title.author
        let genre = title.genreHint.isEmpty ? "Genre unset" : title.genreHint
        return "\(author), \(genre)"
    }

    private func scheduleSearch(_ raw: String) {
        searchTask?.cancel()
        let needle = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !needle.isEmpty else {
            isSearching = false
            searchError = nil
            results = LocalShelf.items()
            return
        }
        searchTask = Task {
            let wait = Task {
                try await Task.sleep(nanoseconds: 150_000_000)
            }
            do {
                try await wait.value
                if !Task.isCancelled {
                    isSearching = true
                }
                let titles = try await session.catalog.searchDebounced(title: needle)
                guard !Task.isCancelled else { return }
                results = titles.isEmpty ? LocalShelf.search(query: needle) : titles
                searchError = nil
                isSearching = false
                await session.rememberCatalog(titles)
            } catch is CancellationError {
                return
            } catch let error as CatalogError where error == .cancelled {
                return
            } catch {
                guard !Task.isCancelled else { return }
                let local = LocalShelf.search(query: needle)
                results = local
                searchError = local.isEmpty ? "Title search could not reach the catalog. Try again, or use the local shelf." : nil
                isSearching = false
            }
        }
    }

    private func lookup(_ raw: String) async {
        guard let isbn = IsbnDigits.canonicalize(raw) ?? (raw.isEmpty ? nil : raw) else {
            lookupError = "That number does not look like an ISBN."
            return
        }
        isLookingUp = true
        lookupError = nil
        do {
            let title = try await session.catalog.lookup(isbn: isbn)
            await moor(title)
            await session.rememberCatalog([title])
        } catch let error as CatalogError where error == .notFound {
            lookupError = "No catalog row for that ISBN. Search by title instead."
        } catch {
            if let local = LocalShelf.items().first(where: { $0.isbn == isbn }) {
                await moor(local)
            } else {
                lookupError = "The catalog hop failed. Try title search."
            }
        }
        isLookingUp = false
    }

    private func moor(_ title: CatalogTitle) async {
        let islandID = session.record.islandID(matchingGenre: title.genreHint)
            ?? selectedIslandID
            ?? session.record.islands.first?.id
        guard let islandID else {
            lookupError = "Add a genre island in Settings first."
            return
        }
        let book = Book(
            isbn: title.isbn,
            title: title.title,
            islandID: islandID
        )
        _ = await session.apply(.moor(book), celebrate: true)
    }
}
