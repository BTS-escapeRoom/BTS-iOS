import SwiftUI

/// 신고 사유 입력 시트 (게시글/댓글/리뷰 공용)
struct ReportSheet: View {
    @Binding var description: String
    let title: String
    let onSubmit: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // 핸들
            Capsule()
                .fill(Color(.systemGray4))
                .frame(width: 36, height: 4)
                .padding(.top, 12)
                .padding(.bottom, 20)

            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)

            Text("신고 사유를 입력해주세요.")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 4)
                .padding(.bottom, 12)

            ZStack(alignment: .topLeading) {
                TextEditor(text: $description)
                    .frame(height: 120)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                if description.isEmpty {
                    Text("예) 욕설, 스팸, 음란물 등")
                        .foregroundColor(Color(.placeholderText))
                        .padding(.top, 16)
                        .padding(.leading, 12)
                        .allowsHitTesting(false)
                }
            }
            .padding(.horizontal, 20)

            HStack(spacing: 12) {
                Button("취소") {
                    dismiss()
                }
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(Color(.systemGray5))
                .foregroundColor(.primary)
                .cornerRadius(10)

                Button("신고하기") {
                    onSubmit()
                }
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray.opacity(0.4) : Color.black.opacity(0.85))
                .foregroundColor(.white)
                .cornerRadius(10)
                .disabled(description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .presentationDetents([.height(320)])
        .presentationDragIndicator(.hidden)
    }
}
