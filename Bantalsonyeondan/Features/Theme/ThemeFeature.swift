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
    private let distanceCoordinateCacheAge: TimeInterval = 60 * 60 * 24
    private struct ResolvedCoordinate {
        let latitude: Double?
        let longitude: Double?
        let shouldCache: Bool
    }

    struct State: Equatable {
        var searchText: String = ""
        var themes: [Theme] = []
        var nextPage: Int = 0
        var totalPage: Int = 0
        var isLoading: Bool = false
        var selectedThemeDetail: ThemeDetail? = nil
        var sortOption: SortOption = .distance
        var cachedLatitude: Double? = nil
        var cachedLongitude: Double? = nil
        var errorMessage: String? = nil
    }
    
    enum Action {
        case fetchThemesResponse(Result<ThemeResponse, Error>, requestedPage: Int)
        case fetchThemeDetailResponse(Result<ThemeDetail, Error>)
        case reloadThemes(String)
        case onSortOptionSelected(SortOption)
        case onLoadNextPage
        case themeTapped(themeId: Int)
        case cacheDistanceCoordinate(latitude: Double, longitude: Double)
        case dismissDetail
        case clearErrorMessage
    }
    
    @Dependency(\.themeAPIClient) var themeApiClient
    
    func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case let .reloadThemes(keyword):
            state.searchText = keyword
            state.nextPage = 0
            state.isLoading = true
            state.errorMessage = nil
            let requestedPage = 1
            let currentSortOption = state.sortOption
            let currentKeyword = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
            if currentSortOption == .distance,
               (state.cachedLatitude == nil || state.cachedLongitude == nil),
               let cachedCoordinate = locationManager.cachedCoordinate(maxAge: distanceCoordinateCacheAge) {
                state.cachedLatitude = cachedCoordinate.latitude
                state.cachedLongitude = cachedCoordinate.longitude
            }
            let cachedLatitude = state.cachedLatitude
            let cachedLongitude = state.cachedLongitude
            return .run { send in
                do {
                    try await Task.sleep(for: .milliseconds(300))
                    let coordinate = await resolveCoordinate(
                        for: currentSortOption,
                        cachedLatitude: cachedLatitude,
                        cachedLongitude: cachedLongitude
                    )
                    if coordinate.shouldCache,
                       let latitude = coordinate.latitude,
                       let longitude = coordinate.longitude {
                        await send(
                            .cacheDistanceCoordinate(
                                latitude: latitude,
                                longitude: longitude
                            )
                        )
                    }

                    let themeResponse = try await themeApiClient.fetchThemes(
                        ThemeRequest(keyword: currentKeyword.isEmpty ? nil : currentKeyword,
                                     sort: currentSortOption,
                                     latitude: coordinate.latitude,
                                     longitude: coordinate.longitude,
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
            return .send(.reloadThemes(state.searchText))

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
            let cachedLatitude = state.cachedLatitude
            let cachedLongitude = state.cachedLongitude
            return .run { send in
                do {
                    let coordinate = await resolveCoordinate(
                        for: currentSortOption,
                        cachedLatitude: cachedLatitude,
                        cachedLongitude: cachedLongitude
                    )
                    if coordinate.shouldCache,
                       let latitude = coordinate.latitude,
                       let longitude = coordinate.longitude {
                        await send(
                            .cacheDistanceCoordinate(
                                latitude: latitude,
                                longitude: longitude
                            )
                        )
                    }

                    let themeResponse = try await themeApiClient.fetchThemes(
                        ThemeRequest(keyword: currentKeyword.isEmpty ? nil : currentKeyword,
                                     sort: currentSortOption,
                                     latitude: coordinate.latitude,
                                     longitude: coordinate.longitude,
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

        case let .cacheDistanceCoordinate(latitude, longitude):
            state.cachedLatitude = latitude
            state.cachedLongitude = longitude
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

    private func resolveCoordinate(
        for sortOption: SortOption,
        cachedLatitude: Double?,
        cachedLongitude: Double?
    ) async -> ResolvedCoordinate {
        guard sortOption == .distance else {
            return .init(latitude: nil, longitude: nil, shouldCache: false)
        }

        if let cachedLatitude, let cachedLongitude {
            return .init(
                latitude: cachedLatitude,
                longitude: cachedLongitude,
                shouldCache: false
            )
        }

        if let coordinate = try? await locationManager.getLocation(maxCacheAge: distanceCoordinateCacheAge) {
            return .init(
                latitude: coordinate.latitude,
                longitude: coordinate.longitude,
                shouldCache: true
            )
        }

        return .init(latitude: nil, longitude: nil, shouldCache: false)
    }
}
