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
    var testCalendar: Calendar! = Calendar(identifier: .gregorian)
    
    @IBAction func changeToThreeRows(sender: UIButton) {
        numberOfRows = 3
        calendarView.reloadData()
    }
    
    @IBAction func changeToSixRows(sender: UIButton) {
        numberOfRows = 6
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
        calendarView.registerCellViewXib(fileName: "CellView")
        // You also can register by class
        // calendarView.registerCellViewClass(fileName: "JTAppleCalendar_Example.CodeCellView")
        //_____________________________________________________________________________________________
        

        
        // Enable/disable the following code line to show/hide headers.
        calendarView.registerHeaderViewXibs(fileNames: ["PinkSectionHeaderView", "WhiteSectionHeaderView"]) // headers are Optional. You can register multiple if you want.
        
        
        // The following default code can be removed since they are already the default.
        // They are only included here so that you can know what properties can be configured
        //_____________________________________________________________________________________________
        calendarView.direction = .horizontal                                 // default is horizontal
        calendarView.cellInset = CGPoint(x: 0, y: 0)                         // default is (3,3)
        calendarView.allowsMultipleSelection = false                         // default is false
        calendarView.firstDayOfWeek = .sunday                                // default is Sunday
        calendarView.scrollEnabled = true                                    // default is true
        calendarView.scrollingMode = .stopAtEachCalendarFrameWidth           // default is .StopAtEachCalendarFrameWidth
        calendarView.itemSize = nil                                          // default is nil. Use a value here to change the size of your cells
        calendarView.rangeSelectionWillBeUsed = false                        // default is false
        //_____________________________________________________________________________________________
        
        // Reloading the data on viewDidLoad() is only necessary if you made LAYOUT changes eg. number of row per month change
        // or changing the start day of week from sunday etc etc.
        calendarView.reloadData()
        
        // After reloading. Scroll to your selected date, and setup your calendar
        calendarView.scrollToDate(Date(), triggerScrollToDateDelegate: false, animateScroll: false) {
            let currentDate = self.calendarView.currentCalendarDateSegment()
            self.setupViewsOfCalendar(startDate: currentDate.dateRange.start, endDate: currentDate.dateRange.end)
        }
    }
    
    @IBAction func select11(sender: AnyObject?) {
        calendarView.allowsMultipleSelection = false
        let date = formatter.date(from: "2016 02 11")
        self.calendarView.selectDates([date!], triggerSelectionDelegate: false)
    }
    
    @IBAction func scrollToDate(sender: AnyObject?) {
        let date = formatter.date(from: "2016 03 11")
        calendarView.scrollToDate(date!)
    }
    
    @IBAction func printSelectedDates() {
        print("Selected dates --->")
        for date in calendarView.selectedDates {
            print(formatter.string(from: date))
        }
    }
    
    @IBAction func next(sender: UIButton) {
        self.calendarView.scrollToNextSegment() {
            let currentSegmentDates = self.calendarView.currentCalendarDateSegment()
            self.setupViewsOfCalendar(startDate: currentSegmentDates.dateRange.start, endDate: currentSegmentDates.dateRange.end)
        }
    }
    
    @IBAction func previous(sender: UIButton) {
        self.calendarView.scrollToPreviousSegment() {
            let currentSegmentDates = self.calendarView.currentCalendarDateSegment()
            self.setupViewsOfCalendar(startDate: currentSegmentDates.dateRange.start, endDate: currentSegmentDates.dateRange.end)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    func setupViewsOfCalendar(startDate: Date, endDate: Date) {
        let month = testCalendar.component(.month, from: startDate)
        let monthName = DateFormatter().monthSymbols[(month-1) % 12] // 0 indexed array
        let year = Calendar.current.component(.year, from: startDate)
        monthLabel.text = monthName + " " + String(year)
    }
}

// MARK : JTAppleCalendarDelegate
extension ViewController: JTAppleCalendarViewDataSource, JTAppleCalendarViewDelegate {
    func configureCalendar(_ calendar: JTAppleCalendarView) -> (startDate: Date, endDate: Date, numberOfRows: Int, calendar: Calendar) {
        
        let firstDate = formatter.date(from: "2016 01 01")
        let secondDate = Date()
        let aCalendar = Calendar.current // Properly configure your calendar to your time zone here
        return (startDate: firstDate!, endDate: secondDate, numberOfRows: numberOfRows, calendar: aCalendar)
    }
    
    func calendar(_ calendar : JTAppleCalendarView, isAboutToDisplayCell cell: JTAppleDayCellView, date:Date, cellState: CellState) {
        (cell as? CellView)?.setupCellBeforeDisplay(cellState, date: date)
    }
    
    func calendar(_ calendar : JTAppleCalendarView, didDeselectDate date : Date, cell: JTAppleDayCellView?, cellState: CellState) {
        (cell as? CellView)?.cellSelectionChanged(cellState)
    }
    
    func calendar(_ calendar : JTAppleCalendarView, didSelectDate date : Date, cell: JTAppleDayCellView?, cellState: CellState) {
        (cell as? CellView)?.cellSelectionChanged(cellState)
        printSelectedDates()
    }
    
    func calendar(_ calendar : JTAppleCalendarView, didScrollToDateSegmentStartingWithdate startDate: Date, endingWithDate endDate: Date) {
        setupViewsOfCalendar(startDate: startDate, endDate: endDate)
    }
    
    func calendar(_ calendar : JTAppleCalendarView, sectionHeaderIdentifierForDate dateRange: (start: Date, end: Date), belongingTo month: Int) -> String {
        if month % 2 > 0 {
            return "WhiteSectionHeaderView"
        }
        return "PinkSectionHeaderView"
    }
    
    func calendar(_ calendar : JTAppleCalendarView, sectionHeaderSizeForDate dateRange:(start: Date, end: Date), belongingTo month: Int) -> CGSize {
        if month % 2 > 0 {
            return CGSize(width: 200, height: 50)
        } else {
            return CGSize(width: 200, height: 100) // Yes you can have different size headers
        }
    }
    
    func calendar(_ calendar : JTAppleCalendarView, isAboutToDisplaySectionHeader header: JTAppleHeaderView, dateRange: (start: Date, end: Date), identifier: String) {
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
