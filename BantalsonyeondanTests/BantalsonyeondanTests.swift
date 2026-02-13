//
//  BantalsonyeondanTests.swift
//  BantalsonyeondanTests
//
//  Created by 이상현 on 7/31/24.
//

import XCTest
import ComposableArchitecture
@testable import Bantalsonyeondan

@MainActor
final class BantalsonyeondanTests: XCTestCase {
    func testAppFeatureSelectTab() async {
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        }

        await store.send(.selectTab(.community)) {
            $0.selectedTab = .community
        }
        await store.send(.selectTab(.myPage)) {
            $0.selectedTab = .myPage
        }
    }

    func testMyFeatureBlocksLegacyDisplayToggle() async {
        var initialState = MyFeature.State()
        initialState.histories = [
            ReviewHistory(
                reviewId: 100,
                storeName: "테스트 지점",
                themeTitle: "테스트 테마",
                time: 0,
                isSuccess: true,
                isDisplay: false,
                canUpdateDisplay: false
            )
        ]

        let store = TestStore(initialState: initialState) {
            MyFeature()
        }

        await store.send(.toggleHistoryDisplay(reviewId: 100)) {
            $0.errorMessage = "이 기록은 미노출 설정을 변경할 수 없어요."
        }
    }

    func testReviewHistoryDecodingHandlesNullFields() throws {
        let json = """
        {
          "reviewId": 12,
          "storeName": "셜록홈즈 1호점",
          "themeTitle": "산속의 여인",
          "time": null,
          "isSuccess": false,
          "isDisplay": null
        }
        """
        let data = Data(json.utf8)
        let history = try JSONDecoder().decode(ReviewHistory.self, from: data)

        XCTAssertEqual(history.time, 0)
        XCTAssertEqual(history.isDisplay, false)
        XCTAssertEqual(history.canUpdateDisplay, false)
    }
}
