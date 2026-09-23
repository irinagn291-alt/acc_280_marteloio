import SwiftUI

/// Role: Settings. Reach rate, grid, island names, reminder, onboarding, reset, contact.
struct SettingsView: View {
    @Bindable var session: ChartSession

    var body: some View {
        SettingsSheet(session: session)
    }
}

/// Role: Settings. Reach rate, grid, island names, reminder, onboarding, reset, contact.
struct SettingsSheet: View {
    @Bindable var session: ChartSession
    @State private var confirmReset = false
    @State private var reminderError: String?
    @State private var renameDrafts: [Island.ID: String] = [:]

    var body: some View {
        NavigationStack {
            Group {
                if session.record.islands.isEmpty {
                    empty
                } else {
                    populated
                }
            }
            .background(Palette.background)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    SheetStack.closeButton { session.presented = nil }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                for island in session.record.islands where renameDrafts[island.id] == nil {
                    renameDrafts[island.id] = island.genre
                }
            }
            .alert("Reset the chart?", isPresented: $confirmReset) {
                Button("Reset chart", role: .destructive) {
                    Task { await session.resetAll() }
                }
                Button("Keep chart", role: .cancel) {}
            } message: {
                Text("Islands, books and rhumbs will be cleared from this device.")
            }
        }
    }

    private var empty: some View {
        VStack(alignment: .leading, spacing: Space.md) {
            Image("mrt_EmptyList")
                .resizable()
                .scaledToFit()
                .frame(width: 160, height: 160)
                .accessibilityHidden(true)
            Text("No islands yet")
                .font(TypeScale.display)
                .foregroundStyle(Palette.ink)
            Text("Replay the opening pages to plant the genre grid.")
                .font(TypeScale.body)
                .foregroundStyle(Palette.muted)
            Spacer(minLength: Space.md)
            Button("Replay onboarding") {
                session.presented = nil
                session.isReplayingOnboarding = true
            }
            .buttonStyle(PrimaryButtonStyle())
            ContactLinkButton()
        }
        .padding(Space.md)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var populated: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Space.lg) {
                Text("Settings")
                    .font(TypeScale.display)
                    .foregroundStyle(Palette.ink)

                if session.writeIssue != nil {
                    VStack(alignment: .leading, spacing: Space.sm) {
                        Text("The last save did not finish.")
                            .font(TypeScale.body)
                            .foregroundStyle(Palette.ink)
                        Button("Save again") {
                            Task { await session.flush() }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                    .padding(Space.md)
                    .surfaceCard()
                }

                ReachRateControl(rate: session.record.reachRate) { rate in
                    Task { _ = await session.apply(.setReachRate(rate)) }
                }

                gridControl

                islandNames

                reminderBlock

                Button("Replay onboarding") {
                    session.presented = nil
                    session.isReplayingOnboarding = true
                }
                .buttonStyle(PrimaryButtonStyle())

                Button("Reset all data") {
                    confirmReset = true
                }
                .buttonStyle(PrimaryButtonStyle(isDestructive: true))

                ContactLinkButton()

                Link(destination: ContactLink.catalog) {
                    Text("Title search uses Open Library")
                        .font(TypeScale.caption)
                        .foregroundStyle(Palette.muted)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(minHeight: Space.hit, alignment: .leading)
                        .contentShape(Rectangle())
                }
            }
            .padding(Space.md)
        }
    }

    private var gridControl: some View {
        HStack(spacing: Space.md) {
            Button {
                Task { _ = await session.apply(.setGridSize(session.record.gridSize - 1)) }
            } label: {
                Image(systemName: "minus")
                    .frame(width: Space.hit, height: Space.hit)
                    .contentShape(Rectangle())
            }
            .buttonStyle(HairlineTriggerStyle())
            .accessibilityLabel("Decrease chart grid")

            VStack(spacing: Space.xs) {
                Text(ChartNumbers.pages(session.record.gridSize))
                    .font(TypeScale.tabular)
                    .foregroundStyle(Palette.ink)
                Text("grid size")
                    .font(TypeScale.caption)
                    .foregroundStyle(Palette.muted)
            }
            .frame(maxWidth: .infinity)

            Button {
                Task { _ = await session.apply(.setGridSize(session.record.gridSize + 1)) }
            } label: {
                Image(systemName: "plus")
                    .frame(width: Space.hit, height: Space.hit)
                    .contentShape(Rectangle())
            }
            .buttonStyle(HairlineTriggerStyle())
            .accessibilityLabel("Increase chart grid")
        }
        .padding(Space.md)
        .surfaceCard()
    }

    private var islandNames: some View {
        VStack(alignment: .leading, spacing: Space.sm) {
            Text("Island names")
                .font(TypeScale.title)
                .foregroundStyle(Palette.ink)
            ForEach(session.record.islands) { island in
                TextField(
                    "Genre",
                    text: Binding(
                        get: { renameDrafts[island.id] ?? island.genre },
                        set: { renameDrafts[island.id] = $0 }
                    )
                )
                .font(TypeScale.body)
                .padding(Space.md)
                .frame(minHeight: Space.hit)
                .background(Palette.surface)
                .clipShape(RoundedRectangle(cornerRadius: Radius.chip, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.chip, style: .continuous)
                        .stroke(Palette.ink.opacity(0.12), lineWidth: 1)
                )
                .onSubmit {
                    Task {
                        let name = renameDrafts[island.id] ?? island.genre
                        _ = await session.apply(.renameIsland(id: island.id, genre: name))
                    }
                }
            }
        }
    }

    private var reminderBlock: some View {
        VStack(alignment: .leading, spacing: Space.sm) {
            Toggle(isOn: Binding(
                get: { session.record.reminder.isEnabled },
                set: { enabled in
                    var next = session.record.reminder
                    next.isEnabled = enabled
                    Task { await setReminder(next) }
                }
            )) {
                Text("Evening reminder")
                    .font(TypeScale.body)
                    .foregroundStyle(Palette.ink)
            }
            .frame(minHeight: Space.hit)
            .tint(Palette.accent)

            DatePicker(
                "Time",
                selection: Binding(
                    get: { reminderDate },
                    set: { date in
                        let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
                        var next = session.record.reminder
                        next.hour = parts.hour ?? 20
                        next.minute = parts.minute ?? 0
                        Task { await setReminder(next) }
                    }
                ),
                displayedComponents: .hourAndMinute
            )
            .font(TypeScale.body)
            .foregroundStyle(Palette.ink)
            .frame(minHeight: Space.hit)

            if let reminderError {
                Text(reminderError)
                    .font(TypeScale.caption)
                    .foregroundStyle(Palette.ink)
            }
        }
        .padding(Space.md)
        .surfaceCard()
    }

    private var reminderDate: Date {
        return Calendar.current.date(
            bySettingHour: session.record.reminder.hour,
            minute: session.record.reminder.minute,
            second: 0,
            of: Date()
        ) ?? Date()
    }

    private func setReminder(_ settings: ReminderSettings) async {
        _ = await session.apply(.setReminder(settings))
        reminderError = await ReminderScheduler.apply(settings)
    }
}
