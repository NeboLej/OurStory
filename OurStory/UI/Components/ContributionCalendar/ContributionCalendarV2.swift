//
//  ContributionCalendarV2.swift
//  OurStory
//
//  Alternate design: vertical month grid with square day cells,
//  radial glow for multi-friend days, and a streak indicator strip.
//

import SwiftUI

// MARK: - Pre-computed models

private struct CCv2CellData: Identifiable {
    let id: Int // stable index within month
    let day: Int // -1 = placeholder
    let date: Date
    let dayNumber: Int
    let isToday: Bool
    let colors: [Color]
    let noteCount: Int
}

private struct CCv2MonthData: Identifiable {
    let id: Int
    let month: Date
    let weeks: [[CCv2CellData]] // rows of 7
    let totalNotes: Int
    let activeDays: Int
    let streakColors: [(Date, Color?)] // one per day in month
}

// MARK: - View

struct ContributionCalendarV2: View {
    
    private let stories: [Story]
    private let monthsBack: Int
    private let onSelectStory: ((Story?) -> Void)?
    
    @State private var selectedDay: Date?
    @State private var monthPages: [CCv2MonthData] = []
    @State private var currentPageID: Int?
    
    private let cal: Calendar = {
        var c = Calendar(identifier: .gregorian)
        return c
    }()
    
    private let cellSize: CGFloat = 42
    private let cellSpacing: CGFloat = 6
    
    private var weekdaySymbols: [String] {
        let s = cal.shortWeekdaySymbols
        return Array(s[1...]) + [s[0]]
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
    
    private var currentPageIndex: Int {
        monthPages.firstIndex(where: { $0.id == currentPageID }) ?? monthPages.count - 1
    }
    
    var body: some View {
        VStack(spacing: 16) {
            monthSelectorStrip
            weekdayHeader
            
            TabView(selection: $currentPageID) {
                ForEach(monthPages) { page in
                    monthPageView(page)
                        .tag(Optional(page.id))
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: cellSize * 6 + cellSpacing * 5 + 10)
            
            activityStrip
        }
        .onAppear {
            let storyMap = Dictionary(uniqueKeysWithValues: stories.map { ($0.baseDate, $0) })
            monthPages = buildAllPages(storyMap: storyMap)
            currentPageID = monthPages.last?.id
        }
    }
    
    // MARK: - Month Selector
    
    private var monthSelectorStrip: some View {
        let idx = currentPageIndex
        
        return HStack(spacing: 0) {
            Button {
                guard idx > 0 else { return }
                withAnimation { currentPageID = monthPages[idx - 1].id }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.textMulticolor.opacity(idx > 0 ? 0.8 : 0.2))
            }
            .disabled(idx <= 0)
            
            Spacer()
            
            if monthPages.indices.contains(idx) {
                Text(fullMonthName(for: monthPages[idx].month))
                    .font(.mySemiBold(size: 16))
                    .foregroundStyle(.textMulticolor)
                    .contentTransition(.numericText())
            }
            
            Spacer()
            
            Button {
                guard idx < monthPages.count - 1 else { return }
                withAnimation { currentPageID = monthPages[idx + 1].id }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.textMulticolor.opacity(idx < monthPages.count - 1 ? 0.8 : 0.2))
            }
            .disabled(idx >= monthPages.count - 1)
        }
        .padding(.horizontal, 8)
    }
    
    // MARK: - Weekday Header
    
    private var weekdayHeader: some View {
        HStack(spacing: cellSpacing) {
            ForEach(weekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.myMedium(size: 11))
                    .foregroundStyle(.textMulticolor)
                    .frame(maxWidth: .infinity)
                    .frame(height: 20)
            }
        }
        .padding(.horizontal, 4)
    }
    
    // MARK: - Month Page (fixed VStack+HStack grid)
    
    private func monthPageView(_ page: CCv2MonthData) -> some View {
        VStack(spacing: cellSpacing) {
            ForEach(page.weeks, id: \.first?.id) { week in
                HStack(spacing: cellSpacing) {
                    ForEach(week) { cell in
                        if cell.day != -1 {
                            dayCellView(cell)
                        } else {
                            Color.clear
                                .frame(maxWidth: .infinity)
                                .frame(height: cellSize)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 4)
        .drawingGroup()
    }
    
    // MARK: - Day Cell
    
    private let baseCellColor = Color(.systemFill)
    private let activeCellColor = Color(.tertiarySystemFill)
    
    private func dayCellView(_ cell: CCv2CellData) -> some View {
        let isSelected = selectedDay.map { cal.isDate($0, inSameDayAs: cell.date) } ?? false
        let hasContent = !cell.colors.isEmpty
        let shape = RoundedRectangle(cornerRadius: 8, style: .continuous)
        
        return ZStack {
            // Единый фон: чуть ярче если есть контент
            shape.fill(hasContent ? activeCellColor : baseCellColor)
            
            // Обводка цветами друзей
            if cell.colors.count >= 2 {
                shape
                    .strokeBorder(
                        AngularGradient(
                            gradient: Gradient(stops: angularStops(for: cell.colors)),
                            center: .center
                        ),
                        lineWidth: 2.5
                    )
                    .padding(1)
            } else if let color = cell.colors.first {
                shape
                    .strokeBorder(color.opacity(0.8), lineWidth: 2)
                    .padding(1)
            }
            
            if isSelected {
                shape.fill(Color.myPrimary)
            }
            
            // Контент
            VStack(spacing: 1) {
                Text("\(cell.dayNumber)")
                    .font(.myMedium(size: 13))
                    .foregroundStyle(isSelected ? .black : (hasContent ? Color.primary : Color.textMulticolor.opacity(0.6)))
                
                if cell.noteCount > 0 {
                    HStack(spacing: 2) {
                        ForEach(0..<min(cell.noteCount, 3), id: \.self) { _ in
                            Circle()
                                .fill(isSelected ? Color.black.opacity(0.5) : (cell.colors.first ?? .white).opacity(0.8))
                                .frame(width: 3, height: 3)
                        }
                    }
                }
            }
            
            // Сегодня
            if cell.isToday && !isSelected {
                shape.strokeBorder(Color.myPrimary, lineWidth: 2)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: cellSize)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) { selectedDay = cell.date }
            onSelectStory?(storyForDate(cell.date))
        }
    }
    
    // MARK: - Activity Strip
    
    private var activityStrip: some View {
        Group {
            if monthPages.indices.contains(currentPageIndex) {
                let page = monthPages[currentPageIndex]
                
                HStack(spacing: 16) {
                    statLabel(value: "\(page.totalNotes)", label: "notes")
                    statLabel(value: "\(page.activeDays)", label: "days")
                    Spacer()
                    streakBar(page.streakColors)
                }
                .padding(.horizontal, 4)
            }
        }
    }
    
    private func statLabel(value: String, label: String) -> some View {
        HStack(spacing: 4) {
            Text(value).font(.mySemiBold(size: 14)).foregroundStyle(.textMulticolor)
            Text(label).font(.myRegular(size: 12)).foregroundStyle(.textMulticolor)
        }
    }
    
    private func streakBar(_ data: [(Date, Color?)]) -> some View {
        let barWidth: CGFloat = 120
        let segW = barWidth / CGFloat(max(data.count, 1))
        
        return HStack(spacing: 0) {
            ForEach(data.indices, id: \.self) { i in
                Rectangle()
                    .fill(data[i].1?.opacity(0.7) ?? Color.gray.opacity(0.1))
                    .frame(width: segW, height: 6)
            }
        }
        .clipShape(Capsule())
        .frame(width: barWidth)
    }
    
    // MARK: - Helpers
    
    private func angularStops(for colors: [Color]) -> [Gradient.Stop] {
        let segment = 1.0 / Double(colors.count)
        var stops = colors.enumerated().map { i, c in
            Gradient.Stop(color: c, location: Double(i) * segment)
        }
        stops.append(Gradient.Stop(color: colors[0], location: 1.0))
        return stops
    }
    
    private var storyMap: [BaseDate: Story] {
        Dictionary(uniqueKeysWithValues: stories.map { ($0.baseDate, $0) })
    }
    
    private func storyForDate(_ date: Date) -> Story? {
        storyMap[BaseDate(date: date)]
    }
    
    // MARK: - Pre-compute all pages once
    
    private func buildAllPages(storyMap: [BaseDate: Story]) -> [CCv2MonthData] {
        let today = Date.now
        var pages: [CCv2MonthData] = []
        
        for i in (0...monthsBack).reversed() {
            guard let date = cal.date(byAdding: .month, value: -i, to: today),
                  let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: date)),
                  let range = cal.range(of: .day, in: .month, for: monthStart) else { continue }
            
            // Build flat cell array
            var cells: [CCv2CellData] = []
            var totalNotes = 0
            var activeDays = 0
            var streakColors: [(Date, Color?)] = []
            var cellIndex = 0
            
            // Leading placeholders
            if let firstDay = cal.date(bySetting: .day, value: range.lowerBound, of: monthStart) {
                let wd = cal.component(.weekday, from: firstDay)
                let offset = wd == 1 ? 6 : wd - 2
                for _ in 0..<offset {
                    cells.append(CCv2CellData(id: cellIndex, day: -1, date: .distantPast, dayNumber: 0, isToday: false, colors: [], noteCount: 0))
                    cellIndex += 1
                }
            }
            
            for day in range {
                guard let dayDate = cal.date(bySetting: .day, value: day, of: monthStart) else { continue }
                
                let story = storyMap[BaseDate(date: dayDate)]
                let colors = extractColors(from: story)
                let noteCount = story?.notes.count ?? 0
                
                if noteCount > 0 {
                    totalNotes += noteCount
                    activeDays += 1
                }
                
                streakColors.append((dayDate, colors.first))
                
                cells.append(CCv2CellData(
                    id: cellIndex,
                    day: day,
                    date: dayDate,
                    dayNumber: day,
                    isToday: cal.isDateInToday(dayDate),
                    colors: colors,
                    noteCount: noteCount
                ))
                cellIndex += 1
            }
            
            // Split into weeks of 7
            var weeks: [[CCv2CellData]] = []
            var week: [CCv2CellData] = []
            for cell in cells {
                week.append(cell)
                if week.count == 7 {
                    weeks.append(week)
                    week = []
                }
            }
            // Pad last week to 7
            if !week.isEmpty {
                while week.count < 7 {
                    week.append(CCv2CellData(id: cellIndex, day: -1, date: .distantPast, dayNumber: 0, isToday: false, colors: [], noteCount: 0))
                    cellIndex += 1
                }
                weeks.append(week)
            }
            
            // Pad to 6 rows so all months have equal height
            while weeks.count < 6 {
                var emptyWeek: [CCv2CellData] = []
                for _ in 0..<7 {
                    emptyWeek.append(CCv2CellData(id: cellIndex, day: -1, date: .distantPast, dayNumber: 0, isToday: false, colors: [], noteCount: 0))
                    cellIndex += 1
                }
                weeks.append(emptyWeek)
            }
            
            pages.append(CCv2MonthData(
                id: pages.count,
                month: monthStart,
                weeks: weeks,
                totalNotes: totalNotes,
                activeDays: activeDays,
                streakColors: streakColors
            ))
        }
        
        return pages
    }
    
    private func extractColors(from story: Story?) -> [Color] {
        guard let story, !story.notes.isEmpty else { return [] }
        let unique = Array(Set(story.notes.flatMap(\.friends).map(\.color)))
        guard !unique.isEmpty else { return [Color.gray.opacity(0.35)] }
        return unique.sorted(by: <).map { Color(hex: $0) }
    }
    
    private func fullMonthName(for date: Date) -> String {
        let f = DateFormatter()
        f.locale = .current
        f.dateFormat = "LLLL yyyy"
        return f.string(from: date).capitalized
    }
}

// MARK: - Preview

#Preview {
    let stories: [Story] = (0..<120).map { offset in
        let date = Calendar.current.date(byAdding: .day, value: -offset, to: .now)!
        let notes: [Note] = Bool.random() ? [
            Note(rootStoryID: UUID(), date: date, text: "Test note", friends: Friend.getRandomFriends()),
            Note(rootStoryID: UUID(), date: date, text: "Test note 2", friends: Friend.getRandomFriends())
        ] : []
        return Story(date: date, notes: notes)
    }
    
    ContributionCalendarV2(stories: stories, monthsBack: 4) { story in
        print("Selected: \(String(describing: story?.date))")
    }
    .padding()
    .frame(maxWidth: .infinity)
    .background(Color.backgroundFill)
}
