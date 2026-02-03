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

    struct State: Equatable {
        var searchText: String?
        var themes: [Theme] = []
        var nextPage: Int = 0
        var totalPage: Int = 0
        var isLoading: Bool = false
        var selectedThemeDetail: ThemeDetail? = nil
        var sortOption: SortOption = .distance
    }
    
    enum Action {
        case fetchThemesResponse(Result<ThemeResponse, Error>)
        case fetchThemeDetailResponse(Result<ThemeDetail, Error>)
        case onSearchBarEntered(String, sortOption:SortOption)
        case onSortOptionSelected(SortOption)
        case onLoadNextPage(sortOption:SortOption)
        case themeTapped(themeId:Int)
        case dismissDetail
//        case fetchThemeResponse(Result<Theme, Error>)
    }
    
    @Dependency(\.themeAPIClient) var themeApiClient
    
    func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case let .onSearchBarEntered(keyword, sortOption):
            state.isLoading = true
            return .run { send in
                do {
                    let coordinate = sortOption == .distance
                                    ? try await locationManager.getLocation()
                                    : nil
                    let latitude = coordinate?.latitude;
                    let longitude = coordinate?.longitude;
                    let themeResponse = try await themeApiClient.fetchThemes(
                        ThemeRequest(keyword:keyword,
                                     sort:sortOption,
                                     latitude: latitude,
                                     longitude:longitude
                                    )
                    )
                    await send(.fetchThemesResponse(.success(themeResponse)))
                } catch {
                    await send(.fetchThemesResponse(.failure(error)))
                }
            }
        case let .onSortOptionSelected(sortOption):
            state.isLoading = true
            state.nextPage = 0
            state.sortOption = sortOption // 정렬 옵션 상태 업데이트
            return .run { send in
                do {
                    let coordinate = sortOption == .distance
                                    ? try await locationManager.getLocation()
                                    : nil
                    let latitude = coordinate?.latitude;
                    let longitude = coordinate?.longitude;
                    let themeResponse = try await themeApiClient.fetchThemes(
                        ThemeRequest(sort:sortOption,
                                     latitude: latitude,
                                     longitude:longitude
                                    )
                    )
                    await send(.fetchThemesResponse(.success(themeResponse)))
                } catch {
                    await send(.fetchThemesResponse(.failure(error)))
                }
            }
        case let .onLoadNextPage(sortOption: sortOption):
            let nextPage = state.nextPage
            if (nextPage == state.totalPage) {
                return .none
            }
            return .run { send in
                do {
                    let themeResponse = try await themeApiClient.fetchThemes(ThemeRequest(sort:sortOption, page: nextPage))
                    await send(.fetchThemesResponse(.success(themeResponse)))
                } catch {
                    await send(.fetchThemesResponse(.failure(error)))
                }
            }
        case let .themeTapped(themeId):
            return .run { send in
                do {
                    let themeDetailResponse = try await themeApiClient.fetchThemeById("\(themeId)")
                    await send(.fetchThemeDetailResponse(.success(themeDetailResponse)))
                } catch {
                    await send(.fetchThemesResponse(.failure(error)))
                }
            }
        case .dismissDetail:
            state.selectedThemeDetail = nil
            return .none
        case let .fetchThemesResponse(.success(themeResponse)):
            state.isLoading = false
            state.nextPage = themeResponse.nextPage
            state.totalPage = themeResponse.totalPage
            
            if (state.nextPage == 2) {
                state.themes = themeResponse.themes
            } else {
                state.themes += themeResponse.themes
            }
            return .none
        case let .fetchThemesResponse(.failure(error)):
            state.isLoading = false
#if DEBUG
            print("Error: \(error)")
#endif
            return .none
        case let .fetchThemeDetailResponse(.success(themeResponse)):
            state.selectedThemeDetail = themeResponse
            state.isLoading = false
            return .none
        case .fetchThemeDetailResponse(.failure(_)):
            return .none
        }
    }
}
