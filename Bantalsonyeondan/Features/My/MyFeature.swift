import ComposableArchitecture
import Foundation

// MARK: - My Root Feature
struct MyFeature: Reducer {
    struct State: Equatable {
        var member: Member? = nil
        var histories: [ReviewHistory] = []
        var displayedReviewIds: Set<Int> = []
        var recruitBoardActivity = RecruitBoardActivityFeature.State()
        var myReviews = MyReviewsFeature.State()

        var isLoading: Bool = false
        var isUpdatingDisplay: Bool = false
        var didLoad: Bool = false
        var errorMessage: String? = nil

        var previewHistories: [ReviewHistory] {
            let displayedHistories = histories.filter { displayedReviewIds.contains($0.reviewId) }
            let source = displayedHistories.isEmpty ? histories : displayedHistories
            return Array(source.prefix(2))
        }
    }

    @CasePathable
    enum Action {
        case onAppear
        case memberResponse(Result<Member, Error>)
        case historyResponse(Result<[ReviewHistory], Error>)
        case toggleHistoryDisplay(reviewId: Int)
        case updateHistoryDisplayResponse(Result<String, Error>, previousDisplayedReviewIds: Set<Int>)
        case recruitBoardActivity(RecruitBoardActivityFeature.Action)
        case myReviews(MyReviewsFeature.Action)
        case logoutTapped
        case clearErrorMessage
        case delegate(Delegate)
    }

    @CasePathable
    enum Delegate {
        case logoutRequested
        case openThemeTab
    }

    @Dependency(\.memberAPIClient) var memberAPIClient
    @Dependency(\.reviewAPIClient) var reviewAPIClient

    var body: some ReducerOf<Self> {
        Scope(state: \.recruitBoardActivity, action: \.recruitBoardActivity) {
            RecruitBoardActivityFeature()
        }
        Scope(state: \.myReviews, action: \.myReviews) {
            MyReviewsFeature()
        }

        Reduce { state, action in
            switch action {
            case .onAppear:
                guard !state.didLoad else { return .none }

                state.didLoad = true
                state.isLoading = true

                return .run { send in
                    do {
                        let member = try await memberAPIClient.getMyMembers()
                        await send(.memberResponse(.success(member)))

                        do {
                            let histories = try await reviewAPIClient.getHistory(memberId: member.id)
                            await send(.historyResponse(.success(histories)))
                        } catch {
                            await send(.historyResponse(.failure(error)))
                        }
                    } catch {
                        await send(.memberResponse(.failure(error)))
                    }
                }

            case let .memberResponse(.success(member)):
                state.member = member
                AuthSessionStore.currentMember = member
                return .none

            case let .memberResponse(.failure(error)):
                state.isLoading = false
                state.didLoad = false
                state.errorMessage = error.localizedDescription
                return .none

            case let .historyResponse(.success(histories)):
                state.isLoading = false
                state.histories = histories
                state.displayedReviewIds = Set(histories.filter(\.isDisplay).map(\.reviewId))
                syncDisplayedFlag(&state)
                return .none

            case let .historyResponse(.failure(error)):
                state.isLoading = false
                state.didLoad = false
                state.histories = []
                state.displayedReviewIds = []
                state.errorMessage = error.localizedDescription
                return .none

            case let .toggleHistoryDisplay(reviewId):
                guard let history = state.histories.first(where: { $0.reviewId == reviewId }) else {
                    return .none
                }
                guard history.canUpdateDisplay else {
                    state.errorMessage = "이 기록은 미노출 설정을 변경할 수 없어요."
                    return .none
                }

                let previousDisplayedReviewIds = state.displayedReviewIds
                toggleDisplay(reviewId: reviewId, state: &state)
                syncDisplayedFlag(&state)
                state.isUpdatingDisplay = true
                let reviewIds = displayedReviewIdsForUpdate(from: state)

                return .run { send in
                    do {
                        let message = try await reviewAPIClient.updateHistoryDisplay(reviewIds: reviewIds)
                        await send(
                            .updateHistoryDisplayResponse(
                                .success(message),
                                previousDisplayedReviewIds: previousDisplayedReviewIds
                            )
                        )
                    } catch {
                        await send(
                            .updateHistoryDisplayResponse(
                                .failure(error),
                                previousDisplayedReviewIds: previousDisplayedReviewIds
                            )
                        )
                    }
                }

            case .updateHistoryDisplayResponse(.success, _):
                state.isUpdatingDisplay = false
                return .none

            case let .updateHistoryDisplayResponse(.failure(error), previousDisplayedReviewIds):
                state.isUpdatingDisplay = false
                state.displayedReviewIds = previousDisplayedReviewIds
                syncDisplayedFlag(&state)
                state.errorMessage = error.localizedDescription
                return .none

            case .recruitBoardActivity:
                return .none

            case .myReviews(.delegate(.openThemeTab)):
                return .send(.delegate(.openThemeTab))

            case .myReviews:
                return .none

            case .logoutTapped:
                return .send(.delegate(.logoutRequested))

            case .clearErrorMessage:
                state.errorMessage = nil
                return .none

            case .delegate:
                return .none
            }
        }
    }

    private func syncDisplayedFlag(_ state: inout State) {
        state.histories = state.histories.map { history in
            var mutableHistory = history
            mutableHistory.isDisplay = state.displayedReviewIds.contains(history.reviewId)
            return mutableHistory
        }
    }

    private func toggleDisplay(reviewId: Int, state: inout State) {
        if state.displayedReviewIds.contains(reviewId) {
            state.displayedReviewIds.remove(reviewId)
        } else {
            state.displayedReviewIds.insert(reviewId)
        }
    }

    private func displayedReviewIdsForUpdate(from state: State) -> [Int] {
        state.histories
            .filter { $0.canUpdateDisplay && state.displayedReviewIds.contains($0.reviewId) }
            .map(\.reviewId)
            .sorted()
    }
}

// MARK: - My Reviews Feature
struct MyReviewItem: Equatable, Identifiable {
    let review: Review
    let themeTitle: String
    let storeName: String
    let isEscaped: Bool

    var id: Int { review.id }

    func updating(review: Review) -> MyReviewItem {
        MyReviewItem(
            review: review,
            themeTitle: themeTitle,
            storeName: storeName,
            isEscaped: isEscaped
        )
    }
}

private enum MyReviewError: LocalizedError {
    case emptyThemeKeyword
    case themeNotFound

    var errorDescription: String? {
        switch self {
        case .emptyThemeKeyword:
            return "테마 정보를 찾을 수 없어요."
        case .themeNotFound:
            return "연결된 테마 상세 정보를 찾지 못했어요."
        }
    }
}

struct MyReviewsFeature: Reducer {
    struct State: Equatable {
        var items: [MyReviewItem] = []
        var selectedThemeDetail: ThemeDetail? = nil
        var editingReview: Review? = nil
        var isLoading: Bool = false
        var isProcessing: Bool = false
        var didLoad: Bool = false
        var errorMessage: String? = nil
    }

    @CasePathable
    enum Action {
        case onAppear
        case reload
        case loadResponse(Result<[MyReviewItem], Error>)
        case themeTapped(reviewId: Int)
        case themeDetailResponse(Result<ThemeDetail, Error>)
        case dismissThemeDetail
        case requestEdit(reviewId: Int)
        case dismissEdit
        case saveEditedReview(reviewId: Int, request: ReviewUpdateRequest)
        case saveEditedReviewResponse(Result<Review, Error>)
        case requestDelete(reviewId: Int)
        case deleteResponse(Result<Int, Error>)
        case tapExploreThemes
        case clearErrorMessage
        case delegate(Delegate)
    }

    @CasePathable
    enum Delegate {
        case openThemeTab
    }

    @Dependency(\.reviewAPIClient) var reviewAPIClient
    @Dependency(\.memberAPIClient) var memberAPIClient
    @Dependency(\.themeAPIClient) var themeAPIClient

    func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .onAppear:
            guard !state.didLoad else { return .none }
            return .send(.reload)

        case .reload:
            state.didLoad = true
            state.isLoading = true
            state.errorMessage = nil
            return .run { send in
                do {
                    let items = try await loadMyReviewItems()
                    await send(.loadResponse(.success(items)))
                } catch {
                    await send(.loadResponse(.failure(error)))
                }
            }

        case let .loadResponse(.success(items)):
            state.isLoading = false
            state.items = items
            return .none

        case let .loadResponse(.failure(error)):
            state.isLoading = false
            state.errorMessage = error.localizedDescription
            return .none

        case let .themeTapped(reviewId):
            guard let item = state.items.first(where: { $0.id == reviewId }) else {
                return .none
            }
            state.errorMessage = nil

            let keyword = item.themeTitle.trimmingCharacters(in: .whitespacesAndNewlines)
            return .run { send in
                do {
                    let detail = try await fetchThemeDetail(withTitle: keyword)
                    await send(.themeDetailResponse(.success(detail)))
                } catch {
                    await send(.themeDetailResponse(.failure(error)))
                }
            }

        case let .themeDetailResponse(.success(detail)):
            state.selectedThemeDetail = detail
            return .none

        case let .themeDetailResponse(.failure(error)):
            state.errorMessage = error.localizedDescription
            return .none

        case .dismissThemeDetail:
            state.selectedThemeDetail = nil
            return .none

        case let .requestEdit(reviewId):
            state.editingReview = state.items.first(where: { $0.id == reviewId })?.review
            return .none

        case .dismissEdit:
            state.editingReview = nil
            return .none

        case let .saveEditedReview(reviewId, request):
            state.isProcessing = true
            return .run { send in
                do {
                    let review = try await reviewAPIClient.updateReview("\(reviewId)", request: request)
                    await send(.saveEditedReviewResponse(.success(review)))
                } catch {
                    await send(.saveEditedReviewResponse(.failure(error)))
                }
            }

        case let .saveEditedReviewResponse(.success(review)):
            state.isProcessing = false
            state.editingReview = nil
            if let index = state.items.firstIndex(where: { $0.id == review.id }) {
                state.items[index] = state.items[index].updating(review: review)
            }
            return .none

        case let .saveEditedReviewResponse(.failure(error)):
            state.isProcessing = false
            state.errorMessage = error.localizedDescription
            return .none

        case let .requestDelete(reviewId):
            state.isProcessing = true
            return .run { send in
                do {
                    _ = try await reviewAPIClient.deleteReview("\(reviewId)")
                    await send(.deleteResponse(.success(reviewId)))
                } catch {
                    await send(.deleteResponse(.failure(error)))
                }
            }

        case let .deleteResponse(.success(reviewId)):
            state.isProcessing = false
            state.items.removeAll(where: { $0.id == reviewId })
            return .none

        case let .deleteResponse(.failure(error)):
            state.isProcessing = false
            state.errorMessage = error.localizedDescription
            return .none

        case .tapExploreThemes:
            return .send(.delegate(.openThemeTab))

        case .clearErrorMessage:
            state.errorMessage = nil
            return .none

        case .delegate:
            return .none
        }
    }

    private func loadMyReviewItems() async throws -> [MyReviewItem] {
        let reviews = try await reviewAPIClient.getMyReviews()
        let historyByReviewId = await fetchHistoryByReviewId()

        return reviews
            .sorted(by: { $0.id > $1.id })
            .map { review in
                let history = historyByReviewId[review.id]
                return MyReviewItem(
                    review: review,
                    themeTitle: history?.themeTitle ?? "테마 정보 없음",
                    storeName: history?.storeName ?? "",
                    isEscaped: history?.isSuccess ?? (review.isSuccess ?? false)
                )
            }
    }

    private func fetchHistoryByReviewId() async -> [Int: ReviewHistory] {
        guard let member = try? await memberAPIClient.getMyMembers(),
              let histories = try? await reviewAPIClient.getHistory(memberId: member.id) else {
            return [:]
        }
        return Dictionary(uniqueKeysWithValues: histories.map { ($0.reviewId, $0) })
    }

    private func fetchThemeDetail(withTitle title: String) async throws -> ThemeDetail {
        guard !title.isEmpty else {
            throw MyReviewError.emptyThemeKeyword
        }

        let themes = try await themeAPIClient.fetchThemes(ThemeRequest(keyword: title, page: 1)).themes
        guard let target = themes.first(where: { $0.title == title }) ?? themes.first else {
            throw MyReviewError.themeNotFound
        }
        return try await themeAPIClient.fetchThemeById("\(target.id)")
    }
}
