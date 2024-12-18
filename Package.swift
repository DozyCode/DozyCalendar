// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "DozyCalendar",
    platforms: [
        .iOS("18.0")
    ],
    products: [
        .library(name: "DozyCalendar", targets: ["DozyCalendar"]),
    ],
    dependencies: [],
    targets: [
        .target(name: "DozyCalendar"),
        .testTarget(name: "DozyCalendarTests", dependencies: ["DozyCalendar"]),
    ]
)
