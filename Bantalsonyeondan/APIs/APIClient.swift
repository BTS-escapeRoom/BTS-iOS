//
//  APIClient.swift
//  Bantalsonyeondan
//
//  Created by 이상현 on 1/15/25.
//

import Foundation
import KakaoSDKUser
import KakaoSDKAuth
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
    func  updateReview(_ reviewId: String, review:Review) async throws -> Review {
        try await request("reviews/\(reviewId)",
                          method: "PUT",
                          body: review)
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
}

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
    
    /// POST /v1/boards/like
    func toggleLikedBoards(_ boardId: String) async throws -> String {
        try await request("boards/like",
                          method: "POST",
                          query: ["boardId":boardId])
    }
    
    /// GET /v1/boards/{boardId}
    func getBoard(_ boardId: String) async throws -> BoardDetail {
        try await request("boards/\(boardId)")
    }
    
    /// DELETE /v1/boards/{boardId}
    func deleteBoard(_ boardId: String) async throws -> String {
        try await request("boards/\(boardId)",
                          method: "DELETE")
    }
}

//MARK: 유저 API
struct UserAPIClient: APIClient {
    /// 카카오톡 로그인: 클라이언트에서 Kakao 로그인과 유저 조회까지 처리 후 userId만 서버에 전달
    func loginWithKakaoTalkAsync() async throws -> String {
        // Kakao SDK async 브리지로 토큰 획득 (필요 시 서버에 함께 보낼 수 있음)
        let accessToken = try await UserApi.shared.loginWithKakaoTalkAsync()

        // Kakao 사용자 정보 조회 (userId 사용)
        let user = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<User, Error>) in
            UserApi.shared.me { user, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let user = user {
                    continuation.resume(returning: user)
                } else {
                    continuation.resume(throwing: NSError(
                        domain: "KakaoLoginError",
                        code: 0,
                        userInfo: [NSLocalizedDescriptionKey: "No User Info"]
                    ))
                }
            }
        }

        guard let userId = user.id else {
            throw NSError(
                domain: "KakaoLoginError",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "No User ID"]
            )
        }

        // 우리 서버에 userId 전달
        let body: [String: String] = ["accessToken": accessToken, "id": "\(userId)"]
        let response: String = try await self.request("auth/login/kakao", method: "POST", body: body)
        return response
    }

    /// 카카오 계정 로그인: 카카오 계정으로 로그인 후 동일하게 userId만 서버에 전달
    func loginWithKakaoAccountAsync() async throws -> String {
        // Kakao 계정으로 로그인 (비동기 브리지 사용)
        _ = try await UserApi.shared.loginWithKakaoAccountAsync()

        // 내 정보 조회해서 user.id 가져오기
        let user = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<User, Error>) in
            UserApi.shared.me { user, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let user = user {
                    continuation.resume(returning: user)
                } else {
                    continuation.resume(throwing: NSError(
                        domain: "KakaoMe",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "No user info"]
                    ))
                }
            }
        }

        guard let userId = user.id else {
            throw NSError(
                domain: "KakaoMe",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "No user id"]
            )
        }

        // 우리 서버에 userId만 전달
        let body: [String: Int64] = ["userId": userId]
        let response: String = try await self.request("auth/login/kakao", method: "POST", body: body)
        return response
    }

    /// 네이버 로그인 (TODO: 구현 필요)
    func loginWithNaverAsync() async throws -> String {
        // TODO: Naver login implementation
        throw NSError(domain: "NaverLogin", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not implemented"])
    }

    /// 애플 로그인 전체 플로우: Apple 인증 + 서버 로그인
    func loginWithAppleAsync() async throws -> String {
        // 1) state / nonce 생성
        let state = UUID().uuidString
        let nonce = UUID().uuidString
        
        let result = try await AppleSignInManager.shared
            .signInWithAppleAsync(state: state, nonce: nonce)

        // 3) state 검증
        if result.state != state {
            throw NSError(domain: "AppleLogin", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid state"])
        }

        let body = AppleLoginRequest(
            code: result.authorizationCode,
            nonce: nonce
        )

        let response: String = try await self.request("auth/login/apple", method: "POST", body: body)
        return response
    }
}
