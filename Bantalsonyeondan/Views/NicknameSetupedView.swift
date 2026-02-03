
import SwiftUI

struct NicknameSetupedView: View {
    var nickname: String = "초코심장도리얼글자씩"
    
    var body: some View {
        VStack(spacing: 20) {
            // 상단 네비게이션 타이틀
            ZStack {
                HStack {
                    Button(action: {
                        // 뒤로 가기 액션
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.black)
                    }.padding(.horizontal)
                    Spacer()
                }
                Text("닉네임 설정")
                    .font(.headline)
            }
            
            Spacer()
            
            // 축하 이미지
            Image("nickname_signup_Done")
                .resizable()
                .scaledToFit()
                .frame(width: 150, height: 150)
            
            // 축하 메시지
            Text("축하합니다!")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("\(nickname)님")
                .font(.title3)
                .fontWeight(.bold)
            
            Text("방탈보이즈와 함께 알찬 방탈출 생활 하세요")
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
            
            // 입장 버튼
            Button(action: {
                // 입장 액션
            }) {
                Text("입장")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.black)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .navigationBarHidden(true)
    }
}

// 미리보기
struct NicknameSetupedView_Previews: PreviewProvider {
    static var previews: some View {
        NicknameSetupedView()
    }
}
