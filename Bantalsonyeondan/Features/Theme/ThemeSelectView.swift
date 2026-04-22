import SwiftUI
import ComposableArchitecture

struct ThemeSelectView: View {
    let store: StoreOf<ThemeFeature>
    @Binding var selectedTheme: Theme?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        WithViewStore(store, observe: \.self) { viewStore in
            VStack(spacing: 0) {
                // 상단 바
                HStack {
                    Text("테마 연결하기")
                        .font(.headline)
                        .padding(.leading)
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.black)
                            .padding()
                    }
                }
                // 검색창
                CustomSearchBar(
                    text: viewStore.binding(
                        get: \.searchText,
                        send: ThemeFeature.Action.onSearchTextChanged
                    ),
                    placeholder: "원하는 지역 또는 테마 검색"
                )
                .padding(.horizontal)
                .padding(.top, 8)

                // 검색 결과/빈 상태
                if viewStore.isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if viewStore.themes.isEmpty {
                    Spacer()
                    Text(viewStore.searchText.isEmpty ? "연결할 테마를 검색해주세요." : "'\(viewStore.searchText)'에 대한 검색 결과가 없습니다.")
                        .foregroundColor(.gray)
                        .font(.subheadline)
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(viewStore.themes) { theme in
                                Button(action: {
                                    selectedTheme = theme
                                }) {
                                    ThemeRowView(theme: theme, isSelected: selectedTheme?.id == theme.id)
                                }
                                .buttonStyle(PlainButtonStyle())
                                Divider()
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                // 선택 완료 버튼
                Button(action: {
                    if selectedTheme != nil {
                        dismiss()
                    }
                }) {
                    Text("선택 완료")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedTheme != nil ? Color.black : Color.gray.opacity(0.3))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding()
                .disabled(selectedTheme == nil)
            }
            .background(Color.white)
            .onAppear {
                viewStore.send(.onSortOptionSelected(.popular))
            }
        }
    }
}

struct ThemeRowView: View {
    let theme: Theme
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            CachedAsyncImage(url: URL(string: theme.thumbnail)) { phase in
                switch phase {
                case .empty:
                    Color.gray.opacity(0.1)
                case .success(let image):
                    image.resizable().scaledToFill()
                case .failure:
                    Image(systemName: "photo")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.gray)
                        .padding(12)
                @unknown default:
                    Color.gray.opacity(0.1)
                }
            }
            .frame(width: 56, height: 56)
            .cornerRadius(8)

            VStack(alignment: .leading, spacing: 4) {
                Text(theme.title)
                    .font(.body)
                    .foregroundColor(.black)
                // 장르 배지 + 난이도 + 시간
                HStack(spacing: 6) {
                    if let genrePresentation = theme.genrePresentation {
                        ThemeGenreBadge(presentation: genrePresentation)
                    }
                    if let difficulty = theme.difficulty {
                        HStack(spacing: 2) {
                            ThemeDifficultyView(difficulty: difficulty)
                        }
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color("EEEEEE"))
                        .cornerRadius(4)
                    }
                    if let time = theme.time, time > 0 {
                        HStack(spacing: 3) {
                            Image(systemName: "clock")
                                .font(.system(size: 9))
                            Text("\(time)분")
                                .font(.caption2)
                        }
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color("EEEEEE"))
                        .cornerRadius(4)
                    }
                }
                Text(theme.store)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            Spacer()
            if isSelected {
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.trailing, 8)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(isSelected ? Color.gray.opacity(0.06) : Color.clear)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.black : Color.clear, lineWidth: 2)
        )
        .contentShape(Rectangle())
    }
}
