//
//  NoteListScreen.swift
//  OurStory
//
//  Created by Nebo on 23.09.2026.
//

import SwiftUI

struct NoteListScreen: View {
    
    @State var title: String?
    @State var store: NoteListScreenStore
    @Binding var isShowFriendsList: Bool
    
    var body: some View {
        NoteListContent(store: store, isShowFriendsList: $isShowFriendsList, isShowDate: true)
            .background(.backgroundFill)
            .navigationTitle(title ?? "Истории")
            .navigationBarTitleDisplayMode(.automatic)
    }
}

#Preview {
    NavigationStack {
        ScreenBuilder.previewBuilder.getScreen(type: .notes(title: "Notes", filter: .byDate(BaseDate(date: .now)), isShowFriendsList: .constant(false)))
    }
}
