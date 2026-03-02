//
//  ThemeView.swift
//  Bantalsonyeondan
//
//  Created by 이상현 on 4/16/25.
//

import SwiftUI
import ComposableArchitecture

struct ThemeDetailView: View {
    let themeInfo: ThemeDetail
    let isAuthenticated: Bool
    let onRequireLogin: () -> Void
    let onDismiss: () -> Void

    init(
        themeInfo: ThemeDetail,
        isAuthenticated: Bool = true,
        onRequireLogin: @escaping () -> Void = {},
        onDismiss: @escaping () -> Void
    ) {
        self.themeInfo = themeInfo
        self.isAuthenticated = isAuthenticated
        self.onRequireLogin = onRequireLogin
        self.onDismiss = onDismiss
    }

    enum Tab: String, CaseIterable, Identifiable {
        case detail = "상세정보"
        case reservation = "예약정보"
        case review = "리뷰"
        var id: String { rawValue }
    }

    @State private var selectedTab: Tab = .detail

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                ForEach(Tab.allCases) { tab in
                    Button(action: {
                        selectedTab = tab
                    }) {
                        VStack(spacing: 4) {
                            Text(tab.rawValue)
                                .foregroundColor(selectedTab == tab ? .black : .gray)
                                .fontWeight(selectedTab == tab ? .bold : .regular)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding()
            
            Divider()
            
            if selectedTab == .review {
                if isAuthenticated {
                    ReviewDetailView(
                        store: Store(initialState: ReviewFeature.State(themeId: themeInfo.id)) {
                            ReviewFeature()
                        }
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    reviewLoginRequiredView
                }
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        if selectedTab == .detail {
                            VStack(alignment: .leading, spacing: 16) {
                                themeDetailView
                                Text(themeInfo.description)
                                    .font(.body)
                            }
                            .padding(.horizontal)
                        } else if selectedTab == .reservation {
                            VStack(alignment: .leading, spacing: 16) {
                                themeDetailView
                                VStack(alignment: .leading, spacing: 12) {
                                    if let store = themeInfo.store {
                                        Text(store.name)
                                            .font(.headline)
                                        Text(store.location)
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("가격 정보")
                                            .font(.headline)
                                        Text("₩ \(themeInfo.price.formatted())")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("예약 시간표")
                                            .font(.headline)
                                        ScrollView(.horizontal, showsIndicators: false) {
                                            HStack {
                                                ForEach(themeInfo.weekdaysTimeList) { timeSlot in
                                                    Text(timeSlot.time)
                                                        .padding(.horizontal, 12)
                                                        .padding(.vertical, 6)
                                                        .background(Color.gray.opacity(0.2))
                                                        .cornerRadius(20)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.top)
                }
            }
            if selectedTab != .review {
                Button(action: {
                    if let urlString = themeInfo.reservationUrl, let url = URL(string: urlString) {
                        UIApplication.shared.open(url)
                    }
                }) {
                    Text("바로 예약")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding(.horizontal)
            }
        }
    }

    private var reviewLoginRequiredView: some View {
        VStack(spacing: 12) {
            Spacer()
            Text("로그인 후 다른 사람이 작성한\n리뷰를 확인해보세요!")
                .font(.system(size: 12))
                .foregroundColor(Color.gray)
                .multilineTextAlignment(.center)

            Button(action: {
                onRequireLogin()
            }) {
                Text("로그인 하러 가기")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.gray)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 8)
                    .background(Color(white: 0.95))
                    .cornerRadius(6)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    var themeDetailView: some View {
        HStack(alignment: .top, spacing: 16) {
            CachedAsyncImage(url: URL(string: themeInfo.thumbnail)) { phase in
                switch phase {
                case .empty:
                    Color.gray.opacity(0.1)
                case .success(let image):
                    image.resizable().scaledToFit()
                case .failure:
                    Color.red.opacity(0.1)
                @unknown default:
                    Color.black
                }
            }
            .frame(width: 130, height: 180)
            .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(themeInfo.title)
                    .font(.headline)
                HStack() {
                    if let genre = themeInfo.genreType ?? themeInfo.genre {
                        Text(genre)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(4)
                    }
                    let time = themeInfo.time
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                        Text("\(time)분")
                    }
                    .font(.caption)
                }
                if let min = themeInfo.minimumPeople, let max = themeInfo.maximumPeople {
                    Text("인원: \(min)~\(max)인")
                        .font(.caption)
                }
                
                Text("난이도: \(themeInfo.difficulty)")
                    .font(.caption)
            }
            Spacer()
        }
    }
}
