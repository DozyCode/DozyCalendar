//
//  File.swift
//  
//
//  Created by Carter Foughty on 3/17/23.
//

import Foundation

public enum Weekday: Int, Hashable, CaseIterable {
    case sun = 1
    case mon = 2
    case tue = 3
    case wed = 4
    case thu = 5
    case fri = 6
    case sat = 7
}

public struct WeekdayModel: Hashable {
    public var weekday: Weekday
    public var normalText: String
    public var shortText: String
    public var veryShortText: String
    
    var index: Int {
        weekday.rawValue
    }
}

public extension Weekday {
    
    var text: String {
        switch self {
        case .sun: return "Sun"
        case .mon: return "Mon"
        case .tue: return "Tue"
        case .wed: return "Wed"
        case .thu: return "Thu"
        case .fri: return "Fri"
        case .sat: return "Sat"
        }
    }
}
