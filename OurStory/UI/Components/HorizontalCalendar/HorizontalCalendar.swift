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
    
    private let calendar = Calendar.current
    
    init(store: HorizontalCalendarStore) {
        self.store = store
    }
    
    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 0) {
                ForEach(store.state.weeks) { week in
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
        .scrollPosition($scrollPosition)
        .defaultScrollAnchor(.center, for: .initialOffset)
        .onGeometryChange(for: CGSize.self) { proxy in
            proxy.size
        } action: { newValue in
            containerSize = newValue
        }
        .onScrollGeometryChange(for: CGFloat.self) { proxy in
            proxy.contentOffset.x + proxy.contentInsets.leading
        } action: { oldValue, newValue in
            guard containerSize.width != .zero else { return }
            
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
    }
    
    @ViewBuilder
    private func dayCellContent(_ day: HCDay) -> some View {
        let isSelected = calendar.isDate(store.state.selectionDate, inSameDayAs: day.date)
        let isCurrenDay = calendar.isDate(day.date, inSameDayAs: Date.now)
        
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
        .onTapGesture {
            store.send(.selectedDate(day.date))
        }
    }
}

#Preview {
    ScreenBuilder.previewBuilder.getScreen(type: .home)
}
