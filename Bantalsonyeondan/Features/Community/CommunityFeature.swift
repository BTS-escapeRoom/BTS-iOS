import ComposableArchitecture
import Foundation

// MARK: - State
struct CommunityFeature: Reducer {
    private enum CancelID { case search }

    struct State: Equatable {
        var searchText: String = ""
        var boards: [Board] = []
        var nextPage: Int = 1
        var totalPage: Int = 0
        var isLoading: Bool = false
        var sortOption: SortOption = .latest
        var showWriteView: Bool = false
        var isOnlyRecruiting: Bool = true
        var errorMessage: String? = nil
    }

    enum Action {
        case onAppear
        case fetchBoardsResponse(Result<BoardResponse, Error>, requestedPage: Int)
        case onSearchBarEntered(String)
        case onSortOptionSelected(SortOption)
        case onLoadNextPage
        case setOnlyRecruiting(Bool)
        case showWriteView(Bool)
        case clearErrorMessage
    }

    @Dependency(\.boardAPIClient) var boardApiClient

    func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .onAppear:
            state.boards = []
            state.nextPage = 1
            return .send(.onSearchBarEntered(state.searchText))

        case let .onSearchBarEntered(keyword):
            state.searchText = keyword
            state.isLoading = true
            state.errorMessage = nil
            let currentKeyword = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
            let currentSortOption = state.sortOption
            let requestedPage = 1
            let typeFilter = state.isOnlyRecruiting ? "recruit" : nil
            return .run { send in
                do {
                    try await Task.sleep(for: .milliseconds(300))
                    let boardRequest = BoardRequest(
                        keyword: currentKeyword.isEmpty ? nil : currentKeyword,
                        type: typeFilter,
                        sortType: currentSortOption,
                        page: requestedPage
                    )
                    let boardResponse = try await boardApiClient.getBoards(boardRequest)
                    await send(.fetchBoardsResponse(.success(boardResponse), requestedPage: requestedPage))
                } catch is CancellationError {
                    return
                } catch {
                    await send(.fetchBoardsResponse(.failure(error), requestedPage: requestedPage))
                }
            }
            .cancellable(id: CancelID.search, cancelInFlight: true)

        case let .fetchBoardsResponse(result, requestedPage):
            state.isLoading = false
            switch result {
            case let .success(boardResponse):
                let filtered: [Board] = state.isOnlyRecruiting
                    ? boardResponse.boards.filter { board in
                        guard let deadline = board.recruitDeadline,
                              let date = ISO8601DateFormatter.iso8601WithOptionalFraction.date(from: deadline)
                                ?? ISO8601DateFormatter().date(from: deadline)
                        else { return true } // 마감일 없으면 모집중으로 간주
                        return date.timeIntervalSinceNow > 0
                    }
                    : boardResponse.boards
                if requestedPage <= 1 {
                    state.boards = filtered
                } else {
                    state.boards += filtered
                }
                state.nextPage = boardResponse.nextPage
                state.totalPage = boardResponse.totalPage
                state.errorMessage = nil
            case .failure(let error):
                state.errorMessage = error.localizedDescription
            }
            return .none

        case let .onSortOptionSelected(option):
            state.sortOption = option
            return .send(.onSearchBarEntered(state.searchText))

        case .onLoadNextPage:
            guard state.nextPage > 0, state.isLoading == false else { return .none }
            state.isLoading = true
            let currentKeyword = state.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            let currentSortOption = state.sortOption
            let currentPage = state.nextPage
            let typeFilter = state.isOnlyRecruiting ? "recruit" : nil
            return .run { send in
                do {
                    let boardResponse = try await boardApiClient.getBoards(
                        BoardRequest(keyword: currentKeyword.isEmpty ? nil : currentKeyword, type: typeFilter, sortType: currentSortOption, page: currentPage)
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
            return .send(.onSearchBarEntered(state.searchText))

        case let .showWriteView(show):
            state.showWriteView = show
            return .none

        case .clearErrorMessage:
            state.errorMessage = nil
            return .none
        }
    }
}
