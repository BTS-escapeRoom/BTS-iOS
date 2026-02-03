//
//  TestFeature.swift
//  Bantalsonyeondan
//
//  Created by 이상현 on 3/5/25.
//

import ComposableArchitecture
import SwiftUI

// MARK: - Reducer
struct TestFeature: Reducer {
    // MARK: - State
    struct State: Equatable {
        var results: [String] = []
    }

    // MARK: - Action
    enum Action {
        case runAllTests
        case testCompleted(String)
        case testFailed(String, Error)
    }
    
    @Dependency(\.reviewAPIClient) var reviewClient
    @Dependency(\.memberAPIClient) var memberClient
    @Dependency(\.commentAPIClient) var commentClient
    @Dependency(\.themeAPIClient) var themeClient
    @Dependency(\.boardAPIClient) var boardClient
//    @Dependency(\.storeAPIClient) var storeClient
//    @Dependency(\.homeAPIClient) var homeClient
//    @Dependency(\.genreAPIClient) var genreClient
//    @Dependency(\.cityAPIClient) var cityClient
    
    func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .runAllTests:
            return .run { send in
                do {
//                    // ✅ 리뷰 API
//                    let createdReview = try await reviewClient.createReviews(ReviewRegist(content: "string", people: 0, time: 0, scareScore: 0, activityScore: 0, difficulty: 0, hints: 0, visitDate: "2025-03-12T12:26:14.840Z", isSuccess: true, themeId: 0))
//                    await send(.testCompleted("✅ 리뷰 생성: \(createdReview)"))
                    
//                    let myReviews = try await reviewClient.getMyReviews()
//                    await send(.testCompleted("✅ 내가 쓴 리뷰 조회: \(myReviews)"))
//                    
//                    let review = try await reviewClient.getReview("\(myReviews[0].id)")
//                    await send(.testCompleted("✅ 리뷰 조회: \(review)"))
////                
//                    let updatedReview = try await reviewClient.updateReview("\(myReviews[0].id)", review: review)
//                    await send(.testCompleted("✅ 리뷰 수정: \(updatedReview)"))
////                    
//                    let deletedReview = try await reviewClient.deleteReview("\(myReviews[0].id)")
//                    await send(.testCompleted("✅ 리뷰 삭제: \(deletedReview)"))
//                
//                    
//                    let reviewList = try await reviewClient.getReviews("0")
//                    await send(.testCompleted("✅ 리뷰 목록 조회: \(reviewList)"))
//                    

//                    
//                     ✅ 회원 API
//                    let myInfo = try await memberClient.getMyMembers()
//                    await send(.testCompleted("✅ 내 회원 정보 조회: \(myInfo)"))
//                    
//                    let newMyInfo = try await memberClient.updateMembers(MemberUpdateRequest(profileImg: "string", nickname: "string", description: "string"))
//                    await send(.testCompleted("✅ 내 회원 정보 조회: \(newMyInfo)"))
//
//                    // ✅ 댓글 API
//                    let comment = try await commentClient.getComments(commentId: "1")
//                    await send(.testCompleted("✅ 댓글 조회: \(comment)"))
//                    
//                    let updatedComment = try await commentClient.updateComments(commentId: "1", "수정된 댓글")
//                    await send(.testCompleted("✅ 댓글 수정: \(updatedComment)"))
//                    
//                    let deletedComment = try await commentClient.deleteComments(commentId: "1")
//                    await send(.testCompleted("✅ 댓글 삭제: \(deletedComment)"))
                    
//                    let boardComments = try await commentClient.getComments(boardId: "1")
//                    await send(.testCompleted("✅ 게시글 댓글 조회: \(boardComments)"))
                    
//                    let newComment = try await commentClient.createComments(boardId: "1", "새 댓글")
//                    await send(.testCompleted("✅ 게시글 댓글 작성: \(newComment)"))
//                    
//                    // ✅ 테마 API
//                    let themes = try await themeClient.fetchThemes()
//                    await send(.testCompleted("✅ 테마 리스트 조회: \(themes)"))
//
//                    let likedThemes = try await themeClient.fetchLikedThemes()
//                    await send(.testCompleted("✅ 찜한 테마 조회: \(likedThemes)"))
                    
//                    let popularThemes = try await themeClient.fetchThemesPopular()
//                    await send(.testCompleted("✅ 인기 테마 조회: \(popularThemes)"))
//                    
//                    let randomThemes = try await themeClient.fetchThemesRandom()
//                    await send(.testCompleted("✅ 랜덤 테마 조회: \(randomThemes)"))
//                    
//                    let themeDetail = try await themeClient.fetchThemeById("test-theme-id")
//                    await send(.testCompleted("✅ 테마 단건 조회: \(themeDetail)"))
//                    
//                    let realTimePopularThemes = try await themeClient.fetchThemesPopularRealtime()
//                    await send(.testCompleted("✅ 실시간 인기 테마 조회: \(realTimePopularThemes)"))
//                    
//                     ✅ 게시판 API
//                    let boards = try await boardClient.getBoards("iOS", "discussion")
//                    await send(.testCompleted("✅ 게시판 조회: \(boards)"))
//                    
//                    let newBoard = try await boardClient.createBoards(BoardCreateRequest(themeId: "1", type: "", title: "", description: ""))
//                    await send(.testCompleted("✅ 게시글 생성: \(newBoard)"))
//                    
//                    let likeBoard = try await boardClient.toggleLikedBoards("\(newBoard.id)")
//                    await send(.testCompleted("✅ 게시글 찜/찜 취소: \(likeBoard)"))
////                    let likeBoard = try await boardClient.toggleLikedBoards("42")
////                    await send(.testCompleted("✅ 게시글 찜/찜 취소: \(likeBoard)"))
//                    
//                    let likedBoards = try await boardClient.getLikedBoards()
//                    await send(.testCompleted("✅ 찜한 게시글 조회: \(likedBoards)"))
//                    
//                    let boardDetail = try await boardClient.getBoard("\(newBoard.id)")
//                    await send(.testCompleted("✅ 게시글 조회: \(boardDetail)"))
//                    
//                    let updatedBoard = try await boardClient.updateBoard("\(newBoard.id)", "수정된 제목", description: "수정된 내용")
//                    await send(.testCompleted("✅ 게시글 수정: \(updatedBoard)"))
//                    
//                    let deletedBoard = try await boardClient.deleteBoard("\(newBoard.id)")
//                    await send(.testCompleted("✅ 게시글 삭제: \(deletedBoard)"))
//                    let deletedBoard = try await boardClient.deleteBoard("42")
//                    await send(.testCompleted("✅ 게시글 삭제: \(deletedBoard)"))
                    
                    
                    
//                    // ✅ 매장 API
//                    let stores = try await storeClient.getStores()
//                    await send(.testCompleted("✅ 매장 목록 조회: \(stores)"))
//                    
//                    let storeDetail = try await storeClient.getStores("test-store-id")
//                    await send(.testCompleted("✅ 매장 단건 조회: \(storeDetail)"))
//                    
//                    // ✅ 홈 API
//                    let homeData = try await homeClient.getHome()
//                    await send(.testCompleted("✅ 홈 데이터 조회: \(homeData)"))
//                    
//                    // ✅ 장르 API
//                    let genres = try await genreClient.getGenres()
//                    await send(.testCompleted("✅ 장르 목록 조회: \(genres)"))
//                    
//                    // ✅ 지역 API
//                    let cities = try await cityClient.getCities()
//                    await send(.testCompleted("✅ 지역 목록 조회: \(cities)"))
//                    
//                    let cityDetail = try await cityClient.getCity("test-city-id")
//                    await send(.testCompleted("✅ 지역 단건 조회: \(cityDetail)"))
                    
                    await send(.testCompleted("🎉 모든 API 테스트 완료!"))
                    
                } catch {
                    await send(.testFailed("❌ API 테스트 중 오류 발생", error))
                }
            }
            
        case let .testCompleted(result):
            state.results.append(result)
            return .none
            
        case let .testFailed(message, error):
            state.results.append("\(message): \(error.localizedDescription)")
            return .none
        }
    }
}
