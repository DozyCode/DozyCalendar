//
//  SizePreference.swift
//  DozyCalendar
//
//  Created by Carter Foughty on 3/16/23.
//

import SwiftUI

struct SizePreference: PreferenceKey {
    static var defaultValue = CGSize.zero
    static func reduce(value _: inout CGSize, nextValue _: () -> CGSize) {}
}
