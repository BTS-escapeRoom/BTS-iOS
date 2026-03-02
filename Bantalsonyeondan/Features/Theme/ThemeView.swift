//
//  ThemeView.swift
//  Bantalsonyeondan
//
//  Created by 이상현 on 4/16/25.
//

import SwiftUI
import ComposableArchitecture

struct ThemeView: View {
    let store: StoreOf<ThemeFeature>
    let isAuthenticated: Bool
    let onRequireLogin: () -> Void

    init(
        store: StoreOf<ThemeFeature>,
        isAuthenticated: Bool = true,
        onRequireLogin: @escaping () -> Void = {}
    ) {
        self.store = store
        self.isAuthenticated = isAuthenticated
        self.onRequireLogin = onRequireLogin
    }

    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            VStack {
                CustomSearchBar(
                    text: viewStore.binding(
                        get: \.searchText,
                        send: ThemeFeature.Action.reloadThemes
                    ),
                    placeholder: "원하는 테마 또는 업체명 검색"
                )
                    .padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                Divider()
                Menu {
                    ForEach(SortOption.themeOptions) { option in
                        Button(option.displayName) {
                            viewStore.send(.onSortOptionSelected(option))
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
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.horizontal, 16)
                Spacer()
                if viewStore.themes.isEmpty && viewStore.isLoading {
                    ProgressView("Loading...")
                    Spacer()
                } else {
                    ThemeGridView(
                        themes: viewStore.themes,
                        isLoadingNextPage: viewStore.isLoading && !viewStore.themes.isEmpty,
                        canLoadMorePages: viewStore.nextPage > 1
                            && (viewStore.totalPage == 0 || viewStore.nextPage <= viewStore.totalPage),
                        resetKey: "\(viewStore.sortOption.rawValue)|\(viewStore.searchText)",
                        onTap: { themeId in
                            viewStore.send(.themeTapped(themeId: themeId))
                        },
                        loadNextPage: {
                            viewStore.send(.onLoadNextPage)
                        }
                    )
                }
                
            }
            .onAppear {
                if viewStore.themes.isEmpty {
                    viewStore.send(.onSortOptionSelected(viewStore.sortOption))
                }
            }
            .sheet(item: viewStore.binding(
                get: \.selectedThemeDetail,
                send: .dismissDetail)
            ) { theme in
                if #available(iOS 16.4, *) {
                    ThemeDetailView(
                        themeInfo: theme,
                        isAuthenticated: isAuthenticated,
                        onRequireLogin: onRequireLogin,
                        onDismiss: {
                            viewStore.send(.dismissDetail)
                        }
                    )
                    .presentationDetents([.fraction(0.92)])
                    .presentationDragIndicator(.visible)
                    .presentationBackground(.thickMaterial)
                } else {
                    // Fallback on earlier versions
                }
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
}

struct ThemeGridView: View {
    let themes: [Theme]
    let isLoadingNextPage: Bool
    let canLoadMorePages: Bool
    let resetKey: String
    let onTap: (_ themeId: Int) -> Void
    let loadNextPage: () -> Void
    @State private var maxVisibleIndex: Int = -1
    @State private var didInitialAutoLoad: Bool = false
    
    private let columns = [
        GridItem(.adaptive(minimum: 150), spacing: 16)
    ]
    private let prefetchRemainingItemCount = 4
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(Array(themes.enumerated()), id:\.offset) { index, theme in
                    ThemeCardView(theme: theme)
                        .onAppear {
                            guard index > maxVisibleIndex else { return }
                            maxVisibleIndex = index
                            requestNextPageIfNeeded()
                        }
                        .onTapGesture {
                            onTap(theme.id)
                        }
                }
            }
            .padding(16)
            
            if isLoadingNextPage {
                ProgressView()
                    .padding(.bottom, 16)
            }

            if canLoadMorePages {
                Color.clear
                    .frame(height: 1)
                    .id("page-sentinel-\(themes.count)-\(resetKey)")
                    .onAppear {
                        requestNextPageIfNeeded(force: true)
                    }
            }
        }
        .onAppear {
            if !didInitialAutoLoad {
                didInitialAutoLoad = true
                requestNextPageIfNeeded(force: true)
            }
        }
        .onChange(of: resetKey) { _ in
            maxVisibleIndex = -1
            didInitialAutoLoad = false
        }
        .onChange(of: themes.count) { newCount in
            if maxVisibleIndex >= newCount {
                maxVisibleIndex = -1
            }
            if newCount == 0 {
                didInitialAutoLoad = false
                return
            }
        }
    }
    
    private func requestNextPageIfNeeded(force: Bool = false) {
        guard !themes.isEmpty else { return }
        guard canLoadMorePages else { return }
        guard !isLoadingNextPage else { return }
        if !force {
            let triggerIndex = max(0, themes.count - prefetchRemainingItemCount)
            guard maxVisibleIndex >= triggerIndex else { return }
        }
        loadNextPage()
    }
}

struct ThemeCardView: View {
    let theme: Theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 썸네일
            AsyncImage(url: URL(string: theme.thumbnail)) { phase in
                switch phase {
                case .empty:
                    Color.gray.opacity(0.1)
                case .success(let img):
                    img.resizable().scaledToFill()
                case .failure:
                    Color.red.opacity(0.1)
                @unknown default:
                    Color.black
                }
            }
            .frame(width: 150, height: 190)
            .clipped()
            .cornerRadius(8)
            
            HStack(spacing: 6) {
                Text(theme.title)
                    .font(.headline)
                    .lineLimit(1)
                //
                //                Text(theme.)
                //                    .font(.caption)
                //                    .lineLimit(1)
            }
            
            HStack(spacing: 6) {
                Text(theme.genreType)
                    .font(.caption2)
                    .padding(.horizontal, 3)
                    .padding(.vertical, 3)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(4)
                HStack(spacing: 2) {
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text("\(theme.time ?? 0)m")
                        .font(.caption2)
                }
                Text("난이도 \(Int(theme.difficulty ?? 0))")
                    .font(.caption2)
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        //        .cornerRadius(12)
        //        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct ThemeView_Preview: PreviewProvider {
    static var previews: some View {
        ThemeView(
            store: StoreOf<ThemeFeature>(
                initialState: ThemeFeature.State(),
                reducer: { ThemeFeature() }
            )
        )
    }
}

enum SortOption: String, CaseIterable, Identifiable, Encodable {
    case distance
    case popularity
    case popular
    case viewed
    case latest
    case old
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .distance:     return "거리순"
        case .popularity:   return "인기순"
        case .popular:      return "인기순"
        case .viewed:       return "조회순"
        case .latest:       return "최신순"
        case .old:          return "오래된 순"
        }
    }
    
    // ThemeView에서 사용할 옵션 (오래된순 제외)
    static var themeOptions: [SortOption] {
        [.distance, .popular, .latest]
    }
    // CommunityView에서 사용할 옵션 (거리순 제외)
    static var communityOptions: [SortOption] {
        [.latest, .popular, .viewed, .old]
    }
}
