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
    @Dependency(\.memberAPIClient) var memberAPIClient

    // MARK: - State
    struct State: Equatable {
        var selectedTab: Tab = .theme
        var theme = ThemeFeature.State()
        var community = CommunityFeature.State()
        var myPage = MyFeature.State()
        var login = LoginFeature.State()
        var nicknameSetup = NicknameSetupFeature.State()
        var userSession: UserSession? = AuthSessionStore.currentSession
        var currentMember: Member? = AuthSessionStore.currentMember
        var needsNicknameSetup: Bool = false

        var isAuthenticated: Bool {
            guard let token = userSession?.accessToken
                .trimmingCharacters(in: .whitespacesAndNewlines),
                  !token.isEmpty else {
                return false
            }
            return true
        }
        var shouldShowNicknameSetup: Bool { isAuthenticated && needsNicknameSetup }
    }
    
    // MARK: - Action
    @CasePathable
    enum Action {
        case onAppear
        case sessionExpired
        case selectTab(Tab)
        case theme(ThemeFeature.Action)
        case community(CommunityFeature.Action)
        case myPage(MyFeature.Action)
        case login(LoginFeature.Action)
        case nicknameSetup(NicknameSetupFeature.Action)
        case refreshMemberResponse(Result<Member, Error>)
    }

    var body: some ReducerOf<Self> {
        Scope(state: \.theme, action: \.theme) { ThemeFeature() }
        Scope(state: \.community, action: \.community) { CommunityFeature() }
        Scope(state: \.myPage, action: \.myPage) { MyFeature() }
        Scope(state: \.login, action: \.login) { LoginFeature() }
        Scope(state: \.nicknameSetup, action: \.nicknameSetup) { NicknameSetupFeature() }

        Reduce { state, action in
            switch action {
            case .onAppear:
                restoreSessionState(&state)
                evaluateNicknameRequirement(&state)

                guard state.isAuthenticated, state.currentMember == nil else {
                    return .none
                }
                return .run { send in
                    do {
                        let member = try await memberAPIClient.getMyMembers()
                        await send(.refreshMemberResponse(.success(member)))
                    } catch {
                        await send(.refreshMemberResponse(.failure(error)))
                    }
                }

            case .sessionExpired:
                logout(&state)
                state.login.errorMessage = "로그인이 만료되었어요. 다시 로그인해주세요."
                return .none

            case let .refreshMemberResponse(.success(member)):
                state.currentMember = member
                state.myPage.member = member
                AuthSessionStore.currentMember = member
                evaluateNicknameRequirement(&state)
                return .none

            case .refreshMemberResponse(.failure):
                return .none

            case let .selectTab(tab):
                state.selectedTab = tab
                if tab == .myPage, state.isAuthenticated {
                    return .send(.myPage(.refresh))
                }
                return .none

            case let .login(.delegate(.didLogin(session, member))):
                applyLogin(session: session, member: member, to: &state)
                evaluateNicknameRequirement(&state)
                return .none

            case let .nicknameSetup(.delegate(.didComplete(member))):
                state.currentMember = member
                state.myPage.member = member
                state.needsNicknameSetup = false
                state.nicknameSetup = NicknameSetupFeature.State()
                AuthSessionStore.currentMember = member

                if let session = state.userSession {
                    let updatedSession = UserSession(
                        accessToken: session.accessToken,
                        refreshToken: session.refreshToken,
                        memberId: session.memberId,
                        role: session.role,
                        isNewUser: false
                    )
                    state.userSession = updatedSession
                    AuthSessionStore.currentSession = updatedSession
                }
                return .none

            case .myPage(.delegate(.logoutRequested)):
                logout(&state)
                return .none

            case .myPage(.delegate(.openThemeTab)):
                state.selectedTab = .theme
                return .none

            case .theme, .community, .myPage, .login, .nicknameSetup:
                return .none
            }
        }
    }

    private func restoreSessionState(_ state: inout State) {
        state.userSession = normalizedSession(AuthSessionStore.currentSession)
        state.currentMember = AuthSessionStore.currentMember

        if state.userSession == nil {
            AuthSessionStore.currentSession = nil
            AuthSessionStore.currentMember = nil
            state.currentMember = nil
        }

        state.myPage.member = state.currentMember
        state.nicknameSetup.nickname = state.currentMember?.nickname ?? ""
    }

    private func applyLogin(session: UserSession, member: Member?, to state: inout State) {
        state.userSession = normalizedSession(session)
        state.currentMember = member
        state.myPage = MyFeature.State(member: member)
        state.nicknameSetup.nickname = member?.nickname ?? ""
        AuthSessionStore.currentSession = state.userSession
        AuthSessionStore.currentMember = member
    }

    private func logout(_ state: inout State) {
        AuthSessionStore.clearAll()
        state.selectedTab = .theme
        state.theme = ThemeFeature.State()
        state.community = CommunityFeature.State()
        state.myPage = MyFeature.State()
        state.login = LoginFeature.State()
        state.nicknameSetup = NicknameSetupFeature.State()
        state.userSession = nil
        state.currentMember = nil
        state.needsNicknameSetup = false
    }

    private func evaluateNicknameRequirement(_ state: inout State) {
        let trimmedNickname = state.currentMember?.nickname?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let sessionNeedsSetup = state.userSession?.isNewUser == true
        let memberNeedsSetup = !trimmedNickname.isEmpty ? false : state.currentMember != nil

        state.needsNicknameSetup = sessionNeedsSetup || memberNeedsSetup
        if state.needsNicknameSetup {
            state.nicknameSetup.nickname = trimmedNickname
        }
    }

    private func normalizedSession(_ session: UserSession?) -> UserSession? {
        guard let session else { return nil }
        let normalizedToken = session.accessToken.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedToken.isEmpty else { return nil }

        guard normalizedToken != session.accessToken else {
            return session
        }

        return UserSession(
            accessToken: normalizedToken,
            refreshToken: session.refreshToken,
            memberId: session.memberId,
            role: session.role,
            isNewUser: session.isNewUser
        )
    }
}
