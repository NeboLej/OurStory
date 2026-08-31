//
//  HorizontalCalendar.swift
//  OurStory
//
//  Created by Nebo on 31.08.2026.
//

import SwiftUI

struct HorizontalCalendar: View {
    
    var updatesDateFromScroll = true
    @Binding var date: Date
//    var content: (HCDay) -> Content
    
    @State private var weeks: [HCWeek]
    @State private var scrollPosition: ScrollPosition = .init()
    private let calendar = Calendar.current
    private var currentDay: Date = .now.getOffsetDate(-3, component: .day)
    
    init(updatesDateFromScroll: Bool = true,
         date: Binding<Date>) {
        self.updatesDateFromScroll = updatesDateFromScroll
        self._date = date
        
        let weeks: [HCWeek] = (-1...0).compactMap {
            HCWeek.load(from: date.wrappedValue, value: $0)
        }
        self.weeks = weeks
    }
    
    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 0) {
                ForEach(weeks) { week in
                    HStack(spacing: 0) {
                        ForEach(week.days) { day in
                            dayCellContent(day)
                                .frame(maxWidth: .infinity)
                        }
                    }.containerRelativeFrame(.horizontal)
                }
            }
        }
        .scrollIndicators(.hidden)
        .scrollTargetBehavior(.paging)
        .defaultScrollAnchor(.trailing, for: .initialOffset)
    }
    
    
    
    @ViewBuilder
    private func dayCellContent(_ day: HCDay) -> some View {
        let isSelected = calendar.isDate(date, inSameDayAs: day.date)
        let isCurrenDay = calendar.isDate(day.date, inSameDayAs: currentDay)
        
        VStack {
            Text("\(day.value)")
                .font(isSelected ? .mySemiBold(size: 14) : .myMedium(size: 14))
                .foregroundStyle(isSelected ? .white : (day.notFromThisMonth ? .gray : .black))
            Text(day.weekdaySymbol)
                .font(isSelected ? .mySemiBold(size: 14) : .myMedium(size: 14))
                .foregroundStyle(isSelected ? .white : (day.notFromThisMonth ? .gray : .black))
        }
        .frame(width: 50, height: 60)
        .background(isSelected ? .black.opacity(0.6) : isCurrenDay ? Color.myPrimary : Color.clear)
        .cornerRadius(20)
        .overlay {
            RoundedRectangle(cornerSize: CGSize(width: 20, height: 20), style: .circular)
                .stroke(lineWidth: 1)
                .foregroundStyle(.black)
                .padding(1)
        }
    }
}

#Preview {
    ScreenBuilder.previewBuilder.getScreen(type: .home)
}
