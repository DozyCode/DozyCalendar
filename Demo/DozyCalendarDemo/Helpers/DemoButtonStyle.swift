//
//  DemoButtonStyle.swift
//  Demo
//
//  Created by Carter Foughty on 4/8/24.
//

import SwiftUI

internal struct DemoButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.blue)
            .frame(height: 34)
            .frame(maxWidth: .infinity)
            .background(Color.gray.opacity(0.15))
            .cornerRadius(8)
    }
}
