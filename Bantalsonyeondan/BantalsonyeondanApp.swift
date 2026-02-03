//
//  BantalsonyeondanApp.swift
//  Bantalsonyeondan
//
//  Created by 이상현 on 7/31/24.
//

import SwiftUI

//@main
//struct BantalsonyeondanApp: App {
//    var body: some Scene {
//        WindowGroup {
////            LoginView()
//
//        }
//    }
//}
import SwiftUI
import ComposableArchitecture

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
//            APITestView(
//                store: Store(initialState: TestFeature.State()) {
//                    TestFeature()
//                        .dependency(\.reviewAPIClient, ReviewAPIClient())
//                        .dependency(\.memberAPIClient, MemberAPIClient())
//                        .dependency(\.commentAPIClient, CommentAPIClient())
//                        .dependency(\.themeAPIClient, ThemeAPIClient())
//                        .dependency(\.boardAPIClient, BoardAPIClient())
//                        .dependency(\.storeAPIClient, StoreAPIClient())
//                        .dependency(\.homeAPIClient, HomeAPIClient())
//                        .dependency(\.genreAPIClient, GenreAPIClient())
//                        .dependency(\.cityAPIClient, CityAPIClient())
//                }
//            )
//            HomeView(
//                store: Store(
//                    initialState: HomeFeature.State()
//                ) {
//                    HomeFeature()
//                }
//            )
// -----------------------------
//            LoginView()
            
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
        }
    }
}
