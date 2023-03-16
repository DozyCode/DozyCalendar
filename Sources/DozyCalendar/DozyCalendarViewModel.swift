//
//  DozyCalendarViewModel.swift
//  DozyCalendar
//
//  Created by Carter Foughty on 3/16/23.
//

import UIKit

// TODO: What's Left...
// - Make sure jumping in certain direction looks accurate w/ scrolling
//      - This is still an issue when you jump so far that a complete regeneration is needed
// - Multiple selection
// - No selection

// State:
// - Selected Date
//
// Proxy:
// - Current month/section
//
// Other State:
// - func willScrollTo(_ date: Date)
// - func didScrollTo(_ date: Date)
// - func shouldSelect(_ date: Date) -> Bool
// - func shouldDeselect(_ date: Date) -> Bool
// - func didSelect(_ date: Date)
// - func didDeselect(_ date: Date)
//
// Configuration:
// - DateRange
// - Section style
// - Scroll Axis
// - Cell Spacing

let calendar = Calendar(identifier: .gregorian)

enum CalendarError: String {
    case range = "The desired date lies outside of the provided date range."
    case configuration = "The developer provided a non-viable configuration."
    case metadataGeneration = "The calendar failed to generate the correct dates."
}

class DozyCalendarViewModel: NSObject, ObservableObject, DozyCalendarChangeProvider {
    
    // MARK: - API
    
    @Published var selectedDate: Date
    @Published var sections: [Section] = []
    @Published var calendarSize: CGSize = .zero
    
    var willScroll: (([Day]) -> Void)?
    var didScroll: (([Day]) -> Void)?
    
    init(sectionStyle: SectionStyle, dateRange: DateRange) {
        self.sectionStyle = sectionStyle
        self.dateRange = dateRange
        
        let selectedDate = Date()
        self.selectedDate = selectedDate
        currentSectionID = selectedDate.sectionID(style: sectionStyle, calendar: calendar)
        
        super.init()
        generateCalendar(baseDate: selectedDate)
    }
    
    func install(_ uiScrollView: UIScrollView) {
        self.uiScrollView = uiScrollView
        uiScrollView.isPagingEnabled = true
        uiScrollView.delegate = self
    }
    
    // MARK: - Constants
    
    private let sectionDistanceToEdge = 6
    
    // MARK: - Variables
    
    private var currentSectionID: Section.Identifier
    
    private weak var uiScrollView: UIScrollView?
    private var sectionCache = [Section.Identifier: Section]()
    
    private var sectionStyle: SectionStyle
    private var dateRange: DateRange
    private let calendar = Calendar.current
    
    // MARK: - Helpers
    
    private func generateCalendar(baseDate: Date) {
        switch dateRange {
        case .infinite:
            let currentSectionID = baseDate.sectionID(style: sectionStyle, calendar: calendar)
            let firstSectionID = currentSectionID.advanced(by: -sectionDistanceToEdge)
            let lastSectionID = currentSectionID.advanced(by: sectionDistanceToEdge)
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
                sectionCache[sectionIDIterator] = section
                sections.append(section)
            }
            sectionIDIterator = sectionIDIterator.next
        }
        self.sections = sections
    }
    
    private func section(for sectionID: Section.Identifier) -> Section {
        let firstDate = sectionID.firstDate
        
        var days = [Day]()
        
        switch sectionID.style {
        case .week:
            for day in 1...7 {
                guard let date = calendar.date(byAdding: .day, value: day, to: firstDate) else { assert(false) }
                days.append(.month(date))
            }
        case let .month(dynamicRows):
            guard let range = calendar.range(of: .day, in: .month, for: firstDate) else { assert(false) }
            var lastMonthDate = firstDate
            // Check the weekday of the first date. If it isn't the first day of the week,
            // we need to create the relevant 'pre-month dates'.
            let weekDay = calendar.component(.weekday, from: firstDate)
            if weekDay > 1 {
                for dayDifference in stride(from: weekDay - 1, through: 1, by: -1) {
                    guard let date = calendar.date(byAdding: .day, value: -dayDifference, to: firstDate) else { assert(false) }
                    days.append(.preMonth(date))
                }
            }
            // Create the `month` dates.
            for day in range {
                // Subtract one, because the first of the month is the `firstDate`.
                guard let date = calendar.date(byAdding: .day, value: day - 1, to: firstDate) else { assert(false) }
                days.append(.month(date))
                lastMonthDate = date
            }
            // Check the weekday of the last date. If it isn't the last day of the week,
            // we need to create the relevant 'post-month dates'.
            let remainingDaysRequired = dynamicRows ? 7 - calendar.component(.weekday, from: lastMonthDate) : 42 - days.count
            if remainingDaysRequired > 0 {
                for day in 1...remainingDaysRequired {
                    guard let date = calendar.date(byAdding: .day, value: day, to: lastMonthDate) else { assert(false) }
                    days.append(.postMonth(date))
                }
            }
        }
        
        return Section(id: sectionID, days: days)
    }
    
    private func appendSection(direction: Direction) {
        guard let endSectionID = sections[keyPath: direction.endSectionIDKeypath] else { assert(false) }
        let nextSectionID = endSectionID[keyPath: direction.nextSectionID]
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
        
        var nextSectionID: KeyPath<Section.Identifier, Section.Identifier> {
            switch self {
            case .backward: return \.previous
            case .forward: return \.next
            }
        }
    }
}

extension DozyCalendarViewModel: DozyCalendarProxy {
    
    func scrollTo(_ date: Date, animated: Bool) {
        guard let uiScrollView else { return }
        let sectionID = date.sectionID(style: sectionStyle, calendar: calendar)
        
        // If the current array of sections contains the date, scroll directly to it.
        if let firstSection = sections.first,
           let lastSection = sections.last,
           firstSection.id...lastSection.id ~= sectionID,
           let sectionPosition = sections.firstIndex(where: { $0.id == sectionID }) {
               let adjustedContentOffset = CGPoint(x: CGFloat(sectionPosition) * uiScrollView.frame.width, y: 0)
               uiScrollView.setContentOffset(adjustedContentOffset, animated: animated)
        } else {
            // Otherwise, regenerate the calendar.
            generateCalendar(baseDate: date)
            let adjustedContentOffset = CGPoint(x: CGFloat(sectionDistanceToEdge) * uiScrollView.frame.width, y: 0)
            uiScrollView.setContentOffset(adjustedContentOffset, animated: animated)
        }
    }
}

extension DozyCalendarViewModel: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard case .infinite = dateRange else { return }
        
        let currentPosition = Int(scrollView.contentOffset.x / calendarSize.width).clamped(to: 0...sections.count - 1)
        // If we approach either end, recalculate the months.
        if currentPosition >= sections.count - 2 {
            appendSection(direction: .forward)
        } else if currentPosition <= 2 {
            appendSection(direction: .backward)
            // If we insert a new section at the beginning of the section array, adjust the content
            // offset to make the update look seemless.
            let positionByWidth = CGFloat((scrollView.contentOffset.x) / calendarSize.width)
            scrollView.setContentOffset(CGPoint(x: calendarSize.width * CGFloat(positionByWidth + 1), y: 0), animated: false)
        }
    }
    
    func scrollViewWillEndDragging(
        _ scrollView: UIScrollView,
        withVelocity velocity: CGPoint,
        targetContentOffset: UnsafeMutablePointer<CGPoint>
    ) {
        guard let willScroll else { return }
        
        let targetPosition = Int(targetContentOffset.pointee.x / calendarSize.width)
        let targetSection = sections[targetPosition]
        willScroll(targetSection.days)
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard let didScroll else { return }
        
        let targetPosition = Int(scrollView.contentOffset.x / calendarSize.width)
        let targetSection = sections[targetPosition]
        didScroll(targetSection.days)
    }
}

public extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        min(max(self, limits.lowerBound), limits.upperBound)
    }
}
