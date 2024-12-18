//
//  DozyCalendarViewModel.swift
//  DozyCalendar
//
//  Created by Carter Foughty on 3/16/23.
//

import SwiftUI

class DozyCalendarViewModel: NSObject, ObservableObject, DozyCalendarChangeProvider, DozyCalendarProxy {
    
    // MARK: - API
    
    @Published var sections: [Section] = []
    @Published var currentSection: Section?
    
    var onWillScroll: (([Day]) -> Void)?
    var onDidScroll: (([Day]) -> Void)?
    
    init(configuration: DozyCalendarConfiguration) {
        self.sectionStyle = configuration.sectionStyle
        self.dateRange = configuration.range
        self.startOfWeek = configuration.startOfWeek
        self.scrollAxis = configuration.scrollAxis
        
        var calendar = Calendar.current
        calendar.firstWeekday = startOfWeek.rawValue
        self.calendar = calendar
        
        super.init()
        // Generate the calendar around the current date
        let sectionID = Date().sectionID(style: sectionStyle, calendar: calendar)
        generateCalendar(baseSectionID: sectionID)
    }
    
    func calendarSizeUpdated(_ size: CGSize) {
        calendarSize = size
    }
    
    /// - Returns: A boolean which is true when the index matches the current weekday
    func isCurrentWeekday(index: Int) -> Bool {
        let weekday = calendar.component(.weekday, from: Date())
        return index == weekday
    }
    
    /// Commands the scroll view to scroll to the given date
    /// - Parameters:
    ///     - date: The date to scroll to
    ///     - animated: Dictates whether the scroll should animate
    func scrollTo(_ date: Date, animated: Bool) {
        let sectionID = date.sectionID(style: sectionStyle, calendar: calendar)
        // If the current array of sections contains the date, scroll directly to it.
        // Otherwise, regenerate the calendar and try again.
        if !scrollToExisting(sectionID: sectionID, animated: animated) {
            generateCalendar(baseSectionID: sectionID)
            scrollToExisting(sectionID: sectionID, animated: animated)
        }
    }
    
    func scrollPhaseChanged(oldPhase: ScrollPhase, newPhase: ScrollPhase, geometry: ScrollGeometry) {
        switch (oldPhase, newPhase) {
        case (.decelerating, .idle):
            let contentOffset = {
                switch scrollAxis {
                case .horizontal: return geometry.contentOffset.x
                case .vertical: return geometry.contentOffset.y
                }
            }()
            
            let sectionIndex = Int(contentOffset / calendarSectionSize)
            let section = sections[sectionIndex]
            onDidScroll?(section.days)
        default: break
        }
    }
    
    func scrollOffsetChanged(offset: CGPoint) {
        let offset = {
            switch scrollAxis {
            case .horizontal: return offset.x
            case .vertical: return offset.y
            }
        }()
        let targetSectionIndex = Int(offset / calendarSectionSize)
        let targetSection = sections[targetSectionIndex]
        if targetSection != lastWillScrollSection {
            lastWillScrollSection = targetSection
            onWillScroll?(targetSection.days)
        }
        
        if targetSectionIndex >= sections.count - 2 {
            appendSection(direction: .forward)
        } else if targetSectionIndex <= 2 {
            appendSection(direction: .backward)
        }
    }
    
    // MARK: - Constants
    
    /// The number of sections to generate to each edge from the center section
    private let sectionDistanceToEdge = 6
    
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
    
    // MARK: - Variables
    
    private let calendar: Calendar
    private let sectionStyle: SectionStyle
    private let dateRange: DateRange
    private let startOfWeek: Weekday
    private let scrollAxis: Axis
    
    /// A cache of each `Section`, keyed by its `Identifier`
    private var sectionCache = [Section.Identifier: Section]()
    /// The current view size of the calendar
    private var calendarSize: CGSize = .zero
    /// The date to scroll into view when the scroll view appears
    private var queuedDateScrollPosition: Date?
    /// The `Section` last reported to any `willScroll` callback
    private var lastWillScrollSection: Section?
    
    /// The view size of a single section in the direction of scroll
    private var calendarSectionSize: CGFloat {
        switch scrollAxis {
        case .horizontal: return calendarSize.width
        case .vertical: return calendarSize.height
        }
    }
    
    // MARK: - Helpers
    
    /// Generates the calendar data using the `dateRange` provided in the `DozyCalendarConfiguration`
    /// - Parameters:
    ///     - baseSectionID: Identifies the section around which the calendar should be generated.
    ///     If using `DateRange.infinite`, the base section ID will represent the center section.
    private func generateCalendar(baseSectionID: Section.Identifier) {
        switch dateRange {
        case .infinite:
            let firstSectionID = baseSectionID.advanced(by: -sectionDistanceToEdge, calendar)
            let lastSectionID = baseSectionID.advanced(by: sectionDistanceToEdge, calendar)
            generateSections(firstSectionID, lastSectionID)
        case let .limited(startDate, endDate):
            let firstSectionID = startDate.sectionID(style: sectionStyle, calendar: calendar)
            let lastSectionID = endDate.sectionID(style: sectionStyle, calendar: calendar)
            generateSections(firstSectionID, lastSectionID)
        }
    }
    
    /// Generates sections ranging from the `startSectionID` to the `endSectionID`
    /// - Parameters:
    ///     - startSectionID: Identifies the starting section in the span to be generated
    ///     - endSectionID: Identifies the ending section in the span to be generated
    private func generateSections(_ startSectionID: Section.Identifier, _ endSectionID: Section.Identifier) {
        guard startSectionID <= endSectionID else {
            fatalError("Starting section must be earlier than ending section. Please check the provided `DozyCalendarConfiguration")
        }
        
        var sections = [Section]()
        var sectionIDIterator = startSectionID
        
        while sectionIDIterator <= endSectionID {
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
    
    /// Generates a section for the provided `sectionID`
    /// - Parameters:
    ///     - sectionID: Identifies the section to be generated
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
            // Create the `month` dates
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
    
    /// Appends a new section to an end of the array of sections
    /// - Parameters:
    ///     - direction: Specifies which edge of the section array to append the new section
    private func appendSection(direction: Direction) {
        guard let endSectionID = sections[keyPath: direction.endSectionIDKeypath] else { assert(false) }
        let nextSectionID = direction.nextSectionID(sectionID: endSectionID, calendar)
        let newSection = section(for: nextSectionID)
        
        switch direction {
        case .backward: sections.insert(newSection, at: 0)
        case .forward: sections.append(newSection)
        }
    }
    
    /// Scrolls to the `Section` identified by the `sectionID`, if it is in the displayed sections array
    /// - Parameters:
    ///     - sectionID: The `Section.Identifier` identifying the section to scroll to
    ///     - animated: Indicates whether the scroll should be animated
    ///     - scrollView: The `UIScrollView` whose scroll offset should be adjusted
    @discardableResult
    private func scrollToExisting(sectionID: Section.Identifier, animated: Bool) -> Bool {
        guard let section = sectionCache[sectionID] else { return false }
        onWillScroll?(section.days)
        withAnimation(animated ? .default : nil) {
            currentSection = section
        }
        onDidScroll?(section.days)
        return true
    }
}
