//
//  Date+Extensions.swift
//  DozyCalendar
//
//  Created by Carter Foughty on 3/16/23.
//

import Foundation

let idFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    return formatter
}()

extension Date {
    
    var id: String {
        idFormatter.string(from: self)
    }
    
    var next: Date {
        return advanced(by: 60 * 60 * 24)
    }
    
    func sectionID(style: SectionStyle, calendar: Calendar) -> Section.Identifier {
        let year = calendar.component(.year, from: self)
        switch style {
        case .week:
            let weekOfYear = calendar.component(.weekOfYear, from: self)
            return .init(style: style, year: year, section: weekOfYear)
        case .month:
            let month = calendar.component(.month, from: self)
            return .init(style: style, year: year, section: month)
        }
    }
}
