//
//  NoteListScreen.swift
//  OurStory
//
//  Created by Nebo on 23.09.2026.
//

import SwiftUI

struct NoteListScreen: View {
    
    @State var title: String?
    @State private var store: NoteListScreenStore
    
    
    init(title: String?, store: NoteListScreenStore) {
        self.store = store
        self.title = title
    }
    
    var body: some View {
        
        ScrollView(.vertical) {
            VStack(alignment: .leading) {
                ForEach(store.state.notes, id: \.id) {
                    noteView($0)
                }
            }
        }
        .background(.backgroundFill)
        .navigationTitle(title ?? "Истории")
        .navigationBarTitleDisplayMode(.automatic)
        
    }
    
    @ViewBuilder
    private func noteView(_ note: Note) -> some View {
        HStack {
            VStack {
                if let title = note.title {
                    Text(title)
                        .font(.mySemiBold(size: 16))
                        .foregroundColor(.textMulticolor)
                }
                Text(note.text)
                    .font(.myMedium(size: 16))
                    .foregroundColor(.textMulticolor)
            }

        }
    }
    
}


#Preview {
//    let notes: [SyncNote] = [
//        SyncNote(id: UUID(), text: "asdasdkan kjsndkan kdjanskjdnasj dn", title: nil, date: Date()),
//        SyncNote(id: UUID(), text: "asdasdkan kj", title: nil, date: Date()),
//        SyncNote(id: UUID(), text: "asdasdkan kjsndkan kdjans", title: nil, date: Date()),
//        SyncNote(id: UUID(), text: "asdasdkan kjsndkan kdjanskjdnasj dnsa askd askjdn askd lansdjas djk", title: "adas ada", date: Date()),
//        
//    ]
    NavigationStack {
        ScreenBuilder.previewBuilder.getScreen(type: .notes(title: "Notes", notes: []))
    }
}
