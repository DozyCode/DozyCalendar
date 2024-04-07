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
    
    @Published var visibleSectionID: Section.Identifier?
    @Published var sections: [Section] = []
    
    var onWillScroll: (([Day]) -> Void)?
    var onDidScroll: (([Day]) -> Void)?
    
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
        self.visibleSectionID = baseDate.sectionID(style: sectionStyle, calendar: calendar)
        
        super.init()
        generateCalendar(baseDate: baseDate)
        
    }
    
    func calendarSizeUpdated(_ size: CGSize) {
        calendarSize = size
    }
    
    func visibleSectionChanged() {
        guard let visibleSectionID,
              let section = sectionCache[visibleSectionID] else { return }
        onDidScroll?(section.days)
        
        guard let currentPosition = sections.firstIndex(where: { $0.id == visibleSectionID }) else { return }
        // If we approach either end, recalculate the months.
        if currentPosition >= sections.count - 2 {
            appendSection(direction: .forward)
        } else if currentPosition <= 2 {
            appendSection(direction: .backward)
        }
    }
    
    // MARK: - Constants
    
    private let sectionDistanceToEdge = 6
    
    // MARK: - Variables
    
    private let calendar: Calendar
    private let sectionStyle: SectionStyle
    private let dateRange: DateRange
    private let startOfWeek: Weekday
    private let scrollAxis: Axis
    
    private var sectionCache = [Section.Identifier: Section]()
    private var dateUponAppear: Date?
    private var calendarSize: CGSize = .zero
    
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
        
        scrollTo(baseDate, animated: false)
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
                sectionCache[sectionIDIterator] = section
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
        
        return Section(id: sectionID, days: days)
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
        let sectionID = date.sectionID(style: sectionStyle, calendar: calendar)
        // If the current array of sections contains the date, scroll directly to it.
        if let firstSection = sections.first,
           let lastSection = sections.last,
           firstSection.id...lastSection.id ~= sectionID {
            self.visibleSectionID = sectionID
        } else {
            // Otherwise, regenerate the calendar.
            generateCalendar(baseDate: date)
            self.visibleSectionID = sectionID
        }
    }
}
