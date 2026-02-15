//
//  NicknameSetupView.swift
//  Bantalsonyeondan
//
//  Created by 이상현 on 10/29/24.
//

import SwiftUI
import ComposableArchitecture

struct NicknameSetupFeature: Reducer {
    struct State: Equatable {
        var nickname: String = ""
        var isSubmitting: Bool = false
        var didSubmit: Bool = false
        var completedMember: Member? = nil
        var errorMessage: String? = nil

        var trimmedNickname: String {
            nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        var isNicknameValid: Bool {
            let count = trimmedNickname.count
            return count >= 2 && count <= 10
        }
    }

    @CasePathable
    enum Action {
        case setNickname(String)
        case clearNickname
        case submitTapped
        case submitResponse(Result<Member, Error>)
        case completeTapped
        case clearErrorMessage
        case delegate(Delegate)
    }

    @CasePathable
    enum Delegate {
        case didComplete(Member)
    }

    @Dependency(\.memberAPIClient) var memberAPIClient

    func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case let .setNickname(value):
            state.nickname = String(value.prefix(10))
            return .none

        case .clearNickname:
            state.nickname = ""
            return .none

        case .submitTapped:
            guard !state.isSubmitting else { return .none }
            guard state.isNicknameValid else {
                state.errorMessage = "닉네임은 2~10자로 입력해주세요."
                return .none
            }

            let nickname = state.trimmedNickname
            state.isSubmitting = true
            state.errorMessage = nil

            return .run { send in
                do {
                    let member = try await memberAPIClient.updateMembers(
                        MemberUpdateRequest(
                            profileImg: nil,
                            nickname: nickname,
                            description: nil
                        )
                    )
                    await send(.submitResponse(.success(member)))
                } catch {
                    await send(.submitResponse(.failure(error)))
                }
            }

        case let .submitResponse(.success(member)):
            state.isSubmitting = false
            state.didSubmit = true
            state.completedMember = member
            state.nickname = member.nickname ?? state.nickname
            return .none

        case let .submitResponse(.failure(error)):
            state.isSubmitting = false
            state.errorMessage = error.localizedDescription
            return .none

        case .completeTapped:
            guard let member = state.completedMember else { return .none }
            return .send(.delegate(.didComplete(member)))

        case .clearErrorMessage:
            state.errorMessage = nil
            return .none

        case .delegate:
            return .none
        }
    }
}

struct NicknameSetupView: View {
    let store: StoreOf<NicknameSetupFeature>

    init(
        store: StoreOf<NicknameSetupFeature> = Store(
            initialState: NicknameSetupFeature.State(),
            reducer: { NicknameSetupFeature() }
        )
    ) {
        self.store = store
    }

    var body: some View {
        WithViewStore(store, observe: \.self) { viewStore in
            if viewStore.didSubmit {
                completedView(viewStore: viewStore)
            } else {
                formView(viewStore: viewStore)
            }
        }
    }

    private func formView(viewStore: ViewStoreOf<NicknameSetupFeature>) -> some View {
        VStack(spacing: 20) {
            headerTitle("닉네임 설정")

            Spacer()

            Image("nickname_setting_lock_hall")
                .resizable()
                .scaledToFit()
                .frame(width: 68, height: 68)

            VStack(spacing: 8) {
                Text("반갑습니다!")
                    .font(.system(size: 24, weight: .bold))
                Text("방탈소년단에서 사용할 닉네임을 설정해 주세요")
                    .font(.system(size: 16, weight: .bold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color("cod_gray"))
            }
            .padding(.horizontal, 24)

            HStack(spacing: 8) {
                TextField(
                    "닉네임을 입력해주세요 (2~10자)",
                    text: viewStore.binding(
                        get: \.nickname,
                        send: NicknameSetupFeature.Action.setNickname
                    )
                )
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)

                if !viewStore.nickname.isEmpty {
                    Button {
                        viewStore.send(.clearNickname)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Color(UIColor.systemGray2))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .frame(height: 48)
            .background(Color(UIColor.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .padding(.horizontal, 20)

            Text("공백 제외 \(viewStore.trimmedNickname.count)/10")
                .font(.system(size: 12))
                .foregroundStyle(viewStore.isNicknameValid ? .secondary : Color.red)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.horizontal, 20)

            Spacer()

            Button {
                viewStore.send(.submitTapped)
            } label: {
                ZStack {
                    Text("완료")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                    if viewStore.isSubmitting {
                        ProgressView()
                            .tint(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    viewStore.isNicknameValid
                    ? Color("cod_gray")
                    : Color(UIColor.systemGray3)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .disabled(!viewStore.isNicknameValid || viewStore.isSubmitting)
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .alert(
            "닉네임 설정 실패",
            isPresented: Binding(
                get: { viewStore.errorMessage != nil },
                set: { isPresented in
                    if !isPresented {
                        viewStore.send(.clearErrorMessage)
                    }
                }
            )
        ) {
            Button("확인", role: .cancel) {
                viewStore.send(.clearErrorMessage)
            }
        } message: {
            Text(viewStore.errorMessage ?? "")
        }
    }

    private func completedView(viewStore: ViewStoreOf<NicknameSetupFeature>) -> some View {
        VStack(spacing: 20) {
            headerTitle("닉네임 설정")

            Spacer()

            Image("nickname_signup_Done")
                .resizable()
                .scaledToFit()
                .frame(width: 150, height: 150)

            Text("축하합니다!")
                .font(.system(size: 24, weight: .bold))

            Text("\(viewStore.completedMember?.nickname ?? viewStore.nickname)님")
                .font(.system(size: 20, weight: .bold))

            Text("방탈보이즈와 함께 알찬 방탈출 생활 하세요")
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()

            Button {
                viewStore.send(.completeTapped)
            } label: {
                Text("입장")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color("cod_gray"))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
    }

    private func headerTitle(_ title: String) -> some View {
        HStack {
            Spacer()
            Text(title)
                .font(.system(size: 20, weight: .bold))
            Spacer()
        }
        .padding(.top, 16)
    }
}

struct NicknameSetupView_Previews: PreviewProvider {
    static var previews: some View {
        NicknameSetupView()
    }
}
