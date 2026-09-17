//
//  Array+.swift
//  OurStory
//
//  Created by Nebo on 11.09.2026.
//

import Foundation

extension Array where Element: Identifiable {
    func replaceFirst(_ value: Element) -> [Element] {
        var result = self
        
        if let index = result.firstIndex(where: { $0.id == value.id }) {
            result[index] = value
        }

        return result
    }
}

extension Array where Element: Equatable {
    func deleteOrAppend(_ value: Element) -> [Element] {
        var result = self

        if let index = result.firstIndex(of: value) {
            result.remove(at: index)
        } else {
            result.append(value)
        }

        return result
    }
    
    
    func deleteFirst(_ value: Element) -> [Element] {
        var result = self

        if let index = result.firstIndex(of: value) {
            result.remove(at: index)
        }

        return result
    }
}
