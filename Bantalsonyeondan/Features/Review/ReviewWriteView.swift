import SwiftUI
import ComposableArchitecture

struct ReviewWriteView: View {
    @State private var visitDate: Date = Date()
    @State private var isVisitDateNone: Bool = false
    @State private var difficulty: Double = 0.5
    @State private var playMinute: String = ""
    @State private var playSecond: String = ""
    @State private var isTimeNone: Bool = false
    @State private var people: String = ""
    @State private var hints: String = ""
    @State private var isHintsNone: Bool = false
    @State private var activityScore: Int = 0
    @State private var scareScore: Int = 0
    @State private var isSuccess: Bool? = nil
    @State private var content: String = ""
    @State private var isRecommend: Bool = false
    @FocusState private var isTextEditorFocused: Bool
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    let store: StoreOf<ReviewFeature>
    var themeId: Int
    var onComplete: (() -> Void)?
    
    var body: some View {
        WithViewStore(store, observe: \.self) { viewStore in
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Group {
                        HStack {
                            Text("방문일")
                            Spacer()
                            if !isVisitDateNone {
                                DatePicker("", selection: $visitDate, displayedComponents: .date)
                                    .labelsHidden()
                                Divider()
                            }
                            Toggle("기억 안나요", isOn: $isVisitDateNone)
                                .labelsHidden()
                                .toggleStyle(CheckboxToggleStyle())
                        }
                        HStack {
                            Text("체감 난이도")
                            Spacer()
                            HStack(spacing: 0) {
                                ForEach(0..<5) { idx in
                                    // 왼쪽(0.5, 1.5, 2.5, 3.5, 4.5)
                                    let leftValue = Double(idx) + 0.5
                                    let leftImage = difficulty >= leftValue ? "icon_locker_left_filled" : "icon_locker_left"
                                    Image(leftImage)
                                        .resizable()
                                        .frame(width: 18, height: 18)
                                        .onTapGesture { difficulty = leftValue }
                                    // 오른쪽(1.0, 2.0, 3.0, 4.0, 5.0)
                                    let rightValue = Double(idx) + 1.0
                                    let rightImage = difficulty >= rightValue ? "icon_locker_right_filled" : "icon_locker_right"
                                    Image(rightImage)
                                        .resizable()
                                        .frame(width: 18, height: 18)
                                        .onTapGesture { difficulty = rightValue }
                                }
                            }
                            Text(String(format: "%.1f", difficulty))
                                .foregroundColor(.purple)
                        }
                        HStack {
                            Text("플레이타임")
                            Spacer()
                            if !isTimeNone {
                                TextField("0", text: $playMinute)
                                    .keyboardType(.numberPad)
                                    .frame(width: 40)
                                Text("분")
                                TextField("0", text: $playSecond)
                                    .keyboardType(.numberPad)
                                    .frame(width: 40)
                                Text("초")
                                Divider()
                            }
                            Toggle("기록 안 함", isOn: $isTimeNone)
                                .labelsHidden()
                                .toggleStyle(CheckboxToggleStyle())
                        }
                        HStack {
                            Text("플레이 인원")
                            Spacer()
                            TextField("2", text: $people)
                                .keyboardType(.numberPad)
                                .frame(width: 40)
                            Text("명")
                        }
                        HStack {
                            Text("사용 힌트 수")
                            Spacer()
                            if !isHintsNone {
                                TextField("0", text: $hints)
                                    .keyboardType(.numberPad)
                                    .frame(width: 40)
                                Text("개")
                                Divider()
                            }
                            Toggle("기록 안 함", isOn: $isHintsNone)
                                .labelsHidden()
                                .toggleStyle(CheckboxToggleStyle())
                        }
                    }
                    Group {
                        HStack {
                            Text("활동성")
                            Spacer()
                        }
                        HStack {
                            ForEach(0...5, id: \.self) { idx in
                                Circle()
                                    .fill(activityScore == idx ? Color.purple : Color.gray.opacity(0.2))
                                    .frame(width: 24, height: 24)
                                    .overlay(Text("\(idx)").font(.caption).foregroundColor(.black))
                                    .onTapGesture { activityScore = idx }
                            }
                            .frame(maxWidth: .infinity)
                        }
                        HStack {
                            Text("공포")
                            Spacer()
                        }
                        HStack {
                            ForEach(0...5, id: \.self) { idx in
                                Circle()
                                    .fill(scareScore == idx ? Color.purple : Color.gray.opacity(0.2))
                                    .frame(width: 24, height: 24)
                                    .overlay(Text("\(idx)").font(.caption).foregroundColor(.black))
                                    .onTapGesture { scareScore = idx }
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    HStack(spacing: 12) {
                        Button(action: { isSuccess = true }) {
                            Text("탈출했어요")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(isSuccess == true ? Color.purple : Color.gray.opacity(0.2), lineWidth: 1)
                                        .background(
                                            (isSuccess == true ? Color.purple.opacity(0.08) : Color.clear)
                                                .cornerRadius(8)
                                        )
                                )
                                .foregroundColor(isSuccess == true ? Color.purple : Color.gray.opacity(0.7))
                        }
                        Button(action: { isSuccess = false }) {
                            Text("탈출 못했어요")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(isSuccess == false ? Color.purple : Color.gray.opacity(0.2), lineWidth: 1)
                                        .background(
                                            (isSuccess == false ? Color.purple.opacity(0.08) : Color.clear)
                                                .cornerRadius(8)
                                        )
                                )
                                .foregroundColor(isSuccess == false ? Color.purple : Color.gray.opacity(0.7))
                        }
                    }
                    TextEditor(text: $content)
                        .frame(height: 100)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.2)))
                        .padding(.vertical, 4)
                        .background(Color.osloGray.opacity(0.05))
                        .cornerRadius(8)
                        .overlay(
                            Group {
                                if content.isEmpty {
                                    Text("테마에 대한 자유로운 후기를 남겨주세요! (최대 300자, 스포가 포함되어 있으면 임의 삭제처리 될 수 있습니다.)")
                                        .foregroundColor(.gray)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 12)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        )
                    HStack {
                        Toggle("이 테마 추천하기", isOn: $isRecommend)
                            .toggleStyle(CheckboxToggleStyle())
                        if isRecommend {
                            Label("추천해요!", systemImage: "hand.thumbsup.fill")
                                .foregroundColor(.purple)
                        }
                    }
                    Button(action: submit) {
                        Text("리뷰 작성 완료")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.black)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .disabled(viewStore.isLoading)
                    .padding(.top, 8)
                    .alert("리뷰 등록 실패", isPresented: $showErrorAlert) {
                        Button("확인", role: .cancel) {}
                    } message: {
                        Text(errorMessage)
                    }
                }
                .padding()
            }
            .navigationTitle("리뷰 작성")
            .onChange(of: viewStore.isLoading) { isLoading in
                // 등록 성공 후 전체화면 닫기
                if !isLoading && viewStore.errorMessage == nil && onComplete != nil {
                    onComplete?()
                }
            }
        }
    }
    
    func submit() {
        let review = ReviewRegist(
            content: content,
            people: Int(people) ?? 0,
            time: (Int(playMinute) ?? 0) * 60 + (Int(playSecond) ?? 0),
            scareScore: scareScore,
            activityScore: activityScore,
            difficulty: Int(difficulty),
            hints: Int(hints) ?? 0,
            visitDate: isVisitDateNone ? "" : formattedDate(visitDate),
            isSuccess: isSuccess ?? false,
            themeId: themeId
        )
        store.send(.createReview(review))
    }
    
    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return formatter.string(from: date)
    }
}

// 체크박스 토글 스타일
struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                .foregroundColor(configuration.isOn ? .purple : .gray)
                .onTapGesture { configuration.isOn.toggle() }
        }
    }
}
