import SwiftUI
import ComposableArchitecture

struct CommunityView: View {
    let store: StoreOf<CommunityFeature>
    @FocusState private var isSearchFocused: Bool
    
    var body: some View {
        NavigationStack {
            WithViewStore(store, observe: \.self) { viewStore in
                ZStack {
                    VStack(spacing: 0) {
                        HStack {
                            CustomSearchBar(
                                text: viewStore.binding(
                                    get: \.searchText,
                                    send: CommunityFeature.Action.onSearchBarEntered
                                ),
                                placeholder: "모집글, 업체명, 키워드 검색"
                            )
                            .padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                        }
                        
                        Divider()
                        
                        // 상단 필터/정렬
                        HStack {
                            Toggle(isOn: viewStore.binding(get: \.isOnlyRecruiting, send: { CommunityFeature.Action.setOnlyRecruiting($0) })) {
                                Text("모집중인 글만 보기")
                                    .font(.subheadline)
                            }
                            .toggleStyle(CommunityCheckboxToggleStyle())
                            
                            Spacer()
                            Menu {
                                ForEach(SortOption.communityOptions) { option in
                                    Button(option.displayName) {
                                        viewStore.send(CommunityFeature.Action.onSortOptionSelected(option))
                                    }
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Text(viewStore.sortOption.displayName)
                                        .font(.subheadline)
                                        .tint(Color("cod_gray"))
                                    Image("polygon")
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 12)

                        // 모집글 리스트
                        if viewStore.isLoading && viewStore.boards.isEmpty {
                            Spacer()
                            ProgressView()
                            Spacer()
                        } else if viewStore.boards.isEmpty {
                            Spacer()
                            VStack(spacing: 8) {
                                Text("")
                                    .font(.title3)
                                    .foregroundColor(.gray)
                                Text("검색 결과가 없습니다.")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                Button(action: { isSearchFocused = false }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "arrow.uturn.left")
                                        Text("이전 화면으로 돌아가기")
                                    }
                                    .font(.footnote)
                                    .foregroundColor(.gray)
                                }
                            }
                            Spacer()
                        } else {
                            ScrollView {
                                LazyVStack(spacing: 8) {
                                    ForEach(viewStore.boards.indices, id: \.self) { index in
                                        let board = viewStore.boards[index]
                                        NavigationLink {
                                            BoardDetailView(                                                 store: StoreOf<BoardDetailFeature>(
                                                    initialState: BoardDetailFeature.State(boardId: board.id, board: board),
                                                    reducer: { BoardDetailFeature() }
                                                ),
                                                onBoardChanged: {
                                                    viewStore.send(.onSearchBarEntered(viewStore.searchText))
                                                }
                                            )
                                        } label: {
                                            BoardCardView(board: board)
                                        }
                                        .buttonStyle(.plain)
                                        .onAppear {
                                            if index == viewStore.boards.count - 1 && !viewStore.isLoading {
                                                viewStore.send(CommunityFeature.Action.onLoadNextPage)
                                            }
                                        }
                                    }

                                    if viewStore.isLoading {
                                        ProgressView()
                                            .padding(.vertical, 16)
                                    }
                                }
                                .padding(.top, 8)
                            }
                            .background(Color(UIColor.systemGray6))
                        }
                    }
                    .onAppear { viewStore.send(CommunityFeature.Action.onLoadNextPage) }
                    .fullScreenCover(isPresented: viewStore.binding(get: \.showWriteView, send: CommunityFeature.Action.showWriteView)) {
                        viewStore.send(CommunityFeature.Action.onLoadNextPage)
                    } content: {
                        CommunityWriteView()
                    }
                    VStack {
                        Spacer()
                        HStack() {
                            Spacer()
                                .foregroundStyle(.clear)
                            Button(action: {
                                viewStore.send(.showWriteView(true))
                            }) {
                                Text("모집하기 +")
                                    .font(.headline)
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 24)
                                    .background(Color.black)
                                    .foregroundColor(.white)
                                    .cornerRadius(24)
                                    .shadow(radius: 2)
                            }
                            .padding(.bottom, 24)
                            .padding(.trailing, 16)
                        }
                        .foregroundStyle(.clear)
                    }
                    .zIndex(1)
                }
                .appToast(
                    message: Binding(
                        get: { viewStore.errorMessage },
                        set: { _ in viewStore.send(.clearErrorMessage) }
                    ),
                    style: .error
                )
            }
        }
    }
}

// MARK: - BoardCardView
struct BoardCardView: View {
    let board: Board
    
    // MARK: Helpers
    private var deadlineStatus: (text: String, isUrgent: Bool, isClosed: Bool)? {
        guard
            let recruitDeadline = board.recruitDeadline,
            let date = ISO8601DateFormatter.iso8601WithOptionalFraction.date(from: recruitDeadline)
                ?? ISO8601DateFormatter().date(from: recruitDeadline)
        else {
            return nil
        }

        let interval = date.timeIntervalSinceNow
        if interval <= 0 {
            return ("모집 마감", false, true)
        }

        if interval <= 60 * 60 * 24 {
            let hours = max(1, Int(ceil(interval / 3600)))
            return ("마감 \(hours)시간 전", true, false)
        }

        let days = max(1, Int(ceil(interval / (60 * 60 * 24))))
        return ("마감 \(days)일 전", false, false)
    }

    private var recruitPeopleText: String {
        if let people = board.recruitPeople {
            return "모집인원 \(people)명"
        }
        return "모집인원 정보 없음"
    }
    
    private var escapeDateText: String {
        guard let str = board.escapeDate, !str.isEmpty else {
            return "탈출일자 협의 후 결정"
        }
        // Try ISO8601 parse, else show raw string
        if let date = ISO8601DateFormatter.iso8601WithOptionalFraction.date(from: str) ?? ISO8601DateFormatter().date(from: str) {
            let df = DateFormatter()
            df.locale = Locale(identifier: "ko_KR")
            df.timeZone = .current
            df.dateFormat = "yyyy년 MM월 dd일 a h시 mm분"
            return "탈출일자 " + df.string(from: date)
        }
        return "탈출일자 " + str
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                if let deadlineStatus {
                    HStack(spacing: 4) {
                        if deadlineStatus.isUrgent {
                            Image(systemName: "clock.badge.exclamationmark")
                                .font(.caption2)
                        }
                        Text(deadlineStatus.text)
                            .font(.caption2)
                    }
                    .foregroundColor(
                        deadlineStatus.isClosed
                            ? Color(UIColor.systemGray)
                            : (deadlineStatus.isUrgent ? Color(UIColor.systemGray) : Color("cod_gray"))
                    )
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(
                        deadlineStatus.isClosed
                            ? Color(UIColor.systemGray6)
                            : Color("EEEEEE")
                    )
                    .cornerRadius(8)
                }

                if board.isPopular {
                    Text("인기글")
                        .font(.caption2)
                        .foregroundColor(Color.green)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(Color.green.opacity(0.12))
                        .cornerRadius(8)
                }

                Spacer(minLength: 0)
            }

            // 상태 뱃지
            if board.hit >= 100 && !board.isPopular {
                HStack(spacing: 6) {
                    Text("인기글")
                        .font(.caption2)
                        .foregroundColor(Color.green)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                    Spacer(minLength: 0)
                }
            }
            
            Text(board.title)
                .font(.headline)
                .lineLimit(2)
                .foregroundColor(Color("cod_gray"))
            
            // 모집 정보 + 태그를 하나의 컨테이너로 묶기
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    TagPill(text: board.themeName ?? "")
                    Spacer(minLength: 8)
                    TagPill(text: board.storeName ?? "")
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(recruitPeopleText)
                        .font(.caption)
                    Text(escapeDateText)
                        .font(.caption)
                }
            }
            .padding(12)
            .background(Color("FAFAFA"))
            .cornerRadius(12)
            
            HStack {
                Text(board.memberName)
                    .font(.caption2)
                    .foregroundColor(.secondary)

                if board.hit > 0 {
                    Text("· 조회수 \(board.hit)")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }

                Spacer()

                HStack(spacing: 10) {
                    if board.likeCount > 0 {
                        HStack(spacing: 3) {
                            Image("icon-like")
                                .resizable()
                                .frame(width: 12, height: 11)
                            Text("\(board.likeCount)")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    }

                    if board.commentCount > 0 {
                        HStack(spacing: 3) {
                            Image("icon-comment")
                                .resizable()
                                .renderingMode(.template)
                                .foregroundColor(.gray)
                                .frame(width: 11, height: 10)
                            Text("\(board.commentCount)")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
        }
        .padding(14)
        .background(Color.white)
        .overlay(
            Group {
                if deadlineStatus?.isClosed == true {
                    ZStack {
                        Color.white.opacity(0.6)
                        Text("모집마감")
                            .font(.subheadline)
                            .foregroundColor(Color(UIColor.systemGray))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color("EEEEEE"))
                            .cornerRadius(10)
                    }
                    .cornerRadius(12)
                }
            }
        )
    }
}

struct TagPill: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.caption)
            .foregroundColor(.primary)
            .padding(.vertical, 6)
            .cornerRadius(8)
    }
}

// MARK: - CheckboxToggleStyle (scoped to Community)
struct CommunityCheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 8) {
            Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                .foregroundColor(configuration.isOn ? .black : .gray)
            configuration.label
        }
        .contentShape(Rectangle())
        .onTapGesture { configuration.isOn.toggle() }
    }
}

// MARK: - ISO8601 helper
extension ISO8601DateFormatter {
    static let iso8601WithOptionalFraction: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()
}
