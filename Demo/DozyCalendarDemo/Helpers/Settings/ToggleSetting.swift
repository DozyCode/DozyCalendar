//
//  ToggleSetting.swift
//  Demo
//
//  Created by Carter Foughty on 4/8/24.
//

import SwiftUI

internal struct ToggleSetting: View {
    
    // MARK: - API
    
    init(
        _ isOn: Binding<Bool>,
        title: String
    ) {
        self.isOn = isOn.wrappedValue
        self.binding = isOn
        self.title = title
        self.onChange = nil
    }
    
    init(
        title: String,
        initialValue: Bool = false,
        onChange: @escaping (Bool) -> Void
    ) {
        self.title = title
        self.isOn = initialValue
        self.onChange = onChange
    }
    
    // MARK: - Variables
    
    @State private var isOn: Bool
    private var binding: Binding<Bool>?
    
    private let title: String
    private let onChange: ((Bool) -> Void)?
    
    // MARK: - Body
    
    var body: some View {
        Toggle(isOn: $isOn) {
            Text(title)
        }
        .onChange(of: isOn) { _, selection in
            binding?.wrappedValue = selection
            onChange?(selection)
        }
    }
}
