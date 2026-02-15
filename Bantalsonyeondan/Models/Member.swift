//
//  Member.swift
//  Bantalsonyeondan
//
//  Created by 이상현 on 2/13/25.
//

import Foundation

struct MemberUpdateRequest: Encodable {
    let profileImg: String?
    let nickname: String?
    let description: String?
}

struct Member: Codable, Equatable {
    let id: Int
    let profileImg: String?
    let nickname: String?
    let description: String?
    let socialType: String?
    let role: String?
}
