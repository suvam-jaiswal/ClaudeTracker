# ClaudeTracker

A macOS menu bar app that tracks Claude Code usage sessions with a 50-session monthly quota and 5-hour session limits.

## Features

- ✅ Start/Stop 5-hour coding sessions
- ✅ Track 50 sessions per month quota
- ✅ Persistent session history
- ✅ Auto-stop when session limit reached
- ✅ Monthly rollover on first day of new month
- ✅ Real-time countdown timer
- ✅ Menu bar integration with system tray

## Tech Stack

- **SwiftUI** for the UI
- **MenuBarExtra** for menu bar integration
- **Combine** for reactive updates
- **Swift Package Manager** for build system
- **XCTest** for unit testing

## Development

### Quick Start

```bash
# Install dependencies (if needed)
brew install fswatch

# Build and run
npm run preview-swift

# Run tests
npm run test

# Watch mode (auto-rebuild on file changes)
npm run watch
```

### VS Code Tasks

The project includes VS Code tasks for easy development:

- **Cmd+Shift+P** → "Tasks: Run Task" → "Build and Preview Swift App"
- **Cmd+Shift+P** → "Tasks: Run Task" → "Run Tests"
- **Cmd+Shift+P** → "Tasks: Run Task" → "Watch Swift Files"

### Project Structure

```
ClaudeTracker/
├── Package.swift              # SwiftPM manifest
├── Sources/
│   ├── App/
│   │   ├── ClaudeTrackerApp.swift    # Main app entry point
│   │   └── MenuBarContent.swift      # Menu bar UI
│   └── Core/
│       ├── DataModels.swift          # Data structures
│       └── SessionStore.swift        # Business logic
├── Tests/
│   └── SessionStoreTests.swift       # Unit tests (90%+ coverage)
└── scripts/
    ├── preview-swift.sh              # Build & launch script
    └── watch.sh                      # File watcher for development
```

## Usage

1. **Start Session**: Click the timer icon in menu bar → "Start Session"
2. **Monitor Progress**: Watch the countdown timer and progress bar
3. **Session Auto-Stop**: Sessions automatically end after 5 hours
4. **Quota Tracking**: View remaining sessions (X/50) in the menu
5. **Monthly Reset**: Quota resets on the 1st of each month

## API

### SessionStore

```swift
@MainActor
public final class SessionStore: ObservableObject {
    func startSession() throws          // Start new session
    func stopSession() throws           // Stop active session
    func tick()                         // Called every second
    var activeSession: Session?         // Current session
    var stats: MonthlyStats            // Monthly usage stats
}
```

### Data Models

```swift
struct Session: Codable, Identifiable {
    let id: UUID
    let start: Date
    var end: Date?
    var messages: Int

    func duration(at: Date) -> TimeInterval
    func remainingTime(at: Date) -> TimeInterval
}

struct MonthlyStats: Codable {
    let ym: YearMonth
    var sessions: [Session]
    var usedSessions: Int        // Count of sessions
    var remainingSessions: Int   // 50 - usedSessions
}
```

## Testing

Run comprehensive unit tests:

```bash
swift test
```

Tests cover:

- Session lifecycle (start/stop)
- 5-hour auto-stop functionality
- Monthly quota enforcement (50 sessions)
- Monthly rollover behavior
- Edge cases and error handling

## Build & Distribution

### Development Build

```bash
npm run preview-swift
```

### Release Build

```bash
swift build -c release
```

The app bundle is created at `.build/release/ClaudeTracker.app`

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make changes with tests
4. Run `swift test` to verify
5. Submit a pull request

Use Conventional Commits format:

- `feat:` for new features
- `fix:` for bug fixes
- `test:` for test improvements
- `docs:` for documentation

## License

MIT License - see LICENSE file for details.
