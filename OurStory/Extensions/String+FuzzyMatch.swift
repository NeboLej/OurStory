//
//  String+FuzzyMatch.swift
//  OurStory
//

import Foundation

extension String {
    
    /// Prefix-based fuzzy match for Russian names with declensions.
    /// Declensions mutate endings, not beginnings — so shared prefix ≥ `minPrefix` is a reliable signal.
    func fuzzyMatchesName(_ name: String, minPrefix: Int = 3) -> Bool {
        let a = self.lowercased()
        let b = name.lowercased()
        
        guard a.count >= minPrefix, b.count >= minPrefix else { return false }
        
        let sharedPrefix = a.commonPrefix(with: b)
        return sharedPrefix.count >= minPrefix
    }
}
