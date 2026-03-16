//
//  LoginFeature.swift
//  Bantalsonyeondan
//
//  Created by 이상현 on 10/29/24.
//

import ComposableArchitecture
import Foundation
import KakaoSDKCommon

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
                    if !session.isNewUser {
                        throw error
                    }
                }
                await send(.loginSucceeded(session, member))
            } catch {
                await send(.loginFailed(loginErrorMessage(from: error)))
            }
        }
    }

    private func loginErrorMessage(from error: Error) -> String {
        if let sdkError = error as? SdkError {
            switch sdkError {
            case let .ClientFailed(reason, message):
                switch reason {
                case .Cancelled:
                    return "로그인이 취소되었어요."
                case .TokenNotFound:
                    return "카카오 인증 토큰을 확인하지 못했어요. 다시 시도해주세요."
                case .NotSupported:
                    return "카카오톡 로그인에 실패했어요. 카카오계정 로그인으로 다시 시도해주세요."
                case .MustInitAppKey:
                    return "카카오 SDK 초기화 설정을 확인해주세요."
                default:
                    return message ?? "카카오 로그인 중 오류가 발생했어요."
                }
            case let .AuthFailed(reason, info):
                let backendMessage = info?.errorDescription?.trimmingCharacters(in: .whitespacesAndNewlines)
                switch reason {
                case .Misconfigured:
                    return "카카오 개발자 콘솔 iOS 설정(번들 ID/플랫폼)을 확인해주세요."
                case .InvalidClient:
                    return "카카오 앱 키 설정이 올바르지 않아요."
                case .InvalidGrant:
                    return "카카오 인증 정보가 만료되었어요. 다시 시도해주세요."
                case .AccessDenied:
                    return "카카오 로그인에 동의하지 않아 취소되었어요."
                default:
                    if let backendMessage, !backendMessage.isEmpty {
                        return backendMessage
                    }
                    return "카카오 인증 중 오류가 발생했어요."
                }
            case .ApiFailed, .AppsFailed:
                return "카카오 로그인 요청 처리 중 오류가 발생했어요."
            }
        }

        let message = error.localizedDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        return message.isEmpty ? "로그인 중 오류가 발생했어요. 다시 시도해주세요." : message
    }
}
