import ComposableArchitecture
import SwiftUI

struct ThemeDetailRouteFeature: Reducer {
    struct State: Equatable {
        let themeId: Int
        var themeDetail: ThemeDetail? = nil
        var isLoading: Bool = false
        var errorMessage: String? = nil
    }

    enum Action {
        case onAppear
        case fetchThemeDetailResponse(Result<ThemeDetail, Error>)
        case retryTapped
    }

    @Dependency(\.themeAPIClient) var themeAPIClient

    func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .onAppear, .retryTapped:
            guard state.isLoading == false else { return .none }
            state.isLoading = true
            state.errorMessage = nil
            let themeId = state.themeId

            return .run { send in
                do {
                    let detail = try await themeAPIClient.fetchThemeById(String(themeId))
                    await send(.fetchThemeDetailResponse(.success(detail)))
                } catch {
                    await send(.fetchThemeDetailResponse(.failure(error)))
                }
            }

        case let .fetchThemeDetailResponse(.success(detail)):
            state.themeDetail = detail
            state.isLoading = false
            state.errorMessage = nil
            return .none

        case let .fetchThemeDetailResponse(.failure(error)):
            state.themeDetail = nil
            state.isLoading = false
            state.errorMessage = error.localizedDescription
            return .none
        }
    }
}

struct ThemeDetailRouteView: View {
    let store: StoreOf<ThemeDetailRouteFeature>

    var body: some View {
        WithViewStore(store, observe: \.self) { viewStore in
            Group {
                if let detail = viewStore.themeDetail {
                    ThemeDetailView(themeInfo: detail, onDismiss: {})
                } else if let errorMessage = viewStore.errorMessage {
                    VStack(spacing: 12) {
                        Text("테마 정보를 불러오지 못했습니다.")
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.gray)
                        Button("다시 시도") {
                            viewStore.send(.retryTapped)
                        }
                    }
                    .padding()
                } else {
                    VStack {
                        ProgressView()
                            .padding()
                        Text("불러오는 중...")
                            .font(.footnote)
                            .foregroundColor(.gray)
                    }
                }
            }
            .onAppear {
                viewStore.send(.onAppear)
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
