//
//  NaverSignInManager.swift
//  Bantalsonyeondan
//

import Foundation
import NaverThirdPartyLogin

@MainActor
final class NaverSignInManager: NSObject {
    static let shared = NaverSignInManager()

    private var continuation: CheckedContinuation<String, Error>?

    // MARK: - SDK 초기화
    static func configure() {
        let bundle = Bundle.main
        let clientID     = bundle.object(forInfoDictionaryKey: "NaverClientID")     as? String ?? ""
        let clientSecret = bundle.object(forInfoDictionaryKey: "NaverClientSecret") as? String ?? ""
        let redirectURI  = bundle.object(forInfoDictionaryKey: "NaverRedirectURI")  as? String ?? ""
        let urlScheme    = URL(string: redirectURI)?.scheme ?? ""

        let instance = NaverThirdPartyLoginConnection.getSharedInstance()!
        instance.isNaverAppOauthEnable = true
        instance.isInAppOauthEnable   = true
        instance.consumerKey          = clientID
        instance.consumerSecret       = clientSecret
        instance.appName              = bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
                                        ?? bundle.object(forInfoDictionaryKey: "CFBundleName") as? String
                                        ?? "방탈소년단"
        instance.serviceUrlScheme     = urlScheme
        instance.delegate             = NaverSignInManager.shared
    }

    // MARK: - URL 핸들링 (AppDelegate → 여기로 전달)
    func handleOpenURL(_ url: URL) {
        NaverThirdPartyLoginConnection.getSharedInstance()?.receiveAccessToken(url)
    }

    // MARK: - 현재 accessToken 반환 (탈퇴 시 사용)
    static func currentAccessToken() -> String? {
        guard let token = NaverThirdPartyLoginConnection.getSharedInstance()?.accessToken,
              !token.isEmpty else { return nil }
        return token
    }

    // MARK: - 토큰 초기화 (탈퇴 후 호출)
    static func resetToken() {
        NaverThirdPartyLoginConnection.getSharedInstance()?.resetToken()
    }

    // MARK: - 로그인 (accessToken 반환)
    func loginAsync() async throws -> String {
        if continuation != nil {
            throw NaverSignInError.loginInProgress
        }
        return try await withCheckedThrowingContinuation { cont in
            self.continuation = cont
            NaverThirdPartyLoginConnection.getSharedInstance()?.requestThirdPartyLogin()
        }
    }
}

// MARK: - Delegate
extension NaverSignInManager: NaverThirdPartyLoginConnectionDelegate {
    func oauth20ConnectionDidFinishRequestACTokenWithAuthCode() {
        guard let token = NaverThirdPartyLoginConnection.getSharedInstance()?.accessToken,
              !token.isEmpty else {
            continuation?.resume(throwing: NaverSignInError.missingAccessToken)
            continuation = nil
            return
        }
        continuation?.resume(returning: token)
        continuation = nil
    }

    func oauth20ConnectionDidFinishRequestACTokenWithRefreshToken() {
        guard let token = NaverThirdPartyLoginConnection.getSharedInstance()?.accessToken,
              !token.isEmpty else {
            continuation?.resume(throwing: NaverSignInError.missingAccessToken)
            continuation = nil
            return
        }
        continuation?.resume(returning: token)
        continuation = nil
    }

    func oauth20ConnectionDidFinishDeleteToken() {
        // 로그아웃 완료 — 별도 처리 필요 없음
    }

    func oauth20Connection(_ oauthConnection: NaverThirdPartyLoginConnection!, didFailWithError error: Error!) {
        continuation?.resume(throwing: error ?? NaverSignInError.unknown)
        continuation = nil
    }
}

// MARK: - Error
enum NaverSignInError: LocalizedError {
    case loginInProgress
    case missingAccessToken
    case unknown

    var errorDescription: String? {
        switch self {
        case .loginInProgress:   return "네이버 로그인이 이미 진행 중이에요."
        case .missingAccessToken: return "네이버 액세스 토큰을 받아오지 못했어요."
        case .unknown:           return "네이버 로그인 중 오류가 발생했어요."
        }
    }
}
