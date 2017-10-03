//  ThemeLegend.m
//  GMMobile

#import "ThemeLegend.h"
#import "CCodeLibrary/UserDefaults.h"
#import "ThemeLegendMapOverlay.h"

@implementation ThemeLegend

- (id)init
{
    self = [super init];
    
    if (self)
    {
        _showSymbolAsBarChart = YES;
        self.title = @"";
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

@end
