//
//  UserApi+Combine.swift
//  Bantalsonyeondan
//
//  Created by 이상현 on 10/29/24.
//

import UIKit
import Combine
import KakaoSDKUser
import AuthenticationServices

extension UserApi: UserApiType {
    func loginWithKakaoTalk() -> AnyPublisher<String, Error> {
        Future { promise in
            self.loginWithKakaoTalk { token, error in
                if let error = error {
                    promise(.failure(error))
                } else if let token = token {
                    promise(.success(token.accessToken))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func loginWithKakaoAccount() -> AnyPublisher<String, Error> {
        Future { promise in
            self.loginWithKakaoAccount { token, error in
                if let error = error {
                    promise(.failure(error))
                } else if let token = token {
                    promise(.success(token.accessToken))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    // MARK: - Async versions for TCA
    @MainActor
    func loginWithKakaoTalkAsync() async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            self.loginWithKakaoTalk { token, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let token = token {
                    continuation.resume(returning: token.accessToken)
                } else {
                    continuation.resume(throwing: NSError(domain: "KakaoLogin", code: -1, userInfo: [NSLocalizedDescriptionKey: "No token received"]))
                }
            }
        }
    }
    
    @MainActor
    func loginWithKakaoAccountAsync() async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            self.loginWithKakaoAccount { token, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let token = token {
                    continuation.resume(returning: token.accessToken)
                } else {
                    continuation.resume(throwing: NSError(domain: "KakaoLogin", code: -1, userInfo: [NSLocalizedDescriptionKey: "No token received"]))
                }
            }
        }
    }
}
