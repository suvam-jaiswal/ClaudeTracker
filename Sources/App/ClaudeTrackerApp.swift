import SwiftUI
import Core

@main
struct ClaudeTrackerApp: App {
    @StateObject private var sessionStore = SessionStore()

    var body: some Scene {
        MenuBarExtra("Claude Tracker", systemImage: "timer") {
            MenuBarContent()
                .environmentObject(sessionStore)
        }
        .menuBarExtraStyle(.window)
    }
}
