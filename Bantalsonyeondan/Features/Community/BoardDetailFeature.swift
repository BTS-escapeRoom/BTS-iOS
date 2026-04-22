import ComposableArchitecture
import Foundation

struct BoardDetailFeature: Reducer {
    struct State: Equatable {
        let boardId: Int
        var board: Board? // 목록에서 전달된 요약 정보(테마/매장/모집/탈출일자)
        var detail: BoardDetail? // 상세 API 응답(설명 등)
        var comments: [Comment] = []
        var commentsTotalCount: Int = 0
        var themeDetail: ThemeDetail? = nil
        var isLoadingDetail: Bool = false
        var isLoadingComments: Bool = false
        var isLoadingTheme: Bool = false
        var isTogglingLike: Bool = false
        var isLiked: Bool = false
        var likeCount: Int = 0
        var isUpdatingBoardAction: Bool = false
        var isMine: Bool = false
        var isRecruitClosed: Bool = false
        var shouldDismiss: Bool = false
        var didMutateBoard: Bool = false
        var toastMessage: String? = nil
        var errorMessage: String?
        var newCommentText: String = ""
    }
    
    enum Action {
        case onAppear
        case fetchBoardResponse(Result<BoardDetail, Error>)
        case fetchCommentsResponse(Result<BoardCommentsResponse, Error>)
        case fetchThemeResponse(Result<ThemeDetail, Error>)
        case setNewCommentText(String)
        case tapSendComment
        case createCommentResponse(Result<Comment, Error>)
        case tapToggleLike
        case toggleLikeResponse(
            Result<String, Error>,
            previousIsLiked: Bool,
            previousLikeCount: Int
        )
        case tapCloseRecruit
        case closeRecruitResponse(Result<String, Error>)
        case tapDeleteBoard
        case deleteBoardResponse(Result<String, Error>)
        case clearToastMessage
        case clearErrorMessage
        case clearDismissRequest
        case clearMutationFlag
        case refresh
    }
    
    @Dependency(\.boardAPIClient) var boardAPIClient
    @Dependency(\.commentAPIClient) var commentAPIClient
    @Dependency(\.themeAPIClient) var themeAPIClient
    
    func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .onAppear:
            state.isLoadingDetail = true
            state.isLoadingComments = true
            state.shouldDismiss = false
            state.didMutateBoard = false
            state.isMine = isMineBoard(memberId: state.board?.memberId)
            state.isRecruitClosed = isClosedRecruit(deadline: state.board?.recruitDeadline)
            state.isLiked = state.board?.isLike ?? false
            state.likeCount = state.board?.likeCount ?? 0
            let boardIdStr = String(state.boardId)
            var effects: [Effect<Action>] = []
            effects.append(
                .run { send in
                    do {
                        let detail = try await boardAPIClient.getBoard(boardIdStr)
                        await send(.fetchBoardResponse(.success(detail)))
                    } catch {
                        await send(.fetchBoardResponse(.failure(error)))
                    }
                }
            )
            effects.append(
                .run { send in
                    do {
                        let response = try await commentAPIClient.getComments(boardId: boardIdStr)
                        await send(.fetchCommentsResponse(.success(response)))
                    } catch {
                        await send(.fetchCommentsResponse(.failure(error)))
                    }
                }
            )
            return .merge(effects)
            
        case let .fetchBoardResponse(result):
            state.isLoadingDetail = false
            switch result {
            case let .success(detail):
                state.detail = detail
                state.isMine = isMineBoard(memberId: detail.memberId)
                state.isRecruitClosed = isClosedRecruit(deadline: detail.recruit_deadline)
                state.isLiked = detail.isLike ?? state.isLiked
                state.likeCount = detail.likeCount
                state.errorMessage = nil
                if let themeId = detail.theme?.id {
                    state.isLoadingTheme = true
                    return .run { send in
                        do {
                            let theme = try await themeAPIClient.fetchThemeById("\(themeId)")
                            await send(.fetchThemeResponse(.success(theme)))
                        } catch {
                            await send(.fetchThemeResponse(.failure(error)))
                        }
                    }
                }
                return .none
            case let .failure(error):
                state.errorMessage = error.localizedDescription
                print(error.localizedDescription)
            }
            return .none
            
        case let .fetchCommentsResponse(result):
            state.isLoadingComments = false
            switch result {
            case let .success(resp):
                state.comments = resp.comments
                state.commentsTotalCount = resp.totalCount
                state.errorMessage = nil
            case let .failure(error):
                state.errorMessage = error.localizedDescription
            }
            return .none
            
        case let .fetchThemeResponse(result):
            state.isLoadingTheme = false
            switch result {
            case let .success(detail):
                state.themeDetail = detail
            case let .failure(error):
                state.errorMessage = error.localizedDescription
            }
            return .none
            
        case let .setNewCommentText(text):
            state.newCommentText = text
            return .none
            
        case .tapSendComment:
            guard state.newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false else { return .none }
            let text = state.newCommentText
            state.newCommentText = ""
            let boardIdStr = String(state.boardId)
            return .run { send in
                do {
                    let created = try await commentAPIClient.createComments(boardId: boardIdStr, text)
                    await send(.createCommentResponse(.success(created)))
                } catch {
                    await send(.createCommentResponse(.failure(error)))
                }
            }
            
        case let .createCommentResponse(result):
            switch result {
            case let .success(comment):
                state.comments.append(comment)
                state.commentsTotalCount += 1
            case let .failure(error):
                state.errorMessage = error.localizedDescription
            }
            return .none

        case .tapToggleLike:
            guard !state.isTogglingLike else { return .none }
            state.isTogglingLike = true
            let previousIsLiked = state.isLiked
            let previousLikeCount = state.likeCount
            state.isLiked.toggle()
            state.likeCount = max(0, state.likeCount + (state.isLiked ? 1 : -1))

            let boardIdStr = String(state.boardId)
            return .run { send in
                do {
                    let result = try await boardAPIClient.toggleLikedBoards(boardIdStr)
                    await send(
                        .toggleLikeResponse(
                            .success(result),
                            previousIsLiked: previousIsLiked,
                            previousLikeCount: previousLikeCount
                        )
                    )
                } catch {
                    await send(
                        .toggleLikeResponse(
                            .failure(error),
                            previousIsLiked: previousIsLiked,
                            previousLikeCount: previousLikeCount
                        )
                    )
                }
            }

        case let .toggleLikeResponse(result, previousIsLiked, previousLikeCount):
            state.isTogglingLike = false
            switch result {
            case .success:
                break
            case let .failure(error):
                state.isLiked = previousIsLiked
                state.likeCount = previousLikeCount
                state.errorMessage = error.localizedDescription
            }
            return .none

        case .tapCloseRecruit:
            guard state.isMine else { return .none }
            guard !state.isUpdatingBoardAction else { return .none }
            guard !state.isRecruitClosed else {
                state.errorMessage = "이미 마감된 모집글이에요."
                return .none
            }
            state.isUpdatingBoardAction = true
            let boardIdStr = String(state.boardId)
            return .run { send in
                do {
                    let result = try await boardAPIClient.closeRecruit(boardIdStr)
                    await send(.closeRecruitResponse(.success(result)))
                } catch {
                    await send(.closeRecruitResponse(.failure(error)))
                }
            }

        case let .closeRecruitResponse(result):
            state.isUpdatingBoardAction = false
            switch result {
            case .success:
                state.isRecruitClosed = true
                state.toastMessage = "모집을 마감했어요."
                state.didMutateBoard = true
            case let .failure(error):
                state.errorMessage = error.localizedDescription
            }
            return .none

        case .tapDeleteBoard:
            guard state.isMine else { return .none }
            guard !state.isUpdatingBoardAction else { return .none }
            state.isUpdatingBoardAction = true
            let boardIdStr = String(state.boardId)
            return .run { send in
                do {
                    let result = try await boardAPIClient.deleteBoard(boardIdStr)
                    await send(.deleteBoardResponse(.success(result)))
                } catch {
                    await send(.deleteBoardResponse(.failure(error)))
                }
            }

        case let .deleteBoardResponse(result):
            state.isUpdatingBoardAction = false
            switch result {
            case .success:
                state.toastMessage = "게시글을 삭제했어요."
                state.didMutateBoard = true
                state.shouldDismiss = true
            case let .failure(error):
                state.errorMessage = error.localizedDescription
            }
            return .none

        case .clearToastMessage:
            state.toastMessage = nil
            return .none

        case .clearErrorMessage:
            state.errorMessage = nil
            return .none

        case .clearDismissRequest:
            state.shouldDismiss = false
            return .none

        case .clearMutationFlag:
            state.didMutateBoard = false
            return .none
            
        case .refresh:
            state.detail = nil
            state.comments = []
            state.commentsTotalCount = 0
            state.themeDetail = nil
            state.errorMessage = nil
            state.toastMessage = nil
            state.isRecruitClosed = false
            state.isTogglingLike = false
            return .send(.onAppear)
        }
    }

    private func isMineBoard(memberId: Int?) -> Bool {
        guard let memberId,
              let currentMemberId = AuthSessionStore.currentSession?.memberId else {
            return false
        }
        return memberId == currentMemberId
    }

    private func isClosedRecruit(deadline: String?) -> Bool {
        guard let deadline,
              let date = ISO8601DateFormatter.iso8601WithOptionalFraction.date(from: deadline)
                ?? ISO8601DateFormatter().date(from: deadline) else {
            return false
        }
        return date <= Date()
    }
}
