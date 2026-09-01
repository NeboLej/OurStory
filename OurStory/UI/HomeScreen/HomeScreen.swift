//
//  HomeScreen.swift
//  OurStory
//
//  Created by Nebo on 30.08.2026.
//

import SwiftUI

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
        .overlay(alignment: .bottomTrailing) {
            Button {
                store.send(.createNewNote)
            } label: {
                Circle()
                    .frame(width: 60, height: 60)
                    .padding(.trailing)
            }
            .buttonStyle(.plain)

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
