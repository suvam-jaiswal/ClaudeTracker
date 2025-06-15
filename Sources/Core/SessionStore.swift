import Foundation
import Combine

@MainActor
public final class SessionStore: ObservableObject {
    @Published public private(set) var stats: MonthlyStats

    private let clock: Clock
    private let fileManager: FileManager
    private var timer: AnyCancellable?
    private let customDataURL: URL?

    private var dataURL: URL {
        if let customDataURL = customDataURL {
            return customDataURL
        }
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("ClaudeTracker")
        try? fileManager.createDirectory(at: appDir, withIntermediateDirectories: true)
        return appDir.appendingPathComponent("stats.json")
    }

    public init(clock: Clock = SystemClock(), fileManager: FileManager = .default, dataURL: URL? = nil) {
        self.clock = clock
        self.fileManager = fileManager
        self.customDataURL = dataURL

        // Initialize with a temporary stats first
        let currentYM = YearMonth(from: clock.now())
        self.stats = MonthlyStats(ym: currentYM)

        // Now we can safely use dataURL to load existing stats
        if let savedStats = Self.loadStats(from: self.dataURL, fileManager: fileManager),
           savedStats.ym == currentYM {
            self.stats = savedStats
        }

        // Start timer if there's an active session
        if stats.activeSession != nil {
            startTimer()
        }
    }

    public var activeSession: Session? {
        stats.activeSession
    }

    public func startSession() throws {
        // Check if we need to rollover to new month
        let currentYM = YearMonth(from: clock.now())
        if stats.ym != currentYM {
            stats = MonthlyStats(ym: currentYM)
        }

        // Check quota
        guard stats.remainingSessions > 0 else {
            throw UsageError.quotaReached
        }

        // Check if session already active
        guard stats.activeSession == nil else {
            throw UsageError.sessionAlreadyActive
        }

        // Create new session
        let newSession = Session(start: clock.now())
        stats.sessions.append(newSession)

        // Start timer
        startTimer()

        // Save
        saveStats()
    }

    public func stopSession() throws {
        guard let activeIndex = stats.sessions.firstIndex(where: { $0.isActive }) else {
            throw UsageError.noActiveSession
        }

        // End the session
        stats.sessions[activeIndex].end = clock.now()

        // Stop timer
        stopTimer()

        // Save
        saveStats()
    }

    public func tick() {
        guard let activeIndex = stats.sessions.firstIndex(where: { $0.isActive }) else {
            stopTimer()
            return
        }

        let session = stats.sessions[activeIndex]
        let currentTime = clock.now()

        // Check if session should auto-stop (5 hours = 18000 seconds)
        if session.duration(at: currentTime) >= 5 * 60 * 60 {
            stats.sessions[activeIndex].end = currentTime
            stopTimer()
            saveStats()
        }

        // Trigger UI update
        objectWillChange.send()
    }

    private func startTimer() {
        timer = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }

    private func stopTimer() {
        timer?.cancel()
        timer = nil
    }

    private func saveStats() {
        guard let data = try? JSONEncoder().encode(stats) else { return }
        try? data.write(to: dataURL)
    }

    private static func loadStats(from url: URL, fileManager: FileManager) -> MonthlyStats? {
        guard fileManager.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url),
              let stats = try? JSONDecoder().decode(MonthlyStats.self, from: data) else {
            return nil
        }
        return stats
    }
}
