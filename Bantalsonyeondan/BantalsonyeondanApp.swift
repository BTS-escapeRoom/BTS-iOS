//
//  BantalsonyeondanApp.swift
//  Bantalsonyeondan
//
//  Created by 이상현 on 7/31/24.
//

import SwiftUI
import ComposableArchitecture
import KakaoSDKCommon
import KakaoSDKAuth

@MainActor
private enum AppURLRouter {
    static func handle(_ url: URL) -> Bool {
        #if DEBUG
        print("[DEBUG] App received URL: \(url.absoluteString)")
        #endif

        if AuthApi.isKakaoTalkLoginUrl(url) {
            return AuthController.handleOpenUrl(url: url)
        }

        NaverSignInManager.shared.handleOpenURL(url)
        return true
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey : Any] = [:]
    ) -> Bool {
        AppURLRouter.handle(url)
    }
}

@main
struct MyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        KakaoSDK.initSDK(appKey: "a93ca2d555bc0d7e5195bdfb2c8ecdc1")
        NaverSignInManager.configure()
    }

    var body: some Scene {
        WindowGroup {
            AppView(
                store: Store(
                    initialState: AppFeature.State()
                ) {
                    AppFeature()
                }
            )
            .onAppear {
                UIToolbar.appearance().setBackgroundImage(UIImage(), forToolbarPosition: .any, barMetrics: .default)
                UIToolbar.appearance().shadowImage(forToolbarPosition: .any)
                UIToolbar.appearance().barTintColor = .white
            }
            .onOpenURL { url in
                _ = AppURLRouter.handle(url)
            }
        }
    }
}
