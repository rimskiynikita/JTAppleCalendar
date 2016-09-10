//
//  JTAppleCalendarLayout.swift
//  JTAppleCalendar
//
//  Created by JayT on 2016-03-01.
//  Copyright © 2016 OS-Tech. All rights reserved.
//


/// Base class for the Horizontal layout
public class JTAppleCalendarLayout: UICollectionViewLayout, JTAppleCalendarLayoutProtocol {
    let errorDelta: CGFloat = 0.0000001
    var itemSize: CGSize = CGSizeZero
    var headerReferenceSize: CGSize = CGSizeZero
    var scrollDirection: UICollectionViewScrollDirection = .Horizontal
    
    var maxSections: Int { get { return delegate.monthMap.count } }

    var cellCache: [Int:[UICollectionViewLayoutAttributes]] = [:]
    var headerCache: [UICollectionViewLayoutAttributes] = []
    var sectionSize: [CGFloat] = []
    var lastWrittenCellAttribute: UICollectionViewLayoutAttributes?
    var lastWrittenHeaderAttribute: UICollectionViewLayoutAttributes?
    var thereAreHeaders: Bool { get { return delegate.registeredHeaderViews.count > 0}}
    
    var monthData: [month] { get { return delegate.monthInfo } }
    var monthMap: [Int:Int] { get { return delegate.monthMap } }
    var numberOfRows: Int {get{ return delegate.numberOfRows()}}
    
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
    public override func prepareLayout() {
        if !cellCache.isEmpty { return }
        
        var weAreAtTheEndOfRow: Bool {
            get {
                guard let lastWrittenCellAttribute = self.lastWrittenCellAttribute  else { return false }
                return self.xCellOffset + lastWrittenCellAttribute.frame.width >= lastWrittenCellAttribute.frame.width * CGFloat(MAX_NUMBER_OF_DAYS_IN_WEEK)
            }
        }
        
        let weAreAtTheLastItemInRow = {(numberOfDaysInCurrentSection: Int, item:Int)->Bool in
            guard let lastWrittenCellAttribute = self.lastWrittenCellAttribute  else { return false }
            return ((numberOfDaysInCurrentSection - 1 == item && self.xCellOffset + lastWrittenCellAttribute.frame.width < lastWrittenCellAttribute.frame.width * CGFloat(MAX_NUMBER_OF_DAYS_IN_WEEK)))
        }
        
        
        var section = 0
        for aMonth in monthData {
            for numberOfDaysInCurrentSection in aMonth.sections {
                // Generate and cache the headers
                
                
                let sectionIndexPath = NSIndexPath(forItem: 0, inSection: section)

                
                if let aHeaderAttr = layoutAttributesForSupplementaryViewOfKind(UICollectionElementKindSectionHeader, atIndexPath: sectionIndexPath) {
                    headerCache.append(aHeaderAttr)
                    
                    
                    switch scrollDirection {
                    case .Vertical:
                        contentHeight += aHeaderAttr.frame.height
                        yCellOffset += aHeaderAttr.frame.height
                        xCellOffset = 0
                    case .Horizontal:
                        contentWidth += aHeaderAttr.frame.width
                        yCellOffset = aHeaderAttr.frame.height
//                        xCellOffset += aHeaderAttr.frame.width
                    }
                    
                }
                
                // Generate and cache the cells
                for item in 0..<numberOfDaysInCurrentSection {
                    let indexPath = NSIndexPath(forItem: item, inSection: section)
                    
                    if indexPath.item == 6 || indexPath.item == 6 || indexPath.item == 8 {
                        print(indexPath)
                    }
                    
                    if let attribute = layoutAttributesForItemAtIndexPath(indexPath) {
                        if cellCache[section] == nil {
                            cellCache[section] = []
                        }
                        cellCache[section]!.append(attribute)
                        lastWrittenCellAttribute = attribute
                        
                        if
                            weAreAtTheEndOfRow ||
                                (weAreAtTheLastItemInRow(numberOfDaysInCurrentSection, item) && thereAreHeaders) { // We are at the last item in the section && if we have headers
                            
                            
                            xCellOffset = 0
                            yCellOffset += attribute.frame.height
                            if scrollDirection == .Vertical { contentHeight += attribute.frame.height }
                            
                            
                        } else {
                            xCellOffset += attribute.frame.width
                        }
                    }
                }
                section += 1
                // Save the content size for each section
                sectionSize.append(scrollDirection == .Horizontal ? contentWidth : contentHeight)
                
            }
            
        }
        
        if !thereAreHeaders { headerCache.removeAll() } // Get rid of header data if dev didnt register headers. The were used for calculation but are not needed to be displayed
        if scrollDirection == .Horizontal { contentHeight = self.collectionView!.bounds.size.height } else { contentWidth = self.collectionView!.bounds.size.width }
        
        print(sectionSize)
    }
    
    /// Returns the width and height of the collection view’s contents. The width and height of the collection view’s contents.
    public override func collectionViewContentSize() -> CGSize {
        return CGSize(width: contentWidth, height: contentHeight)
    }
    
    /// Returns the layout attributes for all of the cells and views in the specified rectangle.
    override public func layoutAttributesForElementsInRect(rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let startSectionIndex = startIndexFrom(rectOrigin: rect.origin)
        
        // keep looping until there were no interception rects
        var attributes: [UICollectionViewLayoutAttributes] = []
        let maxMissCount = scrollDirection == .Horizontal ? MAX_NUMBER_OF_ROWS_PER_MONTH : MAX_NUMBER_OF_DAYS_IN_WEEK
        var beganIntercepting = false
        var missCount = 0
        for sectionIndex in startSectionIndex..<cellCache.count {
            if let validSection = cellCache[sectionIndex] where validSection.count > 0 {
                // Add header view attributes
                if thereAreHeaders {
                    if CGRectIntersectsRect(headerCache[sectionIndex].frame, rect) { attributes.append(headerCache[sectionIndex]) }
                }
                
                for val in validSection {
                    if CGRectIntersectsRect(val.frame, rect) {
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
    
    override  public func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
        
        
        let monthIndex = delegate.monthMap[indexPath.section]!
        let numberOfDays = numberOfDaysInSection(monthIndex) // JT101 cacche this
        
        if !(0...maxSections ~= indexPath.section) || !(0...numberOfDays  ~= indexPath.item) { return nil} // return nil on invalid range
        let attr = UICollectionViewLayoutAttributes(forCellWithIndexPath: indexPath)
        
        // If this index is already cached, then return it else, apply a new layout attribut to it
        if let alreadyCachedCellAttrib = cellCache[indexPath.section] where indexPath.item < alreadyCachedCellAttrib.count {
            return alreadyCachedCellAttrib[indexPath.item]
        }
        applyLayoutAttributes(attr)
        return attr
    }
    
    /// Returns the layout attributes for the specified supplementary view.
    public override func layoutAttributesForSupplementaryViewOfKind(elementKind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
        let attributes = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: elementKind, withIndexPath: indexPath)
        
        // We cache the header here so we dont call the delegate so much
        let headerSize = cachedHeaderSizeForSection(indexPath.section)
        
        // Use the calculaed header size and force the width of the header to take up 7 columns
        let modifiedSize = CGSize(width: itemSize.width * CGFloat(MAX_NUMBER_OF_DAYS_IN_WEEK), height: headerSize.height)
        
        switch scrollDirection {
        case .Horizontal:
            attributes.frame = CGRect(x: contentWidth, y: 0, width: modifiedSize.width, height: modifiedSize.height)
        case .Vertical:
            attributes.frame = CGRect(x: 0, y: yCellOffset, width: modifiedSize.width, height: modifiedSize.height)
        }
        
        if attributes.frame == CGRectZero { return nil }
        return attributes
    }
    
    func applyLayoutAttributes(attributes : UICollectionViewLayoutAttributes) {
        if attributes.representedElementKind != nil { return }
    
        // Calculate the item size
        if let itemSize = delegate!.itemSize {
            if scrollDirection == .Vertical {
                self.itemSize.height = itemSize
            } else {
                self.itemSize.width = itemSize
                self.itemSize.height = sizeForitemAtIndexPath(attributes.indexPath).height
            }
        } else {
            itemSize = sizeForitemAtIndexPath(attributes.indexPath)
        } // jt101 the width is already set form the outside. may change this to all inside here.
        
        var stride: CGFloat = 0
        
        if scrollDirection == .Horizontal {
            stride = itemSize.width * CGFloat(MAX_NUMBER_OF_DAYS_IN_WEEK * attributes.indexPath.section)
        }
        
        attributes.frame = CGRectMake(xCellOffset + stride, yCellOffset , self.itemSize.width, self.itemSize.height)
    }
    
    func numberOfDaysInSection(index: Int) -> Int {
        return monthData[index].numberOfDaysInMonthGrid
    }
    
    func cachedHeaderSizeForSection(section: Int) -> CGSize {
        // We cache the header here so we dont call the delegate so much
        var headerSize = CGSizeZero
        if let cachedHeader  = currentHeader where cachedHeader.section == section {
            headerSize = cachedHeader.size
        } else {
            headerSize = delegate!.referenceSizeForHeaderInSection(section)
            currentHeader = (section, headerSize)
        }
        return headerSize
    }
    
    func sizeForitemAtIndexPath(indexPath: NSIndexPath) -> CGSize {
        
        // Return the size if the cell size is already cached
        if let cachedCell  = currentCell where cachedCell.section == indexPath.section {
            return cachedCell.itemSize
        }
        
        // Get header size if it alrady cached
        var headerSize =  CGSizeZero
        if thereAreHeaders {
            headerSize = cachedHeaderSizeForSection(indexPath.section)
        }
        let currentItemSize = itemSize
        
        
        let totalNumberOfRows = monthData[monthMap[indexPath.section]!].rows
        let monthSection = monthData[monthMap[indexPath.section]!].sectionIndexMaps[indexPath.section]!
        
        let numberOfSections = CGFloat(totalNumberOfRows) / CGFloat(numberOfRows)
        let fullSections =  Int(numberOfSections)
//        let partial = numberOfSections - CGFloat(fullSections) > 0 ? 1 : 0
        
        let numberOfRowsForSection: Int
        if monthSection + 1 <= fullSections {
            numberOfRowsForSection = numberOfRows
        } else {
            numberOfRowsForSection = totalNumberOfRows - (monthSection * numberOfRows)
        }
        
        
        
        
        
        let size            = CGSize(width: currentItemSize.width, height: (collectionView!.frame.height - headerSize.height) / CGFloat(numberOfRowsForSection))
        currentCell         = (section: indexPath.section, itemSize: size)
        return size
    }
    
    func sizeOfSection(section: Int)-> CGFloat {
        switch scrollDirection {
        case .Horizontal:
            return cellCache[section]![0].frame.width * CGFloat(MAX_NUMBER_OF_DAYS_IN_WEEK)
        case .Vertical:
            let headerSizeOfSection = headerCache.count > 0 ? headerCache[section].frame.height : 0
            return cellCache[section]![0].frame.height * CGFloat(numberOfRowsForMonth(section)) + headerSizeOfSection
        }
    }
    
    func numberOfRowsForMonth(index: Int)->Int {
        let monthIndex = monthMap[index]!
        return monthData[monthIndex].rows
    }
    
    func startIndexFrom(rectOrigin offset: CGPoint)-> Int {
        let key =  scrollDirection == .Horizontal ? offset.x : offset.y
        return startIndexBinarySearch(sectionSize, offset: key)
    }
    
    func sizeOfContentForSection(section: Int) -> CGFloat {
        return sizeOfSection(section)
    }

    func sectionFromRectOffset(offset: CGPoint)-> Int {
        let theOffet = scrollDirection == .Horizontal ? offset.x : offset.y
        return sectionFromOffset(theOffet)
    }
    func sectionFromOffset(theOffSet: CGFloat) -> Int {
        var val: Int = 0
        for (index, sectionSizeValue) in sectionSize.enumerate() {
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
    
    func startIndexBinarySearch<T: Comparable>(a: [T], offset: T) -> Int {
        if a.count < 3 { return 0} // If the range is less than 2 just break here.
        var range = 0..<a.count
        var midIndex: Int = 0
        while range.startIndex < range.endIndex {
            midIndex = range.startIndex + (range.endIndex - range.startIndex) / 2
            if midIndex + 1  >= a.count || offset >= a[midIndex] && offset < a[midIndex + 1] ||  a[midIndex] == offset {
                break
            } else if a[midIndex] < offset {
                range.startIndex = midIndex + 1
            } else {
                range.endIndex = midIndex
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
    public override func targetContentOffsetForProposedContentOffset(proposedContentOffset: CGPoint) -> CGPoint {
        return proposedContentOffset
    }
    
    func clearCache() {
        headerCache.removeAll()
        cellCache.removeAll()
        sectionSize.removeAll()
        currentHeader = nil
        currentCell = nil
        lastWrittenCellAttribute = nil
        lastWrittenHeaderAttribute = nil
        
        contentHeight = 0
        contentWidth = 0
    }
}