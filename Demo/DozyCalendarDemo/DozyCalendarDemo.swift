//
//  DozyCalendarDemo.swift
//  Demo
//
//  Created by Carter Foughty on 3/16/23.
//

import SwiftUI
import DozyCalendar

@main
struct DozyCalendarDemo: App {
    
    private let gridItem = GridItem(.flexible(minimum: 0, maximum: .infinity), spacing: 0, alignment: .center)
    
    @StateObject private var viewModel = DozyCalendarDemoViewModel()
    @State private var selectedDate = Date()
    @State private var dateToJumpTo = Date()
    
    private let calendarConfig = DozyCalendarConfiguration(
        range: .infinite,
        scrollAxis: .horizontal,
        cellSpacing: nil,
        sectionStyle: .month(dynamicRows: false)
    )
    
    @SceneBuilder var body: some Scene {
        WindowGroup {
            Spacer()
            DozyCalendar(configuration: calendarConfig, selectedDate: $selectedDate) { day, isSelected in
                switch day {
                case let .month(date):
                    ZStack {
                        Text(string(for: date))
                            .padding(14)
                        if isSelected {
                            Color.blue
                                .opacity(0.5)
                                .cornerRadius(8)
                        }
                    }
                case .preMonth, .postMonth:
                    Text(string(for: day.date))
                        .foregroundColor(Color.gray)
                        .padding(14)
                }
            }
            .proxy { viewModel.proxy = $0 }
            .willScrollToSectionWithDays { days in
                print("~~ Will scroll to: \(days.first { $0 == .month($0.date) }!.date)")
            }
            .didScrollToSectionWithDays { days in
                print("~~ Did scroll to: \(days.first { $0 == .month($0.date) }!.date)")
            }
            .background {
                Color.gray
                    .opacity(0.5)
                    .cornerRadius(12)
            }
            Spacer()
            DatePicker("Jump to a date!", selection: $dateToJumpTo, displayedComponents: .date)
                .padding()
                .onChange(of: dateToJumpTo) { date in
                    viewModel.scrollTo(date)
                }
            Spacer()
        }
    }
    
    func string(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
}

class DozyCalendarDemoViewModel: ObservableObject {
    
    weak var proxy: DozyCalendarProxy?
    
    func scrollTo(_ date: Date) {
        proxy?.scrollTo(date, animated: true)
    }
}
