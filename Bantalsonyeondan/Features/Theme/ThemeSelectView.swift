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
                        send: ThemeFeature.Action.reloadThemes
                    ),
                    placeholder: "테마명, 지역명 검색"
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
                viewStore.send(.onSortOptionSelected(.popularity))
            }
        }
    }
}

struct ThemeRowView: View {
    let theme: Theme
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: theme.thumbnail)) { img in
                img.resizable().scaledToFill()
            } placeholder: {
                Color.gray.opacity(0.1)
            }
            .frame(width: 56, height: 56)
            .cornerRadius(8)
            VStack(alignment: .leading, spacing: 4) {
                Text(theme.title)
                    .font(.body)
                    .foregroundColor(.black)
                HStack(spacing: 4) {
                    Text(theme.genre ?? "")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                Text(theme.store)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            Spacer()
            if isSelected {
                Text("선택됨")
                    .font(.caption)
                    .foregroundColor(.purple)
                    .padding(.trailing, 8)
            }
        }
        .padding(.vertical, 12)
        .background(isSelected ? Color.gray.opacity(0.08) : Color.clear)
    }
}
