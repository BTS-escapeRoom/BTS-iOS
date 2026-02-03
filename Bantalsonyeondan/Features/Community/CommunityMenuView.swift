//import SwiftUI
//import ComposableArchitecture
//
//struct CommunityMenuView: View {
//    let store: StoreOf<CommunityFeature>
//    @State private var searchText: String = ""
//    @State private var sortOption: SortOption = .latest
//    
//    var body: some View {
//        WithViewStore(store, observe: { $0 }) { viewStore in
//            VStack {
//                CustomSearchBar(text: $searchText, placeholder: "모집글, 업체명, 키워드 검색")
//                    .padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
//                Divider()
//                Menu {
//                    ForEach(SortOption.allCases) { option in
//                        Button(option.displayName) {
//                            sortOption = option
//                            viewStore.send(.onSortOptionSelected(option))
//                        }
//                    }
//                } label: {
//                    HStack(spacing: 4) {
//                        Text(sortOption.displayName)
//                            .font(.subheadline)
//                            .tint(Color("cod_gray"))
//                        Image("polygon")
//                    }
//                }
//                .frame(maxWidth: .infinity, alignment: .trailing)
//                .padding(.horizontal, 16)
//                Spacer()
//                if viewStore.isLoading {
//                    ProgressView("Loading...")
//                    Spacer()
//                } else {
//                    ScrollView {
//                        LazyVStack(spacing: 12) {
//                            ForEach(viewStore.boards) { board in
//                                BoardCardView(board: board)
//                                    .padding(.horizontal)
//                            }
//                        }
//                        .padding(.top, 8)
//                    }
//                }
//            }
//            .onAppear {
//                viewStore.send(.fetchBoards)
//            }
//            .onChange(of: searchText) { newValue in
//                viewStore.send(.changeSearchText(newValue))
//            }
//        }
//    }
//}
//
//// BoardCardView와 CheckboxToggleStyle은 CommunityView.swift에서 참고하여 사용하세요.
