import SwiftUI
import ComposableArchitecture

struct MyView: View {
    let store: StoreOf<MyFeature>
    @State private var isShowingRecords: Bool = false
    @State private var isShowingRecruitBoardActivity: Bool = false
    @State private var isShowingMyReviews: Bool = false
    @State private var isShowingInquiry: Bool = false
    @State private var isShowingNotice: Bool = false
    @State private var isShowingServiceSettings: Bool = false
    @State private var isShowingLogoutDialog: Bool = false

    private struct MenuItem: Identifiable {
        let id = UUID()
        let title: String
        let action: MenuAction
    }

    private enum MenuAction {
        case recruitBoardActivity
        case myReviews
        case inquiry
        case notice
        case logout
        case serviceSettings
    }

    private let menuItems: [MenuItem] = [
        .init(title: "나의 활동", action: .recruitBoardActivity),
        .init(title: "내가 쓴 리뷰", action: .myReviews),
        .init(title: "문의하기", action: .inquiry),
        .init(title: "공지사항", action: .notice),
        .init(title: "로그아웃", action: .logout),
        .init(title: "서비스 설정", action: .serviceSettings)
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
                        menuSection(viewStore: viewStore)
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
                .navigationDestination(isPresented: $isShowingRecruitBoardActivity) {
                    RecruitBoardActivityView(
                        store: store.scope(
                            state: \.recruitBoardActivity,
                            action: \.recruitBoardActivity
                        )
                    )
                }
                .navigationDestination(isPresented: $isShowingMyReviews) {
                    MyReviewsView(
                        store: store.scope(
                            state: \.myReviews,
                            action: \.myReviews
                        )
                    )
                }
                .navigationDestination(isPresented: $isShowingInquiry) {
                    InquiryView()
                }
                .navigationDestination(isPresented: $isShowingNotice) {
                    NoticeListView()
                }
                .navigationDestination(isPresented: $isShowingServiceSettings) {
                    ServiceSettingsView()
                }
                .confirmationDialog(
                    "로그아웃 하시겠어요?",
                    isPresented: $isShowingLogoutDialog,
                    titleVisibility: .visible
                ) {
                    Button("로그아웃", role: .destructive) {
                        viewStore.send(.logoutTapped)
                    }
                    Button("취소", role: .cancel) {}
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
                    viewStore.send(.refresh)
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

    private func menuSection(viewStore: ViewStoreOf<MyFeature>) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(menuItems.enumerated()), id: \.element.id) { index, item in
                Button {
                    handleMenuAction(item.action, viewStore: viewStore)
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

    private func handleMenuAction(_ action: MenuAction, viewStore: ViewStoreOf<MyFeature>) {
        switch action {
        case .recruitBoardActivity:
            viewStore.send(.recruitBoardActivity(.reload))
            isShowingRecruitBoardActivity = true
        case .myReviews:
            viewStore.send(.myReviews(.reload))
            isShowingMyReviews = true
        case .inquiry:
            isShowingInquiry = true
        case .notice:
            isShowingNotice = true
        case .logout:
            isShowingLogoutDialog = true
        case .serviceSettings:
            isShowingServiceSettings = true
        }
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

// MARK: - My Reviews
private enum ReviewTimeType: String, CaseIterable, Identifiable {
    case remaining = "RAMAINING"
    case elapsed = "ELAPSED"
    case none = "NONE"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .remaining:
            return "남았어요"
        case .elapsed:
            return "걸렸어요"
        case .none:
            return "기록 안함"
        }
    }
}

struct MyReviewsView: View {
    let store: StoreOf<MyReviewsFeature>
    @State private var selectedReviewIdForMore: Int? = nil

    var body: some View {
        WithViewStore(store, observe: \.self) { viewStore in
            VStack(spacing: 0) {
                if viewStore.isLoading && viewStore.items.isEmpty {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if viewStore.items.isEmpty {
                    Spacer()
                    VStack(spacing: 10) {
                        Text("작성한 리뷰가 없어요.\n다른 사람들과 방탈출 후기를 공유해보세요.")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(Color(UIColor.systemGray3))
                            .multilineTextAlignment(.center)
                        Button("테마 둘러보기") {
                            viewStore.send(.tapExploreThemes)
                        }
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color("cod_gray"))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    .padding(.horizontal, 24)
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(viewStore.items) { item in
                                MyReviewCard(
                                    item: item,
                                    onThemeTap: { viewStore.send(.themeTapped(reviewId: item.id)) },
                                    onMoreTap: { selectedReviewIdForMore = item.id }
                                )
                                Divider()
                                    .padding(.leading, 16)
                            }
                        }
                    }
                }
            }
            .navigationTitle("내가 쓴 리뷰")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                viewStore.send(.onAppear)
            }
            .confirmationDialog(
                "",
                isPresented: Binding(
                    get: { selectedReviewIdForMore != nil },
                    set: { isPresented in
                        if !isPresented {
                            selectedReviewIdForMore = nil
                        }
                    }
                ),
                titleVisibility: .hidden
            ) {
                if let reviewId = selectedReviewIdForMore {
                    Button("수정") {
                        viewStore.send(.requestEdit(reviewId: reviewId))
                    }
                    Button("삭제", role: .destructive) {
                        viewStore.send(.requestDelete(reviewId: reviewId))
                    }
                }
                Button("닫기", role: .cancel) {}
            }
            .sheet(
                item: viewStore.binding(
                    get: \.selectedThemeDetail,
                    send: .dismissThemeDetail
                )
            ) { theme in
                ThemeDetailView(themeInfo: theme, onDismiss: {
                    viewStore.send(.dismissThemeDetail)
                })
                .presentationDetents([.fraction(0.9)])
                .presentationDragIndicator(.visible)
            }
            .sheet(
                item: viewStore.binding(
                    get: \.editingReview,
                    send: .dismissEdit
                )
            ) { review in
                NavigationStack {
                    MyReviewEditView(
                        review: review,
                        isSaving: viewStore.isProcessing,
                        onSave: { request in
                            viewStore.send(.saveEditedReview(reviewId: review.id, request: request))
                        },
                        onCancel: {
                            viewStore.send(.dismissEdit)
                        }
                    )
                }
                .interactiveDismissDisabled(viewStore.isProcessing)
            }
            .alert(
                "오류",
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
            .overlay(alignment: .center) {
                if viewStore.isProcessing {
                    ProgressView()
                        .padding(12)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
    }
}

private struct MyReviewCard: View {
    let item: MyReviewItem
    let onThemeTap: () -> Void
    let onMoreTap: () -> Void

    private var review: Review { item.review }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                Button(action: onThemeTap) {
                    HStack(alignment: .top, spacing: 10) {
                        Rectangle()
                            .fill(Color(UIColor.systemGray5))
                            .frame(width: 52, height: 70)
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundStyle(Color(UIColor.systemGray3))
                            )

                        VStack(alignment: .leading, spacing: 6) {
                            Text(item.themeTitle)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Color("cod_gray"))
                                .lineLimit(1)
                            HStack(spacing: 4) {
                                Text("공포")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundStyle(Color("cod_gray"))
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 2)
                                    .background(Color(UIColor.systemGray5))
                                Text(String(format: "%.1f", review.difficulty ?? 0))
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundStyle(Color("cod_gray"))
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 2)
                                    .background(Color(UIColor.systemGray5))
                                Text(MyReviewFormatters.timeLabel(from: review))
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundStyle(Color("cod_gray"))
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 2)
                                    .background(Color(UIColor.systemGray5))
                            }
                            Text(item.storeName)
                                .font(.system(size: 14, weight: .regular))
                                .foregroundStyle(Color(UIColor.systemGray))
                                .lineLimit(1)
                        }
                    }
                }
                .buttonStyle(.plain)
                Spacer()
                Button(action: onMoreTap) {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color(UIColor.systemGray))
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 6) {
                if item.isEscaped {
                    Label("추천해요", systemImage: "hand.thumbsup.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.purple)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.purple.opacity(0.14))
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                }

                Label(item.isEscaped ? "탈출성공" : "탈출실패", systemImage: "lock.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(item.isEscaped ? Color.green : Color.red)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background((item.isEscaped ? Color.green : Color.red).opacity(0.14))
                    .clipShape(RoundedRectangle(cornerRadius: 3))
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 14) {
                    Text("난이도 \(String(format: "%.1f", review.difficulty ?? 0))")
                    Text("활동성 \(review.activityScore ?? 0)")
                    Text("공포 \(review.scareScore ?? 0)")
                }
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(Color("cod_gray"))

                Text(
                    "플레이원 \(review.people ?? 0)명 | \(MyReviewFormatters.playTimeLine(from: review))"
                )
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(Color("cod_gray"))

                Text("방문일 \(MyReviewFormatters.visitDateLine(from: review.visitDate))")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(Color("cod_gray"))
            }

            if let content = review.content, !content.isEmpty {
                Text(content)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(Color("cod_gray"))
                    .lineLimit(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                    .background(Color(UIColor.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

private enum MyReviewFormatters {
    static func visitDateLine(from raw: String?) -> String {
        guard let raw else { return "-" }
        if let date = ISO8601DateFormatter.iso8601WithOptionalFraction.date(from: raw)
            ?? ISO8601DateFormatter().date(from: raw) {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "ko_KR")
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter.string(from: date)
        }
        if raw.count >= 10 {
            return String(raw.prefix(10))
        }
        return raw
    }

    static func timeLabel(from review: Review) -> String {
        if review.effectiveTimeType == "NONE" {
            return "기록안함"
        }
        let total = review.effectiveTimeInSeconds
        let minute = total / 60
        let second = total % 60
        return "\(minute)분\(second)초"
    }

    static func playTimeLine(from review: Review) -> String {
        let total = review.effectiveTimeInSeconds
        let minute = total / 60
        let second = total % 60
        let base = "\(minute)분 \(second)초"
        switch review.effectiveTimeType {
        case "RAMAINING":
            return "\(base) 남겼어요"
        case "NONE":
            return "기록 안함"
        default:
            return base
        }
    }
}

private struct MyReviewEditView: View {
    let review: Review
    let isSaving: Bool
    let onSave: (ReviewUpdateRequest) -> Void
    let onCancel: () -> Void

    @State private var visitDate: Date
    @State private var isVisitDateUnknown: Bool
    @State private var difficulty: Double
    @State private var minuteText: String
    @State private var secondText: String
    @State private var timeType: ReviewTimeType
    @State private var peopleText: String
    @State private var hintsText: String
    @State private var isHintsUnknown: Bool
    @State private var activityScore: Int
    @State private var scareScore: Int
    @State private var isSuccess: Bool
    @State private var content: String

    init(
        review: Review,
        isSaving: Bool,
        onSave: @escaping (ReviewUpdateRequest) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.review = review
        self.isSaving = isSaving
        self.onSave = onSave
        self.onCancel = onCancel

        let parsedVisitDate = MyReviewEditView.parseReviewDate(review.visitDate)
        _visitDate = State(initialValue: parsedVisitDate ?? Date())
        _isVisitDateUnknown = State(initialValue: parsedVisitDate == nil)
        _difficulty = State(initialValue: review.difficulty ?? 0)

        let total = review.effectiveTimeInSeconds
        _minuteText = State(initialValue: "\(total / 60)")
        _secondText = State(initialValue: "\(total % 60)")
        _timeType = State(initialValue: ReviewTimeType(rawValue: review.effectiveTimeType) ?? .elapsed)
        _peopleText = State(initialValue: "\(review.people ?? 0)")
        _hintsText = State(initialValue: "\(review.hints ?? 0)")
        _isHintsUnknown = State(initialValue: review.hints == nil)
        _activityScore = State(initialValue: review.activityScore ?? 0)
        _scareScore = State(initialValue: review.scareScore ?? 0)
        _isSuccess = State(initialValue: review.isSuccess ?? false)
        _content = State(initialValue: review.content ?? "")
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Group {
                    HStack {
                        Text("방문일")
                            .font(.system(size: 20, weight: .bold))
                        Spacer()
                        if !isVisitDateUnknown {
                            DatePicker("", selection: $visitDate, displayedComponents: .date)
                                .labelsHidden()
                        }
                        Toggle("기억 안나요", isOn: $isVisitDateUnknown)
                            .labelsHidden()
                            .toggleStyle(CheckboxToggleStyle())
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("체감 난이도")
                            .font(.system(size: 20, weight: .bold))
                        HStack {
                            Slider(value: $difficulty, in: 0...5, step: 0.5)
                            Text(String(format: "%.1f", difficulty))
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(.purple)
                                .frame(width: 40, alignment: .trailing)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("플레이타임")
                            .font(.system(size: 20, weight: .bold))
                        HStack(spacing: 8) {
                            TextField("분", text: $minuteText)
                                .keyboardType(.numberPad)
                                .textFieldStyle(.roundedBorder)
                            Text("분")
                            TextField("초", text: $secondText)
                                .keyboardType(.numberPad)
                                .textFieldStyle(.roundedBorder)
                            Text("초")
                        }
                        Picker("", selection: $timeType) {
                            ForEach(ReviewTimeType.allCases) { type in
                                Text(type.title).tag(type)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }

                Group {
                    HStack {
                        Text("플레이 인원")
                            .font(.system(size: 20, weight: .bold))
                        Spacer()
                        TextField("0", text: $peopleText)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                        Text("명")
                    }

                    HStack {
                        Text("사용 힌트 수")
                            .font(.system(size: 20, weight: .bold))
                        Spacer()
                        if !isHintsUnknown {
                            TextField("0", text: $hintsText)
                                .keyboardType(.numberPad)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 80)
                            Text("개")
                        }
                        Toggle("기록 안함", isOn: $isHintsUnknown)
                            .labelsHidden()
                            .toggleStyle(CheckboxToggleStyle())
                    }

                    ScoreSelector(title: "활동성", score: $activityScore)
                    ScoreSelector(title: "공포", score: $scareScore)
                }

                HStack(spacing: 10) {
                    Button("탈출했어요") {
                        isSuccess = true
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(isSuccess ? Color.purple.opacity(0.2) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(isSuccess ? Color.purple : Color(UIColor.systemGray4), lineWidth: 1)
                    )

                    Button("탈출 못했어요") {
                        isSuccess = false
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(!isSuccess ? Color.purple.opacity(0.2) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(!isSuccess ? Color.purple : Color(UIColor.systemGray4), lineWidth: 1)
                    )
                }
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Color("cod_gray"))

                VStack(alignment: .leading, spacing: 8) {
                    Text("리뷰")
                        .font(.system(size: 20, weight: .bold))
                    TextEditor(text: $content)
                        .frame(height: 120)
                        .padding(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(UIColor.systemGray4), lineWidth: 1)
                        )
                }

                Button("리뷰 작성 완료") {
                    onSave(buildRequest())
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)
                .background(Color("cod_gray"))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .disabled(isSaving)
            }
            .padding(16)
        }
        .navigationTitle("리뷰 수정")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: onCancel) {
                    Image(systemName: "chevron.left")
                        .foregroundStyle(Color("cod_gray"))
                }
                .disabled(isSaving)
            }
        }
    }

    private func buildRequest() -> ReviewUpdateRequest {
        let minute = max(0, Int(minuteText) ?? 0)
        let second = max(0, Int(secondText) ?? 0)
        let time = timeType == .none ? 0 : (minute * 60 + second)
        let hintsValue = isHintsUnknown ? 0 : max(0, Int(hintsText) ?? 0)

        return ReviewUpdateRequest(
            content: content,
            people: max(0, Int(peopleText) ?? 0),
            time: time,
            timeType: timeType.rawValue,
            scareScore: scareScore,
            activityScore: activityScore,
            difficulty: difficulty,
            hints: hintsValue,
            visitDate: isVisitDateUnknown ? nil : Self.serverDateFormatter.string(from: visitDate),
            isSuccess: isSuccess,
            themeId: nil
        )
    }

    private static func parseReviewDate(_ value: String?) -> Date? {
        guard let value else { return nil }
        if let date = ISO8601DateFormatter.iso8601WithOptionalFraction.date(from: value)
            ?? ISO8601DateFormatter().date(from: value) {
            return date
        }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: value)
    }

    private static var serverDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return formatter
    }
}

private struct ScoreSelector: View {
    let title: String
    @Binding var score: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 20, weight: .bold))
            HStack {
                ForEach(0...5, id: \.self) { number in
                    Button {
                        score = number
                    } label: {
                        HStack(spacing: 5) {
                            Circle()
                                .stroke(Color(UIColor.systemGray3), lineWidth: 1)
                                .frame(width: 14, height: 14)
                                .background(
                                    Circle()
                                        .fill(score == number ? Color.purple : Color.clear)
                                )
                            Text("\(number)")
                                .font(.system(size: 16, weight: .regular))
                                .foregroundStyle(Color("cod_gray"))
                        }
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
}

// MARK: - Inquiry
private struct InquiryView: View {
    @Environment(\.openURL) private var openURL
    @State private var showMailAlert = false

    var body: some View {
        List {
            Section("문의 채널") {
                Button("이메일 문의하기") {
                    guard let url = URL(string: "mailto:bangtal.boys.app@gmail.com") else {
                        showMailAlert = true
                        return
                    }
                    openURL(url)
                }
                Text("평일 10:00 - 18:00 순차 답변")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("앱 정보") {
                LabeledContent("앱 버전", value: appVersion)
                LabeledContent("문의 메일", value: "bangtal.boys.app@gmail.com")
            }
        }
        .navigationTitle("문의하기")
        .navigationBarTitleDisplayMode(.inline)
        .alert("메일 앱을 열 수 없어요.", isPresented: $showMailAlert) {
            Button("확인", role: .cancel) {}
        }
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "-"
        return "\(version) (\(build))"
    }
}

// MARK: - Notice
private struct NoticeListView: View {
    private let notices: [NoticeItem] = [
        .init(
            title: "방탈소년단 서비스 안내",
            date: "2026-02-15",
            content: "문의하기, 공지사항, 서비스 설정 화면이 새로 추가되었습니다."
        ),
        .init(
            title: "리뷰 관리 기능 업데이트",
            date: "2026-02-15",
            content: "내가 쓴 리뷰에서 수정/삭제 및 테마 상세 이동이 가능합니다."
        )
    ]

    var body: some View {
        List(notices) { notice in
            NavigationLink {
                NoticeDetailView(notice: notice)
            } label: {
                VStack(alignment: .leading, spacing: 6) {
                    Text(notice.title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color("cod_gray"))
                    Text(notice.date)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 6)
            }
        }
        .navigationTitle("공지사항")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct NoticeItem: Identifiable {
    let id = UUID()
    let title: String
    let date: String
    let content: String
}

private struct NoticeDetailView: View {
    let notice: NoticeItem

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text(notice.title)
                    .font(.system(size: 22, weight: .bold))
                Text(notice.date)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                Divider()
                Text(notice.content)
                    .font(.system(size: 16))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(16)
        }
        .navigationTitle("공지사항")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Service Settings
private struct ServiceSettingsView: View {
    @AppStorage("settings.push.enabled") private var isPushEnabled: Bool = true
    @AppStorage("settings.marketing.enabled") private var isMarketingEnabled: Bool = false
    @AppStorage("settings.location.enabled") private var isLocationEnabled: Bool = true

    var body: some View {
        List {
            Section("알림 설정") {
                Toggle("푸시 알림", isOn: $isPushEnabled)
                Toggle("마케팅 알림", isOn: $isMarketingEnabled)
            }

            Section("앱 권한") {
                Toggle("위치 기반 추천 사용", isOn: $isLocationEnabled)
            }

            Section("약관") {
                NavigationLink("서비스 이용약관") {
                    PolicyDetailView(
                        title: "서비스 이용약관",
                        content: "서비스 이용약관 전문은 추후 업데이트됩니다."
                    )
                }
                NavigationLink("개인정보 처리방침") {
                    PolicyDetailView(
                        title: "개인정보 처리방침",
                        content: "개인정보 처리방침 전문은 추후 업데이트됩니다."
                    )
                }
            }
        }
        .navigationTitle("서비스 설정")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct PolicyDetailView: View {
    let title: String
    let content: String

    var body: some View {
        ScrollView {
            Text(content)
                .font(.system(size: 16))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
