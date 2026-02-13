//
//  AppFeature.swift
//  Bantalsonyeondan
//
//  Created by 이상현 on 4/9/25.
//

import ComposableArchitecture
import SwiftUI

enum Tab: Equatable {
    case theme
    case community
    case myPage
}

// MARK: - Reducer
struct AppFeature: Reducer {
    // MARK: - State
    struct State: Equatable {
        var selectedTab: Tab = .theme
        var theme = ThemeFeature.State()
        var community = CommunityFeature.State()
        var myPage = MyFeature.State()
    }
    
    // MARK: - Action
    @CasePathable
    enum Action {
        case selectTab(Tab)
        case theme(ThemeFeature.Action)
        case community(CommunityFeature.Action)
        case myPage(MyFeature.Action)
    }

    var body: some ReducerOf<Self> {
        Scope(state: \.theme, action: \.theme) { ThemeFeature() }
        Scope(state: \.community, action: \.community) { CommunityFeature() }
        Scope(state: \.myPage, action: \.myPage) { MyFeature() }

        Reduce { state, action in
            switch action {
            case let .selectTab(tab):
                state.selectedTab = tab
                return .none
            case .theme, .community, .myPage:
                return .none
            }
        }
    }
}
