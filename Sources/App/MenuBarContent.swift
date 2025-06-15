import SwiftUI
import Core

struct MenuBarContent: View {
    @EnvironmentObject private var sessionStore: SessionStore
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(.blue)
                Text("Claude Tracker")
                    .font(.headline)
            }

            Divider()

            // Session Status
            VStack(spacing: 8) {
                if let activeSession = sessionStore.activeSession {
                    // Active session view
                    VStack(spacing: 4) {
                        Text("Session Active")
                            .font(.subheadline)
                            .foregroundColor(.green)

                        Text(formatTime(activeSession.remainingTime(at: Date())))
                            .font(.title2.monospacedDigit())
                            .foregroundColor(.primary)

                        Text("remaining")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        // Progress bar
                        let progress = 1.0 - (activeSession.remainingTime(at: Date()) / (5 * 60 * 60))
                        ProgressView(value: progress)
                            .progressViewStyle(LinearProgressViewStyle())
                            .frame(height: 8)
                    }

                    Button("Stop Session") {
                        do {
                            try sessionStore.stopSession()
                        } catch {
                            errorMessage = error.localizedDescription
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)

                } else {
                    // No active session
                    Text("No Active Session")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Button("Start Session") {
                        do {
                            try sessionStore.startSession()
                            errorMessage = nil
                        } catch {
                            errorMessage = error.localizedDescription
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .disabled(sessionStore.stats.remainingSessions == 0)
                }
            }

            Divider()

            // Usage Stats
            VStack(spacing: 4) {
                HStack {
                    Text("Sessions Used:")
                    Spacer()
                    Text("\(sessionStore.stats.usedSessions)/50")
                        .monospacedDigit()
                }
                .font(.caption)

                HStack {
                    Text("Remaining:")
                    Spacer()
                    Text("\(sessionStore.stats.remainingSessions)")
                        .monospacedDigit()
                        .foregroundColor(sessionStore.stats.remainingSessions > 10 ? .primary : .red)
                }
                .font(.caption)

                if let activeSession = sessionStore.activeSession {
                    HStack {
                        Text("Messages:")
                        Spacer()
                        Text("\(activeSession.messages)/250")
                            .monospacedDigit()
                    }
                    .font(.caption)
                }
            }

            // Error message
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }

            Divider()

            // Quit button
            Button("Quit Claude Tracker") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.plain)
            .foregroundColor(.red)
            .font(.caption)
        }
        .padding()
        .frame(width: 200)
    }

    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) % 3600 / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%d:%02d:%02d", hours, minutes, seconds)
    }
}

#Preview {
    MenuBarContent()
        .environmentObject(SessionStore())
}
