//
//  BaseEntity.swift
//  Bantalsonyeondan
//
//  Created by 이상현 on 2/5/25.
//

import Foundation

struct BaseResponse<T: Decodable>: Decodable {
    let code: String
    let message: String?
    let data: T
}