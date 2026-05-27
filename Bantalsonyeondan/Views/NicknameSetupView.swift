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
        var duplicateToastMessage: String? = nil

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
        case dismissDuplicateToast
        case backTapped
        case delegate(Delegate)
    }

    @CasePathable
    enum Delegate {
        case didComplete(Member)
        case didTapBack
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
            if error.localizedDescription.contains("Query did not return a unique result") {
                state.duplicateToastMessage = "이미 사용중인 닉네임입니다."
                return .none
            }
            state.errorMessage = error.localizedDescription
            return .none

        case .completeTapped:
            guard let member = state.completedMember else { return .none }
            return .send(.delegate(.didComplete(member)))

        case .clearErrorMessage:
            state.errorMessage = nil
            return .none

        case .dismissDuplicateToast:
            state.duplicateToastMessage = nil
            return .none

        case .backTapped:
            return .send(.delegate(.didTapBack))

        case .delegate:
            return .none
        }
    }
}

struct NicknameSetupView: View {
    let store: StoreOf<NicknameSetupFeature>
    @State private var greetingTextWidth: CGFloat = 68

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
            headerTitle("닉네임 설정", onBack: { viewStore.send(.backTapped) })

            Spacer()
                .frame(maxHeight: 24)

            Image("nickname_setting_lock_hall")
                .resizable()
                .scaledToFit()
                .frame(width: 72, height: 72)
                .shadow(color: Color.green.opacity(0.9), radius: 60, x: 0, y: 0)
                .shadow(color: Color.green.opacity(0.6), radius: 100, x: 0, y: 0)

            VStack(spacing: 8) {
                Text("반갑습니다!")
                    .font(.system(size: 24, weight: .bold))
                    .overlay(
                        GeometryReader { geo in
                            Color.clear.onAppear {
                                greetingTextWidth = geo.size.width
                            }
                        }
                    )
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
        .appToast(
            message: viewStore.binding(
                get: \.duplicateToastMessage,
                send: { _ in NicknameSetupFeature.Action.dismissDuplicateToast }
            ),
            style: .error,
            duration: 2.5,
            bottomPadding: 100
        )
        .onPreferenceChange(GreetingTextWidthKey.self) { width in
            if width > 0 { greetingTextWidth = width }
        }
    }

    private func completedView(viewStore: ViewStoreOf<NicknameSetupFeature>) -> some View {
        VStack(spacing: 0) {
            Image("icon-launch")
                .resizable()
                .scaledToFit()
                .frame(width: 160)
                .frame(maxWidth: .infinity)
                .padding(.top, 80)

            Spacer()

            VStack(spacing: 16) {
                Text("환영합니다!")
                    .font(.system(size: 28, weight: .bold))

                Text("\(viewStore.completedMember?.nickname ?? viewStore.nickname)님")
                    .font(.system(size: 28, weight: .bold))

                Text("방탈소년단과 함께 알찬 방탈출 생활하세요")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

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
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            Image("nickname_singup_done")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
        )
    }

    private func headerTitle(_ title: String, onBack: (() -> Void)? = nil) -> some View {
        ZStack {
            Text(title)
                .font(.system(size: 20, weight: .bold))
                .frame(maxWidth: .infinity, alignment: .center)
            if let onBack {
                HStack {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Color(UIColor.systemGray))
                    }
                    .padding(.leading, 16)
                    Spacer()
                }
            }
        }
        .padding(.top, 16)
    }
}

struct NicknameSetupView_Previews: PreviewProvider {
    static var previews: some View {
        NicknameSetupView()
    }
}

private struct GreetingTextWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
