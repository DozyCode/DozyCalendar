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
        selectedDate: Binding<Date?>,
        @ViewBuilder cellBuilder: @escaping (Day, Bool) -> Cell
    ) {
        self.configuration = configuration
        self._selectedDate = selectedDate
        self.cellBuilder = cellBuilder
        
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
    
    private let configuration: DozyCalendarConfiguration
    private let cellBuilder: (Day, Bool) -> Cell
    private let dateFormatter = DateFormatter()
    private let columns = Array(0...6).map { _ in
        return GridItem(.flexible(minimum: 0, maximum: .infinity), spacing: 0, alignment: .center)
    }
    
    // LEFT OFF: Vertical scrolling is completely broken.
    public var body: some View {
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
                            .size { size in
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
        .onAppear {
            proxyProvider?(viewModel)
            viewModel.onWillScroll = willScroll
            viewModel.onDidScroll = didScroll
        }
        .size { size in
            calendarWidth = size.width
            viewModel.calendarSizeUpdated(size)
        }
    }
    
    @ViewBuilder private func calendarSection(_ section: Section) -> some View {
        LazyVGrid(columns: columns, alignment: .center, spacing: configuration.cellSpacing ?? 0) {
            ForEach(section.days, id: \.self) { day in
                cellBuilder(day, selectedDate?.id == day.date.id)
                    .onTapGesture {
                        selectedDate = day.date
                    }
            }
        }
    }
}
