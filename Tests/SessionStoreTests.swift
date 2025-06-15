import XCTest
@testable import Core

// Mock Clock for testing
class MockClock: Clock {
    private var currentTime = Date()

    func now() -> Date {
        currentTime
    }

    func advance(by seconds: TimeInterval) {
        currentTime = currentTime.addingTimeInterval(seconds)
    }
}

@MainActor
final class SessionStoreTests: XCTestCase {
    var mockClock: MockClock!
    var sessionStore: SessionStore!
    var tempURL: URL!

    override func setUp() async throws {
        mockClock = MockClock()

        // Create temporary file for each test to avoid conflicts
        let tempFileName = UUID().uuidString + ".json"
        tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(tempFileName)

        // Create a custom SessionStore that uses our temp file
        sessionStore = SessionStore(clock: mockClock, fileManager: .default, dataURL: tempURL)
    }

    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: tempURL)
    }

    func testStartSession() async throws {
        // Should start successfully
        try sessionStore.startSession()

        XCTAssertNotNil(sessionStore.activeSession)
        XCTAssertEqual(sessionStore.stats.usedSessions, 1)
        XCTAssertEqual(sessionStore.stats.remainingSessions, 49)
    }

    func testStartSessionWhenAlreadyActive() async throws {
        try sessionStore.startSession()

        // Should throw error when trying to start another session
        XCTAssertThrowsError(try sessionStore.startSession()) { error in
            XCTAssertEqual(error as? UsageError, .sessionAlreadyActive)
        }
    }

    func testStopSession() async throws {
        try sessionStore.startSession()

        mockClock.advance(by: 100) // Advance 100 seconds

        try sessionStore.stopSession()

        XCTAssertNil(sessionStore.activeSession)
        XCTAssertNotNil(sessionStore.stats.sessions.first?.end)
        XCTAssertEqual(sessionStore.stats.sessions.first?.duration(at: mockClock.now()) ?? 0, 100, accuracy: 1.0)
    }

    func testStopSessionWhenNoneActive() async throws {
        XCTAssertThrowsError(try sessionStore.stopSession()) { error in
            XCTAssertEqual(error as? UsageError, .noActiveSession)
        }
    }

    func testAutoStopAfter5Hours() async throws {
        try sessionStore.startSession()

        // Advance time by 5 hours (18000 seconds)
        mockClock.advance(by: 18000)

        // Trigger tick to check for auto-stop
        sessionStore.tick()

        XCTAssertNil(sessionStore.activeSession)
        XCTAssertNotNil(sessionStore.stats.sessions.first?.end)
    }

    func testQuotaReached() async throws {
        // Fill up the quota
        for _ in 0..<50 {
            try sessionStore.startSession()
            try sessionStore.stopSession()
        }

        // Should throw quota reached error
        XCTAssertThrowsError(try sessionStore.startSession()) { error in
            XCTAssertEqual(error as? UsageError, .quotaReached)
        }
    }

    func testSessionRemainingTime() async throws {
        try sessionStore.startSession()
        let session = sessionStore.activeSession!

        mockClock.advance(by: 3600) // 1 hour

        let remaining = session.remainingTime(at: mockClock.now())
        XCTAssertEqual(remaining, 4 * 60 * 60, accuracy: 1.0) // 4 hours remaining
    }

    func testMonthlyRollover() async throws {
        // Fill up current month
        for _ in 0..<50 {
            try sessionStore.startSession()
            try sessionStore.stopSession()
        }

        XCTAssertEqual(sessionStore.stats.usedSessions, 50)
        XCTAssertEqual(sessionStore.stats.remainingSessions, 0)

        // Simulate month change by creating new store with advanced time
        mockClock.advance(by: 32 * 24 * 60 * 60) // Advance 32 days
        let newStore = SessionStore(clock: mockClock, fileManager: .default)

        // Should be able to start new session in new month
        try newStore.startSession()
        XCTAssertEqual(newStore.stats.usedSessions, 1)
        XCTAssertEqual(newStore.stats.remainingSessions, 49)
    }

    func testTickWithoutActiveSession() async throws {
        // Should not crash when ticking without active session
        sessionStore.tick()
        XCTAssertNil(sessionStore.activeSession)
    }
}
