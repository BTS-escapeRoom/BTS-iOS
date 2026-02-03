//
//  AppleSignInManager.swift
//  Bantalsonyeondan
//
//  Created by Copilot on 12/03/25.
//

import Foundation
import AuthenticationServices
import CryptoKit

struct AppleSignInResult {
    let authorizationCode: String
    let state: String
}

final class AppleSignInManager: NSObject {
    static let shared = AppleSignInManager()

    private var continuation: CheckedContinuation<AppleSignInResult, Error>?
    private var expectedState: String?

    func signInWithAppleAsync(state: String, nonce: String) async throws -> AppleSignInResult {
        // 이전 요청이 남아있다면 에러 처리
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

        let result = AppleSignInResult(
            authorizationCode: code,
            state: state
        )

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
        // 가장 위에 있는 UIWindow 반환
        return UIApplication.shared.windows.first { $0.isKeyWindow } ?? ASPresentationAnchor()
    }
}
