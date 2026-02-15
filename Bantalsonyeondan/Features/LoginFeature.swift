//
//  LoginFeature.swift
//  Bantalsonyeondan
//
//  Created by 이상현 on 10/29/24.
//

import ComposableArchitecture
import Foundation

struct LoginFeature: Reducer {
    struct State: Equatable {
        var isLoading: Bool = false
        var errorMessage: String?
    }

    @CasePathable
    enum Action {
        case kakaoLoginTapped
        case kakaoAccountLoginTapped
        case naverLoginTapped
        case appleLoginTapped
        case loginSucceeded(UserSession, Member?)
        case loginFailed(String)
        case clearErrorMessage
        case delegate(Delegate)
    }

    @CasePathable
    enum Delegate {
        case didLogin(UserSession, Member?)
    }

    @Dependency(\.userAPIClient) var userAPIClient
    @Dependency(\.memberAPIClient) var memberAPIClient

    func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .kakaoLoginTapped:
            startLoading(&state)
            return loginEffect { try await userAPIClient.loginWithKakaoTalkAsync() }

        case .kakaoAccountLoginTapped:
            startLoading(&state)
            return loginEffect { try await userAPIClient.loginWithKakaoAccountAsync() }

        case .naverLoginTapped:
            startLoading(&state)
            return loginEffect { try await userAPIClient.loginWithNaverAsync() }

        case .appleLoginTapped:
            startLoading(&state)
            return loginEffect { try await userAPIClient.loginWithAppleAsync() }

        case let .loginSucceeded(session, member):
            state.isLoading = false
            state.errorMessage = nil
            AuthSessionStore.currentSession = session
            AuthSessionStore.currentMember = member
            return .send(.delegate(.didLogin(session, member)))

        case let .loginFailed(message):
            state.isLoading = false
            state.errorMessage = message
            return .none

        case .clearErrorMessage:
            state.errorMessage = nil
            return .none

        case .delegate:
            return .none
        }
    }

    private func startLoading(_ state: inout State) {
        state.isLoading = true
        state.errorMessage = nil
    }

    private func loginEffect(
        _ login: @escaping @Sendable () async throws -> AuthResponse
    ) -> Effect<Action> {
        .run { send in
            do {
                let authResponse = try await login()
                let session = UserSession(authResponse: authResponse)
                AuthSessionStore.currentSession = session

                var member: Member? = nil
                do {
                    member = try await memberAPIClient.getMyMembers()
                } catch {
                    // Login can still be considered successful if member profile fetch fails.
                }
                await send(.loginSucceeded(session, member))
            } catch {
                await send(.loginFailed(error.localizedDescription))
            }
        }
    }
}
