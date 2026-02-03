//
//  UserApiType.swift
//  Bantalsonyeondan
//
//  Created by 이상현 on 10/29/24.
//

import Combine

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

struct AuthResponse: Decodable, Equatable {
    let accessToken: String
    let refreshToken: String?
    let isNewUser: Bool
    let userId: Int?
    let nickname: String?
}
