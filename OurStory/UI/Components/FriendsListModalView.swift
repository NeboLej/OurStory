//
//  FriendsListModalView.swift
//  OurStory
//
//  Created by Nebo on 09.09.2026.
//

import SwiftUI

struct FriendsListModalView: View {
    
    var allFriends: [Friend]
    var selectedFriends: [Friend]
    
    var selectedFriend: (Friend) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(allFriends) { friend in
                Button {
                    selectedFriend(friend)
//                    store.send(.selectFriend(friend))
                } label: {
                    HStack {
                        Circle()
                            .foregroundStyle(Color(hex: friend.color))
                            .frame(height: 24)
                        Text(friend.name)
                            .font(.myRegular(size: 16))
                            .foregroundStyle(.textMulticolor)
                        Spacer()
                        if selectedFriends.contains(friend) {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.textMulticolor)
                        }
                    }
                    .padding(.vertical, 6)
                }
            }
        }
        .padding()
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .transition(.scale(scale: 0.75).combined(with: .opacity))
    }
}

#Preview {
    FriendsListModalView(allFriends: Friend.mock, selectedFriends: Friend.getRandomFriends(), selectedFriend: {
        print($0.name)
    })
}
