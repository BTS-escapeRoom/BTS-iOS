//
//  LoginFeature.swift
//  Bantalsonyeondan
//
//  Created by 이상현 on 10/29/24.
//

import ComposableArchitecture
import SwiftUI

// MARK: - Reducer
struct LoginFeature: Reducer {
    
    struct State: Equatable {
        var isLoginSuccess = false
    }
    
    enum Action {
        case kakaoLoginTapped
        case kakaoAccountLoginTapped
        case appleLoginTapped
        case loginSuccess
        case loginFailure(String)
    }
    
    @Dependency(\.userAPIClient) var userAPIClient
    
    func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .kakaoLoginTapped:
            return .run { send in
                do {
                    _ = try await userAPIClient.loginWithKakaoTalkAsync()
                    await send(.loginSuccess)
                } catch {
                    await send(.loginFailure(error.localizedDescription))
                }
            }
        case .kakaoAccountLoginTapped:
            return .run { send in
                do {
                    _ = try await userAPIClient.loginWithKakaoAccountAsync()
                    await send(.loginSuccess)
                } catch {
                    await send(.loginFailure(error.localizedDescription))
                }
            }
        case .appleLoginTapped:
            return .run { send in
                do {
                    _ = try await userAPIClient.loginWithAppleAsync()
                    await send(.loginSuccess)
                } catch {
                    await send(.loginFailure(error.localizedDescription))
                }
            }
        case .loginSuccess:
            state.isLoginSuccess = true
            return .none
        case .loginFailure:
            state.isLoginSuccess = false
            return .none
        }
    }
}
