//
//  APIClient+DependencyKeys.swift
//  Bantalsonyeondan
//
//  Created by 이상현 on 1/22/25.
//

import ComposableArchitecture
import Foundation

private struct DependencyKeyFor<T: APIClient>: DependencyKey {
    static var liveValue: T { T.live }
    static var previewValue: T { T.preview }
    static var testValue: T { T.test }
}

extension DependencyValues {
    var reviewAPIClient: ReviewAPIClient {
        get { self[DependencyKeyFor<ReviewAPIClient>.self] }
        set { self[DependencyKeyFor<ReviewAPIClient>.self] = newValue }
    }
    
    var memberAPIClient: MemberAPIClient {
        get { self[DependencyKeyFor<MemberAPIClient>.self] }
        set { self[DependencyKeyFor<MemberAPIClient>.self] = newValue }
    }
    
    var commentAPIClient: CommentAPIClient {
        get { self[DependencyKeyFor<CommentAPIClient>.self] }
        set { self[DependencyKeyFor<CommentAPIClient>.self] = newValue }
    }
    
    var themeAPIClient: ThemeAPIClient {
        get { self[DependencyKeyFor<ThemeAPIClient>.self] }
        set { self[DependencyKeyFor<ThemeAPIClient>.self] = newValue }
    }
    
    var boardAPIClient: BoardAPIClient {
        get { self[DependencyKeyFor<BoardAPIClient>.self] }
        set { self[DependencyKeyFor<BoardAPIClient>.self] = newValue }
    }
    
    var userAPIClient: UserAPIClient {
        get { self[DependencyKeyFor<UserAPIClient>.self] }
        set { self[DependencyKeyFor<UserAPIClient>.self] = newValue }
    }
}
