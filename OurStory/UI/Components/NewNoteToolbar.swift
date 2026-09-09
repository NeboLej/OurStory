//
//  NewNoteToolbar.swift
//  OurStory
//
//  Created by Nebo on 09.09.2026.
//

import SwiftUI

struct NewNoteToolbar: View {
    
    let circleColors: [Color]
    let onAddFriend: () -> Void
    let onCalendar: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        GlassEffectContainer(spacing: 12) {
            HStack(spacing: 12) {
                Button(action: onAddFriend) {
                    Label("Добавить друга", systemImage: "person.badge.plus")
                        .font(.system(size: 14, weight: .medium))
                        .padding(.horizontal, 12)
                        .frame(height: 36)
                    HStack(spacing: -4) {
                        ForEach(circleColors.prefix(4), id: \.self) { color in
                            Circle()
                                .frame(width: 20, height: 20)
                                .foregroundStyle(color)
                        }
                    }
                }
                .buttonStyle(.glass)
                
                Button(action: onCalendar) {
                    Image(systemName: "calendar")
                        .font(.system(size: 14, weight: .medium))
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.glass)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .preferredColorScheme(colorScheme)
    }
}

#Preview {
    NewNoteToolbar(circleColors: []) {
        
    } onCalendar: {
        
    }
}
