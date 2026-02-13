import SwiftUI
import Foundation

struct RecordsView: View {
    let records: [ReviewHistory]
    let selectedDisplayReviewIds: Set<Int>
    let isUpdatingDisplay: Bool
    let onToggleDisplay: (Int) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                VStack(alignment: .trailing, spacing: 4) {
                    Text("총 \(records.count)개 기록 중 성공 기록: \(records.filter(\.isSuccess).count)개")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("티켓을 눌러 미노출 여부를 변경할 수 있어요.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.horizontal, 16)

                if records.isEmpty {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(UIColor.systemGray6))
                        .frame(height: 120)
                        .overlay {
                            Text("리뷰를 남기면 방탈출 기록이 추가돼요.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 16)
                } else {
                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(records) { record in
                            HistoryTicketCard(
                                history: record,
                                isDisplayed: selectedDisplayReviewIds.contains(record.reviewId)
                            )
                            .onTapGesture {
                                guard !isUpdatingDisplay else { return }
                                onToggleDisplay(record.reviewId)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }

                if isUpdatingDisplay {
                    ProgressView("노출 기록 업데이트 중...")
                        .font(.caption)
                        .padding(.top, 4)
                }
            }
            .padding(.top, 12)
            .padding(.bottom, 20)
        }
        .navigationTitle("방탈출 기록")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct HistoryTicketCard: View {
    let history: ReviewHistory
    let isDisplayed: Bool

    private var accentColor: Color {
        history.isSuccess
        ? Color(red: 0.24, green: 0.95, blue: 0.45)
        : Color(red: 0.97, green: 0.45, blue: 0.84)
    }

    private var titleColor: Color {
        .white
    }

    private var backgroundColor: Color {
        history.isSuccess ? Color(UIColor.darkGray) : Color(UIColor.systemGray4)
    }

    var body: some View {
        VStack(spacing: 8) {
            Text(history.themeTitle)
                .font(.custom("Galmuri9", size: 14))
                .foregroundColor(titleColor)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 4)

            Text(HistoryTimeFormatter.string(from: history.time))
                .font(.custom("Galmuri9", size: 16))
                .foregroundColor(accentColor)
                .lineLimit(1)
                .padding(.bottom, 6)
        }
        .blur(radius: isDisplayed ? 0 : 1.2)
        .frame(height: 86)
        .background(backgroundColor)
        .overlay {
            if !isDisplayed {
                ZStack {
                    Rectangle()
                        .fill(Color.white.opacity(0.15))
                    Text("미노출")
                        .font(.custom("Galmuri9", size: 14))
                        .foregroundColor(Color.white.opacity(0.9))
                }
            }
        }
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

enum HistoryTimeFormatter {
    static func string(from rawTime: Int) -> String {
        let seconds = rawTime % 100
        let minutes = (rawTime / 100) % 100
        let hours = rawTime / 10000

        if rawTime > 9999, seconds < 60, minutes < 60 {
            return "\(hours):\(String(format: "%02d", minutes)):\(String(format: "%02d", seconds))"
        }

        let totalHours = max(0, rawTime / 3600)
        let remainingMinutes = max(0, (rawTime % 3600) / 60)
        let remainingSeconds = max(0, rawTime % 60)
        return "\(totalHours):\(String(format: "%02d", remainingMinutes)):\(String(format: "%02d", remainingSeconds))"
    }
}
