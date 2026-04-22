//
//  UIComponents.swift
//  Bantalsonyeondan
//
//  Created by Codex on 3/3/26.
//

import SwiftUI
import UIKit
import CryptoKit

// MARK: - Cached Async Image
actor AppImageCache {
    static let shared = AppImageCache()

    private let memoryCache = NSCache<NSString, NSData>()
    private let fileManager: FileManager
    private let directoryURL: URL
    private var inFlightTasks: [String: Task<Data, Error>] = [:]

    init(
        directoryURL: URL? = nil,
        fileManager: FileManager = .default,
        memoryCostLimit: Int = 80 * 1024 * 1024
    ) {
        self.fileManager = fileManager

        if let directoryURL {
            self.directoryURL = directoryURL
        } else {
            let cacheRoot = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
            self.directoryURL = cacheRoot.appendingPathComponent("BTSImageCache", isDirectory: true)
        }

        memoryCache.totalCostLimit = memoryCostLimit
        try? fileManager.createDirectory(at: self.directoryURL, withIntermediateDirectories: true)
    }

    func data(for url: URL, session: URLSession = .shared) async throws -> Data {
        let key = cacheKey(for: url)

        if let memoryData = memoryCache.object(forKey: key as NSString) {
            return memoryData as Data
        }

        let diskURL = directoryURL.appendingPathComponent(key)
        if fileManager.fileExists(atPath: diskURL.path),
           let diskData = try? Data(contentsOf: diskURL) {
            memoryCache.setObject(diskData as NSData, forKey: key as NSString, cost: diskData.count)
            return diskData
        }

        if let existingTask = inFlightTasks[key] {
            return try await existingTask.value
        }

        let task = Task<Data, Error> {
            let (data, response) = try await session.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw URLError(.badServerResponse)
            }
            return data
        }

        inFlightTasks[key] = task

        do {
            let data = try await task.value
            memoryCache.setObject(data as NSData, forKey: key as NSString, cost: data.count)
            try data.write(to: diskURL, options: .atomic)
            inFlightTasks.removeValue(forKey: key)
            return data
        } catch {
            inFlightTasks.removeValue(forKey: key)
            throw error
        }
    }

    private func cacheKey(for url: URL) -> String {
        let digest = SHA256.hash(data: Data(url.absoluteString.utf8))
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }
}

private enum AppImageLoaderError: Error {
    case invalidImageData
}

struct CachedAsyncImage<Content: View>: View {
    let url: URL?
    let transaction: Transaction
    let content: (AsyncImagePhase) -> Content

    @State private var phase: AsyncImagePhase = .empty
    @State private var loadTask: Task<Void, Never>?

    init(
        url: URL?,
        transaction: Transaction = Transaction(),
        @ViewBuilder content: @escaping (AsyncImagePhase) -> Content
    ) {
        self.url = url
        self.transaction = transaction
        self.content = content
    }

    var body: some View {
        content(phase)
            .onAppear {
                load()
            }
            .onChange(of: url) { _ in
                load()
            }
            .onDisappear {
                loadTask?.cancel()
                loadTask = nil
            }
    }

    private func load() {
        loadTask?.cancel()

        guard let url else {
            phase = .empty
            return
        }

        phase = .empty
        loadTask = Task {
            do {
                let data = try await AppImageCache.shared.data(for: url)
                guard !Task.isCancelled else { return }

                guard let uiImage = UIImage(data: data) else {
                    throw AppImageLoaderError.invalidImageData
                }

                await MainActor.run {
                    withTransaction(transaction) {
                        phase = .success(Image(uiImage: uiImage))
                    }
                }
            } catch {
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    withTransaction(transaction) {
                        phase = .failure(error)
                    }
                }
            }
        }
    }
}

// MARK: - Toast
enum AppToastStyle {
    case info
    case success
    case error

    var foreground: Color {
        return .black
    }

    var background: Color {
        switch self {
        case .info: return Color.black.opacity(0.85)
        case .success: return Color(red: 0.18, green: 0.72, blue: 0.42)
        case .error: return Color(red: 1.0, green: 0.78, blue: 0.1)
        }
    }

    var icon: String {
        switch self {
        case .info: return "info.circle.fill"
        case .success: return "checkmark.circle.fill"
        case .error: return "exclamationmark.triangle.fill"
        }
    }

    var isBottom: Bool { true }

    var cornerRadius: CGFloat { 0 }

    var borderColor: Color {
        switch self {
        case .info: return Color.gray
        case .success: return Color(red: 0.1, green: 0.55, blue: 0.3)
        case .error: return Color(red: 0.75, green: 0.55, blue: 0.0)
        }
    }
}

private struct AppToastModifier: ViewModifier {
    @Binding var message: String?
    let style: AppToastStyle
    let duration: TimeInterval
    let onDismiss: () -> Void

    @State private var visibleMessage: String?
    @State private var isShowing = false
    @State private var dismissTask: Task<Void, Never>?

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                if let visibleMessage, isShowing {
                    HStack(spacing: 10) {
                        // 원형 구멍 효과 아이콘
                        ZStack {
                            Circle()
                                .fill(style.foreground)
                                .frame(width: 28, height: 28)
                            Image(systemName: style.icon)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(style.background)
                        }
                        Text(visibleMessage)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(style.foreground)
                            .multilineTextAlignment(.leading)
                        Spacer()
                        Button {
                            withAnimation { isShowing = false }
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(style.foreground)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(style.background)
                    .clipShape(RoundedRectangle(cornerRadius: style.cornerRadius))
                    .overlay(
                        RoundedRectangle(cornerRadius: style.cornerRadius)
                            .stroke(style.borderColor, lineWidth: 1.5)
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(1000)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: isShowing)
            .onAppear {
                if let message {
                    show(message)
                }
            }
            .onChange(of: message) { newValue in
                guard let newValue else { return }
                show(newValue)
            }
    }

    private func show(_ message: String) {
        dismissTask?.cancel()
        visibleMessage = message
        isShowing = true

        dismissTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            guard !Task.isCancelled else { return }

            await MainActor.run {
                isShowing = false
                self.message = nil
                onDismiss()
            }
        }
    }
}

extension View {
    func appToast(
        message: Binding<String?>,
        style: AppToastStyle = .error,
        duration: TimeInterval = 2.0,
        onDismiss: @escaping () -> Void = {}
    ) -> some View {
        modifier(
            AppToastModifier(
                message: message,
                style: style,
                duration: duration,
                onDismiss: onDismiss
            )
        )
    }
}
