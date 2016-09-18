//
//  JTAppleCalendarView.swift
//  JTAppleCalendar
//
//  Created by JayT on 2016-03-01.
//  Copyright © 2016 OS-Tech. All rights reserved.
//

let cellReuseIdentifier = "JTDayCell"

let NUMBER_OF_DAYS_IN_WEEK = 7

let MAX_NUMBER_OF_DAYS_IN_WEEK = 7                              // Should not be changed
let MIN_NUMBER_OF_DAYS_IN_WEEK = MAX_NUMBER_OF_DAYS_IN_WEEK     // Should not be changed
let MAX_NUMBER_OF_ROWS_PER_MONTH = 6                            // Should not be changed
let MIN_NUMBER_OF_ROWS_PER_MONTH = 1                            // Should not be changed

let FIRST_DAY_INDEX = 0
let NUMBER_OF_DAYS_INDEX = 1
let OFFSET_CALC = 2





/// Describes which month owns the date
public enum DateOwner: Int {
    /// Describes which month owns the date
    case thisMonth = 0, previousMonthWithinBoundary, previousMonthOutsideBoundary, followingMonthWithinBoundary, followingMonthOutsideBoundary
}


/// Describes which month the cell belongs to
/// - ThisMonth: Cell belongs to the current month
/// - PreviousMonthWithinBoundary: Cell belongs to the previous month. Previous month is included in the date boundary you have set in your delegate
/// - PreviousMonthOutsideBoundary: Cell belongs to the previous month. Previous month is not included in the date boundary you have set in your delegate
/// - FollowingMonthWithinBoundary: Cell belongs to the following month. Following month is included in the date boundary you have set in your delegate
/// - FollowingMonthOutsideBoundary: Cell belongs to the following month. Following month is not included in the date boundary you have set in your delegate
///
/// You can use these cell states to configure how you want your date cells to look. Eg. you can have the colors belonging to the month be in color black, while the colors of previous months be in color gray.
public struct CellState {
    /// returns true if a cell is selected
    public let isSelected: Bool
    /// returns the date as a string
    public let text: String
    /// returns the a description of which month owns the date
    public let dateBelongsTo: DateOwner
    /// returns the date
    public let date: Date
    /// returns the day
    public let day: DaysOfWeek
    /// returns the row in which the date cell appears visually
    public let row: ()->Int
    /// returns the column in which the date cell appears visually
    public let column: ()->Int
    /// returns the section the date cell belongs to
    public let dateSection: ()->(dateRange:(start: Date, end: Date), month: Int)
    /// returns the position of a selection in the event you wish to do range selection
    public let selectedPosition: ()->SelectionRangePosition
    /// returns the cell frame. Useful if you wish to display something at the cell's frame/position
    public var cell: ()->JTAppleDayCell?
}

/// Selection position of a range-selected date cell
public enum SelectionRangePosition: Int {
    /// Selection position
    case left = 1, middle, right, full, none
}

/// Days of the week. By setting you calandar's first day of week, you can change which day is the first for the week. Sunday is by default.
public enum DaysOfWeek: Int {
    /// Days of the week.
    case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday
}

/// An instance of JTAppleCalendarView (or simply, a calendar view) is a means for displaying and interacting with a gridstyle layout of date-cells
open class JTAppleCalendarView: UIView {
    
    lazy var dateGenerator: JTAppleDateConfigGenerator = {
        var configurator = JTAppleDateConfigGenerator()
        configurator.delegate = self
        return configurator
    }()
    
    
    /// Configures the behavior of the scrolling mode of the calendar
    public enum ScrollingMode {
        case stopAtEachCalendarFrameWidth,
        stopAtEachSection,
        stopAtEach(customInterval: CGFloat),
        nonStopToSection(withResistance: CGFloat),
        nonStopToCell(withResistance: CGFloat),
        nonStopTo(customInterval: CGFloat, withResistance: CGFloat),
        none
        
        func  pagingIsEnabled()->Bool {
            switch self {
            case .stopAtEachCalendarFrameWidth: return true
            default: return false
            }
        }
    }
    
    /// Configures the size of your date cells
    open var itemSize: CGFloat?
    
    /// Enables and disables animations when scrolling to and from date-cells
    open var animationsEnabled = true
    /// The scroll direction of the sections in JTAppleCalendar.
    open var direction : UICollectionViewScrollDirection = .horizontal {
        didSet {
            if oldValue == direction { return }
            let layout = generateNewLayout()
            calendarView.collectionViewLayout = layout
        }
    }
    /// Enables/Disables multiple selection on JTAppleCalendar
    open var allowsMultipleSelection: Bool = false {
        didSet {
            self.calendarView.allowsMultipleSelection = allowsMultipleSelection
        }
    }
    /// First day of the week value for JTApleCalendar. You can set this to anyday. After changing this value you must reload your calendar view to show the change.
    open var firstDayOfWeek = DaysOfWeek.sunday {
        didSet {
            if firstDayOfWeek != oldValue { layoutNeedsUpdating = true }
        }
    }
    
    /// Alerts the calendar that range selection will be checked. If you are not using rangeSelection and you enable this, then whenever you click on a datecell, you may notice a very fast refreshing of the date-cells both left and right of the cell you just selected.
    open var rangeSelectionWillBeUsed = false
    
    var lastSavedContentOffset: CGFloat = 0.0
    var triggerScrollToDateDelegate: Bool? = true
    
    
    
    
    // Keeps track of item size for a section. This is an optimization
    var scrollInProgress = false
    fileprivate var layoutNeedsUpdating = false
    
    /// The object that acts as the data source of the calendar view.
    weak open var dataSource : JTAppleCalendarViewDataSource? {
        didSet {
            setupMonthInfoAndMap()
            updateLayoutItemSize(calendarView.collectionViewLayout as! JTAppleCalendarLayout)
            reloadData(checkDelegateDataSource: false)
        }
    }
    
    
    func setupMonthInfoAndMap() {
        theData = setupMonthInfoDataForStartAndEndDate()
//        monthInfo = generatedData.months
//        monthMap = generatedData.monthMap
    }
    
    
    /// The object that acts as the delegate of the calendar view.
    weak open var delegate: JTAppleCalendarViewDelegate?

    var delayedExecutionClosure: [(()->Void)] = []
    
    #if os(iOS)
        var lastOrientation: UIInterfaceOrientation?
    #endif
    
    var currentSectionPage: Int {
        return (calendarView.collectionViewLayout as! JTAppleCalendarLayoutProtocol).sectionFromRectOffset(calendarView.contentOffset)
    }
  
    var startDateCache: Date {
        get { return cachedConfiguration.startDate }
    }
    
    var endDateCache: Date {
        get { return cachedConfiguration.endDate }
    }
    
    var calendar: Calendar {
        get { return cachedConfiguration.calendar }
    }
    
    lazy var cachedConfiguration: (startDate: Date, endDate: Date, numberOfRows: Int, calendar: Calendar, generateInDates: Bool, generateOutDates: OutDateCellGeneration) = {
        [weak self] in
        
        guard let  config = self!.dataSource?.configureCalendar(self!) else {
            assert(false, "DataSource is not set")
            return (startDate: Date(), endDate: Date(), 0, Calendar(identifier: .gregorian), false, .off)
        }
        
        return (startDate: config.startDate, endDate: config.endDate, numberOfRows: config.numberOfRows, calendar: config.calendar, config.generateInDates, config.generateOutDates)
        }()
    
    // Set the start of the month
    lazy var startOfMonthCache: Date = {
        [weak self] in
        if let startDate = Date.startOfMonth(for: self!.startDateCache, using: self!.calendar) { return startDate }
        assert(false, "Error: StartDate was not correctly generated for start of month. current date was used: \(Date())")
        return Date()
        }()
    
    // Set the end of month
    lazy var endOfMonthCache: Date = {
        [weak self] in
        if let endDate = Date.endOfMonth(for: self!.endDateCache, using: self!.calendar) { return endDate }
        assert(false, "Error: Date was not correctly generated for end of month. current date was used: \(Date())")
        return Date()
        }()
    
    
    var theSelectedIndexPaths: [IndexPath] = []
    var theSelectedDates:      [Date]      = []
    
    /// Returns all selected dates
    open var selectedDates: [Date] {
        get {
            // Array may contain duplicate dates in case where out-dates are selected. So clean it up here
            return Array(Set(theSelectedDates)).sorted()
        }
    }
    lazy var theData: calendarData = {
        [weak self] in
        return self!.setupMonthInfoDataForStartAndEndDate()
    }()
    
    
    var monthInfo: [month]  {
        get { return theData.months }
        set { theData.months = monthInfo}
    }
    
    var monthMap: [Int:Int] {
        get { return theData.monthMap }
        set { theData.monthMap = monthMap }
    }

    var numberOfMonths: Int {
        get { return monthInfo.count }
    }
    
    var totalMonthSections: Int {
        get { return theData.totalSections }
    }
    
    var totalDays: Int {
        get { return theData.totalDays }
    }
    
    
    
    func numberOfItemsInSection(_ section: Int)-> Int {return collectionView(calendarView, numberOfItemsInSection: section)}
    
    /// Cell inset padding for the x and y axis of every date-cell on the calendar view.
    open var cellInset: CGPoint = CGPoint(x: 3, y: 3)
    var cellViewSource: JTAppleCalendarViewSource!
    var registeredHeaderViews: [JTAppleCalendarViewSource] = []

    /// Enable or disable swipe scrolling of the calendar with this variable
    open var scrollEnabled: Bool = true {
        didSet { calendarView.isScrollEnabled = scrollEnabled }
    }
    
    // Configure the scrolling behavior
    open var scrollingMode: ScrollingMode = .stopAtEachCalendarFrameWidth {
        didSet {
            switch scrollingMode {
            case .stopAtEachCalendarFrameWidth:
                calendarView.decelerationRate = UIScrollViewDecelerationRateFast
            case .stopAtEach,.stopAtEachSection:
                calendarView.decelerationRate = UIScrollViewDecelerationRateFast
            case .nonStopToSection, .nonStopToCell, .nonStopTo, .none:
                calendarView.decelerationRate = UIScrollViewDecelerationRateNormal
            }
            
            #if os(iOS)
                switch scrollingMode {
                case .stopAtEachCalendarFrameWidth:
                    calendarView.isPagingEnabled = true
                default:
                    calendarView.isPagingEnabled = false
                }
            #endif
        }
    }
    
    lazy var calendarView : UICollectionView = {
        
        let layout = JTAppleCalendarLayout(withDelegate: self)
        layout.scrollDirection = self.direction
        
        let cv = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        cv.dataSource = self
        cv.delegate = self
        cv.decelerationRate = UIScrollViewDecelerationRateFast
        cv.backgroundColor = UIColor.clear
        cv.showsHorizontalScrollIndicator = false
        cv.showsVerticalScrollIndicator = false
        cv.allowsMultipleSelection = false
        #if os(iOS)
            cv.isPagingEnabled = true
        #endif
        
        return cv
    }()
    
    fileprivate func updateLayoutItemSize (_ layout: JTAppleCalendarLayoutProtocol) {
        if dataSource == nil { return } // If the delegate is not set yet, then return
        // Default Item height
        var height: CGFloat = (self.calendarView.bounds.size.height - layout.headerReferenceSize.height) / CGFloat(cachedConfiguration.numberOfRows)
        // Default Item width
        var width: CGFloat = self.calendarView.bounds.size.width / CGFloat(MAX_NUMBER_OF_DAYS_IN_WEEK)

        if let userSetItemSize = self.itemSize {
            if direction == .vertical { height = userSetItemSize }
            if direction == .horizontal { width = userSetItemSize }
        }

        layout.itemSize = CGSize(width: width, height: height)
    }
    
    /// The frame rectangle which defines the view's location and size in its superview coordinate system.
    override open var frame: CGRect {
        didSet {
            calendarView.frame = CGRect(x:0.0, y:/*bufferTop*/0.0, width: self.frame.size.width, height:self.frame.size.height/* - bufferBottom*/)
            #if os(iOS)
                let orientation = UIApplication.shared.statusBarOrientation
                if orientation == .unknown { return }
                if lastOrientation != orientation {
                    calendarView.collectionViewLayout.invalidateLayout()
                    let layout = calendarView.collectionViewLayout as! JTAppleCalendarLayoutProtocol
                    layout.clearCache()   
                    lastOrientation = orientation
                    updateLayoutItemSize(self.calendarView.collectionViewLayout as! JTAppleCalendarLayoutProtocol)
                    if delegate != nil { reloadData() }
                } else {
                    updateLayoutItemSize(self.calendarView.collectionViewLayout as! JTAppleCalendarLayoutProtocol)
                }
            #elseif os(tvOS)
                calendarView.collectionViewLayout.invalidateLayout()
                let layout = calendarView.collectionViewLayout as! JTAppleCalendarLayoutProtocol
                layout.clearCache()
                updateLayoutItemSize(self.calendarView.collectionViewLayout as! JTAppleCalendarLayoutProtocol)
                if delegate != nil { reloadData() }
                updateLayoutItemSize(self.calendarView.collectionViewLayout as! JTAppleCalendarLayoutProtocol)
            #endif
        }
    }
    
    /// Initializes and returns a newly allocated view object with the specified frame rectangle.
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.initialSetup()
    }
    
    
    /// Returns an object initialized from data in a given unarchiver. self, initialized using the data in decoder.
    required public init?(coder aDecoder: NSCoder) { super.init(coder: aDecoder) }
    
    /// Prepares the receiver for service after it has been loaded from an Interface Builder archive, or nib file.
    override open func awakeFromNib() { self.initialSetup() }
    
    /// Lays out subviews.
    override open func layoutSubviews() { self.frame = super.frame }
    
    // MARK: Setup
    func initialSetup() {
        self.clipsToBounds = true
        self.calendarView.register(JTAppleDayCell.self, forCellWithReuseIdentifier: cellReuseIdentifier)
        self.addSubview(self.calendarView)
    }
    
    func restoreSelectionStateForCellAtIndexPath(_ indexPath: IndexPath) {
        if theSelectedIndexPaths.contains(indexPath) {
            calendarView.selectItem(at: indexPath, animated: false, scrollPosition: UICollectionViewScrollPosition())
        }
    }
    
    func numberOfSectionsForMonth(_ index: Int) -> Int {
        if !monthInfo.indices.contains(index) { return 0 }
        return monthInfo[index].sections.count
    }
    
    func validForwardAndBackwordSelectedIndexes(forIndexPath indexPath: IndexPath)->[IndexPath] {
        var retval = [IndexPath]()
        if let validForwardIndex = calendarView.layoutAttributesForItem(at: IndexPath(item: (indexPath as NSIndexPath).item + 1, section: (indexPath as NSIndexPath).section)) ,
            theSelectedIndexPaths.contains(validForwardIndex.indexPath){
            retval.append(validForwardIndex.indexPath)
        }
        
        if let validBackwardIndex = calendarView.collectionViewLayout.layoutAttributesForItem(at: IndexPath(item: (indexPath as NSIndexPath).item - 1, section: (indexPath as NSIndexPath).section)) ,
            theSelectedIndexPaths.contains(validBackwardIndex.indexPath) {
            retval.append(validBackwardIndex.indexPath)
        }
        return retval
    }
    
    func calendarOffsetIsAlreadyAtScrollPosition(forIndexPath indexPath:IndexPath) -> Bool? {
        var retval: Bool?
        
        // If the scroll is set to animate, and the target content offset is already on the screen, then the didFinishScrollingAnimation
        // delegate will not get called. Once animation is on let's force a scroll so the delegate MUST get caalled
        if let attributes = self.calendarView.layoutAttributesForItem(at: indexPath) {
            let layoutOffset: CGFloat
            let calendarOffset: CGFloat
            if direction == .horizontal {
                layoutOffset = attributes.frame.origin.x
                calendarOffset = calendarView.contentOffset.x
            } else {
                layoutOffset = attributes.frame.origin.y
                calendarOffset = calendarView.contentOffset.y
            }
            if  calendarOffset == layoutOffset || (scrollingMode.pagingIsEnabled() && ((indexPath as NSIndexPath).section ==  currentSectionPage)) {
                retval = true
            } else {
                retval = false
            }
        }
        return retval
    }
    
    func calendarOffsetIsAlreadyAtScrollPosition(forOffset offset:CGPoint) -> Bool? {
        var retval: Bool?
        
        // If the scroll is set to animate, and the target content offset is already on the screen, then the didFinishScrollingAnimation
        // delegate will not get called. Once animation is on let's force a scroll so the delegate MUST get caalled
        
        let theOffset = direction == .horizontal ? offset.x : offset.y
        let divValue = direction == .horizontal ? calendarView.frame.width : calendarView.frame.height
        let sectionForOffset = Int(theOffset / divValue)
        let calendarCurrentOffset = direction == .horizontal ? calendarView.contentOffset.x : calendarView.contentOffset.y
        if
            calendarCurrentOffset == theOffset ||
                (scrollingMode.pagingIsEnabled() && (sectionForOffset ==  currentSectionPage)){
            retval = true
        } else {
            retval = false
        }
        return retval
    }
    
    func firstDayIndexForMonth(_ date: Date) -> Int {
        let firstDayCalValue: Int
        
        switch firstDayOfWeek {
        case .monday: firstDayCalValue = 6 case .tuesday: firstDayCalValue = 5 case .wednesday: firstDayCalValue = 4
        case .thursday: firstDayCalValue = 10 case .friday: firstDayCalValue = 9
        case .saturday: firstDayCalValue = 8 default: firstDayCalValue = 7
        }
        
        var firstWeekdayOfMonthIndex = calendar.component(.weekday, from: date)
        firstWeekdayOfMonthIndex -= 1 // firstWeekdayOfMonthIndex should be 0-Indexed
        
        return (firstWeekdayOfMonthIndex + firstDayCalValue) % 7 // push it modularly so that we take it back one day so that the first day is Monday instead of Sunday which is the default
    }
    func scrollToHeaderInSection(_ section:Int, triggerScrollToDateDelegate: Bool = false, withAnimation animation: Bool = true, completionHandler: (()->Void)? = nil)  {
        if registeredHeaderViews.count < 1 { return }
        self.triggerScrollToDateDelegate = triggerScrollToDateDelegate
        let indexPath = IndexPath(item: 0, section: section)
        delayRunOnMainThread(0.0) {
            if let attributes =  self.calendarView.layoutAttributesForSupplementaryElement(ofKind: UICollectionElementKindSectionHeader, at: indexPath) {
                if let validHandler = completionHandler {
                    self.delayedExecutionClosure.append(validHandler)
                }
                
                let topOfHeader = CGPoint(x: attributes.frame.origin.x, y: attributes.frame.origin.y)
                self.scrollInProgress = true
                
                self.calendarView.setContentOffset(topOfHeader, animated:animation)
                if  !animation {
                    self.scrollViewDidEndScrollingAnimation(self.calendarView)
                    self.scrollInProgress = false
                } else {
                    // If the scroll is set to animate, and the target content offset is already on the screen, then the didFinishScrollingAnimation
                    // delegate will not get called. Once animation is on let's force a scroll so the delegate MUST get caalled
                    if let check = self.calendarOffsetIsAlreadyAtScrollPosition(forOffset: topOfHeader) , check == true {
                        self.scrollViewDidEndScrollingAnimation(self.calendarView)
                        self.scrollInProgress = false
                    }
                }
            }
        }
    }
        
    func reloadData(checkDelegateDataSource check: Bool, withAnchorDate anchorDate: Date? = nil, withAnimation animation: Bool = false, completionHandler:(()->Void)? = nil) {
        // Reload the datasource
        if check { reloadDelegateDataSource() }
        var layoutWasUpdated: Bool?
        if layoutNeedsUpdating {
            self.configureChangeOfRows()
            self.layoutNeedsUpdating = false
            layoutWasUpdated = true
        }
        // Reload the data
        self.calendarView.reloadData()
        
        // Restore the selected index paths
        for indexPath in theSelectedIndexPaths { restoreSelectionStateForCellAtIndexPath(indexPath) }
        
        delayRunOnMainThread(0.0) {
            let scrollToDate = {(date: Date) -> Void in
                if self.registeredHeaderViews.count < 1 {
                    self.scrollToDate(date, triggerScrollToDateDelegate: false, animateScroll: animation, completionHandler: completionHandler)
                } else {
                    self.scrollToHeaderForDate(date, triggerScrollToDateDelegate: false, withAnimation: animation, completionHandler: completionHandler)
                }
            }
            if let validAnchorDate = anchorDate { // If we have a valid anchor date, this means we want to scroll
                // This scroll should happen after the reload above
                scrollToDate(validAnchorDate)
            } else {
                if layoutWasUpdated == true {
                    // This is a scroll done after a layout reset and dev didnt set an anchor date. If a scroll is in progress, then cancel this one and
                    // allow it to take precedent
                    if !self.scrollInProgress {
                        scrollToDate(self.startOfMonthCache)
                    } else {
                        if let validCompletionHandler = completionHandler { self.delayedExecutionClosure.append(validCompletionHandler) }
                    }
                } else {
                    if let validCompletionHandler = completionHandler {
                        if self.scrollInProgress {
                            self.delayedExecutionClosure.append(validCompletionHandler)
                        } else {
                            validCompletionHandler()
                        }
                    }
                }
            }
        }
    }
    
    func executeDelayedTasks() {
        let tasksToExecute = delayedExecutionClosure
        for aTaskToExecute in tasksToExecute { aTaskToExecute() }
        delayedExecutionClosure.removeAll()
    }
    
    // Only reload the dates if the datasource information has changed
    fileprivate func reloadDelegateDataSource() {
        if let
            newDateBoundary = dataSource?.configureCalendar(self) {
            // Jt101 do a check in each var to see if user has bad star/end dates
            
            let newStartOfMonth = Date.startOfMonth(for: newDateBoundary.startDate, using: cachedConfiguration.calendar)
            let newEndOfMonth = Date.endOfMonth(for: newDateBoundary.startDate, using: cachedConfiguration.calendar)
            let oldStartOfMonth = Date.startOfMonth(for: cachedConfiguration.startDate, using: cachedConfiguration.calendar)
            let oldEndOfMonth = Date.endOfMonth(for: cachedConfiguration.startDate, using: cachedConfiguration.calendar)
            
            
            if
                newStartOfMonth != oldStartOfMonth ||
                newEndOfMonth != oldEndOfMonth ||
                newDateBoundary.calendar != cachedConfiguration.calendar ||
                newDateBoundary.numberOfRows != cachedConfiguration.numberOfRows ||
                newDateBoundary.generateInDates != cachedConfiguration.generateInDates ||
                newDateBoundary.generateOutDates != cachedConfiguration.generateOutDates {
                    layoutNeedsUpdating = true
            }
        }
    }
    
    func configureChangeOfRows() {
        let layout = calendarView.collectionViewLayout as! JTAppleCalendarLayoutProtocol
        layout.clearCache()
        setupMonthInfoAndMap()
        
        // the selected dates and paths will be retained. Ones that are not available on the new layout will be removed.
        var indexPathsToReselect = [IndexPath]()
        var newDates = [Date]()
        for date in selectedDates {
            // add the index paths of the new layout
            let path = pathsFromDates([date])
            indexPathsToReselect.append(contentsOf: path)
            
            if
                path.count > 0,
                let possibleCounterPartDateIndex = indexPathOfdateCellCounterPart(date, indexPath: path[0], dateOwner: DateOwner.thisMonth) {
                indexPathsToReselect.append(possibleCounterPartDateIndex)
            }
        }
        
        for path in indexPathsToReselect {
            if let date = dateInfoFromPath(path)?.date { newDates.append(date) }
        }
        
        theSelectedDates = newDates
        theSelectedIndexPaths = indexPathsToReselect
    }
    
    func calendarViewHeaderSizeForSection(_ section: Int) -> CGSize {
        var retval = CGSize.zero
        if registeredHeaderViews.count > 0 {
            if let
                validDate = dateFromSection(section),
                let size = delegate?.calendar(self, sectionHeaderSizeForDate:validDate.dateRange, belongingTo: validDate.month){retval = size }
        }
        return retval
    }
    
    func indexPathOfdateCellCounterPart(_ date: Date, indexPath: IndexPath, dateOwner: DateOwner) -> IndexPath? {
        if cachedConfiguration.generateInDates == false && cachedConfiguration.generateOutDates == .off { return nil }
        var retval: IndexPath?
        if dateOwner != .thisMonth { // If the cell is anything but this month, then the cell belongs to either a previous of following month
            // Get the indexPath of the counterpartCell
            let counterPathIndex = pathsFromDates([date])
            if counterPathIndex.count > 0 {
                retval = counterPathIndex[0]
            }
        } else { // If the date does belong to this month, then lets find out if it has a counterpart date
            if date < startOfMonthCache || date > endOfMonthCache { return retval }
            guard let dayIndex = calendar.dateComponents([.day], from: date).day else {
                print("Invalid Index")
                return nil
            }
            if case 1...13 = dayIndex  { // then check the previous month
                // get the index path of the last day of the previous month
                let periodApart = calendar.dateComponents([.month], from: startOfMonthCache, to: date)
                
                guard let // If there is no previous months, there are no counterpart dates
                    monthSectionIndex = periodApart.month,
                    monthSectionIndex - 1 >= 0 else {
                        return retval
                }
                
                let previousMonthInfo = monthInfo[monthSectionIndex - 1]
                if previousMonthInfo.postDates < 1 || dayIndex > previousMonthInfo.postDates { return retval } // If there are no postdates for the previous month, then there are no counterpart dates
                
                guard
                    let prevMonth = calendar.date(byAdding: .month, value: -1, to: date),
                    let lastDayOfPrevMonth = Date.endOfMonth(for: prevMonth, using: calendar) else {
                        assert(false, "Error generating date in indexPathOfdateCellCounterPart(). Contact the developer on github")
                        return retval
                }

                let indexPathOfLastDayOfPreviousMonth = pathsFromDates([lastDayOfPrevMonth])
                if indexPathOfLastDayOfPreviousMonth.count < 1 {
                    print("out of range error in indexPathOfdateCellCounterPart() upper. This should not happen. Contact developer on github")
                    return retval
                }
                
                let lastDayIndexPath = indexPathOfLastDayOfPreviousMonth[0]
                
                var section = lastDayIndexPath.section
                var itemIndex = lastDayIndexPath.item + dayIndex
                
                // Determine if the sections/item needs to be adjusted
                let extraSection = itemIndex / numberOfItemsInSection(section)
                let extraIndex = itemIndex % numberOfItemsInSection(section)
                
                section += extraSection
                itemIndex = extraIndex
                
                let reCalcRapth = IndexPath(item: itemIndex, section: section)
                retval = reCalcRapth
            } else if case 26...31 = dayIndex  { // check the following month
                let periodApart = calendar.dateComponents([.month], from: startOfMonthCache, to: date)
                let monthSectionIndex = periodApart.month!
                
                if monthSectionIndex + 1 >= monthInfo.count { return retval }// If there is no following months, there are no counterpart dates

                let followingMonthInfo = monthInfo[monthSectionIndex + 1]
                
                if followingMonthInfo.preDates < 1 { return retval } // If there are no predates for the following month, then there are no counterpart dates
                
                let lastDateOfCurrentMonth = Date.endOfMonth(for: date, using: calendar)!
                let lastDay = calendar.component(.day, from: lastDateOfCurrentMonth)
                
                let section = followingMonthInfo.startSection
                let index = dayIndex - lastDay + (followingMonthInfo.preDates - 1)
                
                if index < 0 { return retval }
                
                print("section \(section) index \(index)")
                retval = IndexPath(item: index, section: section)
            }
        }
        return retval
    }
    
    func scrollToSection(_ section: Int, triggerScrollToDateDelegate: Bool = false, animateScroll: Bool = true, completionHandler: (()->Void)?) {
        if scrollInProgress { return }
        if let date = dateInfoFromPath(IndexPath(item: MAX_NUMBER_OF_DAYS_IN_WEEK - 1, section:section))?.date {
            let recalcDate = Date.startOfMonth(for: date, using: calendar)!
            self.scrollToDate(recalcDate, triggerScrollToDateDelegate: triggerScrollToDateDelegate, animateScroll: animateScroll, preferredScrollPosition: nil, completionHandler: completionHandler)
        }
    }
    
    func generateNewLayout() -> UICollectionViewLayout {
        let layout: UICollectionViewLayout = JTAppleCalendarLayout(withDelegate: self)
        let conformingProtocolLayout = layout as! JTAppleCalendarLayoutProtocol
        
        conformingProtocolLayout.scrollDirection = direction
        return layout
    }
    
    func setupMonthInfoDataForStartAndEndDate()-> calendarData {
        var months = [month]()
        var monthMap = [Int:Int]()
        var totalSections = 0
        var totalDays = 0
        if let validConfig = dataSource?.configureCalendar(self) {
            // check if the dates are in correct order
            if (validConfig.calendar as NSCalendar).compare(validConfig.startDate, to: validConfig.endDate, toUnitGranularity: NSCalendar.Unit.nanosecond) == ComparisonResult.orderedDescending {
                assert(false, "Error, your start date cannot be greater than your end date\n")
                return (calendarData(months:[], totalSections: 0, monthMap: [:], totalDays: 0))
            }
            
            // Set the new cache
            cachedConfiguration = validConfig
            
            if let
                startMonth = Date.startOfMonth(for: validConfig.startDate, using: validConfig.calendar),
                let endMonth = Date.endOfMonth(for: validConfig.endDate, using: validConfig.calendar) {
                
                startOfMonthCache = startMonth
                endOfMonthCache   = endMonth
                
                // Create the parameters for the date format generator
                let parameters = DateConfigParameters(inCellGeneration: validConfig.generateInDates,
                                                                outCellGeneration: validConfig.generateOutDates,
                                                                numberOfRows: validConfig.numberOfRows,
                                                                startOfMonthCache: startOfMonthCache,
                                                                endOfMonthCache: endOfMonthCache,
                                                                configuredCalendar: validConfig.calendar,
                                                                firstDayOfWeek: firstDayOfWeek)
                
                let generatedData        = dateGenerator.setupMonthInfoDataForStartAndEndDate(parameters)
                months = generatedData.months
                monthMap = generatedData.monthMap
                totalSections = generatedData.totalSections
                totalDays = generatedData.totalDays
            }
        }
        
        let data = calendarData(months: months, totalSections: totalSections, monthMap: monthMap, totalDays: totalDays)
        return data
    }
    
    func pathsFromDates(_ dates:[Date])-> [IndexPath] {
        var returnPaths: [IndexPath] = []
        for date in dates {
            
            if  calendar.startOfDay(for: date) >= startOfMonthCache && calendar.startOfDay(for: date) <= endOfMonthCache {
                if  calendar.startOfDay(for: date) >= startOfMonthCache && calendar.startOfDay(for: date) <= endOfMonthCache {
                    
                    let periodApart = calendar.dateComponents([.month], from: startOfMonthCache, to: date)
                    print(periodApart)
                    let day = calendar.dateComponents([.day], from: date).day!
                    let monthSectionIndex = periodApart.month

                    let currentMonthInfo = monthInfo[monthSectionIndex!]
                    
                    if let indexPath = currentMonthInfo.indexPath(forDay: day) {
                        returnPaths.append(indexPath)
                    }
                }
            }
        }
        return returnPaths
    }
}

extension JTAppleCalendarView {
    func cellStateFromIndexPath(_ indexPath: IndexPath, withDateInfo info: (date: Date, owner: DateOwner)? = nil, cell: JTAppleDayCell? = nil)->CellState {
        let validDateInfo: (date: Date, owner: DateOwner)
        if let nonNilDateInfo = info {
            validDateInfo = nonNilDateInfo
        } else {
            guard let newDateInfo = dateInfoFromPath(indexPath) else {
                assert(false, "Error this should not be nil. Contact developer Jay on github by opening a request")
            }
            validDateInfo = newDateInfo
        }
        
        let date = validDateInfo.date
        let dateBelongsTo = validDateInfo.owner
        
        
        let currentDay = calendar.dateComponents([.day], from: date).day!
        
        let componentWeekDay = calendar.component(.weekday, from: date)
        let cellText = String(describing: currentDay)


        let dayOfWeek = DaysOfWeek(rawValue: componentWeekDay)!
        let rangePosition = {()->SelectionRangePosition in
            if self.theSelectedIndexPaths.contains(indexPath) {
                if self.selectedDates.count == 1 { return .full}
                let left = self.theSelectedIndexPaths.contains(IndexPath(item: (indexPath as NSIndexPath).item - 1, section: (indexPath as NSIndexPath).section))
                let right = self.theSelectedIndexPaths.contains(IndexPath(item: (indexPath as NSIndexPath).item + 1, section: (indexPath as NSIndexPath).section))
                if (left == right) {
                    if left == false { return .full } else { return .middle }
                } else {
                    if left == false { return .left } else { return .right }
                }
            }
            return .none
        }
        
        let cellState = CellState(
            isSelected: theSelectedIndexPaths.contains(indexPath),
            text: cellText,
            dateBelongsTo: dateBelongsTo,
            date: date,
            day: dayOfWeek,
            row: { return (indexPath as NSIndexPath).item / MAX_NUMBER_OF_DAYS_IN_WEEK },
            column: { return (indexPath as NSIndexPath).item % MAX_NUMBER_OF_DAYS_IN_WEEK },
            dateSection: { return self.dateFromSection((indexPath as NSIndexPath).section)! },
            selectedPosition: rangePosition,
            cell: {return cell}
        )
        return cellState
    }
    
    func startMonthSectionForSection(_ aSection: Int)->Int {
        let monthIndexWeAreOn = aSection / numberOfSectionsForMonth(aSection)
        let nextSection = numberOfSectionsForMonth(aSection) * monthIndexWeAreOn
        return nextSection
    }
    
    func batchReloadIndexPaths(_ indexPaths: [IndexPath]) {
        if indexPaths.count < 1 { return }
        UICollectionView.performWithoutAnimation({
            self.calendarView.performBatchUpdates({
                self.calendarView.reloadItems(at: indexPaths)
                }, completion: nil)  
        })
    }
    
    func addCellToSelectedSetIfUnselected(_ indexPath: IndexPath, date: Date) {
        if self.theSelectedIndexPaths.contains(indexPath) == false {
            self.theSelectedIndexPaths.append(indexPath)
            self.theSelectedDates.append(date)
        }
    }
    func deleteCellFromSelectedSetIfSelected(_ indexPath: IndexPath) {
        if let index = self.theSelectedIndexPaths.index(of: indexPath) {
            self.theSelectedIndexPaths.remove(at: index)
            self.theSelectedDates.remove(at: index)
        }
    }
    func deselectCounterPartCellIndexPath(_ indexPath: IndexPath, date: Date, dateOwner: DateOwner) -> IndexPath? {
        if let
            counterPartCellIndexPath = indexPathOfdateCellCounterPart(date, indexPath: indexPath, dateOwner: dateOwner) {
            deleteCellFromSelectedSetIfSelected(counterPartCellIndexPath)
            return counterPartCellIndexPath
        }
        return nil
    }
    
    func selectCounterPartCellIndexPathIfExists(_ indexPath: IndexPath, date: Date, dateOwner: DateOwner) -> IndexPath? {
        if let counterPartCellIndexPath = indexPathOfdateCellCounterPart(date, indexPath: indexPath, dateOwner: dateOwner) {
            let dateComps = calendar.dateComponents([.month, .day, .year], from: date)
            guard let counterpartDate = calendar.date(from: dateComps) else { return nil }
            addCellToSelectedSetIfUnselected(counterPartCellIndexPath, date:counterpartDate)
            return counterPartCellIndexPath
        }
        return nil
    }
    
    func monthInfoForIndex(_ index: Int) -> month? {
        if let  index = monthMap[index] {
            return monthInfo[index]
        }
        return nil
    }
    
    func dateFromSection(_ section: Int) -> (dateRange:(start: Date, end: Date), month: Int)? {
        
        let monthIndex = monthMap[section]!
        let monthData = monthInfo[monthIndex]
        let startIndex = monthData.preDates
        let endIndex = monthData.numberOfDaysInMonth + startIndex - 1
        
        
        let startIndexPath = IndexPath(item: startIndex, section: section)
        let endIndexPath = IndexPath(item: endIndex, section: section)
        
        guard let
            startDate = dateInfoFromPath(startIndexPath)?.date,
            let endDate = dateInfoFromPath(endIndexPath)?.date else {
                return nil
        }
            
        if let monthDate = calendar.date(byAdding: .month, value: monthIndex, to: startDateCache) {
            let monthNumber = calendar.dateComponents([.month], from: monthDate)
            return ((startDate, endDate), monthNumber.month!)
        }
        
        return nil
    }
    
    
    
    func dateInfoFromPath(_ indexPath: IndexPath)-> (date: Date, owner: DateOwner)? { // Returns nil if date is out of scope
        guard let monthIndex = monthMap[(indexPath as NSIndexPath).section] else {
            return nil
        }
        
        let monthData = monthInfo[monthIndex]
        let offSet: Int
        var numberOfDaysToAddToOffset: Int = 0
        
        switch monthData.sectionIndexMaps[(indexPath as NSIndexPath).section]! {
        case 0:
            offSet = monthData.preDates
        default:
            offSet = 0
            let currentSectionIndexMap = monthData.sectionIndexMaps[(indexPath as NSIndexPath).section]!
            
            numberOfDaysToAddToOffset = monthData.sections[0..<currentSectionIndexMap].reduce(0, +)
            numberOfDaysToAddToOffset -= monthData.preDates
        }
        
        var dayIndex = 0
        var dateOwner: DateOwner = .thisMonth
        let date: Date?
        var dateComponents = DateComponents()
        
        if (indexPath as NSIndexPath).item >= offSet && (indexPath as NSIndexPath).item + numberOfDaysToAddToOffset < monthData.numberOfDaysInMonth + offSet {
            // This is a month date
            dayIndex = monthData.startDayIndex + (indexPath as NSIndexPath).item - offSet + numberOfDaysToAddToOffset
            dateComponents.day = dayIndex
            date = calendar.date(byAdding: dateComponents, to: startOfMonthCache)
            dateOwner = .thisMonth
        } else if (indexPath as NSIndexPath).item < offSet {
            // This is a preDate
            dayIndex = (indexPath as NSIndexPath).item - offSet  + monthData.startDayIndex
            dateComponents.day = dayIndex
            date = calendar.date(byAdding: dateComponents, to: startOfMonthCache)
            if date! < startOfMonthCache {
                dateOwner = .previousMonthOutsideBoundary
            } else {
                dateOwner = .previousMonthWithinBoundary
            }
        } else {
            // This is a postDate
            dayIndex =  monthData.startDayIndex - offSet + (indexPath as NSIndexPath).item + numberOfDaysToAddToOffset
            dateComponents.day = dayIndex
            date = calendar.date(byAdding: dateComponents, to: startOfMonthCache)
            if date! > endOfMonthCache {
                dateOwner = .followingMonthOutsideBoundary
            } else {
                dateOwner = .followingMonthWithinBoundary
            }
        }
        
        guard let validDate = date else {
            return nil
        }
        
        return (validDate, dateOwner)
    }
}

extension JTAppleCalendarView: JTAppleCalendarDelegateProtocol {
    func cachedDate() -> (start: Date, end: Date, calendar: Calendar) { return (start: cachedConfiguration.startDate, end: cachedConfiguration.endDate, calendar: cachedConfiguration.calendar) }
    func numberOfRows() -> Int {return cachedConfiguration.numberOfRows}
    func numberOfsections(forMonth section:Int) -> Int { return numberOfSectionsForMonth(section) }
    func numberOfMonthsInCalendar() -> Int { return numberOfMonths }
    
    func numberOfPreDatesForMonth(_ month: Date) -> Int { return firstDayIndexForMonth(month) }
    func numberOfPostDatesForMonth(_ month: Date) -> Int { return firstDayIndexForMonth(month) }
    
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
