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
//        ScrollView(.vertical) {
            NoteListContent(store: store, isShowFriendsList: $isShowFriendsList, isShowDate: true)
//                .padding(.bottom, 100)
//        }
        .background(.backgroundFill)
        .navigationTitle(title ?? "Истории")
        .navigationBarTitleDisplayMode(.automatic)
    }
}

#Preview {
    NavigationStack {
        ScreenBuilder.previewBuilder.getScreen(type: .notes(title: "Notes", notes: [
            Note(id: UUID(), rootStoryID: UUID(), title: "ndfsfd", date: Date(), text: "выоатл ыывот аоыва ываи оываорыв ивыл оатыв иаоывр авдыла ытва ", friends: [], owner: Friend(name: "Вася", color: "44fd21")),
            
            Note(id: UUID(), rootStoryID: UUID(), title: "", date: Date().getOffsetDate(-3), text: "выоатл ыывот аоыва ываи оываорыв ивыл оатыв иаоывр авдыла ытва ", friends: [Friend(name: "Вася", color: "44fd21")], owner: nil),
            
            Note(id: UUID(), rootStoryID: UUID(), title: nil, date: Date().getOffsetDate(-5), text: "выоатл ыывот аоыва ываи оываорыв ивыл оатыв иаоывр авдыла ытва ", friends: [], owner: nil)
        ], isShowFriendsList: .constant(false)))
    }
}
