//
//  DozyCalendarProxy.swift
//  DozyCalendar
//
//  Created by Carter Foughty on 3/16/23.
//

import SwiftUI

public protocol DozyCalendarProxy: AnyObject {
    func scrollTo(_ date: Date, animated: Bool)
}

private struct ProxyProviderEnvironmentKey: EnvironmentKey {
    static let defaultValue: ((DozyCalendarProxy) -> Void)? = nil
}

extension EnvironmentValues {
    var proxyProvider: ((DozyCalendarProxy) -> Void)? {
        get { self[ProxyProviderEnvironmentKey.self] }
        set { self[ProxyProviderEnvironmentKey.self] = newValue }
    }
}

public extension View {
    func dozyCalendarProxy(_ provider: @escaping (DozyCalendarProxy) -> Void) -> some View {
        self.environment(\.proxyProvider, provider)
    }
}
