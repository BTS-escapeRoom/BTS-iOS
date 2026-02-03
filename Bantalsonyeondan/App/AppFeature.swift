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
    }
    
    // MARK: - Action
    enum Action {
        case selectTab(Tab)
    }
    
    func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case let .selectTab(tab):
            state.selectedTab = tab
            return .none
        }
    }
}
