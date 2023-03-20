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
    @State private var selectedDate: Date? = Date()
    @State private var currentDate = Date()
    @State private var displayingMonth = true
    @State private var calendarWidth: CGFloat?
    
    private let monthConfig = DozyCalendarConfiguration(
        range: .infinite,
        scrollAxis: .horizontal,
        rowSpacing: 0,
        columnSpacing: 0,
        sectionStyle: .month(dynamicRows: false),
        startOfWeek: .sun
    )
    
    private let weekConfig = DozyCalendarConfiguration(
        range: .infinite,
        scrollAxis: .horizontal,
        rowSpacing: 0,
        columnSpacing: 0,
        sectionStyle: .week,
        startOfWeek: .sun
    )
    
    @SceneBuilder var body: some Scene {
        WindowGroup {
            ZStack {
                if displayingMonth {
                    DozyCalendar(configuration: monthConfig, selectedDate: $selectedDate) { day, isSelected in
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
                    } headerBuilder: { weekday, isToday, isSelected in
                        Text(weekday.shortText)
                            .padding(.vertical, 6)
                            .padding(.top, 4)
                            .foregroundColor(isToday ? .blue : .black)
                            .background(isSelected ? Color.orange : nil)
                    }
                    .background {
                        Color.gray
                            .opacity(0.5)
                            .cornerRadius(12)
                    }
                } else {
                    VStack {
                        HStack {
                            ForEach(monthConfig.weekdays, id: \.self) { day in
                                Text(day.text)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        DozyCalendar(configuration: weekConfig, selectedDate: $selectedDate) { day, isSelected in
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
                        .background {
                            Color.gray
                                .opacity(0.5)
                                .cornerRadius(12)
                        }
                    }
                }
            }
            .proxy { viewModel.proxy = $0 }
            .willScrollToSectionWithDays { days in
                print("~~ Will scroll to: \(days.first { $0 == .month($0.date) }!.date)")
            }
            .didScrollToSectionWithDays { days in
                print("~~ Did scroll to: \(days.first { $0 == .month($0.date) }!.date)")
                currentDate = days.first {
                    if case .month = $0 {
                        return true
                    }
                    return false
                }?.date ?? currentDate
            }
            .padding(.top, 16)
            .padding(.horizontal, 16)
            .onChange(of: selectedDate) { selectedDate in
                guard let selectedDate else { return }
                currentDate = selectedDate
            }
            Spacer()
            
            VStack {
                Divider()
                DatePicker("Current Date", selection: $currentDate, displayedComponents: .date)
                    .padding(.vertical, 4)
                    .onChange(of: currentDate) { date in
                        viewModel.scrollTo(date)
                    }
                Divider()
                HStack {
                    Text("Clear Selection")
                    Spacer()
                    Button("Clear") {
                        selectedDate = nil
                    }
                    .buttonStyle(.bordered)
                }
                Divider()
                HStack {
                    Text(displayingMonth ? "Month" : "Week")
                    Spacer()
                    Button("Switch") {
                        displayingMonth.toggle()
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.vertical, 4)
                Divider()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
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
