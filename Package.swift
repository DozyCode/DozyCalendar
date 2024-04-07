// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "DozyCalendar",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(name: "DozyCalendar", targets: ["DozyCalendar"]),
    ],
    targets: [
        .target(name: "DozyCalendar"),
        .testTarget(name: "DozyCalendarTests", dependencies: ["DozyCalendar"]),
    ]
)
