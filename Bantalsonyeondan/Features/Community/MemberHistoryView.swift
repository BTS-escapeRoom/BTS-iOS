import SwiftUI

struct MemberHistoryTarget: Identifiable, Equatable {
    let id: Int   // memberId
    let name: String
}

/// 다른 멤버의 방탈출 기록을 읽기 전용으로 표시하는 뷰
struct MemberHistoryView: View {
    let memberId: Int
    let memberName: String

    @State private var records: [ReviewHistory] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    @Environment(\.dismiss) private var dismiss

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    if isLoading {
                        ProgressView()
                            .padding(.top, 60)
                    } else if let errorMessage {
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                            .padding(.top, 60)
                    } else if records.isEmpty {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(UIColor.systemGray6))
                            .frame(height: 120)
                            .overlay {
                                Text("공개된 방탈출 기록이 없어요.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 16)
                    } else {
                        Text("총 \(records.count)개 기록 중 성공: \(records.filter(\.isSuccess).count)개")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .padding(.horizontal, 16)

                        LazyVGrid(columns: columns, spacing: 10) {
                            ForEach(records) { record in
                                MemberHistoryTicketCard(history: record)
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.top, 12)
                .padding(.bottom, 20)
            }
            .navigationTitle("\(memberName)의 기록")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("닫기") { dismiss() }
                }
            }
            .task {
                await loadHistory()
            }
        }
    }

    private func loadHistory() async {
        isLoading = true
        errorMessage = nil
        do {
            records = try await ReviewAPIClient.live.getHistory(memberId: memberId)
        } catch {
            errorMessage = "기록을 불러올 수 없어요."
        }
        isLoading = false
    }
}

private struct MemberHistoryTicketCard: View {
    let history: ReviewHistory

    private var accentColor: Color {
        history.isSuccess
            ? Color(red: 0.24, green: 0.95, blue: 0.45)
            : Color(red: 0.97, green: 0.45, blue: 0.84)
    }

    private var backgroundColor: Color {
        history.isSuccess ? Color(UIColor.darkGray) : Color(UIColor.systemGray4)
    }

    var body: some View {
        VStack(spacing: 8) {
            Text(history.themeTitle)
                .font(.custom("Galmuri9", size: 14))
                .foregroundColor(.white)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 4)

            Text(HistoryTimeFormatter.string(from: history.time))
                .font(.custom("Galmuri9", size: 16))
                .foregroundColor(accentColor)
                .lineLimit(1)
                .padding(.bottom, 6)
        }
        .frame(height: 86)
        .background(backgroundColor)
        .overlay(
            HStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 12, height: 12)
                    .offset(x: -6)
                Spacer()
                Circle()
                    .fill(Color.white)
                    .frame(width: 12, height: 12)
                    .offset(x: 6)
            }
            .blendMode(.destinationOut)
        )
        .compositingGroup()
    }
}
