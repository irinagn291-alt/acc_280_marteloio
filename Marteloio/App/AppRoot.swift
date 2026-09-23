import SwiftUI

/// Role: App. Chart-locked root. Onboarding, then the portolan, then the sheet stack.
struct AppRoot: View {
    @State private var session = ChartSession()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if !session.isReady {
                Palette.background.ignoresSafeArea()
            } else if session.shouldOnboard {
                OnboardingView(session: session)
            } else {
                ChartScreen(session: session)
            }
        }
        .task {
            await session.start()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active {
                Task { await session.flush() }
            }
        }
        .preferredColorScheme(.light)
    }
}
