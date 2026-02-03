//
//  SearchBar.swift
//  Bantalsonyeondan
//
//  Created by 이상현 on 4/17/25.
//

import SwiftUI

struct CustomSearchBar: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String
    
    class Coordinator: NSObject, UISearchBarDelegate {
        @Binding var text: String
        
        init(text: Binding<String>) {
            _text = text
        }
        
        func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
            let color = UIColor(named: "Mono-05")!
            searchBar.searchTextField.layer.borderColor = color.cgColor
            searchBar.searchTextField.tintColor = color
            guard let leftIconView = searchBar.searchTextField.leftView as? UIImageView else { return }
            leftIconView.image = leftIconView.image?.withRenderingMode(.alwaysTemplate)
            leftIconView.tintColor = color
        }
        
        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            text = searchText
        }
        
        // 추가적인 delegate 메서드 구현 가능 (예: 검색 버튼 클릭, 취소 버튼 등)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }
    
    func makeUIView(context: Context) -> UISearchBar {
        let searchBar = UISearchBar(frame: .zero)
        searchBar.delegate = context.coordinator
        searchBar.searchTextField.layer.borderColor = UIColor(named: "oslo_gray")?.cgColor
        searchBar.searchTextField.layer.borderWidth = 1
        searchBar.searchTextField.layer.cornerRadius = 6
        searchBar.searchTextField.backgroundColor = .clear
        searchBar.backgroundColor = .clear
        searchBar.tintColor = UIColor(named: "oslo_gray")
        searchBar.placeholder = placeholder
        searchBar.backgroundImage = UIImage()
        return searchBar
    }
    
    func updateUIView(_ uiView: UISearchBar, context: Context) {
        uiView.text = text
    }
}

