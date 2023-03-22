//
//  DemoView.swift
//  
//
//  Created by Carter Foughty on 3/21/23.
//

import SwiftUI
import DozyCalendar

struct DemoView: View {
    
    @StateObject private var viewModel = DozyCalendarDemoViewModel()
    @State private var selectedDate: Date? = Date()
    @State private var currentDate = Date()
    @State private var displayingWeekdays = true
    @State private var configuration = DozyCalendarConfiguration(
        range: .infinite,
        scrollAxis: .horizontal,
        rowSpacing: 1,
        columnSpacing: 1,
        sectionStyle: .month(dynamicRows: false),
        startOfWeek: .sun
    )
    
    var body: some View {
        VStack(spacing: 16) {
            DozyCalendar(configuration: configuration, selectedDate: $selectedDate) { day, isSelected in
                switch day {
                case let .month(date):
                    ZStack {
                        Circle()
                            .fill(isSelected ? .blue : .clear)
                            .padding(4)
                        Text(date.formatted(.dateTime.day(.defaultDigits)))
                            .foregroundColor(isSelected ? .white : .black)
                            .padding(.vertical, 14)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background {
                                Color.gray
                                    .opacity(0.2)
                            }
                    }
                case .preMonth, .postMonth:
                    Text(day.date.formatted(.dateTime.day(.defaultDigits)))
                        .foregroundColor(Color.gray)
                        .padding(.vertical, 14)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background {
                            Color.gray
                                .opacity(0.2)
                        }
                }
            } headerBuilder: { weekday, isToday, isSelected in
                if displayingWeekdays {
                    Text(weekday.shortText)
                        .padding(.vertical, 6)
                        .padding(.top, 4)
                        .foregroundColor(isSelected ? .blue : (isToday ? .orange : .black))
                } else {
                    EmptyView()
                }
            }
            .id(configuration)
            .proxy { viewModel.proxy = $0 }
            .willScrollToSectionWithDays { days in
                print("~~ Will scroll to: \(days.first { $0 == .month($0.date) }!.date)")
            }
            .didScrollToSectionWithDays { days in
                print("~~ Did scroll to: \(days.first { $0 == .month($0.date) }!.date)")
                selectedDate = days.first { $0 == .month($0.date) }?.date
            }
            .padding(.top, 16)
            .padding(.horizontal, 16)
            
            settings
        }
    }
    
    private var settings: some View {
        ScrollView {
            VStack {
                section("Navigate") {
                    HStack {
                        Button("Go to today") {
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
                                        .onChange(of: currentDate) { date in
                                            viewModel.scrollTo(date)
                                        }
                                    Color.white
                                        .allowsHitTesting(false)
                                }
                            }
                    }
                }
                section("Selection") {
                    VStack {
                        ToggleSetting(title: "Multiple selection") { isOn in
                            
                        }
                        Button("Clear") {
                            selectedDate = nil
                        }
                        .buttonStyle(DemoButtonStyle())
                    }
                }
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
                        ToggleSetting($displayingWeekdays, title: "Display weekdays")
                        ToggleSetting(title: "Dynamic rows") { isOn in
                            configuration.sectionStyle = .month(dynamicRows: isOn)
                        }
                    }
                }
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
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
    }
    
    private func section(_ title: String, settings: @escaping () -> some View) -> some View {
        VStack {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
            }
            settings()
            Divider()
        }
    }
}

fileprivate struct PickerValue<ValueType: Hashable>: Hashable {
    var value: ValueType
    var description: String
}

fileprivate struct PickerSetting<ValueType: Hashable>: View {
    
    // MARK: - API
    
    init(
        initialValue: ValueType,
        options: [PickerValue<ValueType>],
        title: String? = nil,
        onChange: @escaping (ValueType) -> Void
    ) {
        self._selection = State(initialValue: initialValue)
        self.options = options
        self.title = title
        self.onChange = onChange
    }
    
    // MARK: - Variables
    
    @State private var selection: ValueType
    
    private let options: [PickerValue<ValueType>]
    private let title: String?
    private let onChange: (ValueType) -> Void
    
    // MARK: - Body
    
    var body: some View {
        HStack {
            if let title {
                HStack {
                    Text(title)
                    Spacer(minLength: 0)
                }
                .frame(width: 90)
            }
            Picker("", selection: $selection) {
                ForEach(options, id: \.value) { option in
                    Text(option.description.capitalized)
                }
            }
            .pickerStyle(.segmented)
        }
        .onChange(of: selection) { selection in
            onChange(selection)
        }
    }
}

fileprivate struct ToggleSetting: View {
    
    // MARK: - API
    
    init(
        _ isOn: Binding<Bool>,
        title: String
    ) {
        self.isOn = isOn.wrappedValue
        self.binding = isOn
        self.title = title
        self.onChange = nil
    }
    
    init(
        title: String,
        initialValue: Bool = false,
        onChange: @escaping (Bool) -> Void
    ) {
        self.title = title
        self.isOn = initialValue
        self.onChange = onChange
    }
    
    // MARK: - Variables
    
    @State private var isOn: Bool
    private var binding: Binding<Bool>?
    
    private let title: String
    private let onChange: ((Bool) -> Void)?
    
    // MARK: - Body
    
    var body: some View {
        Toggle(isOn: $isOn) {
            Text(title)
        }
        .onChange(of: isOn) { selection in
            binding?.wrappedValue = selection
            onChange?(selection)
        }
    }
}

class DozyCalendarDemoViewModel: ObservableObject {
    
    weak var proxy: DozyCalendarProxy?
    
    func scrollTo(_ date: Date) {
        proxy?.scrollTo(date, animated: true)
    }
}

struct DemoButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.blue)
            .frame(height: 34)
            .frame(maxWidth: .infinity)
            .background(Color.gray.opacity(0.14))
            .cornerRadius(8)
    }
}
