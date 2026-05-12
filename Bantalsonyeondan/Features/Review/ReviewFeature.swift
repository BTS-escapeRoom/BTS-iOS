import ComposableArchitecture
import Foundation

struct ReviewFeature: Reducer {
    struct State: Equatable {
        let themeId: Int
        var reviews: [Review] = []
        var isLoading: Bool = false
        var isUpdating: Bool = false
        var errorMessage: String?
    }

    enum Action {
        case fetchReviews
        case fetchReviewsResponse(Result<[Review], Error>)
        case createReview(ReviewRegist)
        case createReviewResponse(Result<Review, Error>)
        case deleteReview(reviewId: Int)
        case deleteReviewResponse(Result<Int, Error>)
        case updateReview(reviewId: Int, request: ReviewUpdateRequest)
        case updateReviewResponse(Result<Review, Error>)
    }

    @Dependency(\.reviewAPIClient) var reviewAPIClient

    func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .fetchReviews:
            state.isLoading = true
            return .run { [themeId = state.themeId] send in
                do {
                    let reviews = try await reviewAPIClient.getReviews("\(themeId)")
                    await send(.fetchReviewsResponse(.success(reviews)))
                } catch {
                    await send(.fetchReviewsResponse(.failure(error)))
                }
            }
        case let .fetchReviewsResponse(.success(reviews)):
            state.isLoading = false
            state.reviews = reviews
            return .none
        case let .fetchReviewsResponse(.failure(error)):
            state.isLoading = false
            state.errorMessage = error.localizedDescription
            return .none
        case let .createReview(reviewRegist):
            state.isLoading = true
            return .run { send in
                do {
                    let review = try await reviewAPIClient.createReviews(reviewRegist)
                    await send(.createReviewResponse(.success(review)))
                } catch {
                    await send(.createReviewResponse(.failure(error)))
                }
            }
        case let .createReviewResponse(.success(review)):
            state.isLoading = false
            state.reviews.insert(review, at: 0)
            return .none
        case let .createReviewResponse(.failure(error)):
            state.isLoading = false
            state.errorMessage = error.localizedDescription
            return .none

        case let .deleteReview(reviewId):
            return .run { send in
                do {
                    _ = try await reviewAPIClient.deleteReview(String(reviewId))
                    await send(.deleteReviewResponse(.success(reviewId)))
                } catch {
                    await send(.deleteReviewResponse(.failure(error)))
                }
            }

        case let .deleteReviewResponse(.success(reviewId)):
            state.reviews.removeAll { $0.id == reviewId }
            return .none

        case let .deleteReviewResponse(.failure(error)):
            state.errorMessage = error.localizedDescription
            return .none

        case let .updateReview(reviewId, request):
            state.isUpdating = true
            return .run { send in
                do {
                    let updated = try await reviewAPIClient.updateReview(String(reviewId), request: request)
                    await send(.updateReviewResponse(.success(updated)))
                } catch {
                    await send(.updateReviewResponse(.failure(error)))
                }
            }
        case let .updateReviewResponse(.success(updated)):
            state.isUpdating = false
            if let idx = state.reviews.firstIndex(where: { $0.id == updated.id }) {
                state.reviews[idx] = updated
            }
            return .none
        case let .updateReviewResponse(.failure(error)):
            state.isUpdating = false
            state.errorMessage = error.localizedDescription
            return .none
        }
    }
}
