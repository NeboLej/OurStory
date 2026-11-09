//
//  WeekCalendarView.swift
//  OurStory
//

import SwiftUI

struct WeekCalendarView: View {
    
    private let appStore: AppStoreProtocol
    
    @State private var weeks: [WeekData] = []
    @State private var visibleWeekID: String?
    @State private var monthTitle: String = ""
    @State private var scrollViewID = UUID()
    
    private let centerOffset = 2
    
    private var calendar: Calendar {
        var c = Calendar.current
        c.locale = L10n.language.locale
        return c
    }
    
    private var selectedDate: Date { appStore.selectedDate }
    
    init(appStore: AppStoreProtocol) {
        self.appStore = appStore
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(monthTitle)
                .font(.mySemiBold(size: 22))
                .foregroundStyle(.textMulticolor)
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.2), value: monthTitle)
                .padding(.horizontal, 8)
            
            ScrollView(.horizontal) {
                LazyHStack(spacing: 0) {
                    ForEach(weeks) { week in
                        weekRow(week)
                            .containerRelativeFrame(.horizontal)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: $visibleWeekID)
            .frame(height: 65)
            .id(scrollViewID)
        }
        .onAppear {
            buildWindow(around: selectedDate)
            visibleWeekID = weeks[centerOffset].id
            monthTitle = makeMonthTitle(for: weeks[centerOffset])
        }
        .onChange(of: visibleWeekID) { _, newID in
            guard let newID,
                  let idx = weeks.firstIndex(where: { $0.id == newID }) else { return }
            
            let title = makeMonthTitle(for: weeks[idx])
            if title != monthTitle { monthTitle = title }
            
            // Scrolled to edge — rebuild around current visible week
            if idx <= 0 || idx >= weeks.count - 1 {
                let anchor = weeks[idx].days.first?.date ?? selectedDate
                buildWindow(around: anchor)
                let newCenter = weeks[centerOffset].id
                visibleWeekID = nil
                scrollViewID = UUID()
                DispatchQueue.main.async {
                    visibleWeekID = newCenter
                }
            }
        }
        .onChange(of: selectedDate) { _, newDate in
            scrollToDate(newDate)
        }
    }
    
    // MARK: - Week row
    
    @ViewBuilder
    private func weekRow(_ week: WeekData) -> some View {
        HStack(spacing: 0) {
            ForEach(week.days) { day in
                dayCell(day)
                    .frame(maxWidth: .infinity)
            }
        }
    }
    
    @ViewBuilder
    private func dayCell(_ day: DayData) -> some View {
        let isSelected = calendar.isDate(selectedDate, inSameDayAs: day.date)
        let isToday = calendar.isDateInToday(day.date)
        
        ZStack {
            RoundedRectangle(cornerSize: CGSize(width: 24, height: 24), style: .continuous)
                .fill(isSelected ? Color.myPrimary : isToday ? .black.opacity(0.6) : .clear)
                .padding(1)
            
            VStack {
                Text("\(day.number)")
                    .font(isSelected ? .mySemiBold(size: 14) : .myMedium(size: 14))
                    .foregroundStyle(isSelected ? .black : .textMulticolor)
                Text(day.weekdaySymbol)
                    .font(isSelected ? .mySemiBold(size: 14) : .myMedium(size: 14))
                    .foregroundStyle(isSelected ? .black : .textMulticolor)
            }
        }
        .frame(width: 48, height: 65)
        .animation(.linear(duration: 0.4), value: isSelected)
        .overlay {
            RoundedRectangle(cornerSize: CGSize(width: 24, height: 24), style: .continuous)
                .stroke(lineWidth: 1)
                .foregroundStyle(.black)
                .padding(1)
        }
        .onTapGesture {
            appStore.send(.selectedDate(day.date))
        }
    }
    
    // MARK: - Logic
    
    private func buildWindow(around date: Date) {
        let anchor = startOfWeek(for: date)
        weeks = (-centerOffset...centerOffset).map { offset in
            let start = calendar.date(byAdding: .weekOfYear, value: offset, to: anchor)!
            return makeWeek(startingFrom: start)
        }
    }
    
    private func scrollToDate(_ date: Date) {
        if let idx = weeks.firstIndex(where: { w in
            w.days.contains { calendar.isDate($0.date, inSameDayAs: date) }
        }) {
            withAnimation(.easeInOut(duration: 0.3)) {
                visibleWeekID = weeks[idx].id
            }
            monthTitle = makeMonthTitle(for: weeks[idx])
        } else {
            // Outside window — full rebuild
            buildWindow(around: date)
            let newCenter = weeks[centerOffset].id
            visibleWeekID = nil
            scrollViewID = UUID()
            monthTitle = makeMonthTitle(for: weeks[centerOffset])
            DispatchQueue.main.async {
                visibleWeekID = newCenter
            }
        }
    }
    
    // MARK: - Helpers
    
    private func startOfWeek(for date: Date) -> Date {
        calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? date
    }
    
    private func makeWeek(startingFrom start: Date) -> WeekData {
        let symbols = calendar.shortWeekdaySymbols
        let days = (0..<7).compactMap { offset -> DayData? in
            guard let date = calendar.date(byAdding: .day, value: offset, to: start) else { return nil }
            let num = calendar.component(.day, from: date)
            let sym = symbols[calendar.component(.weekday, from: date) - 1]
            return DayData(number: num, weekdaySymbol: sym, date: date)
        }
        return WeekData(days: days)
    }
    
    private func makeMonthTitle(for week: WeekData) -> String {
        guard let date = week.days.first?.date else { return "" }
        let fmt = DateFormatter()
        fmt.locale = L10n.language.locale
        fmt.dateFormat = "LLLL yyyy"
        return fmt.string(from: date).capitalized
    }
}

// MARK: - Models

private struct DayData: Identifiable {
    let id = UUID()
    let number: Int
    let weekdaySymbol: String
    let date: Date
}

private struct WeekData: Identifiable {
    let id = UUID().uuidString
    let days: [DayData]
}

// MARK: - Preview

#Preview {
    ScreenBuilder.previewBuilder.getComponent(type: .horizontalCalendar)
//        .padding()
}


