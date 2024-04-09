//
//  DozyCalendarDemoViewModel.swift
//  Demo
//
//  Created by Carter Foughty on 4/8/24.
//

import Foundation
import DozyCalendar

internal class DozyCalendarDemoViewModel: ObservableObject {
    
    weak var proxy: DozyCalendarProxy?
    
    func appeared() {
        proxy?.scrollTo(Date(), animated: false)
    }
    
    func scrollTo(_ date: Date) {
        proxy?.scrollTo(date, animated: true)
    }
}
