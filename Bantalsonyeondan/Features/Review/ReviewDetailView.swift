import SwiftUI
import ComposableArchitecture

struct ReviewDetailView: View {
    
    let store: StoreOf<ReviewFeature>
    @State private var showWriteFullScreen = false
    
    var body: some View {
        WithViewStore(store, observe: \.self) { viewStore in
            ZStack {
                VStack {
                    if viewStore.isLoading {
                        ProgressView()
                    } else if let errorMessage = viewStore.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    } else if !viewStore.reviews.isEmpty {
                        List(viewStore.reviews, id: \.id) { review in
                            ReviewRowView(review: review)
                        }
                        .listStyle(PlainListStyle())
                    } else {
                        Text("아직 작성된 리뷰가 없어요.\n첫번째 리뷰의 주인공이 되어보세요!")
                    }
                }
                .onAppear {
                    viewStore.send(.fetchReviews)
                }
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            showWriteFullScreen = true
                        }) {
                            HStack(spacing: 8) {
                                Text("리뷰 작성")
                                    .foregroundColor(.white)
                                    .font(.headline)
                                Image(systemName: "plus")
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color(.darkGray))
                            .cornerRadius(24)
                            .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 32)
                        .fullScreenCover(isPresented: $showWriteFullScreen) {
                            NavigationView {
                                ReviewWriteView(
                                    store: self.store,
                                    themeId: viewStore.themeId,
                                    onComplete: {
                                        showWriteFullScreen = false
                                    }
                                )
                                .navigationBarTitleDisplayMode(.inline)
                                .toolbar {
                                    ToolbarItem(placement: .navigationBarLeading) {
                                        Button(action: { showWriteFullScreen = false }) {
                                            Image(systemName: "chevron.left")
                                                .foregroundColor(.black)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

private struct ReviewRowView: View {
    let review: Review
    
    // 날짜 포맷 변환 함수
    func formattedDate(_ dateString: String?) -> String {
        guard let dateString = dateString else { return "" }
        let isoFormatter = ISO8601DateFormatter()
        if let date = isoFormatter.date(from: dateString) {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy.MM.dd"
            return formatter.string(from: date)
        }
        // 혹시 기존 yyyy-MM-dd 형식이면 그대로 반환
        if dateString.count >= 10 {
            return String(dateString.prefix(10)).replacingOccurrences(of: "-", with: ".")
        }
        return dateString
    }
    // time(초) -> 분 변환
    func formattedTime(_ time: Int?) -> String {
        guard let time = time else { return "" }
        if time > 300 { // 5분 이상이면 초 단위로 온 것으로 간주
            return "\(time / 60)분"
        } else {
            return "\(time)분"
        }
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                if review.isMyReview == true {
                    Image("내가 쓴 리뷰")
                }
                
                if let isSuccess = review.isSuccess {
                    if isSuccess {
                        Image("탈출성공")
                    } else {
                        Image("탈출실패")
                    }
                }

                Spacer()
                if let nickname = review.nickname {
                    Text(nickname)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            // 주요 정보
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 12) {
                    if let difficulty = review.difficulty {
                        Text("난이도: \(String(format: "%.1f", difficulty))")
                    }
                    if let activityScore = review.activityScore {
                        Text("활동성: \(activityScore)")
                    }
                    if let scareScore = review.scareScore {
                        Text("공포도: \(scareScore)")
                    }
                }
                .font(.subheadline)
                
                HStack(spacing: 12) {
                    if let people = review.people {
                        Text("플레이원: \(people)명")
                    }
                    if let time = review.time {
                        Divider()
                        Text(formattedTime(time))
                    }
                }
                .font(.subheadline)
                
                if let visitDate = review.visitDate {
                    Text("방문일: \(formattedDate(visitDate))")
                        .font(.subheadline)
                }
            }
            // 리뷰 내용
            if let content = review.content {
                Text(content)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.body)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.osloGray.opacity(0.05))
                    )
            }
        }
    }
}

#Preview {
    NavigationView {
        ReviewDetailView(
            store: Store(
                initialState: ReviewFeature.State(
                    themeId: 1,
                    reviews: [
                        Review(id: 1, content: "너무 재밌었어요! 다음에 또 하고 싶네요.", people: 2, time: 60, difficulty: 3, scareScore: 4, activityScore: 5, visitDate: "2024-07-10", hints: 2, isSuccess: true, createdAt: "2024-07-10", isMyReview: true, nickname: "ㅂㅂ"),
                        Review(id: 2, content: "조금 어려웠지만 그래도 만족합니다.", people: 4, time: 75, difficulty: 5, scareScore: 2, activityScore: 3, visitDate: "2024-07-09", hints: 4, isSuccess: false, createdAt: "2024-07-09", isMyReview: false, nickname: "hh")
                    ]
                ),
                reducer: {
                    ReviewFeature()
                }
            )
        )
    }
}
