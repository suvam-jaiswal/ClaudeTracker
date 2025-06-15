import Foundation

// MARK: - Clock Protocol
public protocol Clock {
    func now() -> Date
}

public struct SystemClock: Clock {
    public init() {}

    public func now() -> Date {
        Date()
    }
}

// MARK: - Data Models
public struct YearMonth: Codable, Hashable {
    public let year: Int
    public let month: Int

    public init(year: Int, month: Int) {
        self.year = year
        self.month = month
    }

    public init(from date: Date) {
        let components = Calendar.current.dateComponents([.year, .month], from: date)
        self.year = components.year ?? 2025
        self.month = components.month ?? 1
    }
}

public struct Session: Codable, Identifiable {
    public let id: UUID
    public let start: Date
    public var end: Date?
    public var messages: Int

    public init(start: Date, end: Date? = nil, messages: Int = 0) {
        self.id = UUID()
        self.start = start
        self.end = end
        self.messages = messages
    }

    public var isActive: Bool {
        end == nil
    }

    public func duration(at currentTime: Date) -> TimeInterval {
        if let end = end {
            return end.timeIntervalSince(start)
        }
        return currentTime.timeIntervalSince(start)
    }

    public func remainingTime(at currentTime: Date) -> TimeInterval {
        let sessionLimit: TimeInterval = 5 * 60 * 60 // 5 hours
        return max(0, sessionLimit - duration(at: currentTime))
    }
}

public struct MonthlyStats: Codable {
    public let ym: YearMonth
    public var sessions: [Session]

    public init(ym: YearMonth, sessions: [Session] = []) {
        self.ym = ym
        self.sessions = sessions
    }

    public var usedSessions: Int {
        sessions.count
    }

    public var remainingSessions: Int {
        max(0, 50 - usedSessions)
    }

    public var activeSession: Session? {
        sessions.first { $0.isActive }
    }
}

// MARK: - Errors
public enum UsageError: Error, LocalizedError {
    case quotaReached
    case sessionAlreadyActive
    case noActiveSession

    public var errorDescription: String? {
        switch self {
        case .quotaReached:
            return "Monthly quota of 50 sessions reached"
        case .sessionAlreadyActive:
            return "A session is already active"
        case .noActiveSession:
            return "No active session found"
        }
    }
}
