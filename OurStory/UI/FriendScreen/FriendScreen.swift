//
//  FriendScreen.swift
//  OurStory
//
//  Created by Nebo on 18.09.2026.
//

import SwiftUI

struct FriendScreen: View {
    
    @State var store: FriendScreenStore
    @State var isEditMode: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button {
                    isEditMode.toggle()
                } label: {
                    Text(isEditMode ? "СОХРАНИТЬ" : "ИЗМЕНИТЬ")
                        .font(.mySemiBold(size: 11))
                        .tracking(1.5)
                        .foregroundStyle( Color.textMulticolor.opacity(0.85))
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .overlay {
                            RoundedRectangle(cornerRadius: 2)
                                .stroke(Color.textMulticolor.opacity(0.35), lineWidth: 1)
                        }
                }.padding(.trailing, 12)
            }
            HStack(spacing: 16) {
                Circle()
                    .fill(Color(hex: store.state.friend.color))
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                Text(store.state.friend.name)
                    .font(.myMedium(size: 18))
                    .foregroundColor(.textMulticolor)
            }
            .padding(.vertical, 44)
            
            
            statisticElement(title: "Общих историй", value: "\(store.state.allStoriesCount)") {
                
            }
            statisticElement(title: "Историй не рассказано", value: "\(store.state.notSeenStoriesCount)") {
                
            }
            statisticElement(title: "Последняя синхронизация", value: "\(Date().toReadableDate())", onClick: nil)
            
            Spacer()
            Button {
                print("старт синхронизации")
            } label: {
                Text("Передать истории")
                    .font(.myMedium(size: 18))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .padding(12)
            .tint(.myPrimary)
            .buttonStyle(.glassProminent)
        }
        .frame(maxWidth: .infinity)
        .background(.backgroundFill)
    }
    
    
    @ViewBuilder
    private func statisticElement(title: String, value: String, onClick: (() -> Void)?) -> some View {
        Button {
            onClick?()
        } label: {
            HStack {
                Text(title)
                    .font(.myRegular(size: 18))
                    .foregroundStyle(.textMulticolor)
                Spacer()
                Text(value)
                    .font(onClick != nil ? .myMedium(size: 18) : .myRegular(size: 14))
                    .foregroundStyle(.textMulticolor)
                    .padding(.trailing, 12)
                
                if onClick != nil {
                    Image(systemName: "chevron.right")
                        .padding(.trailing, 12)
                        .foregroundStyle(.textMulticolor)
                }
            }
            .padding(12)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(style: .init(lineWidth: 1))
                
        }
        .padding(.top)
        .padding(.horizontal)
        .disabled(onClick == nil)
    }
}

#Preview {
    ScreenBuilder.previewBuilder.getScreen(type: .friend(Friend(name: "София", color: "F16C6C")))
}
