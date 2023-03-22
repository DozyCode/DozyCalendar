//
//  DateRange.swift
//  DozyCalendar
//
//  Created by Carter Foughty on 3/16/23.
//

import Foundation

public enum DateRange: Hashable {
    case infinite
    case limited(startDate: Date, endDate: Date)
}
