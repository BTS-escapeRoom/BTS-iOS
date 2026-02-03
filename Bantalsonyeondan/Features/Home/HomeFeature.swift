//
//  HomeFeature.swift
//  Bantalsonyeondan
//
//  Created by 이상현 on 1/15/25.
//

import ComposableArchitecture
import Foundation

struct HomeFeature: Reducer {
    struct State: Equatable {
        var themes: [Theme] = []
        var isLoading: Bool = false
    }
    
    enum Action {
        case onAppear
        case fetchThemesResponse(Result<[Theme], Error>)
//        case fetchThemeResponse(Result<Theme, Error>)
    }
    
    @Dependency(\.themeAPIClient) var themeApiClient
    
    func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .onAppear:
            state.isLoading = true
            return .run { send in
                do {
                    let themes = try await themeApiClient.fetchThemesRecent()
                    await send(.fetchThemesResponse(.success(themes)))
                } catch {
                    await send(.fetchThemesResponse(.failure(error)))
                }
            }
        case let .fetchThemesResponse(.success(themes)):
            state.isLoading = false
            state.themes = themes
            return .none
        case let .fetchThemesResponse(.failure(error)):
            state.isLoading = false
#if DEBUG
            print("Error: \(error)")
#endif
            return .none
        }
    }
}
