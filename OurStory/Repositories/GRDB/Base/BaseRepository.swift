//
//  BaseRepository.swift
//  OurStory
//
//  Created by Nebo on 14.09.2026.
//

import Foundation
import GRDB

class BaseRepository {
    let dbPool: DatabasePool
    
    init(dbPool: DatabasePool) {
        self.dbPool = dbPool
        Task {
            await setDefaultValues()
        }
    }
    
    //override
    func setDefaultValues() async { }
}
