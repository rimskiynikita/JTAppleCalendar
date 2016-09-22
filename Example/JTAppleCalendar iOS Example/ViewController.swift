//
//  ViewController.swift
//  JTAppleCalendar iOS Example
//
//  Created by JayT on 2016-08-10.
//
//

import JTAppleCalendar

class ViewController: UIViewController {
    var numberOfRows = 6
    @IBOutlet weak var calendarView: JTAppleCalendarView!
    @IBOutlet weak var monthLabel: UILabel!
    let formatter = DateFormatter()
    var testCalendar: Calendar! = Calendar(identifier: Calendar.Identifier.gregorian)
    
    @IBAction func changeToRow(_ sender: UIButton) {
        numberOfRows = Int(sender.title(for: .normal)!)!
        calendarView.reloadData()
    }
    
    @IBAction func changeDirection(_ sender: UIButton) {
        if sender.title(for: .normal)! == "Horizontal" {
            calendarView.direction = .horizontal
            calendarView.itemSize = nil
        } else {
            calendarView.direction = .vertical
            calendarView.itemSize = 35
        }
        calendarView.reloadData()
    }
    @IBAction func changeToSixRows(_ sender: UIButton) {
        numberOfRows = 2
        calendarView.reloadData()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        formatter.dateFormat = "yyyy MM dd"
        testCalendar.timeZone = TimeZone(abbreviation: "GMT")!
        // Setting up your dataSource and delegate is manditory
        //_____________________________________________________________________________________________
        calendarView.delegate = self
        calendarView.dataSource = self
        //_____________________________________________________________________________________________
        // Registering your cells is manditory
        //_____________________________________________________________________________________________
        calendarView.registerCellViewXib(file: "CellView")
        // You also can register by class
//         calendarView.registerCellViewClass(fileName: "JTAppleCalendar_Example.CodeCellView")
        //_____________________________________________________________________________________________
        // Enable/disable the following code line to show/hide headers.
        calendarView.registerHeaderView(xibFileNames: ["PinkSectionHeaderView", "WhiteSectionHeaderView"]) // headers are Optional. You can register multiple if you want.
        // The following default code can be removed since they are already the default.
        // They are only included here so that you can know what properties can be configured
        //_____________________________________________________________________________________________
//        calendarView.direction = .vertical                                 // default is horizontal
        calendarView.cellInset = CGPoint(x: 0, y: 0)                         // default is (3,3)
//        calendarView.itemSize = 30
        calendarView.allowsMultipleSelection = true                         // default is false
        calendarView.scrollEnabled = true                                    // default is true
        calendarView.scrollingMode = .stopAtEachCalendarFrameWidth
        calendarView.rangeSelectionWillBeUsed = false                        // default is false
    
        //_____________________________________________________________________________________________
        // Reloading the data on viewDidLoad() is only necessary if you made LAYOUT changes eg. number of row per month change
        // or changing the start day of week from sunday etc etc.

        // After reloading. Scroll to your selected date, and setup your calendar
//        calendarView.scrollToDate(Date(), triggerScrollToDateDelegate: false, animateScroll: false) {
//            let currentDate = self.calendarView.currentCalendarDateSegment()
//            self.setupViewsOfCalendar(currentDate.dateRange.start, endDate: currentDate.dateRange.end, month: currentDate.month)
        
//        calendarView.selectDates([formatter.date(from: "2016 02 01")!])
//        }
    }
    @IBAction func select11(_ sender: AnyObject?) {
//        numberOfRows = 1
//        calendarView.reloadData()
//        calendarView.allowsMultipleSelection = false
        let date = formatter.date(from: "2016 02 11")
        self.calendarView.selectDates([date!, Date()], triggerSelectionDelegate: false)
    }
    @IBAction func scrollToDate(_ sender: AnyObject?) {
//        numberOfRows = 6
//        calendarView.reloadData()
        let date = formatter.date(from: "2016 03 11")
        calendarView.scrollToDate(date!)
    }
    @IBAction func printSelectedDates() {
        print("Selected dates --->")
        calendarView.reloadData()
//        for date in calendarView.selectedDates {
//            print(formatter.string(from: date))
//        }
    }
    @IBAction func next(_ sender: UIButton) {
        self.calendarView.scrollToNextSegment() {
            let currentSegmentDates = self.calendarView.currentCalendarDateSegment()
            self.setupViewsOfCalendar(currentSegmentDates.dateRange.start, endDate: currentSegmentDates.dateRange.end, month: currentSegmentDates.month)
        }
    }
    @IBAction func previous(_ sender: UIButton) {
        self.calendarView.scrollToPreviousSegment() {
            let currentSegmentDates = self.calendarView.currentCalendarDateSegment()
            self.setupViewsOfCalendar(currentSegmentDates.dateRange.start, endDate: currentSegmentDates.dateRange.end, month: currentSegmentDates.month)
        }
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    func setupViewsOfCalendar(_ startDate: Date, endDate: Date, month: Int) {
        let monthName = DateFormatter().monthSymbols[(month-1) % 12] // 0 indexed array
        let year = Calendar.current.component(.year, from: startDate)
        monthLabel.text = monthName + " " + String(year)
    }
}

// MARK : JTAppleCalendarDelegate
extension ViewController: JTAppleCalendarViewDataSource, JTAppleCalendarViewDelegate {
    func configureCalendar(_ calendar: JTAppleCalendarView) -> ConfigurationParameters {
        let startDate = formatter.date(from: "2016 02 01")!
        let endDate = formatter.date(from: "2020 03 01")!
        let calendar = Calendar.current
        
//        let parameters =  ConfigurationParameters(startDate: startDate,
//                                endDate: endDate,
//                                numberOfRows: numberOfRows,
//                                calendar: calendar,
//                                generateInDates: true,
//                                generateOutDates: .tillEndOfGrid,
//                                firstDayOfWeek: .monday)
        let parameters = ConfigurationParameters(startDate: startDate,
                                                 endDate: endDate,
                                                 numberOfRows: numberOfRows,
                                                 calendar: calendar,
                                                 generateInDates: true,
                                                 generateOutDates: .tillEndOfRow,
                                                 firstDayOfWeek: .sunday)
        return parameters
        
        
        
//        (startDate: Date, endDate: Date, numberOfRows: Int, calendar: Calendar, generateInDates: Bool, generateOutDates: OutDateCellGeneration) {
        
        
        
//        return (startDate: firstDate!, endDate: secondDate, numberOfRows: numberOfRows, calendar: aCalendar, generateInDates: true, generateOutDates: .tillEndOfGrid)
//        return (startDate: firstDate!, endDate: secondDate, numberOfRows: numberOfRows, calendar: aCalendar, generateInDates: false, generateOutDates: .tillEndOfGrid)
//                return (startDate: firstDate!, endDate: secondDate, numberOfRows: numberOfRows, calendar: aCalendar, generateInDates: false, generateOutDates: .tillEndOfRow)
//                return (startDate: firstDate!, endDate: secondDate, numberOfRows: numberOfRows, calendar: aCalendar, generateInDates: false, generateOutDates: .off)
//        return (startDate: firstDate!, endDate: secondDate, numberOfRows: numberOfRows, calendar: aCalendar, generateInDates: true, generateOutDates: .off)
//        return (startDate: firstDate!, endDate: secondDate, numberOfRows: numberOfRows, calendar: aCalendar, generateInDates: true, generateOutDates: .tillEndOfRow)
    }
    func calendar(_ calendar: JTAppleCalendarView, willDisplayCell cell: JTAppleDayCellView, date: Date, cellState: CellState) {
        (cell as? CellView)?.setupCellBeforeDisplay(cellState, date: date)
    }
    func calendar(_ calendar: JTAppleCalendarView, didDeselectDate date: Date, cell: JTAppleDayCellView?, cellState: CellState) {
        (cell as? CellView)?.cellSelectionChanged(cellState)
    }
    func calendar(_ calendar: JTAppleCalendarView, didSelectDate date: Date, cell: JTAppleDayCellView?, cellState: CellState) {
        (cell as? CellView)?.cellSelectionChanged(cellState)
//        printSelectedDates()
    }
    func calendar(_ calendar: JTAppleCalendarView, willResetCell cell: JTAppleDayCellView) {
        (cell as? CellView)?.selectedView.isHidden = true
    }
    func calendar(_ calendar: JTAppleCalendarView, didScrollToDateSegmentFor dateRange: (start: Date, end: Date), belongingTo month: Int) {
        setupViewsOfCalendar(dateRange.start, endDate: dateRange.end, month: month)
    }
    func calendar(_ calendar: JTAppleCalendarView, sectionHeaderIdentifierFor dateRange: (start: Date, end: Date), belongingTo month: Int) -> String {
        if month % 2 > 0 {
            return "WhiteSectionHeaderView"
        }
        return "PinkSectionHeaderView"
    }
    func calendar(_ calendar: JTAppleCalendarView, sectionHeaderSizeFor dateRange: (start: Date, end: Date), belongingTo month: Int) -> CGSize {
        if month % 2 > 0 {
            return CGSize(width: 200, height: 50)
        } else {
            return CGSize(width: 200, height: 100) // Yes you can have different size headers
        }
    }
    func calendar(_ calendar: JTAppleCalendarView, willDisplaySectionHeader header: JTAppleHeaderView, dateRange: (start: Date, end: Date), identifier: String) {
        switch identifier {
        case "WhiteSectionHeaderView":
            let headerCell = (header as? WhiteSectionHeaderView)
            headerCell?.title.text = "Design multiple headers"
        default:
            let headerCell = (header as? PinkSectionHeaderView)
            headerCell?.title.text = "In any color or size you want"
        }
    }
}
func delayRunOnMainThread(_ delay: Double, closure:@escaping () -> ()) {
    DispatchQueue.main.asyncAfter(
        deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure)
}
