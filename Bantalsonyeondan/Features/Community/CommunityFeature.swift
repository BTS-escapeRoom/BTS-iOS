import ComposableArchitecture
import Foundation

// MARK: - State
struct CommunityFeature: Reducer {
    struct State: Equatable {
        var searchText: String = ""
        var boards: [Board] = []
        var nextPage: Int = 1
        var totalPage: Int = 0
        var isLoading: Bool = false
        var sortOption: SortOption = .latest
        var showWriteView: Bool = false
        var isOnlyRecruiting: Bool = true
    }

    enum Action {
        case fetchBoardsResponse(Result<BoardResponse, Error>, requestedPage: Int)
        case onSearchBarEntered(String, sortOption: SortOption)
        case onSortOptionSelected(SortOption)
        case onLoadNextPage(sortOption: SortOption)
        case setOnlyRecruiting(Bool)
        case showWriteView(Bool)
    }

    @Dependency(\.boardAPIClient) var boardApiClient

    func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case let .onSearchBarEntered(keyword, sortOption):
            state.isLoading = true
            let currentKeyword = keyword.isEmpty ? nil : keyword
            let currentSortOption = sortOption
            let requestedPage = 1
            let typeFilter = state.isOnlyRecruiting ? "recruit" : nil
            return .run { send in
                do {
                    let boardRequest = BoardRequest(
                        keyword: currentKeyword,
                        type: typeFilter,
                        sortType: currentSortOption,
                        page: requestedPage
                    )
                    let boardResponse = try await boardApiClient.getBoards(boardRequest)
                    await send(.fetchBoardsResponse(.success(boardResponse), requestedPage: requestedPage))
                } catch {
                    await send(.fetchBoardsResponse(.failure(error), requestedPage: requestedPage))
                }
            }

        case let .fetchBoardsResponse(result, requestedPage):
            state.isLoading = false
            switch result {
            case let .success(boardResponse):
                if requestedPage <= 1 {
                    state.boards = boardResponse.boards
                } else {
                    state.boards += boardResponse.boards
                }
                state.nextPage = boardResponse.nextPage
                state.totalPage = boardResponse.totalPage
            case .failure(let error):
                print(error)
                break
            }
            return .none

        case let .onSortOptionSelected(option):
            state.sortOption = option
            return .send(.onSearchBarEntered(state.searchText, sortOption: option))

        case let .onLoadNextPage(sortOption):
            guard state.nextPage > 0, state.isLoading == false else { return .none }
            state.isLoading = true
            let currentKeyword = state.searchText.isEmpty ? nil : state.searchText
            let currentSortOption = sortOption
            let currentPage = state.nextPage
            let typeFilter = state.isOnlyRecruiting ? "recruit" : nil
            return .run { send in
                do {
                    let boardResponse = try await boardApiClient.getBoards(
                        BoardRequest(keyword: currentKeyword, type: typeFilter, sortType: currentSortOption, page: currentPage)
                    )
                    await send(.fetchBoardsResponse(.success(boardResponse), requestedPage: currentPage))
                } catch {
                    await send(.fetchBoardsResponse(.failure(error), requestedPage: currentPage))
                }
            }

        case let .setOnlyRecruiting(on):
            state.isOnlyRecruiting = on
            // Reset and reload from page 1 with current filters
            state.nextPage = 1
            state.boards = []
            return .send(.onSearchBarEntered(state.searchText, sortOption: state.sortOption))

        case let .showWriteView(show):
            state.showWriteView = show
            return .none
        }
    }
}
