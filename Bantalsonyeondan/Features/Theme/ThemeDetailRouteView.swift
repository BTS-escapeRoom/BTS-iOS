import SwiftUI

struct ThemeDetailRouteView: View {
    let themeId: Int
    @State private var themeDetail: ThemeDetail? = nil
    @State private var isLoading = true
    @State private var errorMessage: String? = nil
    private let api = ThemeAPIClient()
    
    var body: some View {
        Group {
            if let detail = themeDetail {
                ThemeDetailView(themeInfo: detail, onDismiss: {})
            } else if let errorMessage {
                VStack(spacing: 12) {
                    Text("테마 정보를 불러오지 못했습니다.")
                    Text(errorMessage).font(.caption).foregroundColor(.gray)
                    Button("다시 시도") { load() }
                }
                .padding()
            } else {
                VStack { ProgressView().padding(); Text("불러오는 중...").font(.footnote).foregroundColor(.gray) }
            }
        }
        .onAppear { load() }
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func load() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                let detail = try await api.fetchThemeById(String(themeId))
                await MainActor.run {
                    self.themeDetail = detail
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
}
