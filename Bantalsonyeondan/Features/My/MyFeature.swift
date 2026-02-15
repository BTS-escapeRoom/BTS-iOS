import ComposableArchitecture
import Foundation

// MARK: - State
struct MyFeature: Reducer {
    struct State: Equatable {
        var member: Member? = nil
        var histories: [ReviewHistory] = []
        var displayedReviewIds: Set<Int> = []
        var recruitBoardActivity = RecruitBoardActivityFeature.State()

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
        case clearErrorMessage
    }

    @Dependency(\.memberAPIClient) var memberAPIClient
    @Dependency(\.reviewAPIClient) var reviewAPIClient

    var body: some ReducerOf<Self> {
        Scope(state: \.recruitBoardActivity, action: \.recruitBoardActivity) {
            RecruitBoardActivityFeature()
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

                if state.displayedReviewIds.contains(reviewId) {
                    state.displayedReviewIds.remove(reviewId)
                } else {
                    state.displayedReviewIds.insert(reviewId)
                }

                syncDisplayedFlag(&state)
                state.isUpdatingDisplay = true
                let reviewIds = state.histories
                    .filter { $0.canUpdateDisplay && state.displayedReviewIds.contains($0.reviewId) }
                    .map(\.reviewId)
                    .sorted()

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

            case .clearErrorMessage:
                state.errorMessage = nil
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
}
