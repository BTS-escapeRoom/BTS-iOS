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

