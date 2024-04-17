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
        // in a SwiftUI `background` view. In some cases, like when using the `clipped` modifier,
        // the view is placed one more view up the hierarchy, so we move three steps up the hierarchy.
        guard let parentView = superview?.superview?.superview ?? superview?.superview ?? superview else { return }

        // The `ScrollView` position in the view hierarchy is inconsistent, so we recursively
        // iterate through the view hierarchy beneath the parent until we find it.
        guard let scrollView = findScrollView(fromView: parentView) else {
            assertionFailure("ScrollViewTracingView.findScrollView did not capture the UIScrollView.")
            return
        }
        
        coordinator?.installScrollView(scrollView)
    }
    
    private func findScrollView(fromView view: UIView) -> UIScrollView? {
        for subview in view.subviews {
            if let scrollView = subview as? UIScrollView {
                return scrollView
            } else {
                if let scrollView = findScrollView(fromView: subview) {
                    return scrollView
                }
            }
        }
        
        return nil
    }
}
