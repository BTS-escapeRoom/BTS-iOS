//
//  HomeView.swift
//  Bantalsonyeondan
//
//  Created by 이상현 on 1/15/25.
//

import SwiftUI
import ComposableArchitecture

struct HomeView: View {
    let store: StoreOf<HomeFeature>
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            Text("이번달 인기 테마")
                .font(.headline)
            VStack {
                if viewStore.isLoading {
                    ProgressView("Loading...")
                } else {
                    // 가로 스크롤뷰로 이미지 목록을 표시
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(viewStore.themes, id: \.id) { theme in
                                VStack(alignment: .leading) {
                                    Text(theme.title)
                                        .font(.headline)
                                    
                                    CachedAsyncImage(url: URL(string: theme.thumbnail)) { phase in
                                        switch phase {
                                        case .empty:
                                            ProgressView()
                                                .frame(width: 150, height: 150)
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 150, height: 150)
                                                .clipped()
                                                .cornerRadius(10)
                                        case .failure:
                                            Image(systemName: "photo")
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 150, height: 150)
                                                .clipped()
                                                .cornerRadius(10)
                                        @unknown default:
                                            EmptyView()
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .onAppear {
                viewStore.send(.onAppear)
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
