//  ThemeLegend.m
//  GMMobile

#import "ThemeLegend.h"
#import "CCodeLibrary/UserDefaults.h"
#import "ThemeLegendMapOverlay.h"
#import "CCodeLibrary/PointInArea.h"
#import "CCodeLibrary/SymbolDictionary.h"
@import CoreText;

#define STD_ROW_HEIGHT 70
#define STD_WIDTH 640
#define STD_BORDER 4
#define STD_LINE 2
#define STD_MARGIN 10
#define STD_FONT_SIZE 48

@implementation ThemeLegend

- (id)init
{
    self = [super init];
    
    if (self)
    {
        _showSymbolAsBarChart = YES;
        _title = @"";
        _outputFile = @"";
        _outputFactor = 1.0;
    }
    
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    ThemeLegend *another = [[ThemeLegend allocWithZone: zone] init];
    another.numCells = _numCells;
    another.numColumns = _numColumns;
    another.numDecimals = _numDecimals;
    another.aspectRatio = _aspectRatio;
    another.pctBorder = _pctBorder;
    another.pctInnerMargin = _pctInnerMargin;
    another.pctSymbol = _pctSymbol;
    another.pctTitle = _pctTitle;
    another.usePointSymbols = _usePointSymbols;
    another.showSymbolAsBarChart = _showSymbolAsBarChart;
    another.useClassColors = _useClassColors;
    another.appendClassCount = _appendClassCount;
    another.borderColor = [[UIColor alloc]initWithCGColor:_borderColor.CGColor];
    another.titleBkColor = [[UIColor alloc]initWithCGColor:_titleBkColor.CGColor];
    another.titleTxColor = [[UIColor alloc]initWithCGColor:_titleTxColor.CGColor];
    another.labelBkColor = [[UIColor alloc]initWithCGColor:_labelBkColor.CGColor];
    another.labelTxColor = [[UIColor alloc]initWithCGColor:_labelTxColor.CGColor];
    another.symbolDefaultColor = [[UIColor alloc]initWithCGColor:_symbolDefaultColor.CGColor];
    another.title = [NSString stringWithString:_title];
    another.outputFile = [NSString stringWithString:_outputFile];
    another.titles = [NSMutableArray arrayWithArray:_titles];
    another.currentTitleIndex = _currentTitleIndex;
    another.cells = NSMutableArray.array;
    another.type = _type;
    another.portraitMapOrigin = self.portraitMapOrigin;
    another.landscapeMapOrigin = self.landscapeMapOrigin;
    another.isDraggedLandscape = _isDraggedLandscape;
    another.isDraggedPortrait = _isDraggedPortrait;
    another.type = _type;
    another.hasColors = _hasColors;
    another.maxValBounds = _maxValBounds;
    another.selectionMode = _selectionMode;
    another.hasOverlay = _hasOverlay;
    
    for (ThemeLegendCell *cl in _cells)
    {
        ThemeLegendCell *newCell = [cl copy];
        [another.cells addObject:newCell];
    }
    
    return another;
}

- (CGPoint)portraitMapOrigin
{
    CGPoint pmo = CGPointZero;
    pmo.x = [UserDefaults.defaults CGFloatForKey:[NSString stringWithFormat:@"XpmoThemeLegend%li", (long)_type]];
    pmo.y = [UserDefaults.defaults CGFloatForKey:[NSString stringWithFormat:@"YpmoThemeLegend%li", (long)_type]];
    
    if (pmo.x && pmo.y)
        _isDraggedPortrait = YES;
    
    return pmo;
}

- (CGPoint)landscapeMapOrigin
{
    CGPoint lmo = CGPointZero;
    lmo.x = [UserDefaults.defaults CGFloatForKey:[NSString stringWithFormat:@"XlmoThemeLegend%li", (long)_type]];
    lmo.y = [UserDefaults.defaults CGFloatForKey:[NSString stringWithFormat:@"YlmoThemeLegend%li", (long)_type]];
    
    if (lmo.x && lmo.y)
        _isDraggedLandscape = YES;
    
    return lmo;
}

- (void)setPortraitMapOrigin:(CGPoint)portraitMapOrigin
{
    [UserDefaults.defaults saveCGFloat:portraitMapOrigin.x
                                forKey:[NSString stringWithFormat:@"XpmoThemeLegend%li", (long)_type]];
    
    [UserDefaults.defaults saveCGFloat:portraitMapOrigin.y
                                forKey:[NSString stringWithFormat:@"YpmoThemeLegend%li", (long)_type]];
}

- (void)setLandscapeMapOrigin:(CGPoint)landscapeMapOrigin
{
    [UserDefaults.defaults saveCGFloat:landscapeMapOrigin.x
                                forKey:[NSString stringWithFormat:@"XlmoThemeLegend%li", (long)_type]];
    
    [UserDefaults.defaults saveCGFloat:landscapeMapOrigin.y
                                forKey:[NSString stringWithFormat:@"YlmoThemeLegend%li", (long)_type]];
}

- (BOOL)drawOnMap
{
    return [UserDefaults.defaults boolForKey:[NSString stringWithFormat:@"ThemeLegend%li", (long)_type]];
}

- (void)setDrawOnMap:(BOOL)drawOnMap
{
    [UserDefaults.defaults saveBool:drawOnMap
                             forKey:[NSString stringWithFormat:@"ThemeLegend%li", (long)_type]];
}

- (void)setCurrentTitleIndex:(int)currentTitleIndex
{
    if (currentTitleIndex < _titles.count)
    {
        _currentTitleIndex = currentTitleIndex;
        _title = (NSString *)_titles[_currentTitleIndex];
    }
}

- (CGFloat)headerHeight
{
    return [self getHeightForText:_title
                             font:ThemeLegendMapOverlay.headerFont
                            width:ThemeLegendMapOverlay.width];
}

- (CGFloat)getHeightForText:(NSString *)text
                       font:(UIFont *)font
                      width:(CGFloat)width
{
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
        width -= 4.0;
    
    else
        width -= 8.0;
    
    CGSize constraint = CGSizeMake(width , 20000.0);
    CGSize titleSize = CGSizeZero;
    CGFloat height = 0.0;
    
    titleSize = [text boundingRectWithSize:constraint
                                   options:NSStringDrawingUsesLineFragmentOrigin
                                attributes:@{NSFontAttributeName:font}
                                   context:nil].size;
    
    height = ceil(titleSize.height);
    
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
        return (height + 6.0);
    
    else
        return (height + 10.0);
}

- (CGSize)writeThemeLegendToFile
{
    CGSize rtn = {0};
    
    if (_outputFile && _outputFile.length)
    {
        void *bmData = NULL;
        CGColorRef white = UIColor.whiteColor.CGColor;
        CGColorRef black = UIColor.blackColor.CGColor;
        CGColorRef red = UIColor.redColor.CGColor;
        CGColorRef blue = UIColor.blueColor.CGColor;
        CGColorRef stdDevMask = [UIColor colorWithWhite:0.0 alpha:0.05].CGColor;
        
        int rowHeight = round(STD_ROW_HEIGHT * _outputFactor);
        int margin = round(STD_MARGIN * _outputFactor);
        int width = round(STD_WIDTH * _outputFactor);
        int height = (rowHeight * (_numCells + 1));
        int border = round(STD_BORDER * _outputFactor);
        CGFloat fontSize = (STD_FONT_SIZE * _outputFactor);
        int lineWidth = round(STD_LINE * _outputFactor);
        NSUInteger countLength = 0;
        CGFloat symbolSize = round((CGFloat)rowHeight * 0.8);
        CGFloat barAreaWidth = 0.0;
        
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGContextRef context = createBitmapContext(width, height, colorSpace, &bmData);
        CGContextSetAllowsAntialiasing(context, YES);
        CGContextSetShouldAntialias(context, YES);
        CGRect rect = CGRectZero;
        CGContextSetFillColorWithColor(context, white);
        
        for (int i = 1; i < (_numCells + 1); i++)
        {
            rect = CGRectMake(border, (i * rowHeight), (width - (border * 2.0)), (rowHeight - border));
            CGContextFillRect(context, rect);
        }
        
        CTFontRef fontRef = CTFontCreateWithName((CFStringRef)@"AppleSDGothicNeo-Bold", fontSize, NULL);
        CGRect fontRect = CTFontGetBoundingBox(fontRef);
        CGFloat verticalOffset = (rowHeight - fontRect.size.height);
        
        NSMutableParagraphStyle *style = NSParagraphStyle.defaultParagraphStyle.mutableCopy;
        style.alignment = NSTextAlignmentCenter;
        
        NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                        (__bridge id)fontRef, kCTFontAttributeName,
                                        style, kCTParagraphStyleAttributeName,
                                        white, kCTForegroundColorAttributeName, nil];
        
        NSAttributedString *text = [[NSAttributedString alloc] initWithString:_title
                                                                   attributes:textAttributes];
        
        rect = CGRectMake(0.0, (-verticalOffset * 0.5), width, (rowHeight - verticalOffset));
        CGPathRef path = CGPathCreateWithRect(rect, NULL);
        CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)text);
        CTFrameRef frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, text.length), path, NULL);
        
        CGContextTranslateCTM(context, 0.0, rowHeight);
        CGContextScaleCTM(context, 1.0, -1.0);
        
        CTFrameDraw(frame, context);
        
        CFRelease(path);
        CFRelease(framesetter);
        CFRelease(frame);
        CFRelease(fontRef);
        
        int sum = 0, max = 0;
        NSMutableArray<NSNumber *> *countArray = NSMutableArray.array;
        NSString *countString = @"";
        
        for (int i = 0; i < _numCells; i++)
        {
            countString = [NSString stringWithFormat:@"%i", _cells[i].count];
            countLength = MAX(countLength, countString.length);
            
            if (!_usePointSymbols && _hasOverlay)
            {
                sum+= _cells[i].count;
                max = MAX(max, _cells[i].count);
                [countArray addObject:[NSNumber numberWithInt:_cells[i].count]];
            }
        }
        
        NSSortDescriptor *sortAscending = [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES];
        [countArray sortUsingDescriptors:[NSArray arrayWithObject:sortAscending]];

        fontRef = CTFontCreateWithName((CFStringRef)@"CourierNewPS-BoldMT", (fontSize * 0.64), NULL);
        fontRect = CTFontGetBoundingBox(fontRef);
        verticalOffset = (rowHeight - fontRect.size.height);
        
        textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                          (__bridge id)fontRef, kCTFontAttributeName,
                          black, kCTForegroundColorAttributeName, nil];
        
        for (int i = 0; i < _numCells; i++)
        {
            if (_usePointSymbols)
            {
                LPDPOINT point = malloc(sizeof(DPOINT) + 4);
                point->x = (rowHeight * 0.5);
                point->y = (-rowHeight * (i + 1) + (rowHeight * 0.5));
                
                CGColorRef color = _symbolDefaultColor.CGColor;
                
                if (_useClassColors)
                    color = _cells[i].symbolColor.CGColor;
                
                [SymbolDictionary drawPointWithSymbol:context
                                                   at:point
                                          usingSymbol:_cells[i].symbol
                                                 Size:symbolSize
                                            fillColor:color
                                            lineColor:black
                                            lineWidth:lineWidth];
                
                free(point);
            }
            
            NSMutableString *label = _cells[i].label.mutableCopy;
            NSMutableString *countString = NSMutableString.string;
            [countString insertString:[NSString stringWithFormat:@"%i", _cells[i].count] atIndex:0];
            
            while (countString.length < countLength)
                [countString insertString:@" " atIndex:0];
            
            [label appendString:[NSString stringWithFormat:@" (%@)", countString.copy]];
            
            text = [[NSAttributedString alloc] initWithString:label.copy
                                                   attributes:textAttributes];
            
            if (_usePointSymbols)
            {
                rect = CGRectMake(symbolSize + (margin * 2.0),
                                  ((-rowHeight * (i + 1)) - (verticalOffset * 0.5)),
                                  width, (rowHeight - verticalOffset));
            }
            
            else
            {
                rect = CGRectMake(margin, ((-rowHeight * (i + 1)) - (verticalOffset * 0.5)),
                                  width, (rowHeight - verticalOffset));
            }
            
            path = CGPathCreateWithRect(rect, NULL);
            framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)text);
            frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, text.length), path, NULL);
            
            if (!_usePointSymbols)
            {
                CGSize frameSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0, text.length),
                                                                                NULL, rect.size, NULL);
                
                rect = CGRectMake(width - margin - frameSize.width, rect.origin.y,
                                  frameSize.width, rect.size.height);
                
                path = CGPathCreateWithRect(rect, NULL);
                framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)text);
                frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, text.length), path, NULL);
                
                barAreaWidth = (width - (margin * 3.0) - frameSize.width);
                
                rect = CGRectMake(margin, (-rowHeight * (i + 1) + (rowHeight * 0.15)),
                                  (barAreaWidth * _cells[i].symbolWidth), (rowHeight * 0.7));
                
                if (_useClassColors)
                    CGContextSetFillColorWithColor(context, _cells[i].symbolColor.CGColor);
                
                else
                    CGContextSetFillColorWithColor(context, _symbolDefaultColor.CGColor);
                
                CGContextSetStrokeColorWithColor(context, black);
                CGContextSetLineWidth(context, lineWidth);
                CGContextFillRect(context, rect);
                CGContextStrokeRect(context, rect);
            }

            CTFrameDraw(frame, context);
            
            CFRelease(path);
            CFRelease(framesetter);
            CFRelease(frame);
        }
        
        CFRelease(fontRef);
        
        if (max)
        {
            double avgPctOfMax = 0.0, medianPctOfMax = 0.0, stdDev = 0.0, avgValue = 0.0;
            double sd1Lower = 0.0, sd1Upper = 0.0, sd2Lower = 0.0, sd2Upper = 0.0;
            int middle = 0;
            
            avgValue = (sum / (double)_numCells);
            avgPctOfMax = (avgValue / (double)max);
            middle = ((int)countArray.count / 2);
            
            if (countArray.count % 2)
                medianPctOfMax = ((countArray[middle].intValue) / (CGFloat)max);
            
            else
            {
                int value1 = (countArray[middle].intValue);
                int value2 = (countArray[middle - 1].intValue);
                medianPctOfMax = (((value1 + value2) / 2.0) / (double)max);
            }
            
            for (int i = 0; i < _numCells; i++)
                stdDev += pow((avgValue -_cells[i].count), 2);
            
            stdDev = sqrt(stdDev / (double)_numCells);
            sd1Lower = ((avgValue - stdDev) / (double)max);
            sd1Upper = ((avgValue + stdDev) / (double)max);
            sd2Lower = ((avgValue - (stdDev * 2.0)) / (double)max);
            sd2Upper = ((avgValue + (stdDev * 2.0)) / (double)max);
            
            CGFloat avgXPos = (margin + (barAreaWidth * avgPctOfMax));
            CGFloat medianXPos = (margin + (barAreaWidth * medianPctOfMax));
            CGFloat sd1XPos = (margin + (barAreaWidth * sd1Lower));
            CGFloat sd1Width = (barAreaWidth * (sd1Upper - sd1Lower));
            CGFloat sd2XPos = (margin + (barAreaWidth * sd2Lower));
            CGFloat sd2Width = (barAreaWidth * (sd2Upper - sd2Lower));
            
            rect = CGRectMake(avgXPos, (-height + rowHeight) , border, (height - rowHeight));
            CGContextSetFillColorWithColor(context, red);
            CGContextFillRect(context, rect);
            
            rect = CGRectMake(medianXPos, rect.origin.y, rect.size.width, rect.size.height);
            CGContextSetFillColorWithColor(context, blue);
            CGContextFillRect(context, rect);
            
            rect = CGRectMake(sd1XPos, rect.origin.y, sd1Width, rect.size.height);
            CGContextSetFillColorWithColor(context, stdDevMask);
            CGContextFillRect(context, rect);
            
            rect = CGRectMake(sd2XPos, rect.origin.y, sd2Width, rect.size.height);
            CGContextSetFillColorWithColor(context, stdDevMask);
            CGContextFillRect(context, rect);
        }

        WriteBitmapDataToFile((LPSTR)_outputFile.UTF8String, width, height, colorSpace, bmData);
        //UIImage *image = [UIImage imageWithContentsOfFile:_outputFile];
        
        CGColorSpaceRelease(colorSpace);
        CGContextRelease(context);
        
        rtn = CGSizeMake(width,height);
    }
    
    return rtn;
}

@end
