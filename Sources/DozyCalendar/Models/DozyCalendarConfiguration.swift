//
//  DozyCalendarConfiguration.swift
//  DozyCalendar
//
//  Created by Carter Foughty on 3/16/23.
//

import SwiftUI

public struct DozyCalendarConfiguration {
    
    public init(
        range: DateRange,
        scrollAxis: Axis,
        rowSpacing: CGFloat,
        columnSpacing: CGFloat,
        sectionStyle: SectionStyle,
        startOfWeek: Weekday
    ) {
        self.range = range
        self.scrollAxis = scrollAxis
        self.rowSpacing = rowSpacing
        self.columnSpacing = columnSpacing
        self.sectionStyle = sectionStyle
        self.startOfWeek = startOfWeek
    }
    
    let range: DateRange
    let scrollAxis: Axis
    let rowSpacing: CGFloat
    let columnSpacing: CGFloat
    let sectionStyle: SectionStyle
    let startOfWeek: Weekday
}

public extension DozyCalendarConfiguration {
    
    var weekdays: [Weekday] {
        let weekdays = Weekday.allCases
        let weekdaySequences = weekdays.split(separator: startOfWeek, omittingEmptySubsequences: false)
        
        guard weekdaySequences.count > 1,
              let firstSequence = weekdaySequences.first,
              let secondSequence = weekdaySequences.last else { return weekdays }
        return Array([startOfWeek] + secondSequence + firstSequence)
    }
    
    var weekdayModels: [WeekdayModel] {
        var calendar = Calendar.current
        calendar.firstWeekday = startOfWeek.rawValue
        let weekdays = weekdays
        return weekdays.map {
            WeekdayModel(
                weekday: $0,
                normalText: calendar.weekdaySymbols[$0.rawValue - 1],
                shortText: calendar.shortWeekdaySymbols[$0.rawValue - 1],
                veryShortText: calendar.veryShortWeekdaySymbols[$0.rawValue - 1]
            )
        }
    }
}
