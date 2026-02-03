import SwiftUI
import ComposableArchitecture

struct MyView: View {
    let store: StoreOf<MyFeature>
    
    var body: some View {
        WithViewStore(store, observe: \.self) { viewStore in
            VStack(alignment:.leading, spacing: 0) {
                Text("나의 탈출")
                    .font(.subheadline)
                    .bold()
                    .padding(10)
                HStack {
                    Circle()
                        .background(Image(.iconCommunitySelected))
                        .frame(width: 50, height: 50)
                    Text("닉네임123")
                        .padding(.leading, 10)
                    Spacer()
                }
                .padding(20)
                Text("나의 활동")
                    .padding(.leading, 10)
                Button(action: {
                    
                }, label: {
                    Text("모집 게시판")
                        .font(.subheadline)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 24)
                        .background(Color.BDBDBD)
                        .foregroundColor(.white)
                        .cornerRadius(24)
                        .shadow(radius: 2)
                })
                .frame(width: 300, height: 100)
                .foregroundStyle(.BDBDBD)
                Color.red.ignoresSafeArea()
            }
            .onAppear {  }
        }
    }
}
