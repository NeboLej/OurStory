//
//  FriendListScreen.swift
//  OurStory
//
//  Created by Nebo on 17.09.2026.
//

import SwiftUI

struct FriendListScreen: View {
    
    @State private var store: FriendListScreenStore
    
    init(store: FriendListScreenStore) {
        self.store = store
    }
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            List {
                ForEach(store.state.allFriends, id: \.self) { friend in
                    friendRow(friend: friend)
                        .listRowBackground(Color.clear)
                }
            }
            .listStyle(.plain)
            .navigationTitle("Друзья")
            .navigationBarTitleDisplayMode(.large)
            .background(.backgroundFill)
            
            Button {
                store.send(.addNewRandomFriend)
            } label: {
                Image(systemName: "plus")
                    .font(Font.myRegular(size: 24))
                    .padding(8)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.glassProminent)
            .tint(.myPrimary)
            .padding(.trailing , 16)
        }
    }
    
    @ViewBuilder
    private func friendRow(friend: Friend) -> some View {
        HStack(spacing: 14) {
            Circle()
                .fill(Color(hex: friend.color))
                .frame(width: 38, height: 38)
            
            Text(friend.name)
                .font(.myMedium(size: 16))
                .foregroundStyle(.textMulticolor)
            
            Spacer()
        }
    }
}

#Preview {
    ScreenBuilder.previewBuilder.getScreen(type: .friendList)
}
