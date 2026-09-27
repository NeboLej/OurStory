//
//  NoteListScreenStore.swift
//  OurStory
//
//  Created by Nebo on 23.09.2026.
//

import SwiftUI

//protocol NoteProtocol: Hashable, Identifiable where ID == UUID  {
//    var id: UUID { get }
//    var title: String? { get }
//    var text: String { get }
//    var date: Date { get }
//}

//struct AnyNote {
//    var id: UUID
//    var title: String?
//    var text: String
//    var date: Date
//    
//    init(from: SyncNote) {
//        self.id = from.id
//        self.title = from.title
//        self.text = from.text
//        self.date = from.date
//    }
//}

@Observable
final class NoteListScreenStore: BaseStore {
    
    private var notes: [Note]
    
    var state: NoteListScreenState {
        NoteListScreenState(notes: notes)
    }
    
    init(appStore: AppStore, notes: [Note]) {
        self.notes = notes
        super.init(appStore: appStore)
    }
    
}
