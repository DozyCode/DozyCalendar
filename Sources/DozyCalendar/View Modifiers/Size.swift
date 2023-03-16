//
//  Size.swift
//  DozyCalendar
//
//  Created by Carter Foughty on 3/16/23.
//

import SwiftUI

extension View {
    func size(onChange: @escaping (CGSize) -> Void) -> some View {
        modifier(Size(onChange: onChange))
    }
}

struct Size: ViewModifier {
    
    init(onChange: @escaping (CGSize) -> Void) {
        self.onChange = onChange
    }
    
    private let onChange: (CGSize) -> Void
    
    func body(content: Content) -> some View {
        content
            .background {
                GeometryReader { geometryProxy in
                    Color.clear
                        .preference(key: SizePreference.self, value: geometryProxy.size)
                }
            }
            .onPreferenceChange(SizePreference.self, perform: onChange)
    }
}
