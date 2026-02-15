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
    let elapsedTime: Int?
    let remainingTime: Int?
    let timeType: String?
    let difficulty: Double?
    let scareScore: Int?
    let activityScore: Int?
    let visitDate: String?
    let hints: Int?
    let isSuccess: Bool?
    let createdAt: String?
    let isMyReview: Bool?
    let nickname: String?

    init(
        id: Int,
        content: String? = nil,
        people: Int? = nil,
        time: Int? = nil,
        elapsedTime: Int? = nil,
        remainingTime: Int? = nil,
        timeType: String? = nil,
        difficulty: Double? = nil,
        scareScore: Int? = nil,
        activityScore: Int? = nil,
        visitDate: String? = nil,
        hints: Int? = nil,
        isSuccess: Bool? = nil,
        createdAt: String? = nil,
        isMyReview: Bool? = nil,
        nickname: String? = nil
    ) {
        self.id = id
        self.content = content
        self.people = people
        self.time = time
        self.elapsedTime = elapsedTime
        self.remainingTime = remainingTime
        self.timeType = timeType
        self.difficulty = difficulty
        self.scareScore = scareScore
        self.activityScore = activityScore
        self.visitDate = visitDate
        self.hints = hints
        self.isSuccess = isSuccess
        self.createdAt = createdAt
        self.isMyReview = isMyReview
        self.nickname = nickname
    }

    var effectiveTimeType: String {
        if let timeType, !timeType.isEmpty {
            return timeType
        }
        return "ELAPSED"
    }

    var effectiveTimeInSeconds: Int {
        if let time {
            return time
        }
        switch effectiveTimeType {
        case "RAMAINING":
            return remainingTime ?? 0
        case "NONE":
            return 0
        default:
            return elapsedTime ?? remainingTime ?? 0
        }
    }
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

struct ReviewUpdateRequest: Encodable, Equatable {
    let content: String
    let people: Int
    let time: Int
    let timeType: String
    let scareScore: Int
    let activityScore: Int
    let difficulty: Double
    let hints: Int
    let visitDate: String?
    let isSuccess: Bool
    let themeId: Int?
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

    init(
        reviewId: Int,
        storeName: String,
        themeTitle: String,
        time: Int,
        isSuccess: Bool,
        isDisplay: Bool,
        canUpdateDisplay: Bool = true
    ) {
        self.reviewId = reviewId
        self.storeName = storeName
        self.themeTitle = themeTitle
        self.time = time
        self.isSuccess = isSuccess
        self.isDisplay = isDisplay
        self.canUpdateDisplay = canUpdateDisplay
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
