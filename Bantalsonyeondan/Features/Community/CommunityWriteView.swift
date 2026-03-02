import SwiftUI
import ComposableArchitecture

struct CommunityWriteView: View {
    private enum ContactMethodType: String, CaseIterable {
        case openTalk = "OPEN_TALK"
        case google = "GOOGLE"
        case etc = "ETC"

        var title: String {
            switch self {
            case .openTalk:
                return "카카오 오픈톡"
            case .google:
                return "구글폼"
            case .etc:
                return "기타"
            }
        }

        var placeholder: String {
            switch self {
            case .openTalk:
                return "오픈톡 링크를 입력해주세요."
            case .google:
                return "구글폼 링크를 입력해주세요."
            case .etc:
                return "연락 방법을 입력해주세요. (선택)"
            }
        }
    }

    @State private var title: String = ""
    @State private var recruitCount: String = ""
    @State private var escapeDate: Date? = nil
    @State private var isDateUndecided: Bool = false
    @State private var contactMethodType: ContactMethodType = .openTalk
    @State private var contactUrl: String = ""
    @State private var deadline: Date? = nil
    @State private var content: String = ""
    @State private var toastMessage: String? = nil
    @State private var showThemeSelectView: Bool = false
    @State private var selectedTheme: Theme? = nil
    let themeStore = Store(initialState: ThemeFeature.State(), reducer: { ThemeFeature() })
    @Environment(\.dismiss) private var dismiss
    let boardApiClient = BoardAPIClient()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Title
                    TextField("제목을 입력해주세요.", text: $title)
                        .font(.headline)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)

                    // Recruit Count
                    HStack {
                        Text("모집 인원")
                            .padding()
                        TextField("0", text: $recruitCount)
                            .keyboardType(.numberPad)
                            .frame(width: 50)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        Text("명")
                        Spacer()
                    }

                    // Escape Date
                    HStack {
                        Text("탈출 일자")
                        VStack(alignment: .leading) {
                            DatePicker("", selection: Binding($escapeDate, replacingNilWith: Date()), displayedComponents: .date)
                                .labelsHidden()
                            Toggle("협의 후 결정하기", isOn: $isDateUndecided)
                        }
                    }

                    // Contact Method
                    VStack(alignment: .leading) {
                        Text("연락 방법")
                        HStack {
                            ForEach(ContactMethodType.allCases, id: \.self) { type in
                                Button(type.title) {
                                    contactMethodType = type
                                }
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    contactMethodType == type
                                        ? Color.black
                                        : Color(.systemGray6)
                                )
                                .foregroundColor(
                                    contactMethodType == type
                                        ? .white
                                        : .black
                                )
                                .cornerRadius(8)
                            }
                        }
                        TextField(contactMethodType.placeholder, text: $contactUrl)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }

                    // Theme Info
                    VStack(alignment: .leading, spacing: 8) {
                        Text("테마 정보")
                        if let theme = selectedTheme {
                            ThemeInfoCard(theme: theme)
                        }
                        Button(action: { showThemeSelectView = true }) {
                            HStack {
                                Text(selectedTheme == nil ? "테마 연결하기" : "다른 테마 선택")
                                    .foregroundColor(.blue)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                        }
                    }

                    // Deadline
                    HStack(alignment: .top) {
                        Text("모집 마감일")
                        DatePicker("", selection: Binding($deadline, replacingNilWith: Date()), displayedComponents: .date)
                            .labelsHidden()
                    }

                    // Content
                    VStack(alignment: .leading) {
                        Text("모집 내용")
                        TextEditor(text: $content)
                            .frame(height: 150)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray, lineWidth: 1)
                            )
                    }

                    // Submit Button
                    Button(action: {
                        // 필수값 체크
                        guard !title.isEmpty, !content.isEmpty else {
                            toastMessage = "제목과 모집 내용을 입력해주세요."
                            return
                        }
                        if contactMethodType != .etc &&
                            contactUrl.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            toastMessage = "연락 링크를 입력해주세요."
                            return
                        }
                        // 날짜 변환
                        let isoFormatter = ISO8601DateFormatter()
                        let recruitDeadlineString = deadline != nil ? isoFormatter.string(from: deadline!) : nil
                        let escapeDateString = (escapeDate != nil && !isDateUndecided) ? isoFormatter.string(from: escapeDate!) : nil
                        // 인원 변환
                        let recruitPeople = recruitCount
                        // themeId 변환
                        let themeId = selectedTheme?.id
                        // contact_url/contact_method 분리
                        let contactMethodValue = contactMethodType.rawValue
                        // BoardCreateRequest 생성
                        let request = BoardCreateRequest(
                            themeId: themeId,
                            type: "recruit",
                            title: title,
                            description: content,
                            recruit_deadline: recruitDeadlineString ?? isoFormatter.string(from: Date()),
                            escape_date: escapeDateString ?? isoFormatter.string(from: Date()),
                            recruit_people: recruitPeople,
                            contact_url: contactUrl,
                            contact_method: contactMethodValue
                        )
                        Task {
                            do {
                                _ = try await boardApiClient.createBoards(request)
                                dismiss()
                            } catch {
                                toastMessage = error.localizedDescription
                            }
                        }
                    }) {
                        Text("작성 완료")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.black)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                .padding()
            }
            .navigationTitle("모집 글쓰기")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.black)
                    }
                }
            }
            .appToast(message: $toastMessage, style: .error)
            .fullScreenCover(isPresented: $showThemeSelectView) {
                ThemeSelectView(store: themeStore, selectedTheme: $selectedTheme)
            }
        }
    }
}

extension Binding where Value: Equatable {
    init(_ binding: Binding<Value?>, replacingNilWith defaultValue: Value) {
        self.init(
            get: { binding.wrappedValue ?? defaultValue },
            set: { binding.wrappedValue = $0 }
        )
    }
}

struct ThemeInfoCard: View {
    let theme: Theme
    var body: some View {
        let difficulty = theme.difficulty
        HStack(alignment: .top, spacing: 12) {
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
                        .padding(16)
                @unknown default:
                    Color.gray.opacity(0.1)
                }
            }
            .frame(width: 72, height: 72)
            .cornerRadius(10)
            VStack(alignment: .leading, spacing: 4) {
                Text(theme.title)
                    .font(.headline)
                Text(theme.genre ?? "")
                    .font(.caption)
                    .foregroundColor(.gray)
                ThemeDifficultyView(difficulty: difficulty ?? 0.0)
                HStack(spacing: 8) {
                    Text("플레이타임: \(theme.time ?? 0)분")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    Text(theme.store)
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
            Spacer()
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct ThemeDifficultyView: View {
    let difficulty: Double
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<5, id: \.self) { i in
                let leftFilled = difficulty >= Double(i) + 0.5
                let rightFilled = difficulty >= Double(i) + 1.0
                Image(leftFilled ? "icon_locker_left_filled" : "icon_locker_left")
                    .resizable()
                    .frame(width: 12, height: 16)
                Image(rightFilled ? "icon_locker_right_filled" : "icon_locker_right")
                    .resizable()
                    .frame(width: 12, height: 16)
            }
        }
    }
}
