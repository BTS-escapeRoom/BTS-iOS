import SwiftUI
import ComposableArchitecture

private enum ReviewFormTimeType: String, CaseIterable, Identifiable {
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

private struct ReviewFormDraft {
    let content: String
    let people: Int
    let time: Int
    let timeType: String
    let scareScore: Int
    let activityScore: Int
    let difficulty: Double
    let hints: Int
    let visitDate: String?
    let isSuccess: Bool
    let isRecommend: Bool

    func makeCreateRequest(themeId: Int) -> ReviewRegist {
        ReviewRegist(
            content: content,
            people: people,
            time: time,
            scareScore: scareScore,
            activityScore: activityScore,
            difficulty: Int(difficulty.rounded()),
            hints: hints,
            visitDate: visitDate ?? "",
            isSuccess: isSuccess,
            themeId: themeId
        )
    }

    func makeUpdateRequest(themeId: Int? = nil) -> ReviewUpdateRequest {
        ReviewUpdateRequest(
            content: content,
            people: people,
            time: time,
            timeType: timeType,
            scareScore: scareScore,
            activityScore: activityScore,
            difficulty: difficulty,
            hints: hints,
            visitDate: visitDate,
            isSuccess: isSuccess,
            themeId: themeId
        )
    }
}

struct ReviewWriteView: View {
    private enum Mode {
        case create(
            store: StoreOf<ReviewFeature>,
            themeId: Int,
            onComplete: (() -> Void)?
        )
        case edit(
            isSubmitting: Bool,
            onSubmitEdit: (ReviewUpdateRequest) -> Void,
            onCancel: () -> Void
        )
    }

    private let mode: Mode

    @State private var visitDate: Date
    @State private var isVisitDateUnknown: Bool
    @State private var difficulty: Double
    @State private var minuteText: String
    @State private var secondText: String
    @State private var timeType: ReviewFormTimeType
    @State private var peopleText: String
    @State private var hintsText: String
    @State private var isHintsUnknown: Bool
    @State private var activityScore: Int
    @State private var scareScore: Int
    @State private var isSuccess: Bool
    @State private var content: String
    @State private var isRecommend: Bool

    @State private var hasSubmittedCreate: Bool = false
    @State private var createErrorMessage: String? = nil

    init(
        store: StoreOf<ReviewFeature>,
        themeId: Int,
        onComplete: (() -> Void)? = nil
    ) {
        self.mode = .create(store: store, themeId: themeId, onComplete: onComplete)
        _visitDate = State(initialValue: Date())
        _isVisitDateUnknown = State(initialValue: false)
        _difficulty = State(initialValue: 0.5)
        _minuteText = State(initialValue: "")
        _secondText = State(initialValue: "")
        _timeType = State(initialValue: .elapsed)
        _peopleText = State(initialValue: "")
        _hintsText = State(initialValue: "")
        _isHintsUnknown = State(initialValue: false)
        _activityScore = State(initialValue: 0)
        _scareScore = State(initialValue: 0)
        _isSuccess = State(initialValue: false)
        _content = State(initialValue: "")
        _isRecommend = State(initialValue: false)
    }

    init(
        review: Review,
        isSubmitting: Bool,
        onSubmitEdit: @escaping (ReviewUpdateRequest) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.mode = .edit(
            isSubmitting: isSubmitting,
            onSubmitEdit: onSubmitEdit,
            onCancel: onCancel
        )
        let parsedVisitDate = Self.parseReviewDate(review.visitDate)
        let totalSeconds = review.effectiveTimeInSeconds

        _visitDate = State(initialValue: parsedVisitDate ?? Date())
        _isVisitDateUnknown = State(initialValue: parsedVisitDate == nil)
        _difficulty = State(initialValue: review.difficulty ?? 0)
        _minuteText = State(initialValue: "\(totalSeconds / 60)")
        _secondText = State(initialValue: "\(totalSeconds % 60)")
        _timeType = State(initialValue: ReviewFormTimeType(rawValue: review.effectiveTimeType) ?? .elapsed)
        _peopleText = State(initialValue: "\(review.people ?? 0)")
        _hintsText = State(initialValue: "\(review.hints ?? 0)")
        _isHintsUnknown = State(initialValue: review.hints == nil)
        _activityScore = State(initialValue: review.activityScore ?? 0)
        _scareScore = State(initialValue: review.scareScore ?? 0)
        _isSuccess = State(initialValue: review.isSuccess ?? false)
        _content = State(initialValue: review.content ?? "")
        _isRecommend = State(initialValue: review.isSuccess ?? false)
    }

    var body: some View {
        switch mode {
        case let .create(store, themeId, onComplete):
            WithViewStore(store, observe: \.self) { viewStore in
                formBody(
                    title: "리뷰 작성",
                    isSubmitting: viewStore.isLoading,
                    onCancel: nil,
                    onSubmit: { draft in
                        hasSubmittedCreate = true
                        viewStore.send(.createReview(draft.makeCreateRequest(themeId: themeId)))
                    }
                )
                .onChange(of: viewStore.isLoading) { isLoading in
                    guard hasSubmittedCreate, !isLoading else { return }
                    if let error = viewStore.errorMessage, !error.isEmpty {
                        createErrorMessage = error
                    } else {
                        onComplete?()
                    }
                    hasSubmittedCreate = false
                }
                .alert(
                    "리뷰 등록 실패",
                    isPresented: Binding(
                        get: { createErrorMessage != nil },
                        set: { isPresented in
                            if !isPresented {
                                createErrorMessage = nil
                            }
                        }
                    )
                ) {
                    Button("확인", role: .cancel) {
                        createErrorMessage = nil
                    }
                } message: {
                    Text(createErrorMessage ?? "")
                }
            }

        case let .edit(isSubmitting, onSubmitEdit, onCancel):
            formBody(
                title: "리뷰 수정",
                isSubmitting: isSubmitting,
                onCancel: onCancel,
                onSubmit: { draft in
                    onSubmitEdit(draft.makeUpdateRequest(themeId: nil))
                }
            )
        }
    }

    private func formBody(
        title: String,
        isSubmitting: Bool,
        onCancel: (() -> Void)?,
        onSubmit: @escaping (ReviewFormDraft) -> Void
    ) -> some View {
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
                            .toggleStyle(ReviewCheckboxToggleStyle())
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
                            ForEach(ReviewFormTimeType.allCases) { type in
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
                            .toggleStyle(ReviewCheckboxToggleStyle())
                    }

                    ReviewScoreSelector(title: "활동성", score: $activityScore)
                    ReviewScoreSelector(title: "공포", score: $scareScore)
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
                        .overlay(alignment: .topLeading) {
                            if content.isEmpty {
                                Text("테마 후기를 남겨주세요.")
                                    .font(.system(size: 14))
                                    .foregroundStyle(Color(UIColor.systemGray3))
                                    .padding(.top, 14)
                                    .padding(.leading, 12)
                            }
                        }
                }

                HStack {
                    Toggle("이 테마 추천하기", isOn: $isRecommend)
                        .toggleStyle(ReviewCheckboxToggleStyle())
                    if isRecommend {
                        Label("추천해요!", systemImage: "hand.thumbsup.fill")
                            .foregroundColor(.purple)
                    }
                }

                Button("리뷰 작성 완료") {
                    onSubmit(buildDraft())
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)
                .background(Color("cod_gray"))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .disabled(isSubmitting)
            }
            .padding(16)
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let onCancel {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: onCancel) {
                        Image(systemName: "chevron.left")
                            .foregroundStyle(Color("cod_gray"))
                    }
                    .disabled(isSubmitting)
                }
            }
        }
    }

    private func buildDraft() -> ReviewFormDraft {
        let minute = max(0, Int(minuteText) ?? 0)
        let second = max(0, Int(secondText) ?? 0)
        let resolvedTimeType = timeType
        let resolvedTime = resolvedTimeType == .none ? 0 : (minute * 60 + second)
        let resolvedHints = isHintsUnknown ? 0 : max(0, Int(hintsText) ?? 0)

        return ReviewFormDraft(
            content: content,
            people: max(0, Int(peopleText) ?? 0),
            time: resolvedTime,
            timeType: resolvedTimeType.rawValue,
            scareScore: scareScore,
            activityScore: activityScore,
            difficulty: difficulty,
            hints: resolvedHints,
            visitDate: isVisitDateUnknown ? nil : Self.serverDateFormatter.string(from: visitDate),
            isSuccess: isSuccess,
            isRecommend: isRecommend
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

private struct ReviewScoreSelector: View {
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

struct ReviewCheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                .foregroundColor(configuration.isOn ? .purple : .gray)
                .onTapGesture { configuration.isOn.toggle() }
        }
    }
}
