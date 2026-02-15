//
//  APIConfig.swift
//  Bantalsonyeondan
//
//  Created by 이상현 on 2/19/25.
//

import Foundation

struct APIConfig {
    static let baseURL = URL(string: "https://apis.bangtal-boys.com/v1/")!
    static let debugFallbackBearerToken = "Bearer eyJhbGciOiJIUzI1NiJ9.eyJ0eXBlIjoiYWNjZXNzLXRva2VuIiwiaWQiOjEsInVzZXJuYW1lIjoi6rSA66as7J6QIiwicm9sZSI6IlJPTEVfQURNSU4iLCJpYXQiOjE3MzYyMjgzMDUsImV4cCI6ODA2MzAyMjgzMDV9.SkiUghz1aukqU2UNpUEON-N5mrQs73I1NuaoifjL0DI"

    static var bearerToken: String? {
        if let accessToken = AuthSessionStore.currentSession?.accessToken, !accessToken.isEmpty {
            return "Bearer \(accessToken)"
        }
        return debugFallbackBearerToken
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
