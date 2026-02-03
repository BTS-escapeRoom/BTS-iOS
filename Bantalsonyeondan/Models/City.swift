//
//  City.swift
//  Bantalsonyeondan
//
//  Created by 이상현 on 2/13/25.
//

import Foundation

struct City: Decodable, Equatable {
    let id: Int
    let name: String
    let districtList: DistrictList
}

struct DistrictList: Decodable, Equatable {
    let id: Int
    let name: String
    let storeCount: Int
}
