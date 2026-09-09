//
//  HomeScreen.swift
//  OurStory
//
//  Created by Nebo on 30.08.2026.
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
    
    @Environment(\.colorScheme) private var colorScheme
    
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

struct HomeScreen: View {
    
    @State private var store: HomeScreenStore
    @State private var screenBuilder: ScreenBuilder
    @State var selectionDate: Date = .now
    
    init(store: HomeScreenStore, screenBuilder: ScreenBuilder) {
        self.store = store
        self.screenBuilder = screenBuilder
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Rectangle()
                .frame(height: 100)
                .foregroundStyle(Color.myPrimary)
            screenBuilder.getComponent(type: .horizontalCalendar)
                .padding(.top, 16)
            
            ScrollView(.vertical) {
                
                if let currentSroty = store.state.currentStory {
                    storyView(currentSroty)
                }
                
            }
            .frame(maxWidth: .infinity)
        }
        
        .background(.backgroundFill)
        .ignoresSafeArea()
        .safeAreaInset(edge: .bottom, spacing: 0) {
            
            VStack(spacing: 8) {
                HomeScreenToolbar {
                   
                } onCalendar: {
                    
                } onNewNote: {
                    store.send(.createNewNote)
                }
            }
        }
    }
    
    
    @ViewBuilder
    private func storyView(_ story: Story) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Group {
                Text(story.title)
                    .font(.myMedium(size: 18))
                    .foregroundStyle(.titleDark)
                    .padding(.bottom, 4)
                    .padding(.top, 20)
                Text(story.date.toReadable())
                    .font(.myItalic(size: 14))
                    .foregroundStyle(.titleDark.opacity(0.6))
                    .padding(.bottom, 36)
            }
            .padding(.leading, 30)
            
            ForEach(story.notes) { note in
                noteView(note)
                Spacer(minLength: 20)
            }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 100)
        //        .frame(maxWidth: .infinity)
    }
    
    
    @ViewBuilder
    private func noteView(_ note: Note) -> some View {
        if note.owner == nil {
            HStack(alignment: .top, spacing: 16) {
                friendsIndicatorView(note.friends)
                VStack(alignment: .leading, spacing: 0) {
                    if let noteTitle = note.title {
                        Text(noteTitle)
                            .font(.mySemiBold(size: 16))
                            .foregroundStyle(.titleDark)
                            .padding(.bottom, 4)
                    }
                    
                    Text(note.text)
                        .font(.myRegular(size: 16))
                        .foregroundStyle(.titleDark)
                }
                Spacer()
            }
        } else {
            friendNoteView(note)
        }
        
    }
    
    @ViewBuilder
    private func friendsIndicatorView(_ friends: [Friend]) -> some View {
        
        let colors = friends.map {  Color(hex: $0.color) }
        Rectangle()
            .fill(LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom))
            .frame(width: 16)
    }
    
    
    private func friendNoteView(_ note: Note) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if let noteTitle = note.title {
                Text(noteTitle)
                    .font(.mySemiBoldItalic(size: 16))
                    .foregroundStyle(.titleDark)
            }
            
            Text(note.text)
                .font(.myItalic(size: 16))
                .foregroundStyle(.titleDark)
                .padding(.top, 2)
            
            HStack(alignment: .center, spacing: 3) {
                Spacer()
                Circle()
                    .fill(Color(hex: note.owner?.color ?? ""))
                    .frame(width: 16)
                    .overlay {
                        Circle()
                            .stroke(.black, lineWidth: 0.5)
                    }
                Text("\(note.owner?.name ?? "")")
                    .font(.myRegular(size: 14))
                    .foregroundStyle(.titleDark.opacity(0.6))
            }
            .padding(.top, 2)
        }
        .padding(.leading, 30)
        .padding([.top, .bottom, .trailing], 8)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.black, style: StrokeStyle(lineWidth: 1, dash: [5, 5]))
        )
    }
}

#Preview {
    ScreenBuilder.previewBuilder.getScreen(type: .home)
}
