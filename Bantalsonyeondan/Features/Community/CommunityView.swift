import SwiftUI
import ComposableArchitecture

struct CommunityView: View {
    let store: StoreOf<CommunityFeature>
    @FocusState private var isSearchFocused: Bool
    @State private var sortOption: SortOption = .latest
    
    var body: some View {
        NavigationStack {
            WithViewStore(store, observe: \.self) { viewStore in
                ZStack {
                    VStack(spacing: 0) {
                        HStack {
                            CustomSearchBar(
                                text: viewStore.binding(
                                    get: \.searchText,
                                    send: { CommunityFeature.Action.onSearchBarEntered($0, sortOption: sortOption) }
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
                                        sortOption = option
                                        viewStore.send(CommunityFeature.Action.onSortOptionSelected(option))
                                    }
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Text(sortOption.displayName)
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
                                LazyVStack(spacing: 12) {
                                    ForEach(viewStore.boards.indices, id: \.self) { index in
                                        let board = viewStore.boards[index]
                                        NavigationLink {
                                            BoardDetailView(
                                                store: StoreOf<BoardDetailFeature>(
                                                    initialState: BoardDetailFeature.State(boardId: board.id, board: board),
                                                    reducer: { BoardDetailFeature() }
                                                )
                                            )
                                        } label: {
                                            BoardCardView(board: board)
                                                .padding(.horizontal)
                                        }
                                        .buttonStyle(.plain)
                                        .onAppear {
                                            if index == viewStore.boards.count - 1 && !viewStore.isLoading {
                                                viewStore.send(CommunityFeature.Action.onLoadNextPage(sortOption: sortOption))
                                            }
                                        }
                                    }
                                    
                                    // 하단 로딩 인디케이터 (다음 페이지 로드 중)
                                    if viewStore.isLoading {
                                        ProgressView()
                                            .padding(.vertical, 16)
                                    }
                                }
                                .padding(.top, 8)
                            }
                        }
                    }
                    .onAppear { viewStore.send(CommunityFeature.Action.onLoadNextPage(sortOption: sortOption)) }
                    .fullScreenCover(isPresented: viewStore.binding(get: \.showWriteView, send: CommunityFeature.Action.showWriteView)) {
                        viewStore.send(CommunityFeature.Action.onLoadNextPage(sortOption: sortOption))
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
            }
        }
    }
}

// MARK: - BoardCardView
struct BoardCardView: View {
    let board: Board
    
    // MARK: Helpers
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
            // 상태 뱃지 (간단 예: 조회수 높으면 인기글)
            if board.hit >= 100 {
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
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            HStack {
                Text(board.memberName)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text("· 조회수 \(board.hit)")
                    .font(.caption2)
                    .foregroundColor(.gray)
                Spacer()
            }
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)
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
                .onTapGesture { configuration.isOn.toggle() }
            configuration.label
        }
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
