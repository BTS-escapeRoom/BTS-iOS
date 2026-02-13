import SwiftUI
import ComposableArchitecture

struct BoardDetailView: View {
    let store: StoreOf<BoardDetailFeature>

    // 날짜 포맷 도우미
    private static func formattedEscapeDateStatic(_ str: String?) -> String? {
        guard let str, !str.isEmpty else { return nil }
        if let date = ISO8601DateFormatter.iso8601WithOptionalFraction.date(from: str) ?? ISO8601DateFormatter().date(from: str) {
            let df = DateFormatter()
            df.locale = Locale(identifier: "ko_KR")
            df.timeZone = .current
            df.dateFormat = "yyyy년 MM월 dd일 a h시 mm분"
            return df.string(from: date)
        }
        return str
    }

    private func adaptTheme(from detail: ThemeDetail) -> Theme {
        Theme(
            id: detail.id,
            thumbnail: detail.thumbnail,
            title: detail.title,
            minimumPeople: detail.minimumPeople,
            maximumPeople: detail.maximumPeople,
            difficulty: Double(detail.difficulty),
            genre: detail.genre,
            time: detail.time,
            genreType: detail.genreType ?? "",
            status: nil,
            store: detail.store?.name ?? "",
            city: detail.store?.location ?? "",
            dictrict: nil
        )
    }

    @ViewBuilder
    private func themeInfoSection(_ viewStore: ViewStore<BoardDetailFeature.State, BoardDetailFeature.Action>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack { Text("테마 정보").font(.subheadline).bold(); Spacer() }
            if let themeDetail = viewStore.themeDetail {
                NavigationLink {
                    ThemeDetailView(themeInfo: themeDetail, onDismiss: {})
                } label: {
                    ThemeInfoCard(theme: adaptTheme(from: themeDetail))
                }
                .buttonStyle(.plain)
            } else if let tid = viewStore.detail?.id { // themeId가 사실 id인 케이스 대응
                NavigationLink {
                    ThemeDetailRouteView(
                        store: Store(
                            initialState: ThemeDetailRouteFeature.State(themeId: tid)
                        ) {
                            ThemeDetailRouteFeature()
                        }
                    )
                } label: {
                    HStack(spacing: 8) {
                        TagPill(text: viewStore.board?.themeName ?? "")
                        Spacer(minLength: 8)
                        if let storeName = viewStore.board?.storeName, !storeName.isEmpty {
                            TagPill(text: storeName)
                        }
                        ProgressView().scaleEffect(0.8)
                    }
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
            } else {
                HStack(spacing: 8) {
                    TagPill(text: viewStore.board?.themeName ?? "")
                    Spacer(minLength: 8)
                    if let storeName = viewStore.board?.storeName, !storeName.isEmpty {
                        TagPill(text: storeName)
                    }
                }
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
        }
    }

    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            // 최소 파생 값만 지역 상수로 계산해서 타입체커 부담을 줄임
            let detailTitle = viewStore.detail?.title.trimmingCharacters(in: .whitespacesAndNewlines)
            let boardTitle = viewStore.board?.title.trimmingCharacters(in: .whitespacesAndNewlines)
            let title = (detailTitle?.isEmpty == false ? detailTitle : nil) ?? (boardTitle ?? "")

            let peopleText: String = {
                if let p = viewStore.detail?.recruit_people ?? viewStore.board?.recruitPeople { return "\(p)명" }
                return "-"
            }()

            let escapeDateText: String = Self.formattedEscapeDateStatic(viewStore.detail?.escape_date ?? viewStore.board?.escapeDate) ?? "협의 후 결정"

            let isSendEnabled = viewStore.newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // 제목
                    Text(title)
                        .font(.title3).bold()
                        .foregroundColor(Color("cod_gray"))
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    // 작성자/조회수 메타
                    HStack(spacing: 8) {
                        Text(viewStore.board?.memberName ?? "")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("· 조회수 \(viewStore.detail?.hit ?? viewStore.board?.hit ?? 0)")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Spacer()
                    }

                    // 모집 정보 섹션
                    VStack(alignment: .leading, spacing: 8) {
                        HStack { Text("모집 정보").font(.subheadline).bold(); Spacer() }
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 12) {
                                Text("모집 인원").font(.caption).foregroundColor(.secondary)
                                Text(peopleText).font(.caption)
                            }
                            HStack(spacing: 12) {
                                Text("탈출 일자").font(.caption).foregroundColor(.secondary)
                                Text(escapeDateText).font(.caption)
                            }
                            if let contact = viewStore.detail?.contact_method, !contact.isEmpty {
                                HStack(spacing: 12) {
                                    Text("연락 방법").font(.caption).foregroundColor(.secondary)
                                    Text(contact).font(.caption)
                                }
                            }
                            if let url = viewStore.detail?.contact_url, !url.isEmpty {
                                HStack(spacing: 12) {
                                    Text("연락 링크").font(.caption).foregroundColor(.secondary)
                                    Text(url).font(.caption)
                                }
                            }
                        }
                    }
                    .padding(14)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)

                    // 테마 정보 섹션
                    themeInfoSection(viewStore)

                    // 모집 내용
                    VStack(alignment: .leading, spacing: 8) {
                        HStack { Text("모집 내용").font(.subheadline).bold(); Spacer() }
                        Divider()
                        Text(viewStore.detail?.description ?? "")
                            .font(.body)
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Divider()
                    }

                    // 댓글 섹션
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Button(action: {}) {
                                HStack(spacing: 6) {
                                    Image(systemName: "heart")
                                        .foregroundColor(.gray)
                                    Text("관심 \(viewStore.detail?.likeCount ?? 0)")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                .padding(.vertical, 6)
                                .padding(.horizontal, 10)
                                .background(Capsule().fill(Color(.systemGray6)))
                                .overlay(Capsule().stroke(Color(.systemGray3), lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                            Spacer()
                            Text("댓글 \(viewStore.commentsTotalCount)")
                                .font(.subheadline).bold()
                        }

                        ForEach(viewStore.comments, id: \.id) { comment in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Circle()
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(width: 32, height: 32)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(comment.memberName)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                }
                                Text(comment.comment)
                                    .font(.body)
                                    .foregroundColor(.primary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(.vertical, 8)
                            Divider()
                        }
                    }
                }
                .padding(16)
            }
            .safeAreaInset(edge: .bottom) {
                HStack(spacing: 8) {
                    TextField(
                        "댓글을 입력해주세요.",
                        text: viewStore.binding(get: \.newCommentText, send: { .setNewCommentText($0) })
                    )
                    .textFieldStyle(.roundedBorder)
                    Button {
                        viewStore.send(.tapSendComment)
                    } label: {
                        Text("등록")
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(isSendEnabled ? Color.black : Color.gray.opacity(0.3))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .disabled(!isSendEnabled)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
            }
            .navigationTitle("모집 게시판")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { viewStore.send(.onAppear) }
        }
    }
}
