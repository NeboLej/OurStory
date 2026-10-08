//
//  CalendarScreen.swift
//  OurStory
//
//  Created by Nebo on 08.10.2026.
//

import SwiftUI

struct CalendarScreen: View {
    
    @State private var store: CalendarScreenStore
    private var screenBuilder: ScreenBuilder
    
    init(store: CalendarScreenStore, screenBuilder: ScreenBuilder) {
        self.store = store
        self.screenBuilder = screenBuilder
    }
    
    @State private var panelDragStartCoeficient: CGFloat?
    @State private var isShowFriendsList = false
    
    @State private var panelHeightCoeficient: CGFloat = 0.58
    private let minPanelHeight: CGFloat = 0.58
    private let maxPanelHeight: CGFloat = 0.92
    private let cellSize: CGFloat = 42
    private let cellSpacing: CGFloat = 5
    private let cornerRadius: CGFloat = 8
    
    private var weekdaySymbols: [String] {
        let s = store.calendar.shortWeekdaySymbols
        return Array(s[1...]) + [s[0]]
    }
    
    private var hasSelectedNotes: Bool {
        store.state.selectedStory?.notes.isEmpty == false
    }
    
    var body: some View {
        GeometryReader { geo in
            let panelHeight = geo.size.height * panelHeightCoeficient
            
            ZStack(alignment: .bottom) {
                VStack(spacing: 0) {
                    weekdayHeader()
                        .background(.backgroundFill)
                    
                    ScrollViewReader { proxy in
                        ScrollView(.vertical, showsIndicators: false) {
                            LazyVStack(spacing: 24) {
                                ForEach(store.state.monthPages) { page in
                                    monthSection(page)
                                        .id(page.id)
                                }
                                .padding(.horizontal, 8)
                            }
                            .padding(.bottom, hasSelectedNotes ? panelHeight + 8 : 8)
                        }
                        .onChange(of: store.state.monthPages.count) {
                            if let last = store.state.monthPages.last {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                        .onChange(of: store.state.selectedDate) { oldDate, newDate in
                            guard let newDate else { return }
                            let panelWillAppear = oldDate == nil
                            let delay: Double = panelWillAppear ? 0.2 : 0
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                                if let page = store.state.monthPages.first(where: {
                                    store.calendar.isDate($0.month, equalTo: newDate, toGranularity: .month)
                                }) {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        proxy.scrollTo(page.id, anchor: .top)
                                    }
                                }
                            }
                        }
                        .background(.backgroundFill)
                        .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: 20, bottomTrailingRadius: 20))
                        .onTapGesture {
                            store.send(.closeNotePanel)
                        }
                    }
                    
                    // Notes panel pinned to bottom
                    if let story = store.state.selectedStory, !story.notes.isEmpty {
                        VStack(spacing: 0) {
                            Rectangle()
                                .fill(.black)
                                .frame(height: 8)
                            
                            notesPanel(story: story, totalHeight: geo.size.height)
                                .frame(height: panelHeight)
                                .frame(maxWidth: .infinity)
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
    }
    
    private func weekdayHeader() -> some View {
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
    
    private func monthSection(_ page: CalendarViewMonthData) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Month title + stats
            HStack(alignment: .firstTextBaseline) {
                Text(page.month.toMonthYearDate())
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
    
    // MARK: - Day Cell
    
    private let baseCellColor = Color(.tertiarySystemFill)
    private let activeCellColor = Color(.tertiarySystemFill)
    
    private func dayCell(_ cell: CalendarViewCellData) -> some View {
        let isSelected = store.state.selectedDate.map { store.calendar.isDate($0, inSameDayAs: cell.date) } ?? false
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
            panelHeightCoeficient = minPanelHeight
            store.send(.selectDate(cell.date))
        }
    }
    
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
                    store.send(.closeNotePanel)
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
                                    store.send(.closeNotePanel)
                                }
                                panelHeightCoeficient = minPanelHeight
                            } else if panelHeightCoeficient > 0.5 {
                                panelHeightCoeficient = maxPanelHeight
                            } else {
                                panelHeightCoeficient = minPanelHeight
                            }
                            panelDragStartCoeficient = nil
                        }
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
    
    private func angularStops(for colors: [Color]) -> [Gradient.Stop] {
        let segment = 1.0 / Double(colors.count)
        var stops = colors.enumerated().map { i, c in
            Gradient.Stop(color: c, location: Double(i) * segment)
        }
        stops.append(Gradient.Stop(color: colors[0], location: 1.0))
        return stops
    }
}

#Preview {
    ScreenBuilder.previewBuilder.getScreen(type: .calendar)
}
