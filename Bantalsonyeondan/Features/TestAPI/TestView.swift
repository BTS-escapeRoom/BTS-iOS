//
//  TestView.swift
//  Bantalsonyeondan
//
//  Created by 이상현 on 3/5/25.
//

import SwiftUI
import ComposableArchitecture

struct APITestView: View {
    var store: StoreOf<TestFeature>

    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            VStack {
                Button("API 테스트 실행") {
                    store.send(.runAllTests)
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
                
                List(viewStore.results, id: \.self) { result in
                    Text(result)
                }
            }
            .padding()
        }
    }
}

