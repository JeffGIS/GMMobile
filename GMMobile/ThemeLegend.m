//  ThemeLegend.m
//  GMMobile

#import "ThemeLegend.h"
#import "CCodeLibrary/UserDefaults.h"
#import "ThemeLegendMapOverlay.h"
#import "CCodeLibrary/PointInArea.h"
@import CoreText;

#define STD_ROW_HEIGHT 70
#define STD_WIDTH 640
#define STD_BORDER 2
#define STD_FONT_SIZE 48

@implementation ThemeLegend

- (id)init
{
    self = [super init];
    
    if (self)
    {
        self.showSymbolAsBarChart = YES;
        self.title = @"";
        self.outputFile = @"";
        self.outputFactor = 1.0;
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
    another.title = [NSString stringWithString:self.title];
    another.outputFile = [NSString stringWithString:self.outputFile];
    another.titles = [NSMutableArray arrayWithArray:_titles];
    another.currentTitleIndex = _currentTitleIndex;
    another.cells = NSMutableArray.array;
    another.portraitMapOrigin = _portraitMapOrigin;
    another.landscapeMapOrigin = _landscapeMapOrigin;
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
    
    another.outputFile = [NSString stringWithFormat:@"%@/TestFile.bmp", UserDefaults.defaults.localFilePath];
    another.outputFactor = 1.0;
    [another writeThemeLegendToFile];
    
    return another;
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

- (void)setLandscapeMapOrigin:(CGPoint)landscapeMapOrigin
{
    _landscapeMapOrigin = landscapeMapOrigin;
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

- (BOOL)writeThemeLegendToFile
{
    BOOL rtn = NO;
    
    if (_outputFile && _outputFile.length)
    {
        void *bmData = NULL;
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGColorRef white = UIColor.whiteColor.CGColor;
        CGFloat rowHeight =  (STD_ROW_HEIGHT * _outputFactor);
        int width = (STD_WIDTH * _outputFactor);
        int height = (rowHeight * (_numCells + 1));
        CGFloat border = (STD_BORDER * _outputFactor);
        CGFloat fontSize = (STD_FONT_SIZE * _outputFactor);
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
        
        CGContextTranslateCTM(context, 0.0, rowHeight);
        CGContextScaleCTM(context, 1.0, -1.0);
        
        CTFontRef fontRef = CTFontCreateWithName((CFStringRef)@"AppleSDGothicNeo-Bold", fontSize, NULL);
        CGRect fontRect = CTFontGetBoundingBox(fontRef);
        CGFloat verticalOffset = (rowHeight - fontRect.size.height);
        rect = CGRectMake(0.0, 0.0, width, (rowHeight - verticalOffset));
        CGPathRef path = CGPathCreateWithRect(rect, NULL);
        NSMutableParagraphStyle *style = NSParagraphStyle.defaultParagraphStyle.mutableCopy;
        style.alignment = NSTextAlignmentCenter;
        
        NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                        (__bridge id)fontRef, kCTFontAttributeName,
                                        style, kCTParagraphStyleAttributeName,
                                        white, kCTForegroundColorAttributeName, nil];
        
        CFRelease(fontRef);
        
        NSAttributedString *text = [[NSAttributedString alloc] initWithString:_title
                                                                   attributes:textAttributes];
        
        CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)text);
        CTFrameRef frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, text.length), path, NULL);
        CTFrameDraw(frame, context);
        CFRelease(frame);
        CFRelease(framesetter);
  
        WriteBitmapDataToFile((LPSTR)_outputFile.UTF8String, width, height, colorSpace, bmData);
        UIImage *image = [UIImage imageWithContentsOfFile:_outputFile];
        
        rtn = YES;
    }
    
    return rtn;
}

@end

