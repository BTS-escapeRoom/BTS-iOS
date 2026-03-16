//
//  APIClient.swift
//  Bantalsonyeondan
//
//  Created by 이상현 on 1/15/25.
//

import Foundation
import KakaoSDKUser
import KakaoSDKAuth
import KakaoSDKCommon
import AuthenticationServices

//MARK: APIClient
protocol APIClient: BaseAPIClientProtocol {
    init()
}

extension APIClient {
    static var live: Self {
        Self()
    }
    
    static var preview: Self {
        Self()
    }
    
    static var test: Self {
        Self()
    }
}

//MARK: 테마 리뷰 API
struct ReviewAPIClient: APIClient {
    /// GET /v1/reviews/{reviewId} 리뷰 단건 조회
    func  getReview(_ reviewId: String) async throws -> Review {
        try await request("reviews/\(reviewId)")
    }
    
    /// PUT /v1/reviews/{reviewId} 리뷰 수정
    func updateReview(_ reviewId: String, request reviewRequest: ReviewUpdateRequest) async throws -> Review {
        try await request("reviews/\(reviewId)",
                          method: "PUT",
                          body: reviewRequest)
    }
    
    /// DELETE /v1/reviews/{reviewId} 리뷰 삭제
    func  deleteReview(_ reviewId: String) async throws -> String {
        try await request("reviews/\(reviewId)",
                          method: "DELETE")
    }
    
    /// GET /v1/reviews 리뷰 목록 조회
    func  getReviews(_ themeId: String) async throws -> [Review] {
        try await request("reviews",
                          query: ["themeId":themeId])
    }
    
    /// POST /v1/reviews 리뷰 등록
    func  createReviews(_ review: ReviewRegist) async throws -> Review {
        try await request("reviews",
                          method: "POST",
                          body: review)
    }
    
    /// GET /v1/reviews/me 내가 쓴 리뷰 조회
    func  getMyReviews() async throws -> [Review] {
        try await request("reviews/me")
    }

    /// GET /v1/reviews/history/{memberId} 방탈출 기록 조회
    func getHistory(memberId: Int) async throws -> [ReviewHistory] {
        try await request("reviews/history/\(memberId)")
    }

    /// PUT /v1/reviews/history-display 방탈출 기록 노출 정보 수정
    func updateHistoryDisplay(reviewIds: [Int]) async throws -> String {
        try await request(
            "reviews/history-display",
            method: "PUT",
            query: ["reviewIds": reviewIds]
        )
    }
}

//MARK: 회원 API
struct MemberAPIClient: APIClient {
    /// PUT /v1/members 회원 정보 수정
    func  updateMembers(_ member: MemberUpdateRequest) async throws -> Member {
        try await request("members",
                          method: "PUT",
                          body: member)
    }
    
    /// GET /v1/members/me 내 회원 정보 조회
    func  getMyMembers() async throws -> Member {
        try await request("members/me")
    }

    /// DELETE /v1/members 회원 탈퇴
    func deleteMember(naverAccessToken: String? = nil) async throws {
        let trimmedNaverToken = naverAccessToken?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let headers: [String: String]
        if trimmedNaverToken.isEmpty {
            headers = [:]
        } else {
            headers = ["naverAccessToken": trimmedNaverToken]
        }

        let _: EmptyResponseObject = try await request(
            "members",
            method: "DELETE",
            headers: headers
        )
    }
}

private struct EmptyResponseObject: Decodable {}

//MARK: 댓글 API
struct CommentAPIClient: APIClient {
    /// GET /v1/comments/{commentId}/boards 댓글 조회
    func  getComments(commentId: String) async throws -> Comment {
        try await request("comments/\(commentId)/boards")
    }
    
    /// PUT /v1/comments/{commentId}/boards 테마 댓글 수정
    func  updateComments(commentId: String, _ comment:String) async throws -> Comment {
        try await request("comments/\(commentId)/boards",
                          method: "PUT",
                          body: ["comment":comment])
    }
    
    /// DELETE /v1/comments/{commentId}/boards 테마 댓글 삭제
    func  deleteComments(commentId: String) async throws -> Comment {
        try await request("comments/\(commentId)/boards")
    }
    
    /// GET /v1/boards/{boardId}/comments 게시글 댓글 조회
    func  getComments(boardId: String) async throws -> BoardCommentsResponse {
        try await request("boards/\(boardId)/comments")
    }
    
    /// POST /v1/comments/boards 게시글 댓글 작성
    func  createComments(boardId: String, _ comment:String) async throws -> Comment {
        try await request("comments",
                          method: "POST",
                          body: ["boardId":boardId, "comment":comment])
    }
}

//MARK: 테마 API
struct ThemeAPIClient: APIClient {
    /// GET /v1/themes/like    내가 찜한 테마 조회
    func fetchLikedThemes() async throws -> [Theme] {
        try await request("themes/like")
    }
    
    /// POST /v1/themes/like   테마 찜 등록/취소 (토글)
    func toggleLikeTheme(_ themeId: String) async throws -> String {
        try await request("themes/like",
                          method: "POST",
                          query: ["themeId": themeId])
    }
    
    /// GET /v1/themes         테마 리스트 조회
    func  fetchThemes(_ themeRequest: ThemeRequest) async throws -> ThemeResponse {
        try await request("themes",
                          query: themeRequest)
    }
    
    /// GET /v1/themes/{id}    테마 단건 조회
    func  fetchThemeById(_ themeId: String) async throws -> ThemeDetail {
        try await request("themes/\(themeId)")
    }
    
    /// GET /v1/themes/recent  최신 테마 조회 (밴드용)
    func  fetchThemesRecent() async throws -> [Theme] {
        try await request("themes/recent")
    }
    
    /// GET /v1/themes/random  랜덤 테마 조회 (빅배너용)
    func  fetchThemesRandom() async throws -> [Theme] {
        try await request("themes/random")
    }
    
    /// GET /v1/themes/popular 인기 테마 조회 (밴드용)
    func  fetchThemesPopular() async throws -> [Theme] {
        try await request("themes/popular")
    }
    
    /// GET /v1/themes/popular/realtime  실시간 인기 테마 조회 (밴드용)
    func  fetchThemesPopularRealtime() async throws -> [Theme] {
        try await request("themes/popular/realtime")
    }
    
    /// GET /v1/themes/most-liked  좋아요 개수 높은 순 (밴드용)
    func  fetchThemesMostLiked() async throws -> [Theme] {
        try await request("themes/most-liked")
    }
}

//MARK: 게시판 API
struct BoardAPIClient: APIClient {
    /// GET /v1/boards
    func getBoards(_ boardRequest: BoardRequest) async throws -> BoardResponse {
        try await request("boards", query: boardRequest)
    }

    /// GET /v1/boards/my
    func getMyBoards() async throws -> [Board] {
        try await request("boards/my")
    }
    
    /// POST /v1/boards
    func createBoards(_ board: BoardCreateRequest) async throws -> BoardSimple {
        try await request("boards",
                          method: "POST",
                          body: board)
    }
    
    /// GET /v1/boards/like
    func getLikedBoards() async throws -> [Board] {
        try await request("boards/like")
    }
    
    /// POST /v1/boards/{boardId}/like
    func toggleLikedBoards(_ boardId: String) async throws -> String {
        try await request("boards/\(boardId)/like", method: "POST")
    }
    
    /// GET /v1/boards/{boardId}
    func getBoard(_ boardId: String) async throws -> BoardDetail {
        try await request("boards/\(boardId)")
    }

    /// PATCH /v1/boards/{boardId}
    func updateBoard(_ boardId: String, _ requestBody: BoardUpdateRequest) async throws -> BoardDetail {
        try await request(
            "boards/\(boardId)",
            method: "PATCH",
            body: requestBody
        )
    }

    /// PATCH /v1/boards/{boardId}/close-recruit
    func closeRecruit(_ boardId: String) async throws -> String {
        try await request(
            "boards/\(boardId)/close-recruit",
            method: "PATCH"
        )
    }
    
    /// DELETE /v1/boards/{boardId}
    func deleteBoard(_ boardId: String) async throws -> String {
        try await request("boards/\(boardId)",
                          method: "DELETE")
    }
}

//MARK: 유저 API
struct UserAPIClient: APIClient {
    /// 카카오톡 로그인
    func loginWithKakaoTalkAsync() async throws -> AuthResponse {
        do {
            let accessToken = try await UserApi.shared.loginWithKakaoTalkAsync()
            return try await loginWithKakao(accessToken: accessToken)
        } catch {
            guard shouldFallbackToKakaoAccount(error) else {
                throw error
            }
            let accessToken = try await UserApi.shared.loginWithKakaoAccountAsync()
            return try await loginWithKakao(accessToken: accessToken)
        }
    }

    /// 카카오 계정 로그인
    func loginWithKakaoAccountAsync() async throws -> AuthResponse {
        let accessToken = try await UserApi.shared.loginWithKakaoAccountAsync()
        return try await loginWithKakao(accessToken: accessToken)
    }

    /// 네이버 로그인: 백엔드 authorization URL을 열고 return-url result를 받아 앱 세션으로 변환
    func loginWithNaverAsync() async throws -> AuthResponse {
        let result = try await NaverSignInManager.shared.signInWithNaverAsync()
        switch result.outcome {
        case .success:
            return AuthResponse(
                accessToken: naverPlaceholderAccessToken,
                refreshToken: nil,
                memberId: nil,
                role: nil,
                isNewUser: false
            )
        case .signup, .emptyNickname:
            return AuthResponse(
                accessToken: naverPlaceholderAccessToken,
                refreshToken: nil,
                memberId: nil,
                role: nil,
                isNewUser: true
            )
        }
    }

    /// 애플 로그인 전체 플로우: Apple 인증 + 서버 로그인
    func loginWithAppleAsync() async throws -> AuthResponse {
        let state = UUID().uuidString
        let nonce = UUID().uuidString
        let result = try await AppleSignInManager.shared
            .signInWithAppleAsync(state: state, nonce: nonce)

        if result.state != state {
            throw NSError(domain: "AppleLogin", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid state"])
        }

        return try await login(
            provider: "apple",
            body: AppSocialLoginRequest(
                code: result.authorizationCode,
                accessToken: nil,
                id: nil,
                state: nil,
                nonce: nonce
            )
        )
    }

    private func login(provider: String, body: AppSocialLoginRequest) async throws -> AuthResponse {
        try await request("auth/login/\(provider)", method: "POST", body: body)
    }

    private func loginWithKakao(accessToken: String) async throws -> AuthResponse {
        // fetch kakao user id using the access token
        let userId = try await fetchCurrentKakaoUserId(accessToken: accessToken)
        // The backend expects either an authorization code or an access token. When the client
        // already obtained an access token via the Kakao SDK, send only the access token payload
        // and omit `code` entirely so the backend does not treat an empty string as a real code.
        return try await login(
            provider: "kakao",
            body: AppSocialLoginRequest(
                code: nil,
                accessToken: accessToken,
                id: userId,
                state: nil,
                nonce: nil
            )
        )
    }

    private func shouldFallbackToKakaoAccount(_ error: Error) -> Bool {
        guard let sdkError = error as? SdkError else {
            return false
        }
        if case let .ClientFailed(reason, _) = sdkError {
            return reason == .TokenNotFound || reason == .NotSupported
        }
        return false
    }

    private func fetchCurrentKakaoUserId(accessToken: String) async throws -> Int64 {
        guard let url = URL(string: "https://kapi.kakao.com/v2/user/me") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        guard 200..<300 ~= httpResponse.statusCode else {
            let responseText = String(data: data, encoding: .utf8) ?? "No response body"
            throw URLError(
                .badServerResponse,
                userInfo: [NSLocalizedDescriptionKey: "Kakao user info failed: \(httpResponse.statusCode), \(responseText)"]
            )
        }

        let me = try JSONDecoder().decode(KakaoUserIDResponse.self, from: data)
        return me.id
    }
}

private struct KakaoUserIDResponse: Decodable {
    let id: Int64
}

private extension UserAPIClient {
    var naverPlaceholderAccessToken: String {
        "naver-oauth-session"
    }
}
