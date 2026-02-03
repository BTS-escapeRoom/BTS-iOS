//
//  Board.swift
//  Bantalsonyeondan
//
//  Created by 이상현 on 2/13/25.
//

import Foundation

struct Board: Decodable, Equatable, Identifiable {
    let id: Int
    let type: String
    let title: String
    let hit: Int
    let memberId: Int?
    let profileImg: String?
    let memberName: String
    let themeName: String?
    let storeName: String?
    let escapeDate: String?
    let recruitPeople: Int?
    let recruitDeadline : String?
    let contactUrl : String?
    let contactMethod : String?
    let likeCount : Int
    let commentCount : Int
    let createdAt : String?
    let updatedAt : String?
    let isPopular : Bool
}

struct BoardSimple: Decodable, Equatable {
    let id: Int
    let type: String
    let title: String
    let description: String
    let hit: Int
}

struct BoardDetail: Decodable, Equatable {
    let id: Int
    let type: String
    let title: String
    let description: String
    let memberId: Int?
    let memberName: String
    let profileImg: String?
    let recruit_deadline: String?
    let escape_date: String?
    let recruit_people: Int?
    let contact_url: String?
    let contact_method: String?
    let hit: Int
    let reportStatus: String?
    let likeCount: Int
    let commentCount: Int
    let theme: ThemeDetail
}

struct BoardCreateRequest: Encodable {
    let themeId: Int?
    let type: String
    let title: String
    let description: String
    let recruit_deadline: String
    let escape_date: String
    let recruit_people: String
    let contact_url: String
    let contact_method: String
}

struct BoardRequest: Encodable {
    let keyword: String?
    let type: String?
    let sortType: SortOption?
    let page: Int
    
    init(keyword: String? = nil, type: String? = nil, sortType: SortOption? = nil, page: Int = 0) {
        self.keyword = keyword
        self.type = type
        self.sortType = sortType
        self.page = page
    }
}

struct BoardResponse: Decodable, Equatable {
    let boards: [Board]
    let nextPage: Int
    let totalPage: Int
}
