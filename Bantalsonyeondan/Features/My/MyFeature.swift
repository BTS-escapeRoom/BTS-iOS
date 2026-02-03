import ComposableArchitecture
import Foundation

// MARK: - State
struct MyFeature: Reducer {
    struct State: Equatable {
        var info: MyResponse? = nil
    }

    enum Action {
        case myResponse(Result<MyResponse, Error>)
    }

    @Dependency(\.boardAPIClient) var boardApiClient

    func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case let .myResponse(result):
            switch result {
            case let .success(response):
                state.info = response
            case .failure:
                state.info = nil
            }
            return .none
        }
    }
}
