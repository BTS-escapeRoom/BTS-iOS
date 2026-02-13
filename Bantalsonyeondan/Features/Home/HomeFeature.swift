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
        var errorMessage: String? = nil
    }
    
    enum Action {
        case onAppear
        case fetchThemesResponse(Result<[Theme], Error>)
        case clearErrorMessage
    }
    
    @Dependency(\.themeAPIClient) var themeApiClient
    
    func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .onAppear:
            state.isLoading = true
            state.errorMessage = nil
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
            state.errorMessage = nil
            return .none

        case let .fetchThemesResponse(.failure(error)):
            state.isLoading = false
            state.errorMessage = error.localizedDescription
            return .none

        case .clearErrorMessage:
            state.errorMessage = nil
            return .none
        }
    }
}
