//
//  KakaoSignInManager.swift
//  Bantalsonyeondan
//

import Foundation
import KakaoSDKUser
import KakaoSDKAuth
import KakaoSDKCommon

final class KakaoSignInManager {
    static let shared = KakaoSignInManager()
    private init() {}

    // MARK: - 카카오톡 앱 로그인 (fallback: 카카오계정)
    func loginAsync() async throws -> (accessToken: String, userId: Int64) {
        do {
            let accessToken = try await UserApi.shared.loginWithKakaoTalkAsync()
            let userId = try await fetchUserId(accessToken: accessToken)
            return (accessToken, userId)
        } catch {
            guard shouldFallbackToAccount(error) else { throw error }
            let accessToken = try await UserApi.shared.loginWithKakaoAccountAsync()
            let userId = try await fetchUserId(accessToken: accessToken)
            return (accessToken, userId)
        }
    }

    // MARK: - 카카오계정 로그인 (직접 호출용)
    func loginWithAccountAsync() async throws -> (accessToken: String, userId: Int64) {
        let accessToken = try await UserApi.shared.loginWithKakaoAccountAsync()
        let userId = try await fetchUserId(accessToken: accessToken)
        return (accessToken, userId)
    }

    // MARK: - 로그아웃
    func logoutAsync() async throws {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            UserApi.shared.logout { error in
                if let error { cont.resume(throwing: error) }
                else { cont.resume() }
            }
        }
    }

    // MARK: - 카카오 userId 조회
    private func fetchUserId(accessToken: String) async throws -> Int64 {
        guard let url = URL(string: "https://kapi.kakao.com/v2/user/me") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              200..<300 ~= httpResponse.statusCode else {
            throw URLError(.badServerResponse)
        }
        let me = try JSONDecoder().decode(KakaoUserIDResponse.self, from: data)
        return me.id
    }

    private func shouldFallbackToAccount(_ error: Error) -> Bool {
        guard let sdkError = error as? SdkError,
              case let .ClientFailed(reason, _) = sdkError else { return false }
        return reason == .TokenNotFound || reason == .NotSupported
    }
}

private struct KakaoUserIDResponse: Decodable {
    let id: Int64
}
