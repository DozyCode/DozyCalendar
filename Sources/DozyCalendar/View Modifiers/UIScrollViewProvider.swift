//
//  UIScrollViewProvider.swift
//  DozyCalendar
//
//  Created by Carter Foughty on 6/11/22.
//

import UIKit
import SwiftUI

/// Gives one access to a `ScrollView`'s underlying `UIScrollView`. This gives the developer
/// access to a number of `UIScrollView` API's which are sorely missing in `SwiftUI.ScrollView`.
///
/// - Parameter onAppear: A callback which provides the caller with the uncovered `UIScrollView`.
public extension ScrollView {
    func uiScrollView(_ onAppear: @escaping (UIScrollView) -> Void) -> some View {
        modifier(UIScrollViewProvider(onAppear: onAppear))
    }
}

private struct UIScrollViewProvider: ViewModifier {
    // MARK: - API

    init(onAppear: @escaping (UIScrollView) -> Void) {
        self.onAppear = onAppear
    }

    // MARK: - Variables

    @StateObject private var coordinator = ScrollViewTracingCoordinator()
    private var onAppear: (UIScrollView) -> Void

    // MARK: - Body

    func body(content: Content) -> some View {
        content
            .background {
                ScrollViewTracingViewRepresentable(coordinator: coordinator)
                    // The frame needs to be non-(0, 0) so that the view is loaded.
                    .frame(width: 1, height: 0)
                    // Call `onAppear` when the coordinator's published value changes.
                    .onReceive(coordinator.$uiScrollView) { uiScrollView in
                        guard let uiScrollView else { return }
                        onAppear(uiScrollView)
                    }
            }
    }
}

/// A coordinator which allows the `UIScrollView` to be passed along UIKit/SwiftUI views easily.
private class ScrollViewTracingCoordinator: ObservableObject {
    // MARK: - API

    @Published private(set) var uiScrollView: UIScrollView?

    func installScrollView(_ uiScrollView: UIScrollView) {
        self.uiScrollView = uiScrollView
    }
}

/// `SwiftUI` View wrapper for the `UIView` used to uncover the `UIScrollView`.
private struct ScrollViewTracingViewRepresentable: UIViewRepresentable {
    // MARK: - API

    init(coordinator: ScrollViewTracingCoordinator) {
        self.coordinator = coordinator
    }

    // MARK: - Variables

    private var coordinator: ScrollViewTracingCoordinator

    // MARK: - UIViewRepresentable

    func makeUIView(context _: UIViewRepresentableContext<ScrollViewTracingViewRepresentable>) -> UIView {
        return ScrollViewTracingView(coordinator: coordinator)
    }

    func updateUIView(_: UIView, context _: UIViewRepresentableContext<ScrollViewTracingViewRepresentable>) {}
}

/// A `UIView` used to find a `UIScrollView` by digging up its view hierarchy.
private class ScrollViewTracingView<ViewType: UIView>: UIView {
    // MARK: - API

    init(coordinator: ScrollViewTracingCoordinator) {
        self.coordinator = coordinator
        super.init(frame: .zero)
    }

    // MARK: - Variables

    private weak var coordinator: ScrollViewTracingCoordinator?

    // MARK: - Lifecycle

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // The UIScrollView should be in the view hierarchy by the
    // time `layoutSubviews` runs.
    override func layoutSubviews() {
        super.layoutSubviews()
        findScrollView()
    }

    // MARK: - Helpers

    private func findScrollView() {
        // Remembering that the `MediatingView` is returned as the relevant `UIView` in
        // `MediatingViewRepresentable`, which itself is placed in the `background` of
        // the view for which we would like the underlying `UIKit` view...
        // The `MediatingViewRepresentable` is wrapped in a SwiftUI `background` view, so
        // we must make one step up the view hierarchy by capturing `MediatingViewRepresentable`'s
        // parent.
        
        // This view is a child of `ScrollViewTracingViewRepresentable` which is wrapped
        // in a SwiftUI `background` view, so we move two steps up the hierarchy.
        guard let wrappingView = superview,
              let parentView = wrappingView.superview else { return }
        let viewID = UUID().uuidString
        wrappingView.accessibilityIdentifier = viewID

        // TODO: Need a more robust way of finding this.
        // The `ScrollView` can consistently be found one place further along in the view stack,
        // so we iterate one position.
        guard let currentViewIndex = parentView.subviews.firstIndex(where: { $0.accessibilityIdentifier == viewID }),
              let desiredViewIndex = parentView.subviews.count >= currentViewIndex + 1 ? currentViewIndex + 1 : nil,
              let scrollView = parentView.subviews[desiredViewIndex].subviews.first as? UIScrollView else {
            assertionFailure("ScrollViewTracingView.findScrollView did not capture the UIScrollView.")
            return
        }
        coordinator?.installScrollView(scrollView)
    }
}
