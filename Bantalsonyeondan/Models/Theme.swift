//
//  Theme.swift
//  Bantalsonyeondan
//
//  Created by 이상현 on 1/15/25.
//

import Foundation

// 테마 기본 정보
struct Theme: Decodable, Equatable, Identifiable {
    let id: Int
    let thumbnail: String
    let title: String
    let minimumPeople: Int?
    let maximumPeople: Int?
    let difficulty: Double?
    let genre: String?
    let time: Int?
    let genreType: String
    let status: String?
    let store: String
    let city: String
    let dictrict: String?
}

struct ThemeResponse: Decodable, Equatable {    
    let themes: [Theme]
    let nextPage: Int
    let totalPage: Int
}
    

struct ThemeRequest: Encodable {
    let keyword: String?
    let peoples: Int?
    let minDiff: Int?
    let maxDiff: Int?
    let genreIdList: [Int]?
    let districtIdList: [Int]?
    let cityIdList: [Int]?
    let sort: SortOption?
    let latitude: Double?
    let longitude: Double?
    let page: Int
    
    init(
        keyword: String?        = nil,
        peoples: Int?           = nil,
        minDiff: Int?           = nil,
        maxDiff: Int?           = nil,
        genreIdList: [Int]?     = nil,
        districtIdList: [Int]?  = nil,
        cityIdList: [Int]?      = nil,
        sort: SortOption?       = nil,
        latitude: Double?       = nil,
        longitude: Double?      = nil,
        page: Int               = 1
    ) {
        self.keyword = keyword
        self.peoples = peoples
        self.minDiff = minDiff
        self.maxDiff = maxDiff
        self.genreIdList = genreIdList
        self.districtIdList = districtIdList
        self.cityIdList = cityIdList
        self.sort = sort
        self.latitude = latitude
        self.longitude = longitude
        self.page   = page
    }
}

// 테마 상세 정보
struct ThemeDetail: Decodable, Equatable, Identifiable {
    let id: Int
    let thumbnail: String
    let title: String
    let description: String
    let minimumPeople: Int?
    let maximumPeople: Int?
    let recommendPeople: Int?
    let difficulty: Int
    let genre: String?
    let fearLevel: Int?
    let time: Int
    let price: Int
    let reservationUrl: String?
    let notes: String
    let registrationDate: String?
    let genreType: String?
    let status: String?
    let store: ThemeStore?
    let weekdaysTimeList: [TimeSlot]
    let weekendTimeList: [TimeSlot]
}

// 매장 정보
struct ThemeStore: Decodable, Equatable {
    let id: Int
    let name: String
    let thumbnail: String?
    let location: String
}

// 시간표 정보
struct TimeSlot: Decodable, Equatable, Identifiable {
    let id: Int
    let time: String
}
