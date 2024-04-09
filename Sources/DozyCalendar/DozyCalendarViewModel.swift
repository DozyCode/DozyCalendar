//
//  DozyCalendarViewModel.swift
//  DozyCalendar
//
//  Created by Carter Foughty on 3/16/23.
//

import UIKit
import SwiftUI

// TODO: What's Left...
// - Make sure jumping in certain direction looks accurate w/ scrolling
//      - This is still an issue when you jump so far that a complete regeneration is needed
// - Multiple selection
// - Vertical scroll axis not working
// - Better errors
// - Add isToday to cell builder

enum CalendarError: String {
    case range = "The desired date lies outside of the provided date range."
    case configuration = "The developer provided a non-viable configuration."
    case metadataGeneration = "The calendar failed to generate the correct dates."
}

class DozyCalendarViewModel: NSObject, ObservableObject, DozyCalendarChangeProvider {
    
    // MARK: - API
    
    @Published var sections: [Section] = []
    
    var onWillScroll: (([Day]) -> Void)?
    var onDidScroll: (([Day]) -> Void)?
    
    func scrollView(_ uiScrollView: UIScrollView) {
        self.scrollView = uiScrollView
        if dateRange == .infinite {
            uiScrollView.delegate = self
        }
        if let queuedDateScrollPosition {
            scrollTo(queuedDateScrollPosition, animated: false)
            self.queuedDateScrollPosition = nil
        }
    }
    
    func isCurrentWeekday(index: Int) -> Bool {
        let weekday = calendar.component(.weekday, from: Date())
        return index == weekday
    }
    
    init(configuration: DozyCalendarConfiguration) {
        self.sectionStyle = configuration.sectionStyle
        self.dateRange = configuration.range
        self.startOfWeek = configuration.startOfWeek
        self.scrollAxis = configuration.scrollAxis
        
        var calendar = Calendar.current
        calendar.firstWeekday = startOfWeek.rawValue
        self.calendar = calendar
        let baseDate = Date()
        
        super.init()
        generateCalendar(baseDate: baseDate)
        
    }
    
    func calendarSizeUpdated(_ size: CGSize) {
        calendarSize = size
    }
    
    // MARK: - Constants
    
    private let sectionDistanceToEdge = 6
    
    // MARK: - Variables
    
    private let calendar: Calendar
    private let sectionStyle: SectionStyle
    private let dateRange: DateRange
    private let startOfWeek: Weekday
    private let scrollAxis: Axis
    
    private weak var scrollView: UIScrollView?
    private var sectionCache = [Section.Identifier: Section]()
    private var dateUponAppear: Date?
    private var calendarSize: CGSize = .zero
    
    private var queuedDateScrollPosition: Date?
    
    private var calendarSectionSize: CGFloat {
        switch scrollAxis {
        case .horizontal: return calendarSize.width
        case .vertical: return calendarSize.height
        }
    }
    
    // MARK: - Helpers
    
    private func generateCalendar(baseDate: Date) {
        switch dateRange {
        case .infinite:
            let currentSectionID = baseDate.sectionID(style: sectionStyle, calendar: calendar)
            let firstSectionID = currentSectionID.advanced(by: -sectionDistanceToEdge, calendar)
            let lastSectionID = currentSectionID.advanced(by: sectionDistanceToEdge, calendar)
            generateSections(firstSectionID, lastSectionID)
        case let .limited(startDate, endDate):
            let firstSectionID = startDate.sectionID(style: sectionStyle, calendar: calendar)
            let lastSectionID = endDate.sectionID(style: sectionStyle, calendar: calendar)
            generateSections(firstSectionID, lastSectionID)
        }
    }
    
    private func generateSections(_ firstSectionID: Section.Identifier, _ secondSectionID: Section.Identifier) {
        guard firstSectionID <= secondSectionID else { fatalError("First section can't be before second.") }
        var sections = [Section]()
        var sectionIDIterator = firstSectionID
        
        while sectionIDIterator <= secondSectionID {
            if let section = sectionCache[sectionIDIterator] {
                sections.append(section)
            } else {
                let section = section(for: sectionIDIterator)
                sections.append(section)
            }
            sectionIDIterator = sectionIDIterator.next(calendar)
        }
        self.sections = sections
    }
    
    private func section(for sectionID: Section.Identifier) -> Section {
        let firstDate = sectionID.firstDate
        let startOfWeek = startOfWeek.rawValue
        var days = [Day]()
        
        switch sectionID.style {
        case .week:
            for dayAdjustment in 0...6 {
                guard let date = calendar.date(byAdding: .day, value: dayAdjustment, to: firstDate(calendar)) else { assert(false) }
                days.append(.month(date))
            }
        case let .month(dynamicRows):
            guard let range = calendar.range(of: .day, in: .month, for: firstDate(calendar)) else { assert(false) }
            var lastMonthDate = firstDate(calendar)
            // Check the weekday of the first date. If the weekday is not equal to the
            // start of the week, generate the pre-month days needed.
            do {
                let weekDay = calendar.component(.weekday, from: firstDate(calendar))
                if weekDay != startOfWeek {
                    let weekPositionAdjustment = weekDay < startOfWeek ? 7 : 0
                    let preMonthDaysNeeded = weekDay - startOfWeek + weekPositionAdjustment
                    for dayAdjustment in stride(from: preMonthDaysNeeded, to: 0, by: -1) {
                        guard let date = calendar.date(byAdding: .day, value: -dayAdjustment, to: firstDate(calendar)) else { assert(false) }
                        days.append(.preMonth(date))
                    }
                }
            }
            // Create the `month` dates.
            do {
                for day in range {
                    // Subtract one, because the first of the month is the `firstDate`.
                    guard let date = calendar.date(byAdding: .day, value: day - 1, to: firstDate(calendar)) else { assert(false) }
                    days.append(.month(date))
                    lastMonthDate = date
                }
            }
            // Check the weekday of the last date. If it isn't the last day of the week,
            // we need to create the relevant 'post-month dates'.
            do {
                let remainingDaysRequired = dynamicRows ? 7 - calendar.component(.weekday, from: lastMonthDate) : 42 - days.count
                if remainingDaysRequired > 0 {
                    for day in 1...remainingDaysRequired {
                        guard let date = calendar.date(byAdding: .day, value: day, to: lastMonthDate) else { assert(false) }
                        days.append(.postMonth(date))
                    }
                }
            }
        }
        let section = Section(id: sectionID, days: days)
        sectionCache[sectionID] = section
        return section
    }
    
    private func appendSection(direction: Direction) {
        guard let endSectionID = sections[keyPath: direction.endSectionIDKeypath] else { assert(false) }
        let nextSectionID = direction.nextSectionID(sectionID: endSectionID, calendar)
        let newSection = section(for: nextSectionID)
        
        switch direction {
        case .backward: sections.insert(newSection, at: 0)
        case .forward: sections.append(newSection)
        }
    }
    
    fileprivate enum Direction {
        case backward
        case forward
        
        var endSectionIDKeypath: KeyPath<[Section], Section.Identifier?> {
            switch self {
            case .backward: return \.first?.id
            case .forward: return \.last?.id
            }
        }
        
        func nextSectionID(sectionID: Section.Identifier, _ calendar: Calendar) -> Section.Identifier {
            switch self {
            case .backward: return sectionID.previous(calendar)
            case .forward: return sectionID.next(calendar)
            }
        }
    }
}

extension DozyCalendarViewModel: DozyCalendarProxy {
    
    func scrollTo(_ date: Date, animated: Bool) {
        guard let scrollView else {
            self.queuedDateScrollPosition = date
            return
        }
        
        let sectionID = date.sectionID(style: sectionStyle, calendar: calendar)
        // If the current array of sections contains the date, scroll directly to it.
        // Otherwise, regenerate the calendar and try again.
        if !scrollToExisting(sectionID: sectionID, animated: animated, scrollView: scrollView) {
            generateCalendar(baseDate: date)
            scrollToExisting(sectionID: sectionID, animated: animated, scrollView: scrollView)
        }
    }
    
    @discardableResult
    private func scrollToExisting(
        sectionID: Section.Identifier,
        animated: Bool,
        scrollView: UIScrollView
    ) -> Bool {
        if let sectionIndex = sections.firstIndex(where: { $0.id == sectionID }),
           let section = sectionCache[sectionID] {
            let offset = {
                switch scrollAxis {
                case .horizontal: return CGPoint(
                        x: CGFloat(sectionIndex) * calendarSize.width,
                        y: scrollView.contentOffset.y
                    )
                case .vertical: return CGPoint(
                    x: scrollView.contentOffset.x,
                    y: CGFloat(sectionIndex) * calendarSize.height
                )
                }
            }()
            onWillScroll?(section.days)
            scrollView.setContentOffset(offset, animated: animated)
            onDidScroll?(section.days)
            return true
        }
        return false
    }
}

extension DozyCalendarViewModel: UIScrollViewDelegate {
    
    func scrollViewWillEndDragging(
        _ scrollView: UIScrollView,
        withVelocity velocity: CGPoint,
        targetContentOffset: UnsafeMutablePointer<CGPoint>
    ) {
        let targetOffset = {
            switch scrollAxis {
            case .horizontal: return targetContentOffset.pointee.x
            case .vertical: return targetContentOffset.pointee.y
            }
        }()
        let targetSectionIndex = Int(targetOffset / calendarSectionSize)
        let targetSection = sections[targetSectionIndex]
        onWillScroll?(targetSection.days)
        
        if targetSectionIndex >= sections.count - 2 {
            appendSection(direction: .forward)
        } else if targetSectionIndex <= 2 {
            appendSection(direction: .backward)
            
            switch scrollAxis {
            case .horizontal:
                scrollView.contentOffset = CGPoint(
                    x: scrollView.contentOffset.x + calendarSize.width,
                    y: scrollView.contentOffset.y
                )
            case .vertical:
                scrollView.contentOffset = CGPoint(
                    x: scrollView.contentOffset.x,
                    y: scrollView.contentOffset.y + calendarSize.height
                )
            }
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let contentOffset = {
            switch scrollAxis {
            case .horizontal: return scrollView.contentOffset.x
            case .vertical: return scrollView.contentOffset.y
            }
        }()
        
        let sectionIndex = Int(contentOffset / calendarSectionSize)
        let section = sections[sectionIndex]
        onDidScroll?(section.days)
    }
}
