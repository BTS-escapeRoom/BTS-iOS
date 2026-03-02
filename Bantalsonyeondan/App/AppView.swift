//
//  AppView.swift
//  Bantalsonyeondan
//
//  Created by 이상현 on 4/9/25.
//

import SwiftUI
import ComposableArchitecture

struct AppView: View {
    let store: StoreOf<AppFeature>
        
    init(store: StoreOf<AppFeature>) {
        self.store = store
    }
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            Group {
                if viewStore.isAuthenticated {
                    if viewStore.shouldShowNicknameSetup {
                        NicknameSetupView(
                            store: store.scope(
                                state: \.nicknameSetup,
                                action: \.nicknameSetup
                            )
                        )
                    } else {
                        VStack {
                            contentForSelectedTab(viewStore.selectedTab)
                            Divider()
                        }
                        .safeAreaInset(edge: .bottom) {
                            BottomToolBar(store: store)
                        }
                    }
                } else {
                    LoginView(
                        store: store.scope(
                            state: \.login,
                            action: \.login
                        )
                    )
                }
            }
            .onAppear {
                viewStore.send(.onAppear)
            }
            .onReceive(NotificationCenter.default.publisher(for: .authSessionExpired)) { _ in
                viewStore.send(.sessionExpired)
            }
        }
    }
    
    struct BottomToolBar: View {
        let store: StoreOf<AppFeature>
        
        var body: some View {
            WithViewStore(store, observe: \.selectedTab) { viewStore in
                HStack {
                    Button {
                        viewStore.send(.selectTab(.theme))
                    } label: {
                        VStack(spacing: 2) {
                            Image(viewStore.state == .theme
                                  ? "icon-theme-selected" : "icon-theme")
                            Text("테마")
                                .foregroundColor(
                                    viewStore.state == .theme
                                    ? .black : .gray
                                )
                        }
                    }
                    .frame(maxWidth: .infinity)
                    
                    Button {
                        viewStore.send(.selectTab(.community))
                    } label: {
                        VStack(spacing: 2) {
                            Image(viewStore.state == .community
                                  ? "icon-community-selected" : "icon-community")
                            Text("커뮤니티")
                                .foregroundColor(
                                    viewStore.state == .community
                                    ? .black : .gray
                                )
                        }
                    }
                    .frame(maxWidth: .infinity)
                    
                    Button {
                        viewStore.send(.selectTab(.myPage))
                    } label: {
                        VStack(spacing: 2) {
                            Image(viewStore.state == .myPage
                                  ? "icon-my-selected" : "icon-my")
                            Text("나의 탈출")
                                .foregroundColor(
                                    viewStore.state == .myPage
                                    ? .black : .gray
                                )
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }
    @ViewBuilder
    private func contentForSelectedTab(_ tab: Tab) -> some View {
        switch tab {
        case .theme:
            ThemeView(
                store: store.scope(state: \.theme, action: \.theme)
            )
        case .community:
            CommunityView(
                store: store.scope(state: \.community, action: \.community)
            )
        case .myPage:
            MyView(
                store: store.scope(state: \.myPage, action: \.myPage)
            )
        }
    }
}

struct AppView_Previews: PreviewProvider {
    static var previews: some View {
        AppView(store: Store(initialState: AppFeature.State(), reducer: { AppFeature() }))
    }
}
