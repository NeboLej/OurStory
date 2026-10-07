//
//  ContributionCalendarV3.swift
//  OurStory
//
//  Hybrid: continuous vertical scroll (V1) + clean cell design (V2).
//

import SwiftUI

// MARK: - Models

private struct V3CellData: Identifiable {
    let id: Int
    let day: Int // -1 = placeholder
    let date: Date
    let dayNumber: Int
    let isToday: Bool
    let colors: [Color]
    let noteCount: Int
}

private struct V3MonthData: Identifiable {
    let id: Int
    let month: Date
    let weeks: [[V3CellData]]
    let totalNotes: Int
    let activeDays: Int
}

// MARK: - View

struct ContributionCalendarV3: View {
    
    private let stories: [Story]
    private let onSelectStory: ((Story?) -> Void)?
    private let screenBuilder: ScreenBuilder
    
    @State private var selectedDay: Date?
    @State private var selectedStory: Story?
    @State private var monthPages: [V3MonthData] = []
    @State private var isShowFriendsList = false
    @State private var scrollTargetID: Int?
    
    private let cal: Calendar = {
        var c = Calendar.current
        return c
    }()
    
    private let cellSize: CGFloat = 42
    private let cellSpacing: CGFloat = 5
    private let cornerRadius: CGFloat = 8
    
    private var weekdaySymbols: [String] {
        let s = cal.shortWeekdaySymbols
        return Array(s[1...]) + [s[0]]
    }
    
    private var hasSelectedNotes: Bool {
        selectedStory?.notes.isEmpty == false
    }
    
    init(stories: [BaseDate: Story],
         screenBuilder: ScreenBuilder,
         onSelectStory: ((Story?) -> Void)? = nil) {
        self.onSelectStory = onSelectStory
        self.screenBuilder = screenBuilder
        storyMap = stories
        self.stories = Array(storyMap.values)
    }
    
    @State var panelHeightCoeficient: CGFloat = 0.3
    @State private var panelDragStartCoeficient: CGFloat?
    
    var body: some View {
        GeometryReader { geo in
            let panelHeight = geo.size.height * panelHeightCoeficient
            
            ZStack(alignment: .bottom) {
                // Calendar
                VStack(spacing: 0) {
                    weekdayHeader
                        .background(.backgroundFill)
//                        .padding(.bottom, 8)
                    
                    ScrollViewReader { proxy in
                        ScrollView(.vertical, showsIndicators: false) {
                            LazyVStack(spacing: 24) {
                                ForEach(monthPages) { page in
                                    monthSection(page)
                                        .id(page.id)
                                }
                                .padding(.horizontal, 8)
                            }
                            .padding(.bottom, hasSelectedNotes ? panelHeight + 8 : 8)
                        }
                        .onChange(of: monthPages.count) {
                            if let last = monthPages.last {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                        .onChange(of: scrollTargetID) { _, targetID in
                            guard let targetID else { return }
                            withAnimation(.easeInOut(duration: 0.3)) {
                                proxy.scrollTo(targetID, anchor: .top)
                            }
                            scrollTargetID = nil
                        }
                        .background(.backgroundFill)
                        .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: 20, bottomTrailingRadius: 20))
                    }
                    
                    
                    // Notes panel pinned to bottom
                    if let story = selectedStory, !story.notes.isEmpty {
                        VStack(spacing: 0) {
                            Rectangle()
                                .fill(.black)
                                .frame(height: 8)
                            
                            notesPanel(story: story, totalHeight: geo.size.height)
                                .frame(height: panelHeight)
                                .frame(maxWidth: .infinity)
                            //                            .background(.ultraThinMaterial)
                                .background(.backgroundFill)
                                .clipShape(UnevenRoundedRectangle(topLeadingRadius: 20, topTrailingRadius: 20))
                                .shadow(color: .black.opacity(0.08), radius: 16, y: -6)
                                
                        }.transition(.move(edge: .bottom))
                    }
                }
                
                
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .ignoresSafeArea(edges: .bottom)
//        .background(.backgroundFill)
        .onAppear {
            monthPages = buildPages()
        }
    }
    
    let minPanelHeight: CGFloat = 0.58
    let maxPanelHeight: CGFloat = 0.92
    
    private func notesPanel(story: Story, totalHeight: CGFloat) -> some View {
        VStack(spacing: 0) {
            // Drag handle
            Capsule()
                .fill(Color.textMulticolor.opacity(0.15))
                .frame(width: 32, height: 4)
                .padding(.top, 10)
                .padding(.bottom, 8)
            
            // Header
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(story.date.toReadable())
                        .font(.mySemiBold(size: 15))
                        .foregroundStyle(.textMulticolor)
                    
                    Text("\(story.notes.count) \(story.notes.count == 1 ? "запись" : "записей")")
                        .font(.myRegular(size: 12))
                        .foregroundStyle(.textMulticolor.opacity(0.4))
                }
                
                Spacer()
                
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        selectedDay = nil
                        selectedStory = nil
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.textMulticolor.opacity(0.4))
                        .frame(width: 28, height: 28)
                        .background(.ultraThinMaterial, in: Circle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 6)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 10, coordinateSpace: .global)
                    .onChanged { value in
                        let startCoef = panelDragStartCoeficient ?? panelHeightCoeficient
                        if panelDragStartCoeficient == nil {
                            panelDragStartCoeficient = panelHeightCoeficient
                        }
                        let dragDelta = -value.translation.height / totalHeight
                        panelHeightCoeficient = min(maxPanelHeight, max(0.05, startCoef + dragDelta))
                    }
                    .onEnded { value in
                        let startCoef = panelDragStartCoeficient ?? minPanelHeight
                        let velocity = value.predictedEndTranslation.height - value.translation.height
                        let swipedUp = velocity < -150 || value.translation.height < -40
                        let swipedDown = velocity > 150 || value.translation.height > 40
                        
                        withAnimation(.snappy(duration: 0.3)) {
                            if swipedUp {
                                panelHeightCoeficient = maxPanelHeight
                            } else if swipedDown {
                                if startCoef <= minPanelHeight + 0.05 {
                                    selectedDay = nil
                                    selectedStory = nil
                                }
                                panelHeightCoeficient = minPanelHeight
                            } else if panelHeightCoeficient > 0.5 {
                                panelHeightCoeficient = maxPanelHeight
                            } else {
                                panelHeightCoeficient = minPanelHeight
                            }
                        }
                        panelDragStartCoeficient = nil
                    }
            )
            
            Divider()
                .opacity(0.3)
            
            screenBuilder.getComponent(
                type: .notesList(notes: story.notes, storyID: story.id, isShowFriendsList: $isShowFriendsList)
            )
            .id(story.id)
        }
    }
    
    // MARK: - Weekday Header
    
    private var weekdayHeader: some View {
        HStack(spacing: cellSpacing) {
            ForEach(weekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.myMedium(size: 12))
                    .foregroundStyle(.textMulticolor.opacity(0.5))
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 4)
    }
    
    // MARK: - Month Section
    
    private func monthSection(_ page: V3MonthData) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Month title + stats
            HStack(alignment: .firstTextBaseline) {
                Text(monthYearString(page.month))
                    .font(.mySemiBold(size: 18))
                    .foregroundStyle(.textMulticolor)
                    .padding(.top, 8)
                    .padding(.bottom, 4)
                
                Spacer()
                
                if page.totalNotes > 0 {
                    Text("\(page.activeDays) дня · \(page.totalNotes) истории")
                        .font(.myRegular(size: 11))
                        .foregroundStyle(.textMulticolor.opacity(0.4))
                }
            }
            .padding(.horizontal, 8)
            
            // Weeks grid
            VStack(spacing: cellSpacing) {
                ForEach(page.weeks, id: \.first?.id) { week in
                    HStack(spacing: cellSpacing) {
                        ForEach(week) { cell in
                            if cell.day != -1 {
                                dayCell(cell)
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
        }
    }
    
    // MARK: - Day Cell (V2-style design)
    
    private let baseCellColor = Color(.tertiarySystemFill)
    private let activeCellColor = Color(.tertiarySystemFill)
    
    private func dayCell(_ cell: V3CellData) -> some View {
        let isSelected = selectedDay.map { cal.isDate($0, inSameDayAs: cell.date) } ?? false
        let hasContent = !cell.colors.isEmpty
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        
        return ZStack {
            // Base fill
            shape.fill(hasContent ? activeCellColor : baseCellColor)
            
            // Friend color border
            if cell.colors.count >= 2 {
                shape
                    .strokeBorder(
                        AngularGradient(gradient: Gradient(stops: angularStops(for: cell.colors)), center: .center ), lineWidth: 2.5)
                    .padding(1)
                //                    .opacity(0.8)
            } else if let color = cell.colors.first {
                shape
                    .strokeBorder(color, lineWidth: 2.5)
                    .padding(1)
            }
            
            // Selected state
            if isSelected {
                shape.fill(Color.myPrimary)
            }
            
            // Content
            VStack(spacing: 1) {
                Text("\(cell.dayNumber)")
                    .font(.myMedium(size: 12))
                    .foregroundStyle(
                        isSelected ? .black :
                            (hasContent ? Color.primary : Color.textMulticolor.opacity(0.6))
                    )
                
                if cell.noteCount > 0 {
                    HStack(spacing: 2) {
                        ForEach(0..<min(cell.noteCount, 3), id: \.self) { _ in
                            Circle()
                                .fill(
                                    isSelected ? Color.black.opacity(0.5) :
                                        (cell.colors.first ?? .white).opacity(0.8)
                                )
                                .frame(width: 3, height: 3)
                        }
                    }
                }
            }
            
            // Today ring
            if cell.isToday && !isSelected {
                shape.strokeBorder(Color.myPrimary, lineWidth: 2)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: cellSize)
        .onTapGesture {
            let story = storyForDate(cell.date)
            withAnimation(.easeInOut(duration: 0.3)) {
                if selectedDay == cell.date {
                    selectedDay = nil
                    selectedStory = nil
                } else {
                    panelHeightCoeficient = minPanelHeight
                    selectedDay = cell.date
                    selectedStory = story
                }
            }
            // Scroll selected month into view after panel appears
            if selectedDay == cell.date {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    if let page = monthPages.first(where: {
                        cal.isDate($0.month, equalTo: cell.date, toGranularity: .month)
                    }) {
                        scrollTargetID = page.id
                    }
                }
            }
            onSelectStory?(story)
        }
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
    
    private let storyMap: [BaseDate: Story]
    
    private func storyForDate(_ date: Date) -> Story? {
        storyMap[BaseDate(date: date)]
    }
    
    private func monthYearString(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = .current
        f.dateFormat = "LLLL yyyy"
        return f.string(from: date).capitalized
    }
    
    // MARK: - Page Builder
    
    private func buildPages() -> [V3MonthData] {
        let today = Date.now
        var pages: [V3MonthData] = []
        
        let monthStarts = monthRange(from: stories, today: today)
        
        for monthStart in monthStarts {
            guard let range = cal.range(of: .day, in: .month, for: monthStart) else { continue }
            
            var cells: [V3CellData] = []
            var totalNotes = 0
            var activeDays = 0
            var cellIndex = 0
            
            let year = cal.component(.year, from: monthStart)
            let month = cal.component(.month, from: monthStart)
            
            // Leading placeholders
            if let firstDay = cal.date(from: DateComponents(year: year, month: month, day: range.lowerBound)) {
                let wd = cal.component(.weekday, from: firstDay)
                let offset = wd == 1 ? 6 : wd - 2
                for _ in 0..<offset {
                    cells.append(V3CellData(id: cellIndex, day: -1, date: .distantPast, dayNumber: 0, isToday: false, colors: [], noteCount: 0))
                    cellIndex += 1
                }
            }
            
            for day in range {
                guard let dayDate = cal.date(from: DateComponents(year: year, month: month, day: day)) else { continue }
                
                let story = storyMap[BaseDate(date: dayDate)]
                let colors = extractColors(from: story)
                let noteCount = story?.notes.count ?? 0
                
                if noteCount > 0 {
                    totalNotes += noteCount
                    activeDays += 1
                }
                
                cells.append(V3CellData(
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
            var weeks: [[V3CellData]] = []
            var week: [V3CellData] = []
            for cell in cells {
                week.append(cell)
                if week.count == 7 {
                    weeks.append(week)
                    week = []
                }
            }
            if !week.isEmpty {
                while week.count < 7 {
                    week.append(V3CellData(id: cellIndex, day: -1, date: .distantPast, dayNumber: 0, isToday: false, colors: [], noteCount: 0))
                    cellIndex += 1
                }
                weeks.append(week)
            }
            
            pages.append(V3MonthData(
                id: pages.count,
                month: monthStart,
                weeks: weeks,
                totalNotes: totalNotes,
                activeDays: activeDays
            ))
        }
        
        return pages
    }
    
    /// Returns sorted array of month-start dates covering all stories up to today.
    private func monthRange(from stories: [Story], today: Date) -> [Date] {
        let dates = stories.map(\.date)
        guard let earliest = dates.min() else {
            // No stories — show current month only
            let comps = cal.dateComponents([.year, .month], from: today)
            return [cal.date(from: comps)].compactMap { $0 }
        }
        
        let startComps = cal.dateComponents([.year, .month], from: earliest)
        let endComps = cal.dateComponents([.year, .month], from: today)
        
        guard var cursor = cal.date(from: startComps),
              let end = cal.date(from: endComps) else { return [] }
        
        var result: [Date] = []
        while cursor <= end {
            result.append(cursor)
            guard let next = cal.date(byAdding: .month, value: 1, to: cursor) else { break }
            cursor = next
        }
        return result
    }
    
    private func extractColors(from story: Story?) -> [Color] {
        guard let story, !story.notes.isEmpty else { return [] }
        let unique = Array(Set(story.notes.flatMap(\.friends).map(\.color)))
        guard !unique.isEmpty else { return [.red.opacity(0.8)] }
        return unique.sorted(by: <).map { Color(hex: $0) }
    }
}

// MARK: - Preview

#Preview {
    
    @Previewable @State var selectedStory: Story? = nil
    @Previewable @State var stories: [BaseDate: Story] = {
        let ff = (0..<100).map { offset in
            let date = Calendar.current.date(byAdding: .day, value: -offset, to: .now)!
            let notes: [Note] = Bool.random() ? [
                Note(rootStoryID: UUID(), date: date, text: "Test note text флывфл тывлофтыл втфолывт флоывол фтволфт ыовтф ловтфлыотв олфыв фщызвзфщылв зщфылв фышв щфштвщф щвы шфщовшщ", friends: Friend.getRandomFriends()),
                Note(rootStoryID: UUID(), date: date, text: "Test note 2", friends: Friend.getRandomFriends())
            ] : []
            return Story(date: date, notes: notes)
        }
        return Dictionary(uniqueKeysWithValues: ff.map { ($0.baseDate, $0) })
    }()
    
    NavigationStack {
        ContributionCalendarV3(stories: stories, screenBuilder: ScreenBuilder.previewBuilder)
    }
}
