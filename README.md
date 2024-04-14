# DozyCalendar

![GitHub Release](https://img.shields.io/github/v/release/DozyCode/DozyCalendar?include_prereleases&display_name=release)
![Static Badge](https://img.shields.io/badge/iOS-17.0%2B-blue?color=%23ad5fb1)
![Static Badge](https://img.shields.io/badge/Swift-5.9%2B-blue?color=%23ad5fb1)
![GitHub License](https://img.shields.io/github/license/DozyCode/DozyCalendar)

## Overview

DozyCalendar provides a highly customizable Calendar component in pure SwiftUI. With either a month or week layout, you can easily design the perfect calendaring UX tailored to your requirements!

Customization options include...
- date range OR infinite scrolling
- horizontal or vertical scrolling
- month or week layout
- start of week
- weekday indicators
- day views
- inter and intra section padding

## Requirements

- iOS 17+
- Xcode 15.0+
- Swift 5.9+

## Installation

DozyCalendar is installed through Swift Package Manager. In Xcode, navigate to `File | Add Package Dependency...`, paste the URL of this repository in the search field, and tap 'Add Package'.

In your source file, import DozyCalendar to access the library.


## Usage

Creating a `DozyCalendar` is simple, and can be declared normally in a SwiftUI ViewBuilder. Simply pass in a `DozyCalendarConfiguration`, a selected date binding, and a day and optional weekday header `ViewBuilder`.

```
var body: some View {
    VStack {
        Text("This month...")
        
        DozyCalendar(
            configuration: DozyCalendarConfiguration(
                range: .infinite,
                scrollAxis: .horizontal,
                rowSpacing: 1,
                columnSpacing: 1,
                sectionPadding: 1,
                sectionStyle: .month(dynamicRows: false),
                startOfWeek: .sun
            )
        ) { day, isToday, isSelected in
            switch day {
            case let .month(date):
                Text(date.formatted(.dateTime.day(.defaultDigits)))
                    .foregroundStyle(Color.black)
            case .preMonth, .postMonth:
                Text(day.date.formatted(.dateTime.day(.defaultDigits)))
            }
        } header: { day, isToday, isSelected in
            Text(weekday.shortText.uppercased())
        }
    }
}
```

This library also provides two `ViewModifier`s that allow you to receive callbacks on scrolling of the calendar.

```
var body: some View {
    DozyCalendar(...)
        .willScrollToSectionWithDays { days in
            ...
        }
        .didScrollToSectionWithDays { days in
            ...
        }
}
``` 

Lastly, use the `DozyCalendarProxy` to instruct the calendar to scroll to a preferred date. This proxy can be stored safely as a weak reference.

```
var body: some View {
    DozyCalendar(...)
        .proxy { proxy in
            proxy.scrollTo(Date(), animated: true)
        }
}
```

## Demo

Check out the demo app associated with this package to get a better idea of the customizability of DozyCalendar.

## License

DozyCalendar is distributed under the [MIT license](https://github.com/DozyCode-Development/DozyCalendar#MIT-1-ov-file). See LICENSE for details.
