//
//  NoteSearchEngine.swift
//  OurStory
//

import Foundation

enum NoteSearchEngine {

    static let minQueryLength = 3

    @concurrent
    static func search(_ notes: [Note], query: String) async -> [Note] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= minQueryLength else { return [] }

        let tokens = trimmed
            .lowercased()
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }

        var scored: [(note: Note, score: Double)] = []
        for note in notes {
            if Task.isCancelled { return [] }
            let score = searchScore(note: note, tokens: tokens)
            if score > 0 {
                scored.append((note, score))
            }
        }

        return scored
            .sorted { $0.score != $1.score ? $0.score > $1.score : $0.note.date > $1.note.date }
            .map(\.note)
    }

    private static func searchScore(note: Note, tokens: [String]) -> Double {
        var totalScore: Double = 0

        let titleLower = note.title?.lowercased() ?? ""
        let textLower = note.text.lowercased()
        let friendNames = note.friends.map { $0.name.lowercased() }
        let ownerName = note.owner?.name.lowercased()

        for token in tokens {
            var tokenScore: Double = 0

            // Title — highest priority
            if titleLower.contains(token) {
                tokenScore = max(tokenScore, 3.0)
            } else if !titleLower.isEmpty, titleLower.commonPrefix(with: token).count >= min(3, token.count) {
                tokenScore = max(tokenScore, 2.0)
            }

            // Text body
            if textLower.contains(token) {
                tokenScore = max(tokenScore, 1.5)
            }

            // Friend names — fuzzy prefix match
            for name in friendNames {
                if name.contains(token) {
                    tokenScore = max(tokenScore, 2.0)
                } else if token.fuzzyMatchesName(name) {
                    tokenScore = max(tokenScore, 1.5)
                }
            }

            // Owner name
            if let ownerName {
                if ownerName.contains(token) {
                    tokenScore = max(tokenScore, 2.0)
                } else if token.fuzzyMatchesName(ownerName) {
                    tokenScore = max(tokenScore, 1.5)
                }
            }

            guard tokenScore > 0 else { return 0 }
            totalScore += tokenScore
        }

        return totalScore
    }
}
