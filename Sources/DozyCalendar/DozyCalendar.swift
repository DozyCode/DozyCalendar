//
//  DozyCalendarView.swift
//  DozyCalendar
//
//  Created by Carter Foughty on 3/16/23.
//

import SwiftUI

public struct DozyCalendar<Cell: View>: View {
    
    public init(
        configuration: DozyCalendarConfiguration,
        selectedDate: Binding<Date>,
        @ViewBuilder cellBuilder: @escaping (Day, Bool) -> Cell
    ) {
        self.configuration = configuration
        self._selectedDate = selectedDate
        self.cellBuilder = cellBuilder
        
        _viewModel = StateObject(wrappedValue: DozyCalendarViewModel(
            sectionStyle: .month(dynamicRows: false),
            dateRange: configuration.range
        ))
    }
    
    @Environment(\.proxyProvider) var proxyProvider
    @Environment(\.willScroll) var willScroll
    @Environment(\.didScroll) var didScroll
    
    @StateObject var viewModel: DozyCalendarViewModel
    @Binding private var selectedDate: Date
    @State private var currentPage: Int = 0
    
    private let configuration: DozyCalendarConfiguration
    private let cellBuilder: (Day, Bool) -> Cell
    private let dateFormatter = DateFormatter()
    private let columns = Array(1...7).map { _ in
        return GridItem(.flexible(minimum: 0, maximum: .infinity), spacing: 0, alignment: .center)
    }
    
    public var body: some View {
        ScrollView(configuration.scrollAxis.toSet, showsIndicators: false) {
            LazyHStack(spacing: 0) {
                switch configuration.sectionStyle {
                case .week:
                    ForEach(viewModel.sections.flatMap { $0.days }, id: \.self) { day in
                        cellBuilder(day, selectedDate.id == day.date.id)
                            .onTapGesture {
                                selectedDate = day.date
                            }
                            .frame(width: viewModel.calendarSize.width)
                    }
                case .month:
                    ForEach(viewModel.sections, id: \.self) { section in
                        LazyVGrid(columns: columns, alignment: .center, spacing: configuration.cellSpacing ?? 0) {
                            ForEach(section.days, id: \.self) { day in
                                cellBuilder(day, selectedDate.id == day.date.id)
                                    .onTapGesture {
                                        selectedDate = day.date
                                    }
                            }
                        }
                        .frame(width: viewModel.calendarSize.width)
                    }
                }
            }
            .fixedSize()
        }
        .uiScrollView { uiScrollView in
            viewModel.install(uiScrollView)
        }
        .onAppear {
            proxyProvider?(viewModel)
            viewModel.willScroll = willScroll
            viewModel.didScroll = didScroll
        }
        .size { size in
            viewModel.calendarSize = size
        }
    }
}
