//
//  JTAppleCalendarLayout.swift
//  JTAppleCalendar
//
//  Created by JayT on 2016-03-01.
//  Copyright © 2016 OS-Tech. All rights reserved.
//


/// Base class for the Horizontal layout
open class JTAppleCalendarLayout: UICollectionViewLayout, JTAppleCalendarLayoutProtocol {
    let errorDelta: CGFloat = 0.0000001
    var itemSize: CGSize = CGSize.zero
    var headerReferenceSize: CGSize = CGSize.zero
    var scrollDirection: UICollectionViewScrollDirection = .horizontal
    
    var maxSections: Int { get { return delegate.monthMap.count } }

    var cellCache: [Int:[UICollectionViewLayoutAttributes]] = [:]
    var headerCache: [Int:UICollectionViewLayoutAttributes] = [:]
    var sectionSize: [CGFloat] = []
    var lastWrittenCellAttribute: UICollectionViewLayoutAttributes?
    var thereAreHeaders: Bool { get { return delegate.registeredHeaderViews.count > 0}}
    
    var monthData: [month] { get { return delegate.monthInfo } }
    var monthMap: [Int:Int] { get { return delegate.monthMap } }
    var numberOfRows: Int {get{ return delegate.numberOfRows()}}
    var totalSections: Int { get { return delegate.totalMonthSections } }
    var stride: CGFloat = 0
    
    weak var delegate: JTAppleCalendarDelegateProtocol!
    
    var currentHeader: (section: Int, size: CGSize)? // Tracks the current header size
    var currentCell: (section: Int, itemSize: CGSize)? // Tracks the current cell size
    
    var contentHeight: CGFloat = 0 // Content height of calendarView

    var contentWidth: CGFloat = 0 // Content wifth of calendarView
    
    var xCellOffset: CGFloat = 0
    var yCellOffset: CGFloat = 0
    
    init(withDelegate delegate: JTAppleCalendarDelegateProtocol) {
        super.init()
        self.delegate = delegate
    }
    
    /// Tells the layout object to update the current layout.
    open override func prepare() {
        if scrollDirection == .vertical {
            verticalStuff()
        } else {
            horizontalStuff()
        }
    }
    
    func horizontalStuff() {
        if !cellCache.isEmpty { return }
        
        var weAreAtTheEndOfRow: Bool {
            get {
                guard let lastWrittenCellAttribute = self.lastWrittenCellAttribute  else { return false }
                return self.xCellOffset >= lastWrittenCellAttribute.frame.width * CGFloat(MAX_NUMBER_OF_DAYS_IN_WEEK)
            }
        }
        
        let weAreAtTheLastItemInRow = {(numberOfDaysInCurrentSection: Int, item:Int)->Bool in
            guard let lastWrittenCellAttribute = self.lastWrittenCellAttribute  else { return false }
            return numberOfDaysInCurrentSection - 1 == item && self.xCellOffset < lastWrittenCellAttribute.frame.width * CGFloat(MAX_NUMBER_OF_DAYS_IN_WEEK)
        }
        
        
        var section = 0
        var x = 0
        
        for aMonth in monthData {
            for numberOfDaysInCurrentSection in aMonth.sections {
                // Generate and cache the headers
                
                
                
                let sectionIndexPath = IndexPath(item: 0, section: section)
                
                if let aHeaderAttr = layoutAttributesForSupplementaryView(ofKind: UICollectionElementKindSectionHeader, at: sectionIndexPath) {
                    headerCache[section] = aHeaderAttr

                    if thereAreHeaders {
                        contentWidth += aHeaderAttr.frame.width
                        yCellOffset = aHeaderAttr.frame.height
                    } else {
                        if lastWrittenCellAttribute == nil {
                            contentWidth += aHeaderAttr.frame.width
                        }
                    }
                    
                }
                
                // Generate and cache the cells
                for item in 0..<numberOfDaysInCurrentSection {
                    
                    let indexPath = IndexPath(item: item, section: section)
                    if let attribute = layoutAttributesForItem(at: indexPath) {
                        if cellCache[section] == nil {
                            cellCache[section] = []
                        }
                        cellCache[section]!.append(attribute)
                        lastWrittenCellAttribute = attribute

                        xCellOffset += attribute.frame.width

                        if (weAreAtTheLastItemInRow(numberOfDaysInCurrentSection, item)) { // We are at the last item in the section && if we have headers
                            if thereAreHeaders {
                                xCellOffset = 0
                                yCellOffset += attribute.frame.height
                            }
                        } else if weAreAtTheEndOfRow {
                            xCellOffset   = 0
                            if thereAreHeaders {
                                
                                yCellOffset   += attribute.frame.height
                            } else {
                                if (x + 1) % numberOfRows * 7 == 0 { // If we are on the last item in this section, then reset, and increase stride
                                    yCellOffset = 0
                                    stride = contentWidth
                                    contentWidth += lastWrittenCellAttribute!.frame.width * 7
                                } else if let lastWrittenCellAttribute = self.lastWrittenCellAttribute , // If we are at the bottom of the screen
                                    abs(lastWrittenCellAttribute.frame.origin.y + lastWrittenCellAttribute.frame.height - collectionView!.frame.height) < errorDelta {
                                    
                                    stride += contentWidth
                                    contentWidth += lastWrittenCellAttribute.frame.width * 7
                                    yCellOffset = 0
                                    
                                } else {
                                    yCellOffset += attribute.frame.height
                                }
                                
                            }
                        
                        }
                    }
                    x += 1
                }
                // Save the content size for each section
                sectionSize.append(scrollDirection == .horizontal ? contentWidth : contentHeight)
                
                if thereAreHeaders {
                    stride = sectionSize[section]
                }

                section += 1
                
                
                
            }
            
        }
        
        if !thereAreHeaders { headerCache.removeAll() } // Get rid of header data if dev didnt register headers. The were used for calculation but are not needed to be displayed
        if scrollDirection == .horizontal { contentHeight = self.collectionView!.bounds.size.height } else { contentWidth = self.collectionView!.bounds.size.width }
        
        //        print(cellCache[0]![0])
    }
    
    func verticalStuff () {
        if !cellCache.isEmpty { return }
        
        var weAreAtTheEndOfRow: Bool {
            get {
                guard let lastWrittenCellAttribute = self.lastWrittenCellAttribute  else { return false }
                return self.xCellOffset >= lastWrittenCellAttribute.frame.width * CGFloat(MAX_NUMBER_OF_DAYS_IN_WEEK)
            }
        }
        
        let weAreAtTheLastItemInRow = {(numberOfDaysInCurrentSection: Int, item:Int)->Bool in
            guard let lastWrittenCellAttribute = self.lastWrittenCellAttribute  else { return false }
            return numberOfDaysInCurrentSection - 1 == item && self.xCellOffset <= lastWrittenCellAttribute.frame.width * CGFloat(MAX_NUMBER_OF_DAYS_IN_WEEK)
        }
        
        
        var section = 0
        
        for aMonth in monthData {
            for numberOfDaysInCurrentSection in aMonth.sections {
                // Generate and cache the headers
                
                let sectionIndexPath = IndexPath(item: 0, section: section)
                
                if thereAreHeaders {
                    if let aHeaderAttr = layoutAttributesForSupplementaryView(ofKind: UICollectionElementKindSectionHeader, at: sectionIndexPath) {
                        headerCache[section] = aHeaderAttr
                        yCellOffset += aHeaderAttr.frame.height
                        contentHeight += aHeaderAttr.frame.height
                    }
                }
                
                // Generate and cache the cells
                for item in 0..<numberOfDaysInCurrentSection {
                    let indexPath = IndexPath(item: item, section: section)

                    if let attribute = layoutAttributesForItem(at: indexPath) {
                        if cellCache[section] == nil {
                            cellCache[section] = []
                        }
                        cellCache[section]!.append(attribute)
                        lastWrittenCellAttribute = attribute
                        
                        xCellOffset += attribute.frame.width

                        if (weAreAtTheLastItemInRow(numberOfDaysInCurrentSection, item)) { // We are at the last item in the section && if we have headers
                            if thereAreHeaders {
                                xCellOffset = 0
                                yCellOffset += attribute.frame.height
                                contentHeight += attribute.frame.height
                            } else {
                                if monthData.last?.sectionIndexMaps[(indexPath as NSIndexPath).section] != nil { // If we are on the last section on a partially filled row
                                    contentHeight += attribute.frame.height
                                }
                            }
                            
                        } else if weAreAtTheEndOfRow {
                            xCellOffset   = 0
                            yCellOffset   += attribute.frame.height
                            contentHeight += attribute.frame.height
                        }
                    }
                }
                // Save the content size for each section
                sectionSize.append(scrollDirection == .horizontal ? contentWidth : contentHeight)
                section += 1
            }
            
        }
        
        if !thereAreHeaders { headerCache.removeAll() } // Get rid of header data if dev didnt register headers. The were used for calculation but are not needed to be displayed
        contentWidth = self.collectionView!.bounds.size.width
    }
    
    
    /// Returns the width and height of the collection view’s contents. The width and height of the collection view’s contents.
    open override var collectionViewContentSize : CGSize {
        return CGSize(width: contentWidth, height: contentHeight)
    }
    
    /// Returns the layout attributes for all of the cells and views in the specified rectangle.
    override open func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let startSectionIndex = startIndexFrom(rectOrigin: rect.origin)
        
        // keep looping until there were no interception rects
        var attributes: [UICollectionViewLayoutAttributes] = []
        let maxMissCount = scrollDirection == .horizontal ? MAX_NUMBER_OF_ROWS_PER_MONTH : MAX_NUMBER_OF_DAYS_IN_WEEK
        var beganIntercepting = false
        var missCount = 0
        for sectionIndex in startSectionIndex..<cellCache.count {
            if let validSection = cellCache[sectionIndex] , validSection.count > 0 {
                // Add header view attributes
                if thereAreHeaders {
                    if headerCache[sectionIndex]!.frame.intersects(rect) { attributes.append(headerCache[sectionIndex]!) }
                }
                
                for val in validSection {
                    if val.frame.intersects(rect) {
                        missCount = 0
                        beganIntercepting = true
                        attributes.append(val)
                    } else {
                        missCount += 1
                        if missCount > maxMissCount && beganIntercepting { break }// If there are at least 8 misses in a row since intercepting began, then this section has no more interceptions. So break
                    }
                }
                if missCount > maxMissCount && beganIntercepting { break }// Also break from outter loop
            }
        }
        return attributes
    }
    
    /// Returns the layout attributes for the item at the specified index path. A layout attributes object containing the information to apply to the item’s cell.
    
    override open func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        
        
        let monthIndex = delegate.monthMap[(indexPath as NSIndexPath).section]!
        let numberOfDays = numberOfDaysInSection(monthIndex) // JT101 cacche this
        
        if !(0...maxSections ~= (indexPath as NSIndexPath).section) || !(0...numberOfDays  ~= (indexPath as NSIndexPath).item) { return nil} // return nil on invalid range
        let attr = UICollectionViewLayoutAttributes(forCellWith: indexPath)
        
        // If this index is already cached, then return it else, apply a new layout attribut to it
        if let alreadyCachedCellAttrib = cellCache[(indexPath as NSIndexPath).section] , (indexPath as NSIndexPath).item < alreadyCachedCellAttrib.count {
            return alreadyCachedCellAttrib[(indexPath as NSIndexPath).item]
        }
        applyLayoutAttributes(attr)
        return attr
    }
    
    /// Returns the layout attributes for the specified supplementary view.
    open override func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let attributes = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: elementKind, with: indexPath)
        
        if let alreadyCachedHeaderAttrib = headerCache[indexPath.section] {
            return alreadyCachedHeaderAttrib
        }
        
        
        // We cache the header here so we dont call the delegate so much
        let headerSize = cachedHeaderSizeForSection((indexPath as NSIndexPath).section)

        // Use the calculaed header size and force the width of the header to take up 7 columns
        let modifiedSize = CGSize(width: itemSize.width * CGFloat(MAX_NUMBER_OF_DAYS_IN_WEEK), height: headerSize.height)
        
        switch scrollDirection {
        case .horizontal:
            attributes.frame = CGRect(x: contentWidth, y: 0, width: modifiedSize.width, height: modifiedSize.height)
        case .vertical:
            attributes.frame = CGRect(x: 0, y: yCellOffset, width: modifiedSize.width, height: modifiedSize.height)
        }
        
        if attributes.frame == CGRect.zero { return nil }
        return attributes
    }
    
    func applyLayoutAttributes(_ attributes : UICollectionViewLayoutAttributes) {
        if attributes.representedElementKind != nil { return }
    
        // Calculate the item size
        if let itemSize = delegate!.itemSize {
            if scrollDirection == .vertical {
                self.itemSize.height = itemSize
            } else {
                self.itemSize.width = itemSize
                self.itemSize.height = sizeForitemAtIndexPath(attributes.indexPath).height
            }
        } else {
            itemSize = sizeForitemAtIndexPath(attributes.indexPath)
        } // jt101 the width is already set form the outside. may change this to all inside here.
        
        
        
        
        attributes.frame = CGRect(x: xCellOffset + stride, y: yCellOffset , width: self.itemSize.width, height: self.itemSize.height)
    }
    
    func numberOfDaysInSection(_ index: Int) -> Int {
        return monthData[index].numberOfDaysInMonthGrid
    }
    
    func cachedHeaderSizeForSection(_ section: Int) -> CGSize {
        // We cache the header here so we dont call the delegate so much
        var headerSize = CGSize.zero
        if let cachedHeader  = currentHeader , cachedHeader.section == section {
            headerSize = cachedHeader.size
        } else {
            headerSize = delegate!.referenceSizeForHeaderInSection(section)
            currentHeader = (section, headerSize)
        }
        return headerSize
    }
    
    func sizeForitemAtIndexPath(_ indexPath: IndexPath) -> CGSize {
        
        // Return the size if the cell size is already cached
        if let cachedCell  = currentCell , cachedCell.section == (indexPath as NSIndexPath).section {
            return cachedCell.itemSize
        }
        
        // Get header size if it alrady cached
        var headerSize =  CGSize.zero
        if thereAreHeaders {
            headerSize = cachedHeaderSizeForSection((indexPath as NSIndexPath).section)
        }
        let currentItemSize = itemSize
        
        
        let totalNumberOfRows = monthData[monthMap[(indexPath as NSIndexPath).section]!].rows
        let monthSection = monthData[monthMap[(indexPath as NSIndexPath).section]!].sectionIndexMaps[(indexPath as NSIndexPath).section]!
        
        let numberOfSections = CGFloat(totalNumberOfRows) / CGFloat(numberOfRows)
        let fullSections =  Int(numberOfSections)
        
        let numberOfRowsForSection: Int
        if scrollDirection == .horizontal {
            numberOfRowsForSection = MAX_NUMBER_OF_ROWS_PER_MONTH
        } else if monthSection + 1 <= fullSections {
            numberOfRowsForSection = numberOfRows
        } else {
            numberOfRowsForSection = totalNumberOfRows - (monthSection * numberOfRows)
        }
        
        let size            = CGSize(width: currentItemSize.width, height: (collectionView!.frame.height - headerSize.height) / CGFloat(numberOfRowsForSection))
        currentCell         = (section: (indexPath as NSIndexPath).section, itemSize: size)
        return size
    }
    
    func sizeOfSection(_ section: Int)-> CGFloat {
        switch scrollDirection {
        case .horizontal:
            return cellCache[section]![0].frame.width * CGFloat(MAX_NUMBER_OF_DAYS_IN_WEEK)
        case .vertical:
            let headerSizeOfSection = headerCache.count > 0 ? headerCache[section]!.frame.height : 0
            return cellCache[section]![0].frame.height * CGFloat(numberOfRowsForMonth(section)) + headerSizeOfSection
        }
    }
    
    func numberOfRowsForMonth(_ index: Int)->Int {
        let monthIndex = monthMap[index]!
        return monthData[monthIndex].rows
    }
    
    func startIndexFrom(rectOrigin offset: CGPoint)-> Int {
        let key =  scrollDirection == .horizontal ? offset.x : offset.y
        return startIndexBinarySearch(sectionSize, offset: key)
    }
    
    func sizeOfContentForSection(_ section: Int) -> CGFloat {
        return sizeOfSection(section)
    }

    func sectionFromRectOffset(_ offset: CGPoint)-> Int {
        let theOffet = scrollDirection == .horizontal ? offset.x : offset.y
        return sectionFromOffset(theOffet)
    }
    func sectionFromOffset(_ theOffSet: CGFloat) -> Int {
        var val: Int = 0
        for (index, sectionSizeValue) in sectionSize.enumerated() {
            if abs(theOffSet - sectionSizeValue) < errorDelta {
                continue
            }
            if theOffSet < sectionSizeValue {
                val = index
                break
            }
        }
        return val
    }
    
    func startIndexBinarySearch<T: Comparable>(_ a: [T], offset: T) -> Int {
        if a.count < 3 { return 0} // If the range is less than 2 just break here.
        var midIndex: Int = 0
        var startIndex = 0
        var endIndex = a.count - 1
        while startIndex < endIndex {
            midIndex = startIndex + (endIndex - startIndex) / 2
            if midIndex + 1  >= a.count || offset >= a[midIndex] && offset < a[midIndex + 1] ||  a[midIndex] == offset {
                break
            } else if a[midIndex] < offset {
                startIndex = midIndex + 1
            } else {
                endIndex = midIndex
            }
        }
        return midIndex
    }
    
    /// Returns an object initialized from data in a given unarchiver. self, initialized using the data in decoder.
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    /// Returns the content offset to use after an animation layout update or change.
    /// - Parameter proposedContentOffset: The proposed point for the upper-left corner of the visible content
    /// - returns: The content offset that you want to use instead
    open override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint) -> CGPoint {
        return proposedContentOffset
    }
    
    func clearCache() {
        headerCache.removeAll()
        cellCache.removeAll()
        sectionSize.removeAll()
        currentHeader = nil
        currentCell = nil
        lastWrittenCellAttribute = nil
        xCellOffset = 0
        yCellOffset = 0
        contentHeight = 0
        contentWidth = 0
        stride = 0
    }
}
