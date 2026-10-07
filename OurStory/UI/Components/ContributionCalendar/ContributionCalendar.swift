//
//  ContributionCalendar.swift
//  OurStory
//

import SwiftUI

// MARK: - Models

private struct CCDayModel: Identifiable {
    let id = UUID()
    let day: Int        // -1 = placeholder
    let date: Date
}

private struct CCMonthModel: Identifiable {
    let id = UUID()
    let month: Date
}

// MARK: - View

struct ContributionCalendar: View {
    
    private let stories: [Story]
    private let monthsBack: Int
    private let onSelectStory: ((Story?) -> Void)?
    
    @State private var selectedDay: Date?
    @State private var months: [CCMonthModel] = []
    
    private let calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
//        cal.firstWeekday = 2 // Monday
        return cal
    }()
    
    private let cellSize: CGFloat = 40
    private let cellSpacing: CGFloat = 6
    private let rows = Array(repeating: GridItem(.flexible(minimum: 36, maximum: 44), spacing: 6), count: 7)
    
    private var weekdaySymbols: [String] {
        // Reorder: Mon..Sun
        let symbols = calendar.shortWeekdaySymbols
        return Array(symbols[1...]) + [symbols[0]]
    }
    
    init(
        stories: [Story],
        monthsBack: Int = 6,
        onSelectStory: ((Story?) -> Void)? = nil
    ) {
        self.stories = stories
        self.monthsBack = monthsBack
        self.onSelectStory = onSelectStory
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 4) {
            // Fixed weekday labels
            VStack(spacing: cellSpacing) {
                ForEach(0..<7, id: \.self) { row in
                    Text(row % 2 == 0 ? weekdaySymbols[row] : "")
                        .font(.myMedium(size: 10))
                        .foregroundStyle(.textMulticolor.opacity(0.6))
                        .frame(width: 28, height: cellSize)
                }
            }
            .padding(.top, 22) // offset for month label height
            
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 10) {
                        ForEach(months) { monthModel in
                            monthView(month: monthModel.month)
                                .id(monthModel.id)
                        }
                    }
                    .padding(.trailing, 4)
                }
                .onAppear {
                    if let last = months.last {
                        proxy.scrollTo(last.id, anchor: .trailing)
                    }
                }
            }
        }
        .onAppear {
            months = buildMonths()
        }
    }
    
    // MARK: - Month View
    
    @ViewBuilder
    private func monthView(month: Date) -> some View {
        let days = extractDays(for: month)
        let gridHeight = (cellSize + cellSpacing) * 7 - cellSpacing
        
        VStack(alignment: .leading, spacing: 4) {
            Text(monthName(for: month))
                .font(.myMedium(size: 10))
                .foregroundStyle(.textMulticolor.opacity(0.6))
                .frame(height: 14)
            
            LazyHGrid(rows: rows, alignment: .center, spacing: cellSpacing) {
                ForEach(days) { day in
                    if day.day != -1 {
                        cellView(for: day.date)
                    } else {
                        emptyCell
                    }
                }
            }
            .frame(height: gridHeight)
        }
    }
    
    // MARK: - Cell
    
    @ViewBuilder
    private func cellView(for date: Date) -> some View {
        let story = storyForDate(date)
        let colors = extractColors(from: story)
        let dayNumber = calendar.component(.day, from: date)
        let isToday = calendar.isDateInToday(date)
        let isSelected = selectedDay.map { calendar.isDate($0, inSameDayAs: date) } ?? false
        
        ZStack {
            if colors.count >= 2 {
                AngularGradient(gradient: Gradient(stops: angularStops(for: colors)), center: .center)
            } else if let color = colors.first {
                color
            } else {
                Color.gray.opacity(0.12)
            }
            
            Text("\(dayNumber)")
                .font(.myMedium(size: 11))
                .foregroundStyle(colors.isEmpty ? .textMulticolor.opacity(0.4) : .white)
        }
        .frame(width: cellSize, height: cellSize)
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .stroke(isToday ? Color.myPrimary : .clear, lineWidth: 2)
        }
        .overlay {
            if isSelected {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(Color.white, lineWidth: 2)
            }
        }
        .shadow(color: colors.first?.opacity(0.3) ?? .clear, radius: colors.isEmpty ? 0 : 2, y: 1)
        .onTapGesture {
            selectedDay = date
            onSelectStory?(story)
        }
    }
    
    private var emptyCell: some View {
        Color.clear
            .frame(width: cellSize, height: cellSize)
    }
    
    // MARK: - Data Helpers
    
    private var storyMap: [BaseDate: Story] {
        Dictionary(uniqueKeysWithValues: stories.map { ($0.baseDate, $0) })
    }
    
    private func storyForDate(_ date: Date) -> Story? {
        storyMap[BaseDate(date: date)]
    }
    
    private func angularStops(for colors: [Color]) -> [Gradient.Stop] {
        let count = colors.count
        let segment = 1.0 / Double(count)
        var stops = colors.enumerated().map { i, color in
            Gradient.Stop(color: color, location: Double(i) * segment)
        }
        stops.append(Gradient.Stop(color: colors[0], location: 1.0))
        return stops
    }
    
    private func extractColors(from story: Story?) -> [Color] {
        guard let story, !story.notes.isEmpty else { return [] }
        
        let friendColors = story.notes
            .flatMap(\.friends)
            .map(\.color)
        
        let unique = Array(Set(friendColors))
        
        guard !unique.isEmpty else { return [Color.gray.opacity(0.35)] }
        
        return unique.sorted(by: <).map { Color(hex: $0) }
    }
    
    // MARK: - Grid Builder
    
    private func buildMonths() -> [CCMonthModel] {
        let today = Date.now
        var result: [CCMonthModel] = []
        
        for i in (0...monthsBack).reversed() {
            if let date = calendar.date(byAdding: .month, value: -i, to: today) {
                let comps = calendar.dateComponents([.year, .month], from: date)
                if let monthStart = calendar.date(from: comps) {
                    result.append(CCMonthModel(month: monthStart))
                }
            }
        }
        
        return result
    }
    
    private func extractDays(for month: Date) -> [CCDayModel] {
        guard let range = calendar.range(of: .day, in: .month, for: month) else { return [] }
        
        var days: [CCDayModel] = range.compactMap { day in
            guard let date = calendar.date(bySetting: .day, value: day, of: month) else { return nil }
            return CCDayModel(day: day, date: date)
        }
        
        // Pad with placeholders so first day aligns to correct weekday row (Mon=0)
        if let firstDate = days.first?.date {
            let weekday = calendar.component(.weekday, from: firstDate) // 1=Sun, 2=Mon...
            let mondayOffset = weekday == 1 ? 6 : weekday - 2
            for _ in 0..<mondayOffset {
                days.insert(CCDayModel(day: -1, date: Date.distantPast), at: 0)
            }
        }
        
        return days
    }
    
    private func monthName(for date: Date) -> String {
        let month = calendar.component(.month, from: date)
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        return formatter.shortMonthSymbols[month - 1].capitalized
    }
}

// MARK: - Preview

#Preview {
    let stories: [Story] = (0..<120).map { offset in
        let date = Calendar.current.date(byAdding: .day, value: -offset, to: .now)!
        let notes: [Note] = Bool.random() ? [
            Note(
                rootStoryID: UUID(),
                date: date,
                text: "Test note",
                friends: Friend.getRandomFriends()
            ),
            
            Note(
                rootStoryID: UUID(),
                date: date,
                text: "Test note",
                friends: Friend.getRandomFriends()
            )
        ] : []
        return Story(date: date, notes: notes)
    }
    
    ContributionCalendar(stories: stories, monthsBack: 2) { story in
        print("Selected: \(story?.date)")
    }
    .frame(maxWidth: .infinity)
    .background(Color.black.opacity(0.9))
}
