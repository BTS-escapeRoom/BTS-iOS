//
//  LoginView.swift
//  Bantalsonyeondan
//
//  Created by 이상현 on 7/31/24.
//

import SwiftUI
import ComposableArchitecture
import KakaoSDKCommon
import KakaoSDKUser
import KakaoSDKAuth
import AuthenticationServices

struct LoginView: View {
    let store: StoreOf<LoginFeature>
    
    init(store: StoreOf<LoginFeature> = Store(initialState: LoginFeature.State(), reducer: { LoginFeature() })) {
        self.store = store
    }
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()

                VStack(spacing: 16) {
                    Spacer()
                    Image("icon-launch")
                    Spacer()
                    Text("소셜로그인으로 간편하게 시작해보세요.")
                        .font(.title3)
                        .foregroundColor(.gray)
                    Button {
                        if UserApi.isKakaoTalkLoginAvailable() {
                            viewStore.send(.kakaoLoginTapped)
                        } else {
                            viewStore.send(.kakaoAccountLoginTapped)
                        }
                    } label : {
                        Image("kakao_login_medium_narrow")
                    }
                    .disabled(viewStore.isLoading)

                    Button {
                        viewStore.send(.naverLoginTapped)
                    } label : {
                        Image("naver_login")
                    }
                    .disabled(viewStore.isLoading)

                    AppleSignInButton {
                        viewStore.send(.appleLoginTapped)
                    }
                    .disabled(viewStore.isLoading)

                    if viewStore.isLoading {
                        ProgressView()
                    }

                    Spacer()
                }
                .padding()
            }
            .appToast(
                message: Binding(
                    get: { viewStore.errorMessage },
                    set: { _ in viewStore.send(.clearErrorMessage) }
                ),
                style: .error
            )
        }
    }
}


#Preview {
    LoginView()
}

// onOpenURL()을 사용해 커스텀 URL 스킴 처리
//    .onOpenURL(perform: { url in
//        if (AuthApi.isKakaoTalkLoginUrl(url)) {
//            _ = AuthController.handleOpenUrl(url: url)
//        }
//    })
// 앱에서 소셜 로그인해서 닉네임이랑 전달
