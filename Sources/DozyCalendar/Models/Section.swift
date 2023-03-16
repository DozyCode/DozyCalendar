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
    
    var firstDate: Date {
        var components = DateComponents()
        components.year = year
        components.setValue(section, for: style.sectionComponent)
        return calendar.date(from: components)!
    }
    
    var previous: Section.Identifier {
        advanced(by: -1)
    }
    
    var next: Section.Identifier {
        advanced(by: 1)
    }
    
    func advanced(by numberOfSections: Int) -> Section.Identifier {
        let newSectionDate = calendar.date(
            byAdding: style.sectionComponent,
            value: numberOfSections,
            to: firstDate
        )!
        let year = calendar.component(.year, from: newSectionDate)
        
        switch style {
        case .week:
            let weekOfYear = calendar.component(.weekOfYear, from: newSectionDate)
            return .init(style: style, year: year, section: weekOfYear)
        case .month:
            let month = calendar.component(.month, from: newSectionDate)
            return .init(style: style, year: year, section: month)
        }
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
