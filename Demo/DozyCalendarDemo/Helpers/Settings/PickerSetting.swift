//
//  PickerSetting.swift
//  Demo
//
//  Created by Carter Foughty on 4/8/24.
//

import SwiftUI

internal struct PickerValue<ValueType: Hashable>: Hashable {
    var value: ValueType
    var description: String
}

internal struct PickerSetting<ValueType: Hashable>: View {
    
    // MARK: - API
    
    init(
        initialValue: ValueType,
        options: [PickerValue<ValueType>],
        title: String? = nil,
        onChange: @escaping (ValueType) -> Void
    ) {
        self._selection = State(initialValue: initialValue)
        self.options = options
        self.title = title
        self.onChange = onChange
    }
    
    // MARK: - Variables
    
    @State private var selection: ValueType
    
    private let options: [PickerValue<ValueType>]
    private let title: String?
    private let onChange: (ValueType) -> Void
    
    // MARK: - Body
    
    var body: some View {
        HStack {
            if let title {
                HStack {
                    Text(title)
                    Spacer(minLength: 0)
                }
                .frame(width: 90)
            }
            Picker("", selection: $selection) {
                ForEach(options, id: \.value) { option in
                    Text(option.description.capitalized)
                }
            }
            .pickerStyle(.segmented)
        }
        .onChange(of: selection) { _, selection in
            onChange(selection)
        }
    }
}
