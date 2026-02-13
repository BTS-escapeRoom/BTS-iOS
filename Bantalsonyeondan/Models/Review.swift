//
//  Review.swift
//  Bantalsonyeondan
//
//  Created by 이상현 on 2/13/25.
//

import Foundation


struct Review: Encodable, Decodable, Equatable, Identifiable {
    let id: Int
    let content: String?
    let people: Int?
    let time: Int?
    let difficulty: Double?
    let scareScore: Int?
    let activityScore: Int?
    let visitDate: String?
    let hints: Int?
    let isSuccess: Bool?
    let createdAt: String?
    let isMyReview: Bool?
    let nickname: String?
}

struct ReviewRegist: Encodable, Decodable, Equatable {
    let content: String
    let people: Int
    let time: Int
    let scareScore: Int
    let activityScore: Int
    let difficulty: Int
    let hints: Int
    let visitDate: String
    let isSuccess: Bool
    let themeId: Int
}

struct ReviewHistory: Decodable, Equatable, Identifiable {
    let reviewId: Int
    let storeName: String
    let themeTitle: String
    let time: Int
    let isSuccess: Bool
    var isDisplay: Bool
    let canUpdateDisplay: Bool

    var id: Int { reviewId }

    private enum CodingKeys: String, CodingKey {
        case reviewId
        case storeName
        case themeTitle
        case time
        case isSuccess
        case isDisplay
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.reviewId = try container.decode(Int.self, forKey: .reviewId)
        self.storeName = try container.decode(String.self, forKey: .storeName)
        self.themeTitle = try container.decode(String.self, forKey: .themeTitle)
        self.time = try container.decodeIfPresent(Int.self, forKey: .time) ?? 0
        self.isSuccess = try container.decode(Bool.self, forKey: .isSuccess)
        let decodedIsDisplay = try container.decodeIfPresent(Bool.self, forKey: .isDisplay)
        self.isDisplay = decodedIsDisplay ?? false
        self.canUpdateDisplay = decodedIsDisplay != nil
    }
}
