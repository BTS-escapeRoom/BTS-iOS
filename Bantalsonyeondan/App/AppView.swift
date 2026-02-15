//
//  AppView.swift
//  Bantalsonyeondan
//
//  Created by 이상현 on 4/9/25.
//

import SwiftUI
import ComposableArchitecture
import KakaoSDKCommon
import KakaoSDKUser
import KakaoSDKAuth
import AuthenticationServices
import NaverThirdPartyLogin

struct AppView: View {
    let store: StoreOf<AppFeature>
    
    init(store: StoreOf<AppFeature>) {
        self.store = store
        KakaoSDK.initSDK(appKey: "a93ca2d555bc0d7e5195bdfb2c8ecdc1")
    }
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            Group {
                if viewStore.isAuthenticated {
                    VStack {
                        contentForSelectedTab(viewStore.selectedTab)
                        Divider()
                    }
                    .safeAreaInset(edge: .bottom) {
                        BottomToolBar(store: store)
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
        }
        .onOpenURL { url in
            handleOpenURL(url)
        }
    }
    
    /// 외부 로그인 콜백 URL 처리: 카카오 / 애플 / 네이버 분기
    private func handleOpenURL(_ url: URL) {
        // 1) 카카오톡 로그인 콜백
        if AuthApi.isKakaoTalkLoginUrl(url) {
            _ = AuthController.handleOpenUrl(url: url)
            return
        }
        
        // 3) 네이버 로그인 콜백
        if url.scheme == NaverThirdPartyLoginConnection.getSharedInstance()?.serviceUrlScheme {
            NaverThirdPartyLoginConnection.getSharedInstance()?.receiveAccessToken(url)
            return
        }
        
        // 그 외 다른 딥링크가 있다면 여기서 추가 처리
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
