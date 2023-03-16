//
//  DozyCalendarScrollDelegate.swift
//  DozyCalendar
//
//  Created by Carter Foughty on 3/16/23.
//

import SwiftUI

public protocol DozyCalendarChangeProvider: AnyObject {
    var willScroll: (([Day]) -> Void)? { get set }
    var didScroll: (([Day]) -> Void)? { get set }
}

private struct WillScrollEnvironmentKey: EnvironmentKey {
    static let defaultValue: (([Day]) -> Void)? = nil
}

private struct DidScrollEnvironmentKey: EnvironmentKey {
    static let defaultValue: (([Day]) -> Void)? = nil
}

extension EnvironmentValues {
    var willScroll: (([Day]) -> Void)? {
        get { self[WillScrollEnvironmentKey.self] }
        set { self[WillScrollEnvironmentKey.self] = newValue }
    }
    
    var didScroll: (([Day]) -> Void)? {
        get { self[DidScrollEnvironmentKey.self] }
        set { self[DidScrollEnvironmentKey.self] = newValue }
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
