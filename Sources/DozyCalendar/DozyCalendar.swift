//
//  DozyCalendarView.swift
//  DozyCalendar
//
//  Created by Carter Foughty on 3/16/23.
//

import SwiftUI

public struct DozyCalendar<Header: View, Cell: View>: View {
    
    public init(
        configuration: DozyCalendarConfiguration,
        selectedDate: Binding<Date?>,
        @ViewBuilder cellBuilder: @escaping (Day, Bool) -> Cell,
        @ViewBuilder headerBuilder: @escaping (Weekday, Bool) -> Header
    ) {
        self.configuration = configuration
        self._selectedDate = selectedDate
        self.cellBuilder = cellBuilder
        self.headerBuilder = headerBuilder
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
        @ViewBuilder cellBuilder: @escaping (Day, Bool) -> Cell
    ) where Header == EmptyView {
        self.configuration = configuration
        self._selectedDate = selectedDate
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
    
    @Environment(\.proxyProvider) var proxyProvider
    @Environment(\.willScroll) var willScroll
    @Environment(\.didScroll) var didScroll
    
    @StateObject var viewModel: DozyCalendarViewModel
    @Binding private var selectedDate: Date?
    @State private var currentPage: Int = 0
    @State private var calendarWidth: CGFloat?
    @State private var calendarHeight: CGFloat?
    @State private var weekdayWidth: CGFloat?
    
    private let configuration: DozyCalendarConfiguration
    private let cellBuilder: (Day, Bool) -> Cell
    private let headerBuilder: ((Weekday, Bool) -> Header)?
    private let dateFormatter = DateFormatter()
    private let columns: [GridItem]
    
    public var body: some View {
        VStack(spacing: 0) {
            if let headerBuilder {
                HStack(alignment: .center, spacing: 0) {
                    ForEach(configuration.weekdays, id: \.self) { weekday in
                        headerBuilder(weekday, false)
                            .frame(width: weekdayWidth)
                    }
                }
            }
            ScrollView(configuration.scrollAxis.toSet, showsIndicators: false) {
                switch configuration.scrollAxis {
                case .horizontal:
                    LazyHStack(spacing: 0) {
                        ForEach(viewModel.sections, id: \.self) { section in
                            calendarSection(section)
                                .frame(width: calendarWidth)
                        }
                    }
                    .fixedSize()
                case .vertical:
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.sections, id: \.self) { section in
                            calendarSection(section)
                                .readSize { size in
                                    calendarHeight = size.height
                                }
                                .frame(width: calendarWidth, height: calendarHeight)
                        }
                    }
                    .frame(height: calendarHeight)
                }
            }
            .uiScrollView { uiScrollView in
                viewModel.install(uiScrollView)
            }
            .frame(height: calendarHeight)
            .readSize { size in
                calendarWidth = size.width
                weekdayWidth = size.width / 7
                viewModel.calendarSizeUpdated(size)
            }
        }
        .onAppear {
            proxyProvider?(viewModel)
            viewModel.onWillScroll = willScroll
            viewModel.onDidScroll = didScroll
        }
    }
    
    @ViewBuilder private func calendarSection(_ section: Section) -> some View {
        LazyVGrid(columns: columns, alignment: .center, spacing: configuration.rowSpacing) {
            ForEach(section.days, id: \.self) { day in
                cellBuilder(day, selectedDate?.id == day.date.id)
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedDate = day.date
                    }
            }
        }
    }
}
