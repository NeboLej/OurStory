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
    var onAddFriend: (() -> Void)? = nil
    var onExit: (() -> Void)?
    
    private let rowHeight: CGFloat = 44
    private let headerHeight: CGFloat = 56
    private let addButtonHeight: CGFloat = 48
    private let minContentHeight: CGFloat = 180
    
    private var calculatedHeight: CGFloat {
        let listHeight = CGFloat(allFriends.count) * rowHeight
        let total = headerHeight + listHeight + (onAddFriend != nil ? addButtonHeight : 0) + 16
        let windowHeight = (UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.frame.height) ?? 800
        return min(max(total, minContentHeight), windowHeight * 0.5)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("ДРУЗЬЯ")
                        .font(.mySemiBold(size: 13))
                        .tracking(2)
                        .foregroundStyle(.textMulticolor)
                    Text("\(selectedFriends.count) из \(allFriends.count)")
                        .font(.myRegular(size: 11))
                        .foregroundStyle(.textMulticolor.opacity(0.5))
                }
                
                Spacer()
                
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        onExit?()
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.textMulticolor.opacity(0.6))
                        .frame(width: 28, height: 28)
                        .background(Color.textMulticolor.opacity(0.08))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 8)
            
            // Divider
            VStack(spacing: 3) {
                Rectangle().frame(height: 1.5)
                Rectangle().frame(height: 0.5)
            }
            .foregroundStyle(.textMulticolor.opacity(0.15))
            .padding(.horizontal, 16)
            
            // Friends list
            if allFriends.isEmpty {
                Spacer()
                Text("Вы пока не добавили друзей")
                    .font(.myRegular(size: 14))
                    .foregroundStyle(.textMulticolor.opacity(0.4))
                    .frame(maxWidth: .infinity)
                Spacer()
            }
            
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(allFriends) { friend in
                        let isSelected = selectedFriends.contains(friend)
                        Button {
                            withAnimation(.spring(response: 0.25)) {
                                selectedFriend(friend)
                            }
                        } label: {
                            HStack(spacing: 12) {
                                Circle()
                                    .foregroundStyle(Color(hex: friend.color))
                                    .frame(width: 20, height: 20)
                                    .overlay {
                                        Circle()
                                            .stroke(Color.textMulticolor.opacity(0.15), lineWidth: 0.5)
                                    }
                                
                                Text(friend.name)
                                    .font(.myMedium(size: 15))
                                    .foregroundStyle(.textMulticolor)
                                
                                Spacer()
                                
                                if isSelected {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(.textMulticolor.opacity(0.7))
                                        .transition(.scale.combined(with: .opacity))
                                }
                            }
                            .padding(.horizontal, 16)
                            .frame(height: rowHeight)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        
                        if friend != allFriends.last {
                            Rectangle()
                                .frame(height: 0.5)
                                .foregroundStyle(.textMulticolor.opacity(0.08))
                                .padding(.leading, 48)
                                .padding(.trailing, 16)
                        }
                    }
                }
            }
            
            // Add friend button
            if onAddFriend != nil {
                addFriendButton()
            }
        }
        .frame(height: calculatedHeight)
        .glassEffect(Glass.regular, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .transition(.scale(scale: 0.75).combined(with: .opacity))
    }
    
    
    @ViewBuilder
    private func addFriendButton() -> some View {
        VStack(spacing: 0) {
            Rectangle()
                .frame(height: 0.5)
                .foregroundStyle(.textMulticolor.opacity(0.15))
                .padding(.horizontal, 16)
            
            Button {
                withAnimation {
                    onAddFriend?()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .semibold))
                    Text("НОВЫЙ ДРУГ")
                        .font(.mySemiBold(size: 11))
                        .tracking(1.5)
                }
                .foregroundStyle(.textMulticolor.opacity(0.6))
                .frame(maxWidth: .infinity)
                .frame(height: addButtonHeight)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }
}

#Preview {
    FriendsListModalView(allFriends: Friend.mock, selectedFriends: Friend.getRandomFriends(), selectedFriend: {
        print($0.name)
    }, onAddFriend: {
        print("Add friend")
    })
}
