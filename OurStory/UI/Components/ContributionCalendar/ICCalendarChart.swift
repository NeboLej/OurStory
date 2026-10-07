//
//  WSCalendarView.swift
//  WaterSeven
//
//  Created by Nebo on 29.10.2022.
//
//
//import SwiftUI
//
//struct DateModel: Identifiable {
//    var id = UUID().uuidString
//    var day: Int
//    var date: Date
//}
//
//struct MonthModel: Identifiable {
//    var id = UUID().uuidString
//    var month: Date
//    
//    init(_ month: Date) {
//        self.id = UUID().uuidString
//        self.month = month
//    }
//}
//
//struct ICCalendarChart: View {
//    
//    private let columns = Array(repeating: GridItem(.flexible(minimum: 19, maximum: 20)), count: 7)
//    private var calendar: Calendar
//    private let days: [String]
//    
//    @Binding var recordsDate: [Date]
//    @Binding var selectedDate: Date?
//    @State private var maxRecordsInDayCount: Int = 0
//    @Binding var color: Color
//    @State private var monthModels: [MonthModel] = []
//    
//    init(recordsDate: Binding<[Date]>, selectedDate: Binding<Date?>, color: Binding<Color>) {
//        calendar = Calendar(identifier: .gregorian)
//        calendar.locale = LocalizationManager.shared.getCurrentLocal()
//        
//        days = calendar.shortWeekdaySymbols
//        
//        _recordsDate = recordsDate
//        _selectedDate = selectedDate
//        _color = color
//    }
//    
//    var body: some View {
//        HStack(alignment: .center, spacing: 4) {
//            VStack(alignment: .leading, spacing: 11) {
//                ForEach(days, id: \.self) { day in
//                    Text(day)
//                        .font(.myFont(type: .regular, size: 14))
//                        .padding(.bottom, 4.5)
//                        .foregroundStyle(.textInfo)
//                }
//            }.padding(.top, 25)
//            
//            ScrollViewReader { proxy in
//                ScrollView(.horizontal, showsIndicators: false) {
//                    HStack(spacing: 12) {
//                        ForEach(monthModels) { monthModel in
//                            monthView(month: monthModel.month)
//                                .id(monthModel.id)
//                        }
//                        .onAppear {
//                            if let lastModel = monthModels.last {
//                                withAnimation {
//                                    proxy.scrollTo(lastModel.id, anchor: .trailing)
//                                }
//                            }
//                        }
//                    }
//                }
//            }
//        }
//        .onAppear {
//            updateMaxRecordsInDayCount()
//            monthModels = getMonths(dates: recordsDate).map { MonthModel($0) }
//        }
//        .onChange(of: recordsDate) { oldValue, newValue in
//            updateMaxRecordsInDayCount()
//        }
//    }
//    
//    @ViewBuilder
//    private func monthView(month: Date) -> some View {
//        VStack(alignment: .leading, spacing: 2) {
//            Text(month.monthNameShort(locale: calendar.locale!))
//                .font(.myFont(type: .medium, size: 18))
//                .foregroundStyle(.textInfo)
//            LazyHGrid(rows: columns, alignment: .center, spacing: 2, pinnedViews: .sectionHeaders) {
//                ForEach(extractDate(month: month)) {
//                    dateCell(model: $0)
//                }
//            }.frame(height: 25 * 7 + 6 * 4)
//                .padding(.leading, 2)
//        }
//    }
//    
//    @ViewBuilder
//    private func dateCell(model: DateModel) -> some View {
//        ZStack {
//            if model.day != -1 {
//                RoundedRectangle(cornerRadius: 4)
//                    .fill(.gray.opacity(0.3))
//                    .overlay {
//                        RoundedRectangle(cornerRadius: 4)
//                            .fill(fillCell(date: model.date))
//                    }
//                    .overlay {
//                        RoundedRectangle(cornerRadius: 4)
//                            .stroke(style: .init(lineWidth: model.date.isSameDay(date: Date()) ? 2 : 0))
//                            .foregroundStyle(.red)
//                    }
//            }
//        }
//        .frame(width: 22, height: 22)
//        .onTapGesture {
//            selectedDate = model.date != selectedDate ? model.date : nil
//        }
//    }
//    
//    private func fillCell(date: Date) -> Color {
//        var color: Color = .clear
//        
//        let records = recordsDate.filter { recordDate in
//            recordDate.isSameDay(date: date)
//        }
//        
//        if !records.isEmpty {
//            let colorInOneRecord: Double =  (0.7 / Double(maxRecordsInDayCount))
//            color = self.color.opacity(0.3 + colorInOneRecord * Double(records.count))
//        }
//        
//        if let selectedDate, date.isSameDay(date: selectedDate) {
//            color = .background3
//        }
//        
//        return color
//    }
//    
//    private func updateMaxRecordsInDayCount() {
//        let days = Dictionary(grouping: recordsDate) { date in
//            calendar.dateComponents([.day, .month], from: date)
//        }
//        
//        maxRecordsInDayCount = days.values.max(by: { $0.count < $1.count })?.count ?? 0
//    }
//    
//    private func getMonths(dates: [Date]) -> [Date] {
//        var monthsSet = Set<DateComponents>()
//        dates.forEach {
//            let date = calendar.dateComponents([.month, .year], from: $0)
//            monthsSet.insert(date)
//        }
//        let months = monthsSet.compactMap { calendar.date(from: $0) }.sorted(by: { $0 < $1 })
//        return months.isEmpty ? [Date()] : months
//    }
//    
//    private func extractDate(month: Date) -> [DateModel] {
//        var days = month.getAllDatesForMonth().compactMap {
//            return DateModel(day: calendar.component(.day, from: $0), date: $0)
//        }
//        
//        let firstWeekday = calendar.component(.weekday, from: days.first?.date ?? Date() )
//        if firstWeekday != 1 {
//            for _ in 0..<firstWeekday - 1 {
//                days.insert(DateModel(day: -1, date: Date()), at: 0)
//            }
//        }
//        return days
//    }
//}
//
////#Preview {
////    @Previewable @State var selectedDate: Date?
////
////    ICCalendarChart(recordsDate: .constant([Date(), Date(), Date().prevMonth, Date().prevDay, Date().prevDay]),
////                    selectedDate: $selectedDate, color: .constant(.green))
////}
////
//#Preview {
//    ScreenBuilder.shared.getScreen(screenType: .counter(Counter(name: "Counter", desc: "bla bla bla jsadk jjda kdjnak sjdkas ndkjasndk anskdj akjsdnaskj dnashb dhasdb jasdl asd;am lsdjk na", count: 123, lastRecord: Date(), colorHex: "04d4f4", isFavorite: true, targetCount: 500, dateCreate: Date())))
//}
