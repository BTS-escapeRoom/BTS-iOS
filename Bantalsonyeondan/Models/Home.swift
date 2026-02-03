//
//  Home.swift
//  Bantalsonyeondan
//
//  Created by 이상현 on 2/13/25.
//

import Foundation

struct Home: Decodable, Equatable {
    let ui_type: String
    let title: String
    let url: String
}

struct MyResponse: Decodable, Equatable {
    let name: String
}
