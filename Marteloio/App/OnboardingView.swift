import SwiftUI

/// Role: App. Three paper-cut pages. Skip writes the same defaults as Continue.
struct OnboardingView: View {
    @Bindable var session: ChartSession
    @State private var page = 0

    private let pages: [(image: String, title: String, line: String)] = [
        (
            "mrt_Onboarding1",
            "Pages turn into distance",
            "Log what you read. Those pages become a Run on the chart."
        ),
        (
            "mrt_Onboarding2",
            "Tap an island to bear",
            "A solid island is close enough. The Run pays twenty pages for each cell."
        ),
        (
            "mrt_Onboarding3",
            "Lines thicken on return",
            "A far tap writes a luff and keeps the Run. The same pair gains weight."
        ),
    ]

    var body: some View {
        VStack(spacing: 0) {
            Button("Skip") {
                Task { await finish() }
            }
            .font(TypeScale.body)
            .foregroundStyle(Palette.ink)
            .frame(maxWidth: .infinity, minHeight: Space.hit, alignment: .trailing)
            .padding(.horizontal, Space.md)
            .contentShape(Rectangle())
            .buttonStyle(HairlineTriggerStyle())
            .accessibilityLabel("Skip onboarding")

            let current = pages[page]
            Image(current.image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .accessibilityHidden(true)
                .padding(.horizontal, Space.md)

            VStack(alignment: .leading, spacing: Space.sm) {
                Text(current.title)
                    .font(TypeScale.display)
                    .foregroundStyle(Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(current.line)
                    .font(TypeScale.body)
                    .foregroundStyle(Palette.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Space.md)
            .padding(.bottom, Space.md)

            Button(page == pages.count - 1 ? "Begin" : "Continue") {
                Task { await advance() }
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, Space.md)
            .padding(.bottom, Space.lg)
        }
        .background(Palette.background.ignoresSafeArea())
    }

    private func advance() async {
        if page < pages.count - 1 {
            page += 1
        } else {
            await finish()
        }
    }

    private func finish() async {
        _ = await session.apply(.setReachRate(ReachCost.defaultPagesPerCell))
        _ = await session.apply(.setGridSize(4))
        _ = await session.apply(.completeOnboarding)
        await session.ensureIslands()
        session.isReplayingOnboarding = false
        session.consumeReviewLaunch()
    }
}
