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
    var startOfMonthCache: Date?
    var endOfMonthCache: Date?
    var configuredCalendar: Calendar?
    var firstDayOfWeek: DaysOfWeek = .sunday
    
}

struct JTAppleDateConfigGenerator {
    
    var parameters: DateConfigParameters?
    weak var delegate: JTAppleCalendarDelegateProtocol!
    
    
    mutating func setupMonthInfoDataForStartAndEndDate(_ parameters: DateConfigParameters?)-> (months:[month], monthMap: [Int:Int], totalSections: Int, totalDays: Int) {
        self.parameters = parameters
        
        guard
            var validParameters = parameters,
            let  startMonth = validParameters.startOfMonthCache,
            let endMonth = validParameters.endOfMonthCache,
            let calendar = validParameters.configuredCalendar else {

                return ([],[:], 0, 0)

        }
        
        // Only allow a row count of 1, 2, 3, or 6
        switch validParameters.numberOfRows {
        case 1, 2, 3:
            break
        default:
            validParameters.numberOfRows = 6
        }
        
        let differenceComponents = calendar.dateComponents([.month], from: startMonth, to: endMonth)
        let numberOfMonths = differenceComponents.month! + 1 // if we are for example on the same month and the difference is 0 we still need 1 to display it
        
        var monthArray: [month] = []
        
        var monthIndexMap: [Int:Int] = [:]
        var section = 0
        var startIndexForMonth = 0
        var startCellIndexForMonth = 0
        var totalDays = 0
        let numberOfRowsPerSectionThatUserWants = validParameters.numberOfRows
        
        // Number of sections in each month
//        let numberOfSectionsPerMonth = Int(ceil(Float(MAX_NUMBER_OF_ROWS_PER_MONTH)  / Float(validParameters.numberOfRows)))
        
        // Section represents # of months. section is used as an offset to determine which month to calculate
        for monthIndex in 0 ..< numberOfMonths {
            if let currentMonth = calendar.date(byAdding: .month, value: monthIndex, to: startMonth) {
                var numberOfDaysInMonthVariable = calendar.range(of: .day, in: .month, for: currentMonth)!.count
                let numberOfDaysInMonthFixed = numberOfDaysInMonthVariable
                
                var numberOfRowsToGenerateForCurrentMonth = 0
                
                
                
                
                var numberOfPreDatesForThisMonth = 0
                if delegate.preDatesAreGenerated() {
                    numberOfPreDatesForThisMonth = delegate.numberOfPreDatesForMonth(currentMonth)
                    numberOfDaysInMonthVariable += numberOfPreDatesForThisMonth
                }
                
                
                if /*validParameters.inCellGeneration == true &&*/ validParameters.outCellGeneration == .tillEndOfGrid {
                    numberOfRowsToGenerateForCurrentMonth = MAX_NUMBER_OF_ROWS_PER_MONTH
                } else {
                    let actualNumberOfRowsForThisMonth = Int(ceil(Float(numberOfDaysInMonthVariable) / Float(MAX_NUMBER_OF_DAYS_IN_WEEK)))
                    numberOfRowsToGenerateForCurrentMonth = actualNumberOfRowsForThisMonth
                    
                }
                
                var numberOfPostDatesForThisMonth = 0
                let postGeneration = delegate.postDatesAreGenerated()
                switch postGeneration {
                case .tillEndOfGrid, .tillEndOfRow:
                    numberOfPostDatesForThisMonth = MAX_NUMBER_OF_DAYS_IN_WEEK * numberOfRowsToGenerateForCurrentMonth - (numberOfDaysInMonthFixed + numberOfPreDatesForThisMonth)
                    numberOfDaysInMonthVariable += numberOfPostDatesForThisMonth
                default:
                    break
                }
                
                
//                let numberOfDaysInMonthFixed = numberOfDaysInMonthVariable
                var sectionsForTheMonth: [Int] = []
                var sectionIndexMaps: [Int:Int] = [:]
                for index in 0..<6 { // Max number of sections in the month
                    if numberOfDaysInMonthVariable < 1 { break }
                    
                    monthIndexMap[section] = monthIndex
                    sectionIndexMaps[section] = index
                    
                    
                    var numberOfDaysInCurrentSection = numberOfRowsPerSectionThatUserWants * MAX_NUMBER_OF_DAYS_IN_WEEK
                    if numberOfDaysInCurrentSection > numberOfDaysInMonthVariable {
                        numberOfDaysInCurrentSection = numberOfDaysInMonthVariable
//                        assert(false)
                    }
                    
                    totalDays += numberOfDaysInCurrentSection
                    
                    sectionsForTheMonth.append(numberOfDaysInCurrentSection)
                    
                    numberOfDaysInMonthVariable -= numberOfDaysInCurrentSection
                    section += 1
                    
                }
                
                monthArray.append(month(startDayIndex: startIndexForMonth, startCellIndex: startCellIndexForMonth, sections: sectionsForTheMonth, preDates: numberOfPreDatesForThisMonth, postDates: numberOfPostDatesForThisMonth, sectionIndexMaps: sectionIndexMaps, rows: numberOfRowsToGenerateForCurrentMonth))
                startIndexForMonth     += numberOfDaysInMonthFixed
                startCellIndexForMonth += numberOfDaysInMonthFixed + numberOfPreDatesForThisMonth + numberOfPostDatesForThisMonth
            }
        }
        
//        print(monthIndexMap)
//        print(monthArray)
        
        return (monthArray, monthIndexMap, section, totalDays)
    }
}
    

