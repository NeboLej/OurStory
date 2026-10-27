//
//  HomeScreenToolbar.swift
//  OurStory
//
//  Created by Nebo on 09.09.2026.
//

import SwiftUI

struct HomeScreenToolbar: View {
    
    enum MenuItem {
        case friends, calendar, search
        
        var iconName: String {
            switch self {
            case .friends: return "person.3.sequence"
            case .calendar: return "calendar"
            case .search: return "magnifyingglass"
            }
        }
        
        var name: String {
            switch self {
            case .friends: return "Друзья"
            case .calendar: return "Календарь"
            case .search: return "Поиск"
            }
        }
    }
    
    let onFriends: () -> Void
    let onCalendar: () -> Void
    let onSearch: () -> Void
    let onNewNote: () -> Void
    
    var body: some View {
        HStack {
            GlassEffectContainer(spacing: 8) {

                HStack(alignment: .bottom, spacing: 16) {
                    munuItem(.friends, action: onFriends)
                    munuItem(.calendar, action: onCalendar)
                    munuItem(.search, action: onSearch)
                }
                .padding(.horizontal, 20)
                .glassEffect()
            }
            
            Spacer()
            
            
            Button {
                onNewNote()
            } label: {
                Image(systemName: "plus")
                    .font(Font.myRegular(size: 24))
                    .foregroundStyle(.black)
                    .padding(8)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.glassProminent)
            .tint(.myPrimary)
        }
        .padding(.horizontal, 16)
    }
    
    @ViewBuilder
    private func munuItem(_ item: MenuItem, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .center, spacing: 3) {
                Image(systemName: item.iconName)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.textMulticolor)
                
                if !item.name.isEmpty {
                    Text(item.name)
                        .font(.myMedium(size: 10))
                        .foregroundStyle(.textMulticolor)
                }

            }
            .frame(height: 64)
        }
    }
}


#Preview {
    HomeScreenToolbar {
        
    } onCalendar: {
        
    } onSearch: {
        
    } onNewNote: {
        
    }

}
