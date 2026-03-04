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

        var message: String {
            switch self {
            case .community:
                return "이 공간은 로그인 후 열람할 수 있어요.\n지금 로그인하고 함께 둘러볼까요?"
            case .myPage:
                return "이 공간은 로그인 후 열람할 수 있어요.\n지금 로그인하고 함께 둘러볼까요?"
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
                                switch context {
                                case .community:
                                    loginRequiredContext = context
                                    pendingTabAfterLogin = .community
                                case .myPage:
                                    loginRequiredContext = context
                                    pendingTabAfterLogin = .myPage
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
            .overlay {
                if let loginRequiredContext {
                    LoginRequiredPopup(
                        message: loginRequiredContext.message,
                        onClose: {
                            self.loginRequiredContext = nil
                            pendingTabAfterLogin = nil
                        },
                        onLogin: {
                            self.loginRequiredContext = nil
                            isShowingLoginView = true
                        }
                    )
                    .transition(.opacity)
                }
            }
            .fullScreenCover(isPresented: $isShowingLoginView) {
                NavigationStack {
                    ZStack {
                        Color(.systemBackground)
                            .ignoresSafeArea()

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
                    pendingTabAfterLogin = nil
                    isShowingLoginView = true
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

private struct LoginRequiredPopup: View {
    let message: String
    let onClose: () -> Void
    let onLogin: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                ZStack {
                    Text("로그인이 필요해요")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.black)

                    HStack {
                        Spacer()
                        Button(action: onClose) {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(.gray)
                        }
                    }
                }
                .frame(maxWidth: .infinity)

                Text(message)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(Color(.systemGray))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)

                HStack(spacing: 10) {
                    Button("닫기", action: onClose)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color(.systemGray))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray5))
                        .cornerRadius(8)

                    Button("로그인 하러 가기", action: onLogin)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.black)
                        .cornerRadius(8)
                }
                .padding(.top, 2)
            }
            .padding(16)
            .frame(maxWidth: 300)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.12), radius: 18, y: 8)
            .padding(.horizontal, 32)
        }
    }
}

struct AppView_Previews: PreviewProvider {
    static var previews: some View {
        AppView(store: Store(initialState: AppFeature.State(), reducer: { AppFeature() }))
    }
}
