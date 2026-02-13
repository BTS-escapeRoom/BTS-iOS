import SwiftUI
import ComposableArchitecture

struct MyView: View {
    let store: StoreOf<MyFeature>
    @State private var isShowingRecords: Bool = false

    private struct MenuItem: Identifiable {
        let id = UUID()
        let title: String
    }

    private let menuItems: [MenuItem] = [
        .init(title: "나의 활동"),
        .init(title: "내가 쓴 리뷰"),
        .init(title: "문의하기"),
        .init(title: "공지사항"),
        .init(title: "로그아웃"),
        .init(title: "서비스 설정")
    ]

    var body: some View {
        WithViewStore(store, observe: \.self) { viewStore in
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("나의 탈출")
                            .font(.headline)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity, alignment: .center)

                        HStack(spacing: 12) {
                            Circle()
                                .fill(Color(UIColor.systemGray5))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .foregroundStyle(.gray)
                                )

                            Text(viewStore.member?.nickname ?? "닉네임")
                                .font(.subheadline)

                            Spacer()
                        }
                        .padding(.horizontal, 4)

                        recordsSection(viewStore: viewStore)
                        menuSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }
                .navigationDestination(isPresented: $isShowingRecords) {
                    RecordsView(
                        records: viewStore.histories,
                        selectedDisplayReviewIds: viewStore.displayedReviewIds,
                        isUpdatingDisplay: viewStore.isUpdatingDisplay,
                        onToggleDisplay: { reviewId in
                            viewStore.send(.toggleHistoryDisplay(reviewId: reviewId))
                        }
                    )
                }
                .overlay {
                    if viewStore.isLoading {
                        ZStack {
                            Color.black.opacity(0.08).ignoresSafeArea()
                            ProgressView()
                                .controlSize(.large)
                        }
                    }
                }
                .onAppear {
                    viewStore.send(.onAppear)
                }
                .alert(
                    "알림",
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
        }
    }

    private func recordsSection(viewStore: ViewStoreOf<MyFeature>) -> some View {
        let visibleHistories = viewStore.histories.filter {
            viewStore.displayedReviewIds.contains($0.reviewId)
        }

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("방탈출 기록")
                    .font(.subheadline)
                    .fontWeight(.bold)

                Spacer()

                Button("더보기") {
                    isShowingRecords = true
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            if viewStore.histories.isEmpty {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(UIColor.systemGray6))
                    .frame(height: 80)
                    .overlay {
                        Text("리뷰를 남기면 방탈출 기록이 추가돼요.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
            } else if visibleHistories.isEmpty {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(UIColor.systemGray6))
                    .frame(height: 80)
                    .overlay {
                        Text("노출 중인 방탈출 기록이 없어요.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(visibleHistories) { history in
                            HistoryPreviewCard(
                                history: history,
                                isDisplayed: true
                            )
                            .frame(width: 164)
                        }
                    }
                }
            }
        }
    }

    private var menuSection: some View {
        VStack(spacing: 0) {
            ForEach(Array(menuItems.enumerated()), id: \.element.id) { index, item in
                Button {
                    // TODO: 메뉴별 액션 연결
                } label: {
                    MenuRow(title: item.title)
                }
                .buttonStyle(.plain)

                if index < menuItems.count - 1 {
                    Divider()
                        .padding(.leading, 16)
                }
            }
        }
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(UIColor.systemGray5), lineWidth: 1)
        )
    }
}

private struct MenuRow: View {
    let title: String

    var body: some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.subheadline)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.footnote)
                .foregroundStyle(.tertiary)
        }
        .contentShape(Rectangle())
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
    }
}

private struct HistoryPreviewCard: View {
    let history: ReviewHistory
    let isDisplayed: Bool

    private var accentColor: Color {
        history.isSuccess
        ? Color(red: 0.24, green: 0.95, blue: 0.45)
        : Color(red: 0.97, green: 0.45, blue: 0.84)
    }

    private var titleColor: Color {
        .white
    }

    private var backgroundColor: Color {
        history.isSuccess ? Color(UIColor.darkGray) : Color(UIColor.systemGray4)
    }

    var body: some View {
        VStack(spacing: 8) {
            Text(history.themeTitle)
                .font(.custom("Galmuri9", size: 14))
                .foregroundColor(titleColor)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 4)

            Text(HistoryTimeFormatter.string(from: history.time))
                .font(.custom("Galmuri9", size: 16))
                .foregroundColor(accentColor)
                .lineLimit(1)
                .padding(.bottom, 6)
        }
        .blur(radius: isDisplayed ? 0 : 1.2)
        .frame(height: 86)
        .background(backgroundColor)
        .overlay {
            if !isDisplayed {
                ZStack {
                    Rectangle()
                        .fill(Color.white.opacity(0.15))
                    Text("미노출")
                        .font(.custom("Galmuri9", size: 14))
                        .foregroundColor(Color.white.opacity(0.9))
                }
            }
        }
        .overlay(
            HStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 12, height: 12)
                    .offset(x: -6)
                Spacer()
                Circle()
                    .fill(Color.white)
                    .frame(width: 12, height: 12)
                    .offset(x: 6)
            }
            .blendMode(.destinationOut)
        )
        .compositingGroup()
    }
}
