//
//  AppleSignInManager.swift
//  Bantalsonyeondan
//
//  Created by Copilot on 12/03/25.
//

import Foundation
import AuthenticationServices
import UIKit

struct AppleSignInResult {
    let authorizationCode: String
    let state: String
}

final class AppleSignInManager: NSObject {
    static let shared = AppleSignInManager()

    private var continuation: CheckedContinuation<AppleSignInResult, Error>?
    private var expectedState: String?

    func signInWithAppleAsync(state: String, nonce: String) async throws -> AppleSignInResult {
        if continuation != nil {
            throw NSError(
                domain: "AppleSignIn",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Another sign-in is in progress"]
            )
        }

        expectedState = state

        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.state = state
        request.nonce = nonce

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self

        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<AppleSignInResult, Error>) in
            self.continuation = continuation
            controller.performRequests()
        }
    }
}

extension AppleSignInManager: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            continuation?.resume(throwing: NSError(
                domain: "AppleSignIn",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Invalid credential type"]
            ))
            continuation = nil
            expectedState = nil
            return
        }

        guard let codeData = credential.authorizationCode,
              let code = String(data: codeData, encoding: .utf8) else {
            continuation?.resume(throwing: NSError(
                domain: "AppleSignIn",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Missing authorization code"]
            ))
            continuation = nil
            expectedState = nil
            return
        }

        let state = credential.state ?? ""
        let result = AppleSignInResult(authorizationCode: code, state: state)

        continuation?.resume(returning: result)
        continuation = nil
        expectedState = nil
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        continuation?.resume(throwing: error)
        continuation = nil
        expectedState = nil
    }
}

extension AppleSignInManager: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        UIApplication.shared.windows.first { $0.isKeyWindow } ?? ASPresentationAnchor()
    }
}

struct NaverSignInResult {
    let code: String
    let state: String
}

private struct NaverSignInConfiguration {
    let clientID: String
    let redirectURI: String
    let callbackScheme: String

    static func load(bundle: Bundle = .main) throws -> NaverSignInConfiguration {
        let clientID = (bundle.object(forInfoDictionaryKey: "NaverClientID") as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let redirectURI = (bundle.object(forInfoDictionaryKey: "NaverRedirectURI") as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard !clientID.isEmpty else {
            throw NaverSignInError.configurationMissing("Info.plist의 NaverClientID를 설정해주세요.")
        }
        guard !redirectURI.isEmpty else {
            throw NaverSignInError.configurationMissing("Info.plist의 NaverRedirectURI를 설정해주세요.")
        }
        guard let schemeSeparatorRange = redirectURI.range(of: "://") else {
            throw NaverSignInError.configurationMissing("NaverRedirectURI는 URL 스킴이 포함된 값이어야 합니다.")
        }
        let scheme = String(redirectURI[..<schemeSeparatorRange.lowerBound])
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !scheme.isEmpty else {
            throw NaverSignInError.configurationMissing("NaverRedirectURI는 URL 스킴이 포함된 값이어야 합니다.")
        }

        return NaverSignInConfiguration(
            clientID: clientID,
            redirectURI: redirectURI,
            callbackScheme: scheme
        )
    }
}

private enum NaverSignInError: LocalizedError {
    case configurationMissing(String)
    case loginInProgress
    case cancelled
    case failedToStartSession
    case missingCallbackURL
    case missingAuthorizationCode
    case missingState
    case stateMismatch
    case authorizationFailed(String)

    var errorDescription: String? {
        switch self {
        case let .configurationMissing(message):
            return message
        case .loginInProgress:
            return "네이버 로그인이 이미 진행 중입니다."
        case .cancelled:
            return "네이버 로그인이 취소되었어요."
        case .failedToStartSession:
            return "네이버 로그인 화면을 시작하지 못했어요."
        case .missingCallbackURL:
            return "네이버 로그인 응답을 받지 못했어요."
        case .missingAuthorizationCode:
            return "네이버 인가 코드를 받지 못했어요."
        case .missingState:
            return "네이버 state 값을 받지 못했어요."
        case .stateMismatch:
            return "네이버 로그인 state 검증에 실패했어요."
        case let .authorizationFailed(message):
            return message
        }
    }
}

final class NaverSignInManager: NSObject {
    static let shared = NaverSignInManager()

    private var authenticationSession: ASWebAuthenticationSession?
    private var continuation: CheckedContinuation<NaverSignInResult, Error>?
    private var expectedState: String?

    @MainActor
    func signInWithNaverAsync() async throws -> NaverSignInResult {
        if continuation != nil {
            throw NaverSignInError.loginInProgress
        }

        let configuration = try NaverSignInConfiguration.load()
        let state = UUID().uuidString
        let authorizationURL = try makeAuthorizationURL(
            clientID: configuration.clientID,
            redirectURI: configuration.redirectURI,
            state: state
        )

        expectedState = state

        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<NaverSignInResult, Error>) in
            self.continuation = continuation

            let session = ASWebAuthenticationSession(
                url: authorizationURL,
                callbackURLScheme: configuration.callbackScheme
            ) { [weak self] callbackURL, error in
                self?.handleNaverCallback(callbackURL: callbackURL, error: error)
            }
            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = false
            authenticationSession = session

            guard session.start() else {
                completeNaverSignIn(with: .failure(NaverSignInError.failedToStartSession))
                return
            }
        }
    }

    private func makeAuthorizationURL(clientID: String, redirectURI: String, state: String) throws -> URL {
        var components = URLComponents(string: "https://nid.naver.com/oauth2.0/authorize")
        components?.queryItems = [
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "state", value: state)
        ]

        guard let url = components?.url else {
            throw URLError(.badURL)
        }
        return url
    }

    private func handleNaverCallback(callbackURL: URL?, error: Error?) {
        if let error {
            if let authError = error as? ASWebAuthenticationSessionError,
               authError.code == .canceledLogin {
                completeNaverSignIn(with: .failure(NaverSignInError.cancelled))
                return
            }
            completeNaverSignIn(with: .failure(error))
            return
        }
        guard let callbackURL else {
            completeNaverSignIn(with: .failure(NaverSignInError.missingCallbackURL))
            return
        }

        let queryItems = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)?.queryItems ?? []
        let query: [String: String] = queryItems.reduce(into: [:]) { partialResult, item in
            partialResult[item.name] = item.value
        }

        if let errorCode = query["error"] {
            let errorMessage = query["error_description"] ?? errorCode
            completeNaverSignIn(with: .failure(NaverSignInError.authorizationFailed(errorMessage)))
            return
        }

        guard let code = query["code"], !code.isEmpty else {
            completeNaverSignIn(with: .failure(NaverSignInError.missingAuthorizationCode))
            return
        }
        guard let receivedState = query["state"], !receivedState.isEmpty else {
            completeNaverSignIn(with: .failure(NaverSignInError.missingState))
            return
        }
        guard receivedState == expectedState else {
            completeNaverSignIn(with: .failure(NaverSignInError.stateMismatch))
            return
        }

        completeNaverSignIn(with: .success(NaverSignInResult(code: code, state: receivedState)))
    }

    private func completeNaverSignIn(with result: Result<NaverSignInResult, Error>) {
        switch result {
        case let .success(value):
            continuation?.resume(returning: value)
        case let .failure(error):
            continuation?.resume(throwing: error)
        }
        continuation = nil
        authenticationSession = nil
        expectedState = nil
    }
}

extension NaverSignInManager: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        UIApplication.shared.windows.first { $0.isKeyWindow } ?? ASPresentationAnchor()
    }
}
