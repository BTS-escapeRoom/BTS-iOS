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
    let district: String
}

struct ThemeGenrePresentation: Equatable {
    let title: String
    let assetName: String

    static func resolve(primary: String?, fallback: String?) -> ThemeGenrePresentation? {
        let rawValue = [primary, fallback]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first(where: { !$0.isEmpty })

        guard let rawValue else { return nil }

        let normalized = rawValue
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "_", with: "")
            .uppercased()

        switch normalized {
        case "SF":
            return .init(title: "SF", assetName: "SF")
        case "19금", "19":
            return .init(title: "19금", assetName: "19금")
        case "감성":
            return .init(title: "감성", assetName: "감성")
        case "게임":
            return .init(title: "게임", assetName: "게임")
        case "공포", "HORROR":
            return .init(title: "공포", assetName: "공포")
        case "드라마", "DRAMA":
            return .init(title: "드라마", assetName: "드라마")
        case "로맨스", "ROMANCE":
            return .init(title: "로맨스", assetName: "로맨스")
        case "미션", "MISSION":
            return .init(title: "미션", assetName: "미션")
        case "미스터리", "MYSTERY":
            return .init(title: "미스터리", assetName: "미스터리")
        case "범죄", "CRIME":
            return .init(title: "범죄", assetName: "범죄")
        case "사극":
            return .init(title: "사극", assetName: "사극")
        case "스릴러", "THRILLER":
            return .init(title: "스릴러", assetName: "스릴러")
        case "액션", "ACTION":
            return .init(title: "액션", assetName: "액션")
        case "어드벤처", "어드벤쳐", "ADVENTURE":
            return .init(title: "어드벤처", assetName: "어드벤처")
        case "잠입":
            return .init(title: "잠입", assetName: "잠입")
        case "코믹", "COMIC", "COMEDY":
            return .init(title: "코믹", assetName: "코믹")
        case "탐험":
            return .init(title: "탐험", assetName: "탐험")
        case "판타지", "FANTASY":
            return .init(title: "판타지", assetName: "판타지")
        case "기타", "ETC", "OTHER":
            return .init(title: "기타", assetName: "기타")
        default:
            return .init(title: rawValue, assetName: "기타")
        }
    }
}

extension Theme {
    var genrePresentation: ThemeGenrePresentation? {
        ThemeGenrePresentation.resolve(primary: genre, fallback: genreType)
    }
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

extension ThemeDetail {
    var genrePresentation: ThemeGenrePresentation? {
        ThemeGenrePresentation.resolve(primary: genre, fallback: genreType)
    }

    var parsedNotes: String {
        notes
            .replacingOccurrences(of: "\\n", with: "\n")
            .replacingOccurrences(of: "<br>", with: "\n")
            .replacingOccurrences(of: "<br/>", with: "\n")
            .replacingOccurrences(of: "<br />", with: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isAvailable: Bool {
        guard let status else { return true }

        switch status.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "false", "0", "n", "no", "unavailable", "closed", "inactive":
            return false
        case "true", "1", "y", "yes", "available", "open", "active", "":
            return true
        default:
            return true
        }
    }
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
