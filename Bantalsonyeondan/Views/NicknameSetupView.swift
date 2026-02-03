//
//  HomeView.swift
//  Bantalsonyeondan
//
//  Created by 이상현 on 10/29/24.
//

import SwiftUI

struct NicknameSetupView: View {
    @State private var nickname: String = "초코심장도리얼글자씩"
    @State private var showAlert: Bool = false
    
    var body: some View {
        NavigationStack {
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
                
                Image("nickname_setting_lock_hall")
                    .frame(width: 68, height: 68)
                    
                
                VStack {
                    Text("반갑습니다!")
                        .font(.title3)
                        .fontWeight(.bold)
                        .padding(.bottom)
                    Text("방탈소년단에서 사용할 닉네임을 설정해 주세요")
                      .font(.title3)
                      .fontWeight(.bold)
                }.frame(width: 213, height: 98)
                .padding(.bottom)
                
                HStack {
                    TextField("닉네임을 입력해주세요 (최대 10자)", text: $nickname)
                        .padding()
                        .background(Color("FAFAFA"))
                        .cornerRadius(2)
                        .overlay {
                            HStack {
                                Spacer() // 오른쪽 정렬을 위해 Spacer 사용
                                if (!nickname.isEmpty) {
                                    Button(action: {
                                        nickname = ""
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(Color("BDBDBD"))
                                            .frame(width: 16, height: 16)
                                    }
                                    .padding(.trailing, 10) // 버튼과 텍스트필드 오른쪽 간격 조정
                                }
                            }
                        }
                }
                .padding(.horizontal)
                
                if showAlert {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.yellow)
                        Text("이미 사용중인 닉네임입니다.")
                            .foregroundColor(.black)
                        Spacer()
                        Button(action: {
                            showAlert = false
                        }) {
                            Image(systemName: "xmark")
                                .foregroundColor(.gray)
                        }
                    }
                    .padding()
                    .background(Color.yellow.opacity(0.8))
                    .cornerRadius(8)
                    .padding(.horizontal)
                }
                
                Spacer()
                
                NavigationLink(value: nickname) {
                    Text("완료")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(nickname.isEmpty ? Color("BDBDBD") : Color.black)
                        .cornerRadius(10)
                }
                .disabled(nickname.isEmpty)
                .padding(.horizontal)
            }
            .navigationDestination(for: String.self) { name in
                NicknameSetupedView(nickname: name)
            }
        }
    }
}

// 미리보기
struct NicknameSetupView_Previews: PreviewProvider {
    static var previews: some View {
        NicknameSetupView()
    }
}
