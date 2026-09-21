//
//  NewFriendScreen.swift
//  OurStory
//
//  Created by Nebo on 21.09.2026.
//

import SwiftUI

struct NewFriendScreen: View {
    @State private var store: NewFriendScreenStore
    @State private var name: String = ""
    @State private var selectedColor: Color = .red
    
    init(store: NewFriendScreenStore) {
        self.store = store
    }
    
    var body: some View {
        ZStack {
            Color(.backgroundFill)
                .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 0) {
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("НОВЫЙ\nПРОФИЛЬ № 1")
                        .font(.mySemiBold(size: 30))
                        .tracking(2)
                        .foregroundColor(.textMulticolor)
                    
                    VStack(spacing: 4) {
                        Divider().frame(height: 3).background(.textMulticolor)
                        Divider().frame(height: 0.5).background(.textMulticolor)
                    }
                    .padding(.top, 4)
                }
                .padding(.bottom, 40)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("ИМЯ ПОЛЬЗОВАТЕЛЯ")
                        .font(.myMedium(size: 12))
                        .tracking(3)
                        .foregroundColor(.textMulticolor)
                    
                    TextField("Введите имя...", text: $name)
                        .font(.myItalic(size: 20))
                        .foregroundColor(.textMulticolor)
                        .tint(Color(hex: "#2B2A27"))
                        .padding(.vertical, 8)
                        .overlay(alignment: .bottom) {
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(Color(hex: "#A39E93"))
                        }
                }
                .padding(.bottom, 40)
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("ЦВЕТОВАЯ МЕТКА")
                        .font(.myMedium(size: 12))
                        .tracking(3)
                        .foregroundColor(.textMulticolor)
                    
                    CustomColorPicker(selectedColor: $selectedColor)
                }
                
                Spacer()
                
                Button {
                    print("старт сохранения")
                } label: {
                    VStack(spacing: 2) {
                        Text("СОХРАНИТЬ")
                            .font(.mySemiBold(size: 14))
                            .tracking(2)
                            .foregroundStyle(.black)
                        
//                        Text("------")
//                            .font(.myRegular(size: 10))
//                            .opacity(0.6)
//                            .foregroundStyle(.black)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.myPrimary)
                    .overlay {
                        Rectangle()
                            .stroke(Color.black.opacity(0.15), lineWidth: 1)
                            .padding(3)
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(12)
        }
    }
}

#Preview {
    ScreenBuilder.previewBuilder.getScreen(type: .newFriend)
//    @Previewable @State var selectedColor: Color = .red
    
//    CustomColorPicker(selectedColor: $selectedColor)
}
