//
//  DemoView.swift
//  
//
//  Created by Carter Foughty on 3/21/23.
//

import SwiftUI
import DozyCalendar

internal struct DemoView: View {
    
    @StateObject private var viewModel = DozyCalendarDemoViewModel()
    @State private var selectedDate: Date? = Date()
    @State private var currentDate = Date()
    @State private var monthText = " "
    @State private var displayingSettings = false
    @State private var configuration = DozyCalendarConfiguration(
        range: .infinite,
        scrollAxis: .horizontal,
        rowSpacing: 0,
        columnSpacing: 0,
        sectionPadding: 0,
        sectionStyle: .month(dynamicRows: false),
        startOfWeek: .sun
    )
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(monthText)
                    .font(.headline)
                Spacer()
            }
            
            // Create the calendar with our desired configuration and selected date binding
            DozyCalendar(
                configuration: configuration,
                selectedDate: $selectedDate
            ) { day, isToday, isSelected in
                dayBuilder(day, isToday: isToday, isSelected: isSelected)
            } header: { weekday, isToday, isSelected in
                headerBuilder(weekday, isToday: isToday, isSelected: isSelected)
            }
            .id(configuration)
            .padding(.top, 4)
            .padding(.bottom, 8)
            .background {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.gray.opacity(0.2))
            }
            // Give the view model the proxy, which allows for programmatic scrolling.
            .proxy { viewModel.proxy = $0 }
            .onAppear(perform: viewModel.appeared)
            // Callbacks on will scroll
            .willScrollToSectionWithDays { days in
                guard let monthDate = days.first(where: { $0 == .month($0.date) })?.date else { return }
                print("~~ Will scroll to: \(monthDate)")
            }
            // Callbacks on did scroll
            .didScrollToSectionWithDays { days in
                guard let monthDate = days.first(where: { $0 == .month($0.date) })?.date else { return }
                monthText = monthDate.formatted(.dateTime.month().year())
                selectedDate = monthDate
                print("~~ Did scroll to: \(monthDate)")
            }
            
            Spacer()
            
            settings
        }
        .padding(.horizontal, 16)
        .sheet(isPresented: $displayingSettings) {
            settingsPanel
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }
    
    @ViewBuilder private func dayBuilder(_ day: Day, isToday: Bool, isSelected: Bool) -> some View {
        switch day {
        case let .month(date):
            Text(date.formatted(.dateTime.day(.defaultDigits)))
                .foregroundStyle(isSelected ? Color.white : isToday ? Color.blue : Color.black)
                .font(Font.system(size: 16, weight: isSelected ? .bold : .regular))
                .frame(width: 34, height: 34)
                .background {
                    if isSelected {
                        Circle()
                            .fill(isToday ? .blue : .black)
                    }
                }
        case .preMonth, .postMonth:
            Text(day.date.formatted(.dateTime.day(.defaultDigits)))
                .foregroundColor(Color.gray)
                .frame(width: 34, height: 34)
        }
    }
    
    @ViewBuilder private func headerBuilder(
        _ weekday: WeekdayModel,
        isToday: Bool,
        isSelected: Bool
    ) -> some View {
        Text(weekday.shortText.uppercased())
            .font(Font.system(size: 12, weight: .regular))
            .padding(.vertical, 6)
            .foregroundStyle(isToday ? .blue : .black)
    }
    
    private var settings: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                Button("Go to Today") {
                    viewModel.scrollTo(Date())
                }
                .buttonStyle(DemoButtonStyle())
                Button("Go to...") { }
                    .buttonStyle(DemoButtonStyle())
                    .allowsHitTesting(false)
                    .background {
                        ZStack {
                            DatePicker("", selection: $currentDate, displayedComponents: .date)
                                .datePickerStyle(.compact)
                                .labelsHidden()
                                .padding(.vertical, 4)
                                .onChange(of: currentDate) { _, date in
                                    viewModel.scrollTo(date)
                                }
                            Color.white
                                .allowsHitTesting(false)
                        }
                    }
            }
            
            HStack(spacing: 16) {
                Button("Clear Selection") {
                    selectedDate = nil
                }
                .buttonStyle(DemoButtonStyle())
                
                Button {
                    displayingSettings = true
                } label: {
                    Image(systemName: "gear")
                }
                .frame(width: 40)
            }
        }
    }
    
    private var settingsPanel: some View {
        ScrollView {
            VStack(spacing: 18) {
                section("Configuration") {
                    VStack(spacing: 14) {
                        PickerSetting(
                            initialValue: Axis.horizontal,
                            options: Axis.allCases.map { PickerValue(value: $0, description: $0.description) },
                            title: "Scroll"
                        ) { selection in
                            configuration.scrollAxis = selection
                        }
                        PickerSetting(
                            initialValue: SectionStyle.month(dynamicRows: false),
                            options: [.week, .month(dynamicRows: false)].map { PickerValue(value: $0, description: $0.description) },
                            title: "Style"
                        ) { selection in
                            configuration.sectionStyle = selection
                        }
                        PickerSetting(
                            initialValue: Weekday.sun,
                            options: Weekday.allCases.map { PickerValue(value: $0, description: $0.text) },
                            title: "Week start"
                        ) { selection in
                            configuration.startOfWeek = selection
                        }
                        ToggleSetting(title: "Dynamic rows") { isOn in
                            configuration.sectionStyle = .month(dynamicRows: isOn)
                        }
                    }
                }
                Divider()
                section("Spacing") {
                    VStack {
                        PickerSetting(
                            initialValue: 1,
                            options: Array(0...6).map { PickerValue(value: $0, description: String($0)) },
                            title: "Row"
                        ) { selection in
                            configuration.rowSpacing = CGFloat(selection)
                        }
                        PickerSetting(
                            initialValue: 1,
                            options: Array(0...6).map { PickerValue(value: $0, description: String($0)) },
                            title: "Column"
                        ) { selection in
                            configuration.columnSpacing = CGFloat(selection)
                        }
                        PickerSetting(
                            initialValue: 1,
                            options: Array(0...6).map { PickerValue(value: $0, description: String($0)) },
                            title: "Section"
                        ) { selection in
                            configuration.sectionPadding = CGFloat(selection)
                        }
                    }
                }
            }
            .padding(16)
        }
    }
    
    private func section(_ title: String, settings: @escaping () -> some View) -> some View {
        VStack(spacing: 10) {
            HStack {
                Text(title.uppercased())
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
            }
            settings()
        }
    }
}
