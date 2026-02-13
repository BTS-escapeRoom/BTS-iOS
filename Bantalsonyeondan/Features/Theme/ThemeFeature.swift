//
//  ThemeFeature.swift
//  Bantalsonyeondan
//
//  Created by 이상현 on 1/15/25.
//

import ComposableArchitecture
import Foundation

struct ThemeFeature: Reducer {
    private var locationManager = LocationManager()
    private enum CancelID { case search }

    struct State: Equatable {
        var searchText: String = ""
        var themes: [Theme] = []
        var nextPage: Int = 0
        var totalPage: Int = 0
        var isLoading: Bool = false
        var selectedThemeDetail: ThemeDetail? = nil
        var sortOption: SortOption = .distance
        var errorMessage: String? = nil
    }
    
    enum Action {
        case fetchThemesResponse(Result<ThemeResponse, Error>, requestedPage: Int)
        case fetchThemeDetailResponse(Result<ThemeDetail, Error>)
        case onSearchBarEntered(String)
        case onSortOptionSelected(SortOption)
        case onLoadNextPage
        case themeTapped(themeId: Int)
        case dismissDetail
        case clearErrorMessage
    }
    
    @Dependency(\.themeAPIClient) var themeApiClient
    
    func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case let .onSearchBarEntered(keyword):
            state.searchText = keyword
            state.nextPage = 0
            state.isLoading = true
            state.errorMessage = nil
            let requestedPage = 1
            let currentSortOption = state.sortOption
            let currentKeyword = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
            return .run { send in
                do {
                    try await Task.sleep(for: .milliseconds(300))
                    let coordinate = currentSortOption == .distance
                                    ? try await locationManager.getLocation()
                                    : nil
                    let latitude = coordinate?.latitude
                    let longitude = coordinate?.longitude
                    let themeResponse = try await themeApiClient.fetchThemes(
                        ThemeRequest(keyword: currentKeyword.isEmpty ? nil : currentKeyword,
                                     sort: currentSortOption,
                                     latitude: latitude,
                                     longitude: longitude,
                                     page: requestedPage
                                    )
                    )
                    await send(.fetchThemesResponse(.success(themeResponse), requestedPage: requestedPage))
                } catch is CancellationError {
                    return
                } catch {
                    await send(.fetchThemesResponse(.failure(error), requestedPage: requestedPage))
                }
            }
            .cancellable(id: CancelID.search, cancelInFlight: true)

        case let .onSortOptionSelected(sortOption):
            state.sortOption = sortOption
            return .send(.onSearchBarEntered(state.searchText))

        case .onLoadNextPage:
            guard state.isLoading == false else { return .none }
            let requestedPage = state.nextPage
            guard requestedPage > 1 else { return .none }
            guard state.totalPage == 0 || requestedPage <= state.totalPage else {
                return .none
            }
            state.isLoading = true
            let currentSortOption = state.sortOption
            let currentKeyword = state.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            return .run { send in
                do {
                    let coordinate = currentSortOption == .distance
                                    ? try await locationManager.getLocation()
                                    : nil
                    let latitude = coordinate?.latitude
                    let longitude = coordinate?.longitude
                    let themeResponse = try await themeApiClient.fetchThemes(
                        ThemeRequest(keyword: currentKeyword.isEmpty ? nil : currentKeyword,
                                     sort: currentSortOption,
                                     latitude: latitude,
                                     longitude: longitude,
                                     page: requestedPage)
                    )
                    await send(.fetchThemesResponse(.success(themeResponse), requestedPage: requestedPage))
                } catch {
                    await send(.fetchThemesResponse(.failure(error), requestedPage: requestedPage))
                }
            }

        case let .themeTapped(themeId):
            return .run { send in
                do {
                    let themeDetailResponse = try await themeApiClient.fetchThemeById("\(themeId)")
                    await send(.fetchThemeDetailResponse(.success(themeDetailResponse)))
                } catch {
                    await send(.fetchThemeDetailResponse(.failure(error)))
                }
            }

        case .dismissDetail:
            state.selectedThemeDetail = nil
            return .none

        case let .fetchThemesResponse(.success(themeResponse), requestedPage):
            state.isLoading = false
            state.errorMessage = nil
            state.nextPage = themeResponse.nextPage
            state.totalPage = themeResponse.totalPage

            if requestedPage <= 1 {
                state.themes = themeResponse.themes
            } else {
                state.themes += themeResponse.themes
            }
            return .none

        case let .fetchThemesResponse(.failure(error), _):
            state.isLoading = false
            state.errorMessage = error.localizedDescription
            return .none

        case let .fetchThemeDetailResponse(.success(themeResponse)):
            state.selectedThemeDetail = themeResponse
            state.isLoading = false
            return .none

        case let .fetchThemeDetailResponse(.failure(error)):
            state.errorMessage = error.localizedDescription
            return .none

        case .clearErrorMessage:
            state.errorMessage = nil
            return .none
        }
    }
}
