//
//  DozyCalendarView.swift
//  DozyCalendar
//
//  Created by Carter Foughty on 3/16/23.
//

import SwiftUI

@available(iOS 17.0, *)
public struct DozyCalendar<Header: View, Cell: View>: View {
    
    // MARK: - API
    
    public init(
        configuration: DozyCalendarConfiguration,
        selectedDate: Binding<Date?>,
        proxyProvider: ((DozyCalendarProxy) -> Void)? = nil,
        @ViewBuilder cell: @escaping (_ day: Day, _ isToday: Bool, _ isSelected: Bool) -> Cell,
        @ViewBuilder header: @escaping (_ weekday: WeekdayModel, _ isToday: Bool, _ isSelected: Bool) -> Header
    ) {
        self.configuration = configuration
        self._selectedDate = selectedDate
        self.proxyProvidingClosure = proxyProvider
        self._currentWeekday = State(initialValue: Calendar.current.component(.weekday, from: Date()))
        if let selectedDate = selectedDate.wrappedValue {
            self._selectedWeekday = State(initialValue: Calendar.current.component(.weekday, from: selectedDate))
        }
        self.cellBuilder = cell
        self.headerBuilder = header
        self.columns = Array(0...6).map { _ in
            return GridItem(
                .flexible(minimum: 0, maximum: .infinity),
                spacing: configuration.columnSpacing,
                alignment: .center
            )
        }
        
        _viewModel = StateObject(wrappedValue: DozyCalendarViewModel(configuration: configuration))
    }
    
    public init(
        configuration: DozyCalendarConfiguration,
        selectedDate: Binding<Date?>,
        proxyProvider: ((DozyCalendarProxy) -> Void)? = nil,
        @ViewBuilder cellBuilder: @escaping (_ day: Day, _ isToday: Bool, _ isSelected: Bool) -> Cell
    ) where Header == EmptyView {
        self.configuration = configuration
        self._selectedDate = selectedDate
        self.proxyProvidingClosure = proxyProvider
        // TODO: Ideally this would dynamically update
        self._currentWeekday = State(initialValue: Calendar.current.component(.weekday, from: Date()))
        if let selectedDate = selectedDate.wrappedValue {
            self._selectedWeekday = State(initialValue: Calendar.current.component(.weekday, from: selectedDate))
        }
        self.headerBuilder = nil
        self.cellBuilder = cellBuilder
        self.columns = Array(0...6).map { _ in
            return GridItem(
                .flexible(minimum: 0, maximum: .infinity),
                spacing: configuration.columnSpacing,
                alignment: .center
            )
        }
        
        _viewModel = StateObject(wrappedValue: DozyCalendarViewModel(configuration: configuration))
    }
    
    // MARK: - Variables
    
    @Environment(\.proxyProvider) private var proxyProvider
    @Environment(\.willScroll) private var willScroll
    @Environment(\.didScroll) private var didScroll
    
    @StateObject var viewModel: DozyCalendarViewModel
    @Binding private var selectedDate: Date?
    @State private var currentPage: Int = 0
    @State private var calendarHeight: CGFloat?
    @State private var calendarWidth: CGFloat = .zero
    @State private var currentWeekday: Int
    @State private var selectedWeekday: Int?
    
    private let configuration: DozyCalendarConfiguration
    private let proxyProvidingClosure: ((DozyCalendarProxy) -> Void)?
    private let cellBuilder: (_ day: Day, _ isToday: Bool, _ isSelected: Bool) -> Cell
    private let headerBuilder: ((_ weekday: WeekdayModel, _ isToday: Bool, _ isSelected: Bool) -> Header)?
    private let dateFormatter = DateFormatter()
    private let columns: [GridItem]
    
    // MARK: - Body
    
    public var body: some View {
        VStack(spacing: 0) {
            // MARK: Header
            if let headerBuilder {
                HStack(alignment: .center, spacing: 0) {
                    ForEach(configuration.weekdayModels, id: \.weekday) { weekday in
                        headerBuilder(
                            weekday,
                            currentWeekday == weekday.index,
                            selectedWeekday == weekday.index
                        )
                        .frame(width: calendarWidth / 7)
                    }
                }
                .padding(.horizontal, configuration.sectionPadding)
            }
            
            // MARK: Calendar
            ScrollView(configuration.scrollAxis.toSet, showsIndicators: false) {
                switch configuration.scrollAxis {
                case .horizontal:
                    LazyHStack(spacing: 0) {
                        ForEach(viewModel.sections, id: \.self) { section in
                            HStack(spacing: 0) {
                                calendarSection(section)
                                    .frame(maxWidth: .infinity)
                                    // Accounts for the section padding
                                    .padding(.horizontal, configuration.sectionPadding)
                                    .readSize { size in
                                        calendarHeight = size.height
                                    }
                            }
                            .containerRelativeFrame(.horizontal)
                            .id(section.id)
                        }
                    }
                    .scrollTargetLayout()
                    .frame(height: calendarHeight)
                case .vertical:
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.sections, id: \.self) { section in
                            calendarSection(section)
                                // Accounts for the section padding
                                .padding(.vertical, configuration.sectionPadding)
                                .readSize { size in
                                    calendarHeight = size.height
                                }
                                .containerRelativeFrame([.horizontal, .vertical])
                                .id(section.id)
                        }
                    }
                    .scrollTargetLayout()
                }
            }
            .uiScrollView { scrollView in
                viewModel.scrollViewFound(scrollView)
            }
            .scrollTargetBehavior(.paging)
            .frame(height: calendarHeight)
            .readSize { size in
                // Account for the section padding in our width measurement
                calendarWidth = size.width - (configuration.sectionPadding * 2)
                viewModel.calendarSizeUpdated(size)
            }
        }
        .onAppear {
            proxyProvider?(viewModel)
            proxyProvidingClosure?(viewModel)
            viewModel.onWillScroll = willScroll
            viewModel.onDidScroll = didScroll
        }
        .onChange(of: selectedDate) { selectedDate in
            guard let selectedDate else {
                selectedWeekday = nil
                return
            }
            selectedWeekday = Calendar.current.component(.weekday, from: selectedDate)
        }
    }
    
    // MARK: - Helpers
    
    @ViewBuilder private func calendarSection(_ section: Section) -> some View {
        LazyVGrid(columns: columns, alignment: .center, spacing: configuration.rowSpacing) {
            ForEach(section.days, id: \.self) { day in
                // We need to add the spacers so that, in a horizontal scrolling context,
                // the day cells will adopt the proper width relative to the size of the
                // calendar.
                HStack(alignment: .center, spacing: 0) {
                    Spacer()
                    cellBuilder(day, day.date.id == Date().id, selectedDate?.id == day.date.id)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedDate = day.date
                }
            }
        }
    }
}
