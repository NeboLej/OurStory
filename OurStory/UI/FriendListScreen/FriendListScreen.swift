//
//  FriendListScreen.swift
//  OurStory
//
//  Created by Nebo on 17.09.2026.
//

import SwiftUI

import SwiftUI

struct FriendListScreen: View {
    
    @State private var store: FriendListScreenStore
    
    init(store: FriendListScreenStore) {
        self.store = store
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 0) {
                    Rectangle()
                        .frame(height: 1)
                        .foregroundStyle(.textMulticolor.opacity(0.35))
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                    
                    if store.state.allFriends.isEmpty {
                        Text("СПИСОК ПУСТ")
                            .font(.mySemiBold(size: 11))
                            .tracking(1.5)
                            .foregroundStyle(.textMulticolor.opacity(0.4))
                            .padding(.top, 40)
                    } else {
                        ForEach(store.state.allFriends, id: \.self) { friend in
                            friendRow(friend: friend)
                        }
                    }
                    
                    Color.clear
                        .frame(height: 100)
                }
            }
            .background(.backgroundFill)
            
            
            VStack(spacing: 0) {
                LinearGradient(
                    colors: [.backgroundFill.opacity(0), .backgroundFill],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 24)
                
                Button {
                    store.send(.toNewFriend)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .bold))
                        
                        Text("ДОБАВИТЬ ДРУГА")
                            .font(.mySemiBold(size: 14))
                            .tracking(2)
                    }
                    .foregroundStyle(.black)
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
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
        }
        .frame(maxWidth: .infinity)
        .navigationTitle("Друзья")
        .navigationBarTitleDisplayMode(.large)
    }
    
    
    @ViewBuilder
    private func friendRow(friend: Friend) -> some View {
        Button {
            store.send(.toFriend(friend))
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color(hex: friend.color))
                        .frame(width: 34, height: 34)
                    
                    Circle()
                        .stroke(.backgroundFill, lineWidth: 1.5)
                        .frame(width: 31, height: 31)
                }
                
                Text(friend.name.uppercased())
                    .font(.myMedium(size: 16))
                    .tracking(0.5)
                    .foregroundStyle(.textMulticolor)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.textMulticolor.opacity(0.3))
                    .padding(.trailing, 4)
            }
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottom) {
            Rectangle()
                .frame(height: 0.5)
                .foregroundStyle(.textMulticolor.opacity(0.2))
        }
        .padding(.horizontal, 20)
    }
}

#Preview {
    NavigationStack {
        ScreenBuilder.previewBuilder.getScreen(type: .friendList)
    }
    
}
