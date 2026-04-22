//
//  APIConfig.swift
//  Bantalsonyeondan
//
//  Created by 이상현 on 2/19/25.
//

import Foundation

struct APIConfig {
    static let baseURL = URL(string: "https://apis.bangtal-boys.com/v1/")!
    static let reissueURL = baseURL
        .appendingPathComponent("reissue")

    static var bearerToken: String? {
        guard let accessToken = AuthSessionStore.currentSession?.accessToken
            .replacingOccurrences(of: "Bearer ", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines),
              !accessToken.isEmpty else {
            return nil
        }
        return "Bearer \(accessToken)"
    }
}

enum AuthSessionStore {
    private static let defaults = UserDefaults.standard
    private static let sessionKey = "auth.session"
    private static let memberKey = "auth.member"
    private static let locationKey = "auth.cached.location"

    static var currentSession: UserSession? {
        get { loadValue(UserSession.self, forKey: sessionKey) }
        set { saveValue(newValue, forKey: sessionKey) }
    }

    static var currentMember: Member? {
        get { loadValue(Member.self, forKey: memberKey) }
        set { saveValue(newValue, forKey: memberKey) }
    }

    static var cachedLocation: CachedUserLocation? {
        get { loadValue(CachedUserLocation.self, forKey: locationKey) }
        set { saveValue(newValue, forKey: locationKey) }
    }

    static func clearAll() {
        defaults.removeObject(forKey: sessionKey)
        defaults.removeObject(forKey: memberKey)
        defaults.removeObject(forKey: locationKey)
    }

    private static func loadValue<T: Decodable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = defaults.data(forKey: key) else {
            return nil
        }
        return try? JSONDecoder().decode(type, from: data)
    }

    private static func saveValue<T: Encodable>(_ value: T?, forKey key: String) {
        guard let value else {
            defaults.removeObject(forKey: key)
            return
        }
        if let data = try? JSONEncoder().encode(value) {
            defaults.set(data, forKey: key)
        }
    }
}

extension Notification.Name {
    static let authSessionExpired = Notification.Name("authSessionExpired")
}

actor AuthRefreshCoordinator {
    static let shared = AuthRefreshCoordinator()

    private var runningTask: Task<UserSession, Error>?

    func refreshSessionIfNeeded(
        _ refreshWork: @escaping @Sendable () async throws -> UserSession
    ) async throws -> UserSession {
        if let runningTask {
            return try await runningTask.value
        }

        let task = Task {
            try await refreshWork()
        }
        runningTask = task
        defer { runningTask = nil }

        return try await task.value
    }
}
