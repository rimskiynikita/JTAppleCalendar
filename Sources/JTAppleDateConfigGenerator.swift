//
//  JTAppleDateConfigGenerator.swift
//  JTAppleCalendar
//
//  Created by JayT on 2016-08-22.
//
//
public enum OutDateCellGeneration {
    case tillEndOfRow, tillEndOfGrid, off
}

struct DateConfigParameters {
    var inCellGeneration = true
    var outCellGeneration: OutDateCellGeneration = .tillEndOfGrid
    var numberOfRows = 6
    var startOfMonthCache: NSDate?
    var endOfMonthCache: NSDate?
    var configuredCalendar: NSCalendar?
    var firstDayOfWeek: DaysOfWeek = .Sunday
    
}

struct JTAppleDateConfigGenerator {
    
    var parameters: DateConfigParameters?
    weak var delegate: JTAppleCalendarDelegateProtocol!
    
    
    mutating func setupMonthInfoDataForStartAndEndDate(parameters: DateConfigParameters?)-> (months:[month], monthMap: [Int:Int]) {
        self.parameters = parameters
        
        guard
            var validParameters = parameters,
            let  startMonth = validParameters.startOfMonthCache,
            endMonth = validParameters.endOfMonthCache,
            calendar = validParameters.configuredCalendar else {

                return ([],[:])

        }
        
        // Only allow a row count of 1, 2, 3, or 6
        switch validParameters.numberOfRows {
        case 1, 2, 3:
            break
        default:
            validParameters.numberOfRows = 6
        }
        
        let differenceComponents = calendar.components(NSCalendarUnit.Month, fromDate: startMonth, toDate: endMonth, options: [] )
        let numberOfMonths = differenceComponents.month + 1 // if we are for example on the same month and the difference is 0 we still need 1 to display it
        
        var monthArray: [month] = []
        
        var monthIndexMap: [Int:Int] = [:]
        var section = 0
        var startIndexForMonth = 0
        let numberOfRowsPerSectionThatUserWants = validParameters.numberOfRows
        
        // Number of sections in each month
//        let numberOfSectionsPerMonth = Int(ceil(Float(MAX_NUMBER_OF_ROWS_PER_MONTH)  / Float(validParameters.numberOfRows)))
        
        // Section represents # of months. section is used as an offset to determine which month to calculate
        for monthIndex in 0 ..< numberOfMonths {
            if let currentMonth = calendar.dateByAddingUnit(.Month, value: monthIndex, toDate: startMonth, options: []) {

                var numberOfDaysInMonth = calendar.rangeOfUnit(NSCalendarUnit.Day, inUnit: NSCalendarUnit.Month, forDate: currentMonth).length

                var numberOfRowsToGenerateForCurrentMonth = 0
                var fdIndex: Int = 0
                
                if delegate.rowsAreStatic() {
                    fdIndex = delegate.firstDayIndexForMonth(currentMonth)
                    numberOfRowsToGenerateForCurrentMonth = MAX_NUMBER_OF_ROWS_PER_MONTH
                } else {
                    let actualNumberOfRowsForThisMonth = Int(ceil(Float(numberOfDaysInMonth) / Float(MAX_NUMBER_OF_DAYS_IN_WEEK)))
                    numberOfRowsToGenerateForCurrentMonth = actualNumberOfRowsForThisMonth
                    
                }
                
                var numberOfPreDatesForThisMonth = 0
                if delegate.preDatesAreGenerated() {
                    numberOfPreDatesForThisMonth = delegate.numberOfPreDatesForMonth(currentMonth)
                    numberOfDaysInMonth += numberOfPreDatesForThisMonth
                }
                
                var numberOfPostDatesForThisMonth = 0
                let postGeneration = delegate.postDatesAreGenerated()
                switch postGeneration {
                case .tillEndOfGrid:
                    numberOfPostDatesForThisMonth = MAX_NUMBER_OF_DAYS_IN_WEEK * numberOfRowsToGenerateForCurrentMonth - (numberOfDaysInMonth + numberOfPreDatesForThisMonth)
                    numberOfDaysInMonth += numberOfPostDatesForThisMonth
                case .tillEndOfRow:
                    
                    break
                default:
                    break
                }
                
                
                let numberOfDaysInMonthFixed = numberOfDaysInMonth
                var sectionsForTheMonth: [Int] = []
                for _ in 0..<6 { // Max number of sections in the month
                    if numberOfDaysInMonth < 1 { break }
                    
                    monthIndexMap[section] = monthIndex
                    
                    
                    var numberOfDaysInCurrentSection = numberOfRowsPerSectionThatUserWants * MAX_NUMBER_OF_DAYS_IN_WEEK
                    if numberOfDaysInCurrentSection > numberOfDaysInMonth {
                        numberOfDaysInCurrentSection = numberOfDaysInMonth
//                        assert(false)
                    }
                    
                    sectionsForTheMonth.append(numberOfDaysInCurrentSection)
                    
                    numberOfDaysInMonth -= numberOfDaysInCurrentSection
                    section += 1
                }
                
                monthArray.append(month(startIndex: startIndexForMonth, sections: sectionsForTheMonth, preDates: numberOfPreDatesForThisMonth, postDates: numberOfPostDatesForThisMonth))
                startIndexForMonth += numberOfDaysInMonthFixed
            }
        }
        
//        print(monthIndexMap)
//        print(monthArray)
        
        return (monthArray, monthIndexMap)
    }
}

                
                
//                
//                // We have number of days in month, now lets see how these days will be allotted into the number of sections in the month
//                // We will add the first segment manually to handle the fdIndex inset
//                let aFullSection = (validParameters.numberOfRows * MAX_NUMBER_OF_DAYS_IN_WEEK)
//                var numberOfDaysInFirstSection = aFullSection - fdIndex
//                
//                // If the number of days in first section is greater that the days of the month, then use days of month instead
//                if numberOfDaysInFirstSection > numberOfDaysInMonth {
//                    numberOfDaysInFirstSection = numberOfDaysInMonth
//                }
//                
//                
//                
//                let numberOfRowsForThisMonth = Int(ceil(Float(numberOfDaysInMonth) / Float(MAX_NUMBER_OF_DAYS_IN_WEEK)))
//                let numberOfSectionsForThisMonth = Int(ceil(Float(numberOfRowsForThisMonth) / Float(validParameters.numberOfRows)))
//                let numberOfSectionsForThisMonthLeft = numberOfSectionsForThisMonth - 1
//                
//                //                let firstSectionDetail: [Int] = [firstWeekdayOfMonthIndex, numberOfDaysInFirstSection, 0]//, numberOfDaysInMonth] //fdIndex, numberofDaysInMonth, offset
//                var sectionArray: [section] = []
//                let aSection = section(fdIndex: fdIndex, numberOfDays: numberOfDaysInFirstSection, offset: 0)
//                //
//                sectionArray.append(aSection)
//                //                monthArray.append(aSection)
//                
//                
//                
//                
//                // Continue adding other segment details in loop
//                if numberOfSectionsForThisMonthLeft < 1 {continue} // Continue if there are no more sections
//                
//                var numberOfDaysLeft = numberOfDaysInMonth - numberOfDaysInFirstSection
//                for _ in 0 ..< numberOfSectionsForThisMonthLeft {
//                    switch numberOfDaysLeft {
//                    case _ where numberOfDaysLeft <= aFullSection: // Partial rows
//                        let midSectionDetail = section(fdIndex: 0, numberOfDays: numberOfDaysLeft, offset: fdIndex)
//                        sectionArray.append(midSectionDetail)
//                        //                        let midSectionDetail: [Int] = [0, numberOfDaysLeft, firstWeekdayOfMonthIndex]
//                        //                        sectionArray.append(midSectionDetail)
//                        numberOfDaysLeft = 0
//                    case _ where numberOfDaysLeft > aFullSection: // Full Rows
//                        let lastPopulatedSectionDetail = section(fdIndex: 0, numberOfDays: aFullSection, offset: fdIndex)
//                        sectionArray.append(lastPopulatedSectionDetail)
//                        //                        let lastPopulatedSectionDetail: [Int] = [0, aFullSection, firstWeekdayOfMonthIndex]
//                        //                        retval.append(lastPopulatedSectionDetail)
//                        numberOfDaysLeft -= aFullSection
//                    default:
//                        break
//                    }
//                }
//                
//                // Section array is complete. Construct month
//                monthArray.append(month(sections: sectionArray))
//            }
//        }
//        print(monthArray)
//        return monthArray
//    }
    
    
//    func noIndatesNoOutDates(calendar: NSCalendar, startMonth: NSDate, endMonth: NSDate, numberOfRows: Int, firstDayOfWeek: DaysOfWeek) -> [month] {
//        let differenceComponents = calendar.components(NSCalendarUnit.Month, fromDate: startMonth, toDate: endMonth, options: [] )
//        let numberOfMonths = differenceComponents.month + 1 // if we are for example on the same month and the difference is 0 we still need 1 to display it
//        
//        var monthArray: [month] = []
//        
//
//        // Number of sections in each month
//        let numberOfSectionsPerMonth = Int(ceil(Float(MAX_NUMBER_OF_ROWS_PER_MONTH)  / Float(numberOfRows)))
//        
//        // Section represents # of months. section is used as an offset to determine which month to calculate
//        for numberOfMonthsIndex in 0 ..< numberOfMonths {
//            if let currentMonth = calendar.dateByAddingUnit(.Month, value: numberOfMonthsIndex, toDate: startMonth, options: []) {
//                
//                var numberOfRowsToGenerateForCurrentMonth = 0
//                var fdIndex: Int = 0
//                
//                
//                var numberOfDaysInMonth = calendar.rangeOfUnit(NSCalendarUnit.Day, inUnit: NSCalendarUnit.Month, forDate: currentMonth).length
//                
//                
//                
//                
//                
//                if delegate.rowsAreStatic() {
//                    fdIndex = delegate.firstDayIndexForMonth(currentMonth)
//                    numberOfRowsToGenerateForCurrentMonth = MAX_NUMBER_OF_ROWS_PER_MONTH
//                } else {
//                    let actualNumberOfRowsForThisMonth = Int(ceil(Float(numberOfDaysInMonth) / Float(MAX_NUMBER_OF_DAYS_IN_WEEK)))
//                    numberOfRowsToGenerateForCurrentMonth = actualNumberOfRowsForThisMonth
//                    
//                }
//                
//                
//                // We have number of days in month, now lets see how these days will be allotted into the number of sections in the month
//                // We will add the first segment manually to handle the fdIndex inset
//                let aFullSection = (numberOfRows * MAX_NUMBER_OF_DAYS_IN_WEEK)
//                var numberOfDaysInFirstSection = aFullSection - fdIndex
//                
//                // If the number of days in first section is greater that the days of the month, then use days of month instead
//                if numberOfDaysInFirstSection > numberOfDaysInMonth {
//                    numberOfDaysInFirstSection = numberOfDaysInMonth
//                }
////                let FIRST_DAY_INDEX = 0
////                let NUMBER_OF_DAYS_INDEX = 1
////                let OFFSET_CALC = 2
//                
//                
//                let numberOfRowsForThisMonth = Int(ceil(Float(numberOfDaysInMonth) / Float(MAX_NUMBER_OF_DAYS_IN_WEEK)))
//                let numberOfSectionsForThisMonth = Int(ceil(Float(numberOfRowsForThisMonth) / Float(numberOfRows)))
//                let numberOfSectionsForThisMonthLeft = numberOfSectionsForThisMonth - 1
//                
////                let firstSectionDetail: [Int] = [firstWeekdayOfMonthIndex, numberOfDaysInFirstSection, 0]//, numberOfDaysInMonth] //fdIndex, numberofDaysInMonth, offset
//                var sectionArray: [section] = []
//                let aSection = section(fdIndex: fdIndex, numberOfDays: numberOfDaysInFirstSection, offset: 0)
////                
//                sectionArray.append(aSection)
////                monthArray.append(aSection)
//
//                
//                
//                
//                // Continue adding other segment details in loop
//                if numberOfSectionsForThisMonthLeft < 1 {continue} // Continue if there are no more sections
//                
//                var numberOfDaysLeft = numberOfDaysInMonth - numberOfDaysInFirstSection
//                for _ in 0 ..< numberOfSectionsForThisMonthLeft {
//                    switch numberOfDaysLeft {
//                    case _ where numberOfDaysLeft <= aFullSection: // Partial rows
//                        let midSectionDetail = section(fdIndex: 0, numberOfDays: numberOfDaysLeft, offset: fdIndex)
//                        sectionArray.append(midSectionDetail)
////                        let midSectionDetail: [Int] = [0, numberOfDaysLeft, firstWeekdayOfMonthIndex]
////                        sectionArray.append(midSectionDetail)
//                        numberOfDaysLeft = 0
//                    case _ where numberOfDaysLeft > aFullSection: // Full Rows
//                        let lastPopulatedSectionDetail = section(fdIndex: 0, numberOfDays: aFullSection, offset: fdIndex)
//                        sectionArray.append(lastPopulatedSectionDetail)
////                        let lastPopulatedSectionDetail: [Int] = [0, aFullSection, firstWeekdayOfMonthIndex]
////                        retval.append(lastPopulatedSectionDetail)
//                        numberOfDaysLeft -= aFullSection
//                    default:
//                        break
//                    }
//                }
//                
//                // Section array is complete. Construct month
//                monthArray.append(month(sections: sectionArray))
//            }
//        }
//        print(monthArray)
//        return monthArray
//    }

//    func generateFormatWithSevenBySix(calendar: NSCalendar, startMonth: NSDate, endMonth: NSDate, numberOfRows: Int, firstDayOfWeek: DaysOfWeek, numberOfMonths: Int) -> [[Int]] {
//        var retval: [[Int]] = []
//        
//        // Number of sections in each month
//        let numberOfSectionsPerMonth = Int(ceil(Float(MAX_NUMBER_OF_ROWS_PER_MONTH)  / Float(numberOfRows)))
//        var firstDayCalValue = 0
//        
//        switch firstDayOfWeek {
//        case .Monday: firstDayCalValue = 6 case .Tuesday: firstDayCalValue = 5 case .Wednesday: firstDayCalValue = 4
//        case .Thursday: firstDayCalValue = 10 case .Friday: firstDayCalValue = 9
//        case .Saturday: firstDayCalValue = 8 default: firstDayCalValue = 7
//        }
//        
//        // Section represents # of months. section is used as an offset to determine which month to calculate
//        for numberOfMonthsIndex in 0 ... numberOfMonths - 1 {
//            if let correctMonthForSectionDate = calendar.dateByAddingUnit(.Month, value: numberOfMonthsIndex, toDate: startMonth, options: []) {
//                
//                let numberOfDaysInMonth = calendar.rangeOfUnit(NSCalendarUnit.Day, inUnit: NSCalendarUnit.Month, forDate: correctMonthForSectionDate).length
//                
//                var firstWeekdayOfMonthIndex = calendar.component(.Weekday, fromDate: correctMonthForSectionDate)
//                firstWeekdayOfMonthIndex -= 1 // firstWeekdayOfMonthIndex should be 0-Indexed
//
//                firstWeekdayOfMonthIndex = (firstWeekdayOfMonthIndex + firstDayCalValue) % 7 // push it modularly so that we take it back one day so that the first day is Monday instead of Sunday which is the default
//                
//                
//                // We have number of days in month, now lets see how these days will be allotted into the number of sections in the month
//                // We will add the first segment manually to handle the fdIndex inset
//                let aFullSection = (numberOfRows * MAX_NUMBER_OF_DAYS_IN_WEEK)
//                var numberOfDaysInFirstSection = aFullSection - firstWeekdayOfMonthIndex
//                
//                // If the number of days in first section is greater that the days of the month, then use days of month instead
//                if numberOfDaysInFirstSection > numberOfDaysInMonth {
//                    numberOfDaysInFirstSection = numberOfDaysInMonth
//                }
//                
//                let firstSectionDetail: [Int] = [firstWeekdayOfMonthIndex, numberOfDaysInFirstSection, 0]//, numberOfDaysInMonth] //fdIndex, numberofDaysInMonth, offset
//                retval.append(firstSectionDetail)
//                let numberOfSectionsLeft = numberOfSectionsPerMonth - 1
//                
//                // Continue adding other segment details in loop
//                if numberOfSectionsLeft < 1 {continue} // Continue if there are no more sections
//                
//                var numberOfDaysLeft = numberOfDaysInMonth - numberOfDaysInFirstSection
//                for _ in 0 ... numberOfSectionsLeft - 1 {
//                    switch numberOfDaysLeft {
//                    case _ where numberOfDaysLeft <= aFullSection: // Partial rows
//                        let midSectionDetail: [Int] = [0, numberOfDaysLeft, firstWeekdayOfMonthIndex]
//                        retval.append(midSectionDetail)
//                        numberOfDaysLeft = 0
//                    case _ where numberOfDaysLeft > aFullSection: // Full Rows
//                        let lastPopulatedSectionDetail: [Int] = [0, aFullSection, firstWeekdayOfMonthIndex]
//                        retval.append(lastPopulatedSectionDetail)
//                        numberOfDaysLeft -= aFullSection
//                    default:
//                        break
//                    }
//                }
//            }
//        }
//        print(retval)
//        return retval
//    }
    

