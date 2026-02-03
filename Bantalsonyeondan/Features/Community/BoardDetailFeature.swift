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
                state.errorMessage = nil
                let themeId = detail.theme.id
                state.isLoadingTheme = true
                return .run { send in
                    do {
                        let theme = try await themeAPIClient.fetchThemeById("\(themeId)")
                        await send(.fetchThemeResponse(.success(theme)))
                    } catch {
                        await send(.fetchThemeResponse(.failure(error)))
                    }
                }
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
            
        case .refresh:
            state.detail = nil
            state.comments = []
            state.commentsTotalCount = 0
            state.themeDetail = nil
            state.errorMessage = nil
            return .send(.onAppear)
        }
    }
}
