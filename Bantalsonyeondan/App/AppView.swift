//
//  AppView.swift
//  Bantalsonyeondan
//
//  Created by 이상현 on 4/9/25.
//

import SwiftUI
import ComposableArchitecture

struct AppView: View {
    enum LoginRequiredContext {
        case community
        case myPage
        case review

        var message: String {
            switch self {
            case .community:
                return "커뮤니티는 로그인 후 이용할 수 있어요."
            case .myPage:
                return "나의 탈출은 로그인 후 이용할 수 있어요."
            case .review:
                return "리뷰는 로그인 후 이용할 수 있어요."
            }
        }
    }

    let store: StoreOf<AppFeature>
    @State private var loginRequiredContext: LoginRequiredContext?
    @State private var isShowingLoginView = false
    @State private var pendingTabAfterLogin: Tab?

    init(store: StoreOf<AppFeature>) {
        self.store = store
    }
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            let effectiveTab: Tab = viewStore.isAuthenticated ? viewStore.selectedTab : .theme

            Group {
                if viewStore.shouldShowNicknameSetup {
                    NicknameSetupView(
                        store: store.scope(
                            state: \.nicknameSetup,
                            action: \.nicknameSetup
                        )
                    )
                } else {
                    VStack {
                        contentForSelectedTab(effectiveTab, viewStore: viewStore)
                        Divider()
                    }
                    .safeAreaInset(edge: .bottom) {
                        BottomToolBar(
                            store: store,
                            isAuthenticated: viewStore.isAuthenticated,
                            onRequireLogin: { context in
                                loginRequiredContext = context
                                switch context {
                                case .community:
                                    pendingTabAfterLogin = .community
                                case .myPage:
                                    pendingTabAfterLogin = .myPage
                                case .review:
                                    pendingTabAfterLogin = nil
                                }
                            }
                        )
                    }
                }
            }
            .onAppear {
                viewStore.send(.onAppear)
            }
            .onChange(of: viewStore.isAuthenticated) { isAuthenticated in
                if isAuthenticated {
                    isShowingLoginView = false
                    if let pendingTabAfterLogin {
                        viewStore.send(.selectTab(pendingTabAfterLogin))
                        self.pendingTabAfterLogin = nil
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .authSessionExpired)) { _ in
                viewStore.send(.sessionExpired)
            }
            .alert(
                "로그인이 필요해요",
                isPresented: Binding(
                    get: { loginRequiredContext != nil },
                    set: { isPresented in
                        if !isPresented {
                            loginRequiredContext = nil
                        }
                    }
                )
            ) {
                Button("취소", role: .cancel) {
                    loginRequiredContext = nil
                }
                Button("로그인하러가기") {
                    loginRequiredContext = nil
                    isShowingLoginView = true
                }
            } message: {
                Text(loginRequiredContext?.message ?? "")
            }
            .fullScreenCover(isPresented: $isShowingLoginView) {
                NavigationStack {
                    LoginView(
                        store: store.scope(
                            state: \.login,
                            action: \.login
                        )
                    )
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("닫기") {
                                isShowingLoginView = false
                            }
                        }
                    }
                }
            }
        }
    }
    
    struct BottomToolBar: View {
        let store: StoreOf<AppFeature>
        let isAuthenticated: Bool
        let onRequireLogin: (LoginRequiredContext) -> Void
        
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
                        if isAuthenticated {
                            viewStore.send(.selectTab(.community))
                        } else {
                            onRequireLogin(.community)
                        }
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
                        if isAuthenticated {
                            viewStore.send(.selectTab(.myPage))
                        } else {
                            onRequireLogin(.myPage)
                        }
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
    private func contentForSelectedTab(_ tab: Tab, viewStore: ViewStoreOf<AppFeature>) -> some View {
        switch tab {
        case .theme:
            ThemeView(
                store: store.scope(state: \.theme, action: \.theme),
                isAuthenticated: viewStore.isAuthenticated,
                onRequireLogin: {
                    loginRequiredContext = .review
                    pendingTabAfterLogin = nil
                }
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
