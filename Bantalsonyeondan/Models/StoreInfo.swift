//
//  Store.swift
//  Bantalsonyeondan
//
//  Created by 이상현 on 2/13/25.
//

import Foundation

struct StoreInfo: Decodable, Equatable {
    let id: Int
    let name: String
    let thumbnail: String
    let location: String
}

struct StoreInfoDetail: Decodable, Equatable {
    let id: Int
    let name: String
    let thumbnail: String
    let description: String
    let location: String
    let registrationDate: String
    let themeList: [Theme]
}
