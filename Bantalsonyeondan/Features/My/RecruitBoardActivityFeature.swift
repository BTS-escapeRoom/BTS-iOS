import ComposableArchitecture
import SwiftUI

struct RecruitBoardActivityFeature: Reducer {
    enum Tab: String, CaseIterable, Equatable, Identifiable {
        case myPosts
        case commentedPosts
        case likedPosts

        var id: String { rawValue }

        var title: String {
            switch self {
            case .myPosts:
                return "나의 게시글"
            case .commentedPosts:
                return "댓글단 글"
            case .likedPosts:
                return "관심 글"
            }
        }

        var emptyMessage: String {
            switch self {
            case .myPosts:
                return "첫번째 모집글을 작성해서 함께 할 사람을 찾아보세요."
            case .commentedPosts:
                return "아직 댓글 단 글이 없어요."
            case .likedPosts:
                return "아직 관심글이 없어요."
            }
        }
    }

    struct State: Equatable {
        var selectedTab: Tab = .myPosts
        var sortOption: SortOption = .latest
        var myBoards: [Board] = []
        var commentedBoards: [Board] = []
        var likedBoards: [Board] = []
        var isLoading: Bool = false
        var errorMessage: String? = nil
    }

    enum Action {
        case onAppear
        case reload
        case setTab(Tab)
        case setSortOption(SortOption)
        case myBoardsResponse(Result<[Board], Error>)
        case commentedBoardsResponse(Result<[Board], Error>)
        case likedBoardsResponse(Result<[Board], Error>)
        case initialLoadFinished
        case clearErrorMessage
    }

    @Dependency(\.boardAPIClient) var boardAPIClient
    @Dependency(\.commentAPIClient) var commentAPIClient

    func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .onAppear:
            return .send(.reload)

        case .reload:
            guard !state.isLoading else { return .none }
            state.isLoading = true
            state.errorMessage = nil

            let boardAPIClient = self.boardAPIClient
            return .run { send in
                async let myResult: Result<[Board], Error> = {
                    do {
                        return .success(try await boardAPIClient.getMyBoards())
                    } catch {
                        return .failure(error)
                    }
                }()

                async let likedResult: Result<[Board], Error> = {
                    do {
                        return .success(try await boardAPIClient.getLikedBoards())
                    } catch {
                        return .failure(error)
                    }
                }()

                async let commentedResult: Result<[Board], Error> = {
                    do {
                        return .success(
                            try await loadCommentedBoards(
                                boardAPIClient: boardAPIClient,
                                commentAPIClient: commentAPIClient
                            )
                        )
                    } catch {
                        return .failure(error)
                    }
                }()

                await send(.myBoardsResponse(await myResult))
                await send(.commentedBoardsResponse(await commentedResult))
                await send(.likedBoardsResponse(await likedResult))
                await send(.initialLoadFinished)
            }

        case let .setTab(tab):
            state.selectedTab = tab
            return .none

        case let .setSortOption(option):
            state.sortOption = option
            return .none

        case let .myBoardsResponse(.success(boards)):
            state.myBoards = boards
            return .none

        case let .myBoardsResponse(.failure(error)):
            state.myBoards = []
            if state.errorMessage == nil {
                state.errorMessage = error.localizedDescription
            }
            return .none

        case let .commentedBoardsResponse(.success(boards)):
            state.commentedBoards = boards
            return .none

        case let .commentedBoardsResponse(.failure(error)):
            state.commentedBoards = []
            if state.errorMessage == nil {
                state.errorMessage = error.localizedDescription
            }
            return .none

        case let .likedBoardsResponse(.success(boards)):
            state.likedBoards = boards
            return .none

        case let .likedBoardsResponse(.failure(error)):
            state.likedBoards = []
            if state.errorMessage == nil {
                state.errorMessage = error.localizedDescription
            }
            return .none

        case .initialLoadFinished:
            state.isLoading = false
            return .none

        case .clearErrorMessage:
            state.errorMessage = nil
            return .none
        }
    }

    private func loadCommentedBoards(
        boardAPIClient: BoardAPIClient,
        commentAPIClient: CommentAPIClient
    ) async throws -> [Board] {
        guard let memberId = AuthSessionStore.currentSession?.memberId else {
            return []
        }

        // 전용 API가 없어서 모집글 전체를 순회하면서 댓글 작성 여부를 역으로 계산
        var allBoards: [Board] = []
        var nextPage = 1

        while nextPage > 0 {
            let response = try await boardAPIClient.getBoards(
                BoardRequest(
                    keyword: nil,
                    type: "recruit",
                    sortType: .latest,
                    page: nextPage
                )
            )
            allBoards += response.boards
            nextPage = response.nextPage
        }

        if allBoards.isEmpty { return [] }

        let candidates = allBoards.filter { $0.commentCount > 0 }
        if candidates.isEmpty { return [] }

        var boardIdsCommentedByMe = Set<Int>()

        for board in candidates {
            let comments = try await commentAPIClient.getComments(boardId: "\(board.id)")
            if comments.comments.contains(where: { $0.memberId == memberId }) {
                boardIdsCommentedByMe.insert(board.id)
            }
        }

        return allBoards.filter { boardIdsCommentedByMe.contains($0.id) }
    }
}

struct RecruitBoardActivityView: View {
    let store: StoreOf<RecruitBoardActivityFeature>

    var body: some View {
        WithViewStore(store, observe: \.self) { viewStore in
            VStack(spacing: 0) {
                tabHeader(viewStore: viewStore)

                let boards = sortedBoards(
                    sourceBoards(for: viewStore.selectedTab, in: viewStore),
                    by: viewStore.sortOption
                )

                if viewStore.isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if boards.isEmpty {
                    Spacer()
                    Text(viewStore.selectedTab.emptyMessage)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Color(UIColor.systemGray3))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                    Spacer()
                } else {
                    sortBar(viewStore: viewStore)
                    Divider()
                        .padding(.top, 8)

                    ScrollView {
                        LazyVStack(spacing: 14) {
                            ForEach(boards) { board in
                                NavigationLink {
                                    BoardDetailView(
                                        store: Store(
                                            initialState: BoardDetailFeature.State(
                                                boardId: board.id,
                                                board: board
                                            )
                                        ) {
                                            BoardDetailFeature()
                                        },
                                        onBoardChanged: {
                                            viewStore.send(.reload)
                                        }
                                    )
                                } label: {
                                    RecruitBoardActivityCard(board: board)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 14)
                    }
                }
            }
            .navigationTitle("모집게시판")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                viewStore.send(.onAppear)
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
        }
    }

    private func tabHeader(viewStore: ViewStoreOf<RecruitBoardActivityFeature>) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(RecruitBoardActivityFeature.Tab.allCases) { tab in
                    Button {
                        viewStore.send(.setTab(tab))
                    } label: {
                        Text(tab.title)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(
                                viewStore.selectedTab == tab
                                ? Color("cod_gray")
                                : Color(UIColor.systemGray3)
                            )
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }
                    .buttonStyle(.plain)
                }
            }

            HStack(spacing: 0) {
                ForEach(RecruitBoardActivityFeature.Tab.allCases) { tab in
                    Rectangle()
                        .fill(
                            viewStore.selectedTab == tab
                            ? Color("cod_gray")
                            : Color.clear
                        )
                        .frame(maxWidth: .infinity)
                        .frame(height: 1)
                }
            }

            Divider()
        }
    }

    private func sortBar(viewStore: ViewStoreOf<RecruitBoardActivityFeature>) -> some View {
        HStack {
            Spacer()
            Menu {
                ForEach(SortOption.communityOptions) { option in
                    Button(option.displayName) {
                        viewStore.send(.setSortOption(option))
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Text(viewStore.sortOption.displayName)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color("cod_gray"))
                    Image("polygon")
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }

    private func sourceBoards(
        for tab: RecruitBoardActivityFeature.Tab,
        in viewStore: ViewStoreOf<RecruitBoardActivityFeature>
    ) -> [Board] {
        switch tab {
        case .myPosts:
            return viewStore.myBoards
        case .commentedPosts:
            return viewStore.commentedBoards
        case .likedPosts:
            return viewStore.likedBoards
        }
    }

    private func sortedBoards(_ boards: [Board], by sortOption: SortOption) -> [Board] {
        switch sortOption {
        case .popular:
            return boards.sorted { lhs, rhs in
                lhs.likeCount > rhs.likeCount
            }
        case .viewed:
            return boards.sorted { lhs, rhs in
                lhs.hit > rhs.hit
            }
        case .old:
            return boards.sorted { lhs, rhs in
                createdAt(from: lhs.createdAt) < createdAt(from: rhs.createdAt)
            }
        case .latest:
            return boards.sorted { lhs, rhs in
                createdAt(from: lhs.createdAt) > createdAt(from: rhs.createdAt)
            }
        default:
            return boards
        }
    }

    private func createdAt(from value: String?) -> Date {
        guard let value = value else { return .distantPast }
        return ISO8601DateFormatter.iso8601WithOptionalFraction.date(from: value)
            ?? ISO8601DateFormatter().date(from: value)
            ?? .distantPast
    }
}

private struct RecruitBoardActivityCard: View {
    let board: Board

    private var deadlineStatus: (text: String, isUrgent: Bool, isClosed: Bool) {
        guard
            let recruitDeadline = board.recruitDeadline,
            let date = ISO8601DateFormatter.iso8601WithOptionalFraction.date(from: recruitDeadline)
                ?? ISO8601DateFormatter().date(from: recruitDeadline)
        else {
            return ("모집중", false, false)
        }

        let interval = date.timeIntervalSinceNow
        if interval <= 0 {
            return ("모집 마감", false, true)
        }

        if interval <= 60 * 60 * 24 {
            return ("0시간 전", true, false)
        }

        let days = max(1, Int(ceil(interval / (60 * 60 * 24))))
        return ("마감 \(days)일 전", false, false)
    }

    private var escapeDateText: String {
        guard
            let escapeDate = board.escapeDate,
            let date = ISO8601DateFormatter.iso8601WithOptionalFraction.date(from: escapeDate)
                ?? ISO8601DateFormatter().date(from: escapeDate)
        else {
            return "탈출일자 미정"
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy년 MM월 dd일 a h시 mm분"
        return formatter.string(from: date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                HStack(spacing: 4) {
                    if deadlineStatus.isUrgent {
                        Image(systemName: "clock.badge.exclamationmark")
                            .font(.caption2)
                    }
                    Text(deadlineStatus.text)
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundStyle(
                    deadlineStatus.isClosed
                        ? Color(UIColor.systemGray)
                        : (deadlineStatus.isUrgent ? Color.red : Color(UIColor.systemGray))
                )
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(
                    deadlineStatus.isClosed
                        ? Color(UIColor.systemGray6)
                        : Color(UIColor.systemGray5)
                )
                .clipShape(RoundedRectangle(cornerRadius: 6))

                if board.isPopular {
                    Text("인기글")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }

                Spacer()
            }

            Text(board.title)
                .font(.system(size: 20, weight: .bold))
                .lineLimit(2)
                .foregroundStyle(Color("cod_gray"))

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(board.themeName ?? "테마 미정")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color(UIColor.systemGray))
                    Spacer()
                    Text(board.storeName ?? "매장 미정")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color(UIColor.systemGray))
                }

                Text("모집인원 \(board.recruitPeople ?? 0)명")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(Color(UIColor.systemGray))

                Text("탈출일자 \(escapeDateText)")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(Color(UIColor.systemGray))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(UIColor.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            HStack(spacing: 6) {
                Text(board.memberName)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(Color(UIColor.systemGray))

                if board.hit > 0 {
                    Text("· 조회수 \(board.hit)")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(Color(UIColor.systemGray))
                }

                if board.likeCount > 0 {
                    Text("· 관심 \(board.likeCount)")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(Color(UIColor.systemGray))
                }

                if board.commentCount > 0 {
                    Text("· 댓글 \(board.commentCount)")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(Color(UIColor.systemGray))
                }

                Spacer()
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
