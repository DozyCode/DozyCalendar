//
//  Section.swift
//  DozyCalendar
//
//  Created by Carter Foughty on 3/16/23.
//

import Foundation

struct Section: Hashable {
    let id: Identifier
    let days: [Day]
    
    struct Identifier: Hashable {
        let style: SectionStyle
        let year: Int
        let section: Int
    }
}

extension Section.Identifier {
    
    func firstDate(_ calendar: Calendar) -> Date {
        var components = DateComponents()
        switch style {
        case .month:
            components.year = year
            components.month = section
        case .week:
            components.yearForWeekOfYear = year
            components.weekOfYear = section
        }
        return calendar.date(from: components)!
    }
    
    func previous(_ calendar: Calendar) -> Section.Identifier {
        advanced(by: -1, calendar)
    }
    
    func next(_ calendar: Calendar) -> Section.Identifier {
        advanced(by: 1, calendar)
    }
    
    func advanced(by numberOfSections: Int, _ calendar: Calendar) -> Section.Identifier {
        let newSectionDate = calendar.date(
            byAdding: style.sectionComponent,
            value: numberOfSections,
            to: firstDate(calendar)
        )!
        let year = calendar.component(style.yearComponent, from: newSectionDate)
        let newSection = calendar.component(style.sectionComponent, from: newSectionDate)
        return Section.Identifier(style: style, year: year, section: newSection)
    }
}

extension Section.Identifier: Comparable, Equatable {
    static func < (lhs: Section.Identifier, rhs: Section.Identifier) -> Bool {
        guard lhs.style == rhs.style else {
            assert(false, "Can't compare `Section.Identifier`s with different styles.")
        }
        
        if lhs.year < rhs.year { return true }
        else { return lhs.year == rhs.year && lhs.section < rhs.section }
    }
}
