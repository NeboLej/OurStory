//
//  HorizontalCalendar.swift
//  OurStory
//
//  Created by Nebo on 31.08.2026.
//

import SwiftUI

struct HorizontalCalendar: View {
    
    @State private var store: HorizontalCalendarStore
    
    @State private var scrollPosition: ScrollPosition = .init()
    @State private var isLocked: Bool = false
    @State private var containerSize: CGSize = .zero
    @State private var monthTitle: String = ""
    
    private let calendar = Calendar.current
    
    init(store: HorizontalCalendarStore) {
        self.store = store
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            monthYearTitle
                .padding(.horizontal, 8)
            
            ScrollView(.horizontal) {
                HStack(spacing: 0) {
                    ForEach(store.state.weeks) { week in
                        HStack(spacing: 0) {
                            ForEach(week.days) { day in
                                dayCellContent(day)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .containerRelativeFrame(.horizontal)
                    }
                }
            }
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.paging)
            .scrollPosition($scrollPosition)
            .onGeometryChange(for: CGSize.self) { proxy in
                proxy.size
            } action: { newValue in
                containerSize = newValue
            }
            .onScrollGeometryChange(for: CGFloat.self) { proxy in
                proxy.contentOffset.x + proxy.contentInsets.leading
            } action: { oldValue, newValue in
                guard containerSize.width != .zero else { return }
                
                // Update month title based on visible week index
                let weekIndex = max(0, min(store.weeks.count - 1, Int(round(newValue / containerSize.width))))
                let newTitle = store.monthTitle(for: store.weeks[weekIndex])
                if newTitle != monthTitle {
                    monthTitle = newTitle
                }
                
                let isAddPreviousWeeks = newValue < 0
                let isAddNextWeeks = newValue > (containerSize.width * 2)
                
                if (isAddPreviousWeeks || isAddNextWeeks) && !isLocked {
                    isLocked = true
                    store.send(isAddPreviousWeeks ? .addPreviousTwoWeeks : .addNextTwoWeeks, animation: nil)
                } else {
                    if isLocked {
                        var transaction = Transaction()
                        transaction.scrollPositionUpdatePreservesVelocity = true
                        withTransaction(transaction) {
                            if isAddPreviousWeeks {
                                scrollPosition.scrollTo(x: containerSize.width * 2)
                            } else {
                                scrollPosition.scrollTo(x: -containerSize.width * 2)
                            }
                        }
                        
                        isLocked = false
                    }
                }
            }
            .onAppear {
                scrollPosition.scrollTo(id: store.currentWeekID)
                monthTitle = store.monthTitle(for: store.weeks[1])
            }
        }
    }
    
    @ViewBuilder
    private var monthYearTitle: some View {
        Text(monthTitle)
            .font(.mySemiBold(size: 22))
            .foregroundStyle(.textMulticolor)
            .contentTransition(.numericText())
            .animation(.easeInOut(duration: 0.2), value: monthTitle)
    }
    
    @ViewBuilder
    private func dayCellContent(_ day: HCDay) -> some View {
        let isSelected = calendar.isDate(store.state.selectionDate, inSameDayAs: day.date)
        let isCurrenDay = calendar.isDate(day.date, inSameDayAs: Date.now)
        
        ZStack {
            RoundedRectangle(cornerSize: CGSize(width: 24, height: 24), style: .continuous)
                .fill(isSelected ? Color.myPrimary : isCurrenDay ? .black.opacity(0.6) : Color.clear)
                .padding(1)
            VStack {
                
                Text("\(day.value)")
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
            store.send(.selectedDate(day.date))
        }
    }
}

#Preview {
    ScreenBuilder.previewBuilder.getScreen(type: .home)
}
