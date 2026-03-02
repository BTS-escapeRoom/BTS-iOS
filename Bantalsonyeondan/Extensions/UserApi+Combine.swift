//
//  UserApi+Combine.swift
//  Bantalsonyeondan
//
//  Created by 이상현 on 10/29/24.
//

import UIKit
import Combine
import KakaoSDKUser
import KakaoSDKAuth
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
            let lock = NSLock()
            var didResume = false

            func resumeOnce(with result: Result<String, Error>) {
                lock.lock()
                defer { lock.unlock() }
                guard !didResume else { return }
                didResume = true

                switch result {
                case let .success(token):
                    continuation.resume(returning: token)
                case let .failure(error):
                    continuation.resume(throwing: error)
                }
            }

            self.loginWithKakaoTalk { token, error in
                if let error {
                    resumeOnce(with: .failure(error))
                } else if let token {
                    resumeOnce(with: .success(token.accessToken))
                } else {
                    resumeOnce(
                        with: .failure(
                            NSError(
                                domain: "KakaoLogin",
                                code: -1,
                                userInfo: [NSLocalizedDescriptionKey: "No token received"]
                            )
                        )
                    )
                }
            }
        }
    }
    
    @MainActor
    func loginWithKakaoAccountAsync() async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let lock = NSLock()
            var didResume = false

            func resumeOnce(with result: Result<String, Error>) {
                lock.lock()
                defer { lock.unlock() }
                guard !didResume else { return }
                didResume = true

                switch result {
                case let .success(token):
                    continuation.resume(returning: token)
                case let .failure(error):
                    continuation.resume(throwing: error)
                }
            }

            self.loginWithKakaoAccount { token, error in
                if let error {
                    resumeOnce(with: .failure(error))
                } else if let token {
                    resumeOnce(with: .success(token.accessToken))
                } else {
                    resumeOnce(
                        with: .failure(
                            NSError(
                                domain: "KakaoLogin",
                                code: -1,
                                userInfo: [NSLocalizedDescriptionKey: "No token received"]
                            )
                        )
                    )
                }
            }
        }
    }
}
