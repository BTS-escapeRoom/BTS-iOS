import ComposableArchitecture
import Foundation

struct ReviewFeature: Reducer {
    struct State: Equatable {
        let themeId: Int
        var reviews: [Review] = []
        var isLoading: Bool = false
        var errorMessage: String?
    }

    enum Action {
        case fetchReviews
        case fetchReviewsResponse(Result<[Review], Error>)
        case createReview(ReviewRegist)
        case createReviewResponse(Result<Review, Error>)
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
        }
    }
}
