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
        cellSpacing: CGFloat?,
        sectionStyle: SectionStyle,
        startOfWeek: Weekday
    ) {
        self.range = range
        self.scrollAxis = scrollAxis
        self.cellSpacing = cellSpacing
        self.sectionStyle = sectionStyle
        self.startOfWeek = startOfWeek
    }
    
    let range: DateRange
    let scrollAxis: Axis
    let cellSpacing: CGFloat?
    let sectionStyle: SectionStyle
    let startOfWeek: Weekday
}
