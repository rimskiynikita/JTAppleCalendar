//
//  JTAppleCalendarDelegateProtocol.swift
//  JTAppleCalendar
//
//  Created by JayT on 2016-09-19.
//
//

extension JTAppleCalendarView: JTAppleCalendarDelegateProtocol {
    func cachedDate() -> (start: Date, end: Date, calendar: Calendar) {
        return (start: cachedConfiguration.startDate, end: cachedConfiguration.endDate, calendar: cachedConfiguration.calendar)
    }
    func numberOfRows() -> Int {return cachedConfiguration.numberOfRows}
    func numberOfsections(forMonth section: Int) -> Int { return numberOfSectionsForMonth(section) }
    func numberOfMonthsInCalendar() -> Int { return numberOfMonths }
    func numberOfPreDatesForMonth(_ month: Date) -> Int { return firstDayIndexForMonth(month) }
//    func numberOfPostDatesForMonth(_ month: Date) -> Int { return firstDayIndexForMonth(month) }
    func preDatesAreGenerated() -> Bool { return cachedConfiguration.generateInDates }
    func postDatesAreGenerated() -> OutDateCellGeneration { return cachedConfiguration.generateOutDates }
    func referenceSizeForHeaderInSection(_ section: Int) -> CGSize {
        if registeredHeaderViews.count < 1 { return CGSize.zero }
        return calendarViewHeaderSizeForSection(section)
    }
    func rowsAreStatic() -> Bool {
        return cachedConfiguration.generateInDates == true && cachedConfiguration.generateOutDates == .tillEndOfGrid
    }
}
