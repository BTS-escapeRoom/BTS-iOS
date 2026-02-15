//
//  UserApiType.swift
//  Bantalsonyeondan
//
//  Created by 이상현 on 10/29/24.
//

import Combine
import Foundation

// UserApi를 추상화한 프로토콜 정의
protocol UserApiType {
    func loginWithKakaoTalk() -> AnyPublisher<String, Error>
    func loginWithKakaoAccount() -> AnyPublisher<String, Error>
    
    // Async versions for TCA
    func loginWithKakaoTalkAsync() async throws -> String
    func loginWithKakaoAccountAsync() async throws -> String
}

struct AppleLoginRequest: Encodable {
    let code: String
    let nonce: String
}

struct AppSocialLoginRequest: Encodable {
    let code: String
    let accessToken: String?
    let id: Int64?
    let state: String?
    let nonce: String?
}

struct AuthResponse: Decodable, Equatable {
    let accessToken: String
    let refreshToken: String?
    let memberId: Int?
    let role: String?
    let isNewUser: Bool

    private enum CodingKeys: String, CodingKey {
        case accessToken
        case refreshToken
        case memberId
        case userId
        case role
        case isNewUser
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        accessToken = try container.decode(String.self, forKey: .accessToken)
        refreshToken = try container.decodeIfPresent(String.self, forKey: .refreshToken)
        memberId =
            try container.decodeIfPresent(Int.self, forKey: .memberId)
            ?? container.decodeIfPresent(Int.self, forKey: .userId)
        role = try container.decodeIfPresent(String.self, forKey: .role)
        isNewUser = try container.decodeIfPresent(Bool.self, forKey: .isNewUser) ?? false
    }
}

struct UserSession: Codable, Equatable {
    let accessToken: String
    let refreshToken: String?
    let memberId: Int?
    let role: String?
    let isNewUser: Bool

    init(
        accessToken: String,
        refreshToken: String? = nil,
        memberId: Int? = nil,
        role: String? = nil,
        isNewUser: Bool = false
    ) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.memberId = memberId
        self.role = role
        self.isNewUser = isNewUser
    }

    init(authResponse: AuthResponse) {
        let normalizedToken = authResponse.accessToken
            .replacingOccurrences(of: "Bearer ", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        self.init(
            accessToken: normalizedToken,
            refreshToken: authResponse.refreshToken,
            memberId: authResponse.memberId,
            role: authResponse.role,
            isNewUser: authResponse.isNewUser
        )
    }
}

struct CachedUserLocation: Codable, Equatable {
    let latitude: Double
    let longitude: Double
    let updatedAt: Date
}
