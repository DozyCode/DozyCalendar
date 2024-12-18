//
//  DozyCalendarScrollDelegate.swift
//  DozyCalendar
//
//  Created by Carter Foughty on 3/16/23.
//

import SwiftUI

public protocol DozyCalendarChangeProvider: AnyObject {
    var onWillScroll: (([Day]) -> Void)? { get set }
    var onDidScroll: (([Day]) -> Void)? { get set }
}

private struct ScrollEnvironmentKey: EnvironmentKey {
    static let defaultValue: (([Day]) -> Void)? = nil
}

extension EnvironmentValues {
    var willScroll: (([Day]) -> Void)? {
        get { self[ScrollEnvironmentKey.self] }
        set { self[ScrollEnvironmentKey.self] = newValue }
    }
    
    var didScroll: (([Day]) -> Void)? {
        get { self[ScrollEnvironmentKey.self] }
        set { self[ScrollEnvironmentKey.self] = newValue }
    }
}

public extension View {
    func willScrollToSectionWithDays(_ onWillScroll: @escaping ([Day]) -> Void) -> some View {
        self.environment(\.willScroll, onWillScroll)
    }
    
    func didScrollToSectionWithDays(_ onDidScroll: @escaping ([Day]) -> Void) -> some View {
        self.environment(\.didScroll, onDidScroll)
    }
}
