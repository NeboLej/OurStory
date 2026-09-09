//
//  HomeScreenToolbar.swift
//  OurStory
//
//  Created by Nebo on 09.09.2026.
//

import SwiftUI

struct HomeScreenToolbar: View {
    
    enum MenuItem {
        case friends, settings, newNote
        
        var iconName: String {
            switch self {
            case .friends: return "person.3.sequence"
            case .settings: return "gearshape"
            case .newNote: return "plus"
            }
        }
        
        var name: String {
            switch self {
            case .friends: return "Друзья"
            case .settings: return "Настройки"
            case .newNote: return "История"
            }
        }
    }
    
    let onFriends: () -> Void
    let onCalendar: () -> Void
    let onNewNote: () -> Void
    
    var body: some View {
        HStack {
            GlassEffectContainer(spacing: 8) {

                HStack(alignment: .bottom, spacing: 16) {
                    munuItem(.settings) { }
                    munuItem(.friends, action: onFriends)
                }
                .padding(.horizontal, 20)
                .glassEffect()
            }
            
            Spacer()
            GlassEffectContainer {
                munuItem(.newNote, action: onNewNote)
                    .padding(.horizontal, 16)
                    .glassEffect()
            }
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
        
    } onNewNote: {
        
    }

}
