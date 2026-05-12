import SwiftUI
import ComposableArchitecture

struct BoardDetailView: View {
    let store: StoreOf<BoardDetailFeature>
    let onBoardChanged: (() -> Void)?
    @Environment(\.dismiss) private var dismiss
    @State private var isShowingOwnerMenu: Bool = false
    @State private var isShowingEditView: Bool = false
    @State private var memberHistoryTarget: MemberHistoryTarget? = nil
    @State private var isShowingReportSheet: Bool = false
    @State private var isShowingCommentReportSheet: Bool = false
    @State private var reportTargetCommentId: Int? = nil
    @State private var reportDescription: String = ""

    init(
        store: StoreOf<BoardDetailFeature>,
        onBoardChanged: (() -> Void)? = nil
    ) {
        self.store = store
        self.onBoardChanged = onBoardChanged
    }

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

    private static func formattedCreatedAt(_ str: String?) -> String? {
        guard let str, !str.isEmpty else { return nil }
        if let date = ISO8601DateFormatter.iso8601WithOptionalFraction.date(from: str) ?? ISO8601DateFormatter().date(from: str) {
            let df = DateFormatter()
            df.locale = Locale(identifier: "ko_KR")
            df.timeZone = .current
            df.dateFormat = "yyyy.MM.dd HH:mm"
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
            district: ""
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
                if let p = viewStore.detail?.recruitPeople ?? viewStore.board?.recruitPeople { return "\(p)명" }
                return "-"
            }()

            let escapeDateText: String = Self.formattedEscapeDateStatic(viewStore.detail?.escapeDate ?? viewStore.board?.escapeDate) ?? "협의 후 결정"

            let isSendEnabled = viewStore.newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // 제목
                    Text(title)
                        .font(.title3).bold()
                        .foregroundColor(Color("cod_gray"))
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    // 작성자/조회수/작성일 메타
                    HStack(spacing: 8) {
                        // 프로필 이미지 (탭 시 해당 멤버의 방탈출 기록 표시)
                        Button {
                            if let mid = viewStore.board?.memberId ?? viewStore.detail?.memberId {
                                memberHistoryTarget = MemberHistoryTarget(
                                    id: mid,
                                    name: viewStore.board?.memberName ?? viewStore.detail?.memberName ?? "멤버"
                                )
                            }
                        } label: {
                            if let profileImgStr = viewStore.board?.profileImg ?? viewStore.detail?.profileImg,
                               let url = URL(string: profileImgStr) {
                                CachedAsyncImage(url: url) { phase in
                                    switch phase {
                                    case .success(let image):
                                        image.resizable().scaledToFill()
                                    default:
                                        Color.gray.opacity(0.2)
                                    }
                                }
                                .frame(width: 28, height: 28)
                                .clipShape(Circle())
                            } else {
                                Circle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: 28, height: 28)
                            }
                        }
                        .buttonStyle(.plain)
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 8) {
                                Text(viewStore.board?.memberName ?? "")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("조회수 \(viewStore.detail?.hit ?? viewStore.board?.hit ?? 0)")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            if let dateStr = Self.formattedCreatedAt(viewStore.board?.createdAt) {
                                Text("\(dateStr)")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        Spacer()
                        if viewStore.isMine {
                            Button {
                                isShowingOwnerMenu = true
                            } label: {
                                Image(systemName: "ellipsis")
                                    .rotationEffect(.degrees(90))
                                    .foregroundStyle(Color(UIColor.systemGray))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                            }
                            .buttonStyle(.plain)
                        } else {
                            Button {
                                reportDescription = ""
                                isShowingReportSheet = true
                            } label: {
                                Image(systemName: "ellipsis")
                                    .rotationEffect(.degrees(90))
                                    .foregroundStyle(Color(UIColor.systemGray))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                            }
                            .buttonStyle(.plain)
                        }
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
                            if let contact = viewStore.detail?.contactMethod, !contact.isEmpty {
                                HStack(spacing: 12) {
                                    Text("연락 방법").font(.caption).foregroundColor(.secondary)
                                    Text(contact).font(.caption)
                                }
                            }
                            if let url = viewStore.detail?.contactUrl, !url.isEmpty {
                                HStack(spacing: 12) {
                                    Text("연락 링크").font(.caption).foregroundColor(.secondary)
                                    Button {
                                        guard let linkURL = URL(string: url) else { return }
                                        UIApplication.shared.open(linkURL)
                                    } label: {
                                        Text(url)
                                            .font(.caption)
                                            .underline()
                                            .foregroundStyle(Color.blue)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .padding(14)
                    .cornerRadius(12)

                    // 테마 정보 섹션 (테마가 연결된 경우에만 표시)
                    if viewStore.themeDetail != nil || (viewStore.board?.themeName?.isEmpty == false) {
                        themeInfoSection(viewStore)
                    }

                    // 모집 내용
                    VStack(alignment: .leading, spacing: 20) {
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
                            Button {
                                viewStore.send(.tapToggleLike)
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "heart.fill")
                                        .foregroundColor(viewStore.isLiked ? Color(.cyan).opacity(0.8) : .gray)
                                    Text("관심 \(viewStore.likeCount)")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                .padding(.vertical, 6)
                                .padding(.horizontal, 10)
                                .background(Capsule().fill(viewStore.isLiked ? Color(.cyan).opacity(0.2) : .clear))
                                .overlay(Capsule().stroke(Color(.systemGray3), lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                            .disabled(viewStore.isTogglingLike)
                            Spacer()
                            HStack(spacing: 4) {
                                Image("icon-comment")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 16, height: 16)
                                Text("댓글 \(viewStore.commentsTotalCount)")
                                    .font(.subheadline).bold()
                            }
                        }

                        ForEach(viewStore.comments, id: \.id) { comment in
                            CommentRowView(
                                comment: comment,
                                onDelete: { viewStore.send(.tapDeleteComment(commentId: comment.id)) },
                                onReport: {
                                    reportTargetCommentId = comment.id
                                    reportDescription = ""
                                    isShowingCommentReportSheet = true
                                }
                            )
                        }
                    } // 댓글 섹션 end
                } // VStack end
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            } // ScrollView end
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
            .sheet(isPresented: $isShowingOwnerMenu) {
                VStack(spacing: 8) {
                    VStack(spacing: 0) {
                        let isRecruitBoard = (viewStore.detail?.type ?? viewStore.board?.type) == "recruit"
                        if isRecruitBoard, !viewStore.isRecruitClosed {
                            Button {
                                isShowingOwnerMenu = false
                                DispatchQueue.main.async {
                                    viewStore.send(.tapCloseRecruit)
                                }
                            } label: {
                                Text("마감")
                                    .font(.system(size: 18, weight: .regular))
                                    .foregroundStyle(Color("cod_gray"))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                            }
                            Divider()
                        }
                        if viewStore.detail != nil {
                            Button {
                                isShowingOwnerMenu = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                    isShowingEditView = true
                                }
                            } label: {
                                Text("수정")
                                    .font(.system(size: 18, weight: .regular))
                                    .foregroundStyle(Color("cod_gray"))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                            }
                            Divider()
                        }
                        Button {
                            isShowingOwnerMenu = false
                            DispatchQueue.main.async {
                                viewStore.send(.tapDeleteBoard)
                            }
                        } label: {
                            Text("삭제")
                                .font(.system(size: 18, weight: .regular))
                                .foregroundStyle(Color.red)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                        }
                    }
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                    Button {
                        isShowingOwnerMenu = false
                    } label: {
                        Text("닫기")
                            .font(.system(size: 18, weight: .regular))
                            .foregroundStyle(Color("cod_gray"))
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                }
                .padding(16)
                .presentationDetents([.height(280)])
                .presentationDragIndicator(.hidden)
            }
            .fullScreenCover(isPresented: $isShowingEditView) {
                CommunityWriteView(
                    editingBoard: viewStore.detail,
                    fallbackBoard: viewStore.board,
                    onCompleted: {
                        isShowingEditView = false
                        viewStore.send(.refresh)
                        onBoardChanged?()
                    }
                )
            }
            .sheet(item: $memberHistoryTarget) { target in
                MemberHistoryView(
                    memberId: target.id,
                    memberName: target.name
                )
                .presentationDetents([.fraction(0.85)])
                .presentationDragIndicator(.visible)
            }
            // 게시글 신고 시트
            .sheet(isPresented: $isShowingReportSheet) {
                ReportSheet(description: $reportDescription, title: "게시글 신고") {
                    viewStore.send(.tapReportBoard(description: reportDescription))
                    isShowingReportSheet = false
                }
            }
            // 댓글 신고 시트
            .sheet(isPresented: $isShowingCommentReportSheet) {
                ReportSheet(description: $reportDescription, title: "댓글 신고") {
                    if let cid = reportTargetCommentId {
                        viewStore.send(.tapReportComment(commentId: cid, description: reportDescription))
                    }
                    isShowingCommentReportSheet = false
                }
            }
            .overlay {
                if viewStore.isUpdatingBoardAction {
                    ZStack {
                        Color.black.opacity(0.08).ignoresSafeArea()
                        ProgressView()
                    }
                }
            }
            .appToast(
                message: Binding(
                    get: { viewStore.toastMessage },
                    set: { _ in viewStore.send(.clearToastMessage) }
                ),
                style: .success
            )
            .appToast(
                message: Binding(
                    get: { viewStore.errorMessage },
                    set: { _ in viewStore.send(.clearErrorMessage) }
                ),
                style: .error
            )
            .onChange(of: viewStore.didMutateBoard) { mutated in
                guard mutated else { return }
                onBoardChanged?()
                viewStore.send(.clearMutationFlag)
            }
            .onChange(of: viewStore.shouldDismiss) { shouldDismiss in
                guard shouldDismiss else { return }
                viewStore.send(.clearDismissRequest)
                dismiss()
            }
            .navigationTitle("모집 게시판")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { viewStore.send(.onAppear) }
        }
    }
}

private struct CommentRowView: View {
    let comment: Comment
    let onDelete: () -> Void
    let onReport: () -> Void
    @State private var isShowingActionSheet = false
    @State private var isShowingDeleteConfirm = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                if let imgStr = comment.profileImg, let url = URL(string: imgStr) {
                    CachedAsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().scaledToFill()
                        default:
                            Color.gray.opacity(0.2)
                        }
                    }
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 32, height: 32)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(comment.memberName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button {
                    isShowingActionSheet = true
                } label: {
                    Image(systemName: "ellipsis")
                        .rotationEffect(.degrees(90))
                        .foregroundStyle(Color(UIColor.systemGray))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
                .confirmationDialog("이 댓글을 삭제하시겠어요?", isPresented: $isShowingDeleteConfirm, titleVisibility: .visible) {
                    Button("삭제", role: .destructive) { onDelete() }
                    Button("취소", role: .cancel) {}
                }
            }
            Text(comment.comment)
                .font(.body)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 8)
        .overlay(alignment: .bottom) { Divider() }
        .sheet(isPresented: $isShowingActionSheet) {
            let isMyComment = comment.memberId == AuthSessionStore.currentSession?.memberId
            VStack(spacing: 8) {
                VStack(spacing: 0) {
                    if isMyComment {
                        Button {
                            isShowingActionSheet = false
                            isShowingDeleteConfirm = true
                        } label: {
                            Text("삭제")
                                .font(.system(size: 18, weight: .regular))
                                .foregroundStyle(Color.red)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                        }
                    } else {
                        Button {
                            isShowingActionSheet = false
                            onReport()
                        } label: {
                            Text("신고")
                                .font(.system(size: 18, weight: .regular))
                                .foregroundStyle(Color.red)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                        }
                    }
                }
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))

                Button {
                    isShowingActionSheet = false
                } label: {
                    Text("닫기")
                        .font(.system(size: 18, weight: .regular))
                        .foregroundStyle(Color("cod_gray"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
            }
            .padding(16)
            .presentationDetents([.height(154)])
            .presentationDragIndicator(.hidden)
        }
    }
}