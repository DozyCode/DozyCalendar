//
//  Day.swift
//  DozyCalendar
//
//  Created by Carter Foughty on 3/16/23.
//

import Foundation

public enum Day: Hashable, Equatable {
    case preMonth(Date)
    case month(Date)
    case postMonth(Date)
    
    public var date: Date {
        switch self {
        case let .preMonth(date): return date
        case let .month(date): return date
        case let .postMonth(date): return date
        }
    }
    
    public var isInMonth: Bool {
        switch self {
        case .month: return true
        default: return false
        }
    }
}
