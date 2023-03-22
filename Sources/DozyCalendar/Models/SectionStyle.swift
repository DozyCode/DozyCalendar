//
//  SectionStyle.swift
//  DozyCalendar
//
//  Created by Carter Foughty on 3/16/23.
//

import Foundation

public enum SectionStyle: Hashable {
    case week
    case month(dynamicRows: Bool)
    
    var sectionComponent: Calendar.Component {
        switch self {
        case .week: return .weekOfYear
        case .month: return .month
        }
    }
    
    public var description: String {
        switch self {
        case .week: return "Week"
        case .month: return "Month"
        }
    }
}
