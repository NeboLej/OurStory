//
//  StoryRepositoryProtocol.swift
//  OurStory
//
//  Created by Nebo on 15.09.2026.
//

import Foundation
import GRDB

protocol StoryRepositoryProtocol {
    func getStories(startDate: Date, endDate: Date) async -> [Story]
    func newStory(_ story: Story) async
}


final class StoryRepository: BaseRepository, StoryRepositoryProtocol {
    
    func getStories(startDate: Date, endDate: Date) async -> [Story] {
        do {
            return try await dbPool.read { db in
                
                let notesAssociation = StoryModelGRDB.notes.including(all: NoteModelGRDB.friends.including(optional: FriendModelGRDB.user))

                let request = StoryModelGRDB
                    .filter(Column("date") >= startDate && Column("date") < endDate)
                    .including(all: notesAssociation)

                let stories = try StoryWithNotes.fetchAll(db, request)
                
                Logger.log("get \(stories.count) stiries", location: .GRDB, event: .success)
                
                return stories.map { Story(from: $0) }
            }

        } catch {
            Logger.log("getStories error", location: .GRDB, event: .error(error))
            fatalError("\(error)")
        }
    }
    
    func newStory(_ story: Story) async {
        do {
            try await dbPool.write { db in
                var storyModel = StoryModelGRDB(from: story)
                try storyModel.save(db)
                Logger.log("save new story \(story.id)", location: .GRDB, event: .success)
            }
        } catch {
            Logger.log("new Story error", location: .GRDB, event: .error(error))
            fatalError("\(error)")
        }
    }
}
