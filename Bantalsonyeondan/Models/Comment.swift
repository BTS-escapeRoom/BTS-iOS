//
//  Comment.swift
//  Bantalsonyeondan
//
//  Created by 이상현 on 2/13/25.
//

import Foundation

struct CommentUpdateRequest: Encodable {
    let comment: String
}

struct Comment: Decodable, Equatable {
    let id: Int
    let comment: String
    let memberId: Int?
    let memberName: String
    let profileImg: String?
    let createdAt: String?
    let isDeleted: Bool?
    let isReported: Bool?
}

struct BoardCommentsResponse: Decodable, Equatable {
    let comments: [Comment]
    let totalCount: Int
}
