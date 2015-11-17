//  ThemeLegendMapOverlay.m
//  GMMobile

#import "ThemeLegendMapOverlay.h"
#import "SymbolDictionary.h"
#import "CCodeLibrary/UIImage+ImageFromColor.h"

@interface ThemeLegendMapOverlay ()

@property (nonatomic) CGFloat rowHeight;
@property (nonatomic) UITableView *tableView;
@property (nonatomic) UIFont *font, *headerFont;
@property (nonatomic) NSUInteger countLength;
@property BOOL isExpanded, selectionMade;
@property (nonatomic) UITabBar *tabBar;
@property (nonatomic) CGRect previousFrame;

@end

@implementation ThemeLegendMapOverlay

+ (ThemeLegendMapOverlay *)drawLegend:(ThemeLegend *)legend
                              withTag:(NSInteger)tag
                             delegate:(id)delegate
                               inView:(UIView *)view
                             atOrigin:(CGPoint)origin
                               tabBar:(UITabBar *)tabBar
{
    ThemeLegendMapOverlay *tlmo = [[ThemeLegendMapOverlay alloc] init];
    tlmo.legend = legend;
    tlmo.backgroundColor = UIColor.clearColor;
    tlmo.tag = tag;
    tlmo.isExpanded = tlmo.selectionMade = NO;
    tlmo.rowHeight = 26.0;
    tlmo.delegate = delegate;
    tlmo.tabBar = tabBar;
    
    tlmo.font = [UIFont fontWithName:@"CourierNewPS-BoldMT"
                                size:18.0];
    
    tlmo.headerFont = [UIFont boldSystemFontOfSize:18.0];
    
    for (ThemeLegendCell *cells in tlmo.legend.cells)
    {
        NSString *countString = [NSString stringWithFormat:@"%i", cells.count];
        tlmo.countLength = MAX(tlmo.countLength, countString.length);
    }
    
    CGFloat height = MIN(((tlmo.legend.numCells + 1) * tlmo.rowHeight), 143.0);
    CGFloat width = 232.0;
    
    tlmo.frame = CGRectMake(origin.x, origin.y, width, height);
    
    tlmo.tableView = [[UITableView alloc] initWithFrame:tlmo.bounds
                                                  style:UITableViewStylePlain];
    
    tlmo.tableView.delegate = tlmo;
    tlmo.tableView.dataSource = tlmo;
    tlmo.tableView.backgroundColor = UIColor.blackColor;
    tlmo.tableView.rowHeight = tlmo.rowHeight;
    tlmo.tableView.bounces = YES;
    tlmo.tableView.bouncesZoom = YES;
    tlmo.tableView.layer.borderColor = UIColor.blackColor.CGColor;
    tlmo.tableView.layer.borderWidth = 2.0;
    tlmo.tableView.delaysContentTouches = NO;
    tlmo.tableView.allowsMultipleSelection = YES;
    tlmo.tableView.separatorColor = UIColor.clearColor;
    tlmo.tableView.separatorInset = UIEdgeInsetsZero;
    tlmo.tableView.layoutMargins = UIEdgeInsetsZero;
    
    [tlmo addSubview:tlmo.tableView];
    [view addSubview:tlmo];
    
    return tlmo;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    return (NSInteger)_legend.numCells;
}

- (CGFloat)tableView:(UITableView *)tableView
heightForHeaderInSection:(NSInteger)section
{
    return _rowHeight;
}

- (UIView *)tableView:(UITableView *)tableView
viewForHeaderInSection:(NSInteger)section
{
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, tableView.frame.size.width, _rowHeight)];
    headerView.backgroundColor = UIColor.blackColor;
    headerView.contentMode = UIViewContentModeCenter;
    
    UILabel *headerLabel = [[UILabel alloc] initWithFrame:headerView.frame];
    headerLabel.font = _headerFont;
    headerLabel.textColor = UIColor.whiteColor;
    headerLabel.textAlignment = NSTextAlignmentCenter;
    headerLabel.text = _legend.title;
    
    [headerView addSubview:headerLabel];
    
    if (![headerView.subviews containsObject:[headerView viewWithTag:(self.tag * 111)]])
    {
        UIButton *addToMap = [UIButton buttonWithType:UIButtonTypeCustom];
        addToMap.tag = (self.tag * 111);
        addToMap.imageView.contentMode = UIViewContentModeScaleAspectFit;
        addToMap.imageEdgeInsets = UIEdgeInsetsMake(2.0, 2.0, 2.0, 2.0);
        addToMap.selected = _isExpanded;
        
        addToMap.frame = CGRectMake((headerView.frame.size.width - (headerView.frame.size.height * 2.0)), 0.0,
                                    (headerView.frame.size.height * 2.0), headerView.frame.size.height);
        
        [addToMap setImage:[UIImage imageWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"resizeOut"
                                                                                          ofType:@"png"]]
                  forState:UIControlStateNormal];
        
        [addToMap setImage:[UIImage imageWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"resizeIn"
                                                                                          ofType:@"png"]]
                  forState:UIControlStateSelected];
        
        [addToMap addTarget:self
                     action:@selector(expandLegend:)
           forControlEvents:UIControlEventTouchUpInside];
        
        [headerView addSubview:addToMap];
    }
    
    return headerView;
}

- (void)expandLegend:(UIButton *)button
{
    if (!_isExpanded)
    {
        UIView *overlayView = [[UIView alloc] initWithFrame:self.superview.frame];
        overlayView.backgroundColor = UIColor.blackColor;
        overlayView.alpha = 0.0;
        overlayView.tag = 123456789;
        [self.superview addSubview:overlayView];
        [self.superview bringSubviewToFront:self];
        
        _previousFrame = self.frame;
        CGSize superSize = self.superview.frame.size;
        _rowHeight *= 2.0;
        _tableView.rowHeight = _rowHeight;
        _tableView.scrollEnabled = NO;
        _tabBar.userInteractionEnabled = NO;
        CGFloat height = ((_legend.numCells + 1) * _rowHeight);
        
        _font = [UIFont fontWithName:@"CourierNewPS-BoldMT"
                                size:36.0];
        
        _headerFont = [UIFont boldSystemFontOfSize:36.0];
        
        [UIView animateWithDuration:0.25
                         animations:^{
                             overlayView.alpha = 0.6;
                             _tabBar.alpha = 0.4;
                             
                             self.frame = CGRectMake((superSize.width * 0.1), ((superSize.height - height) / 2.0),
                                                     (superSize.width * 0.8), height);
                             
                             _tableView.frame = self.bounds;
                             
                         } completion:^(BOOL finished) {
                             [_tableView reloadData];
                             _isExpanded = YES;
                             button.selected = YES;
                         }];
    }
    
    else
    {
        UIView *overlayView = [self.superview viewWithTag:123456789];
        _tabBar.userInteractionEnabled = YES;
        _rowHeight /= 2.0;
        _tableView.rowHeight = _rowHeight;
        _tableView.scrollEnabled = YES;
        
        _font = [UIFont fontWithName:@"CourierNewPS-BoldMT"
                                size:18.0];
        
        _headerFont = [UIFont boldSystemFontOfSize:18.0];
        
        [UIView animateWithDuration:0.25
                         animations:^{
                             overlayView.alpha = 0.0;
                             _tabBar.alpha = 1.0;
                             self.frame = _previousFrame;
                             _tableView.frame = self.bounds;
                             
                         } completion:^(BOOL finished) {
                             [overlayView removeFromSuperview];
                             [_tableView reloadData];
                             _isExpanded = NO;
                             button.selected = NO;
                             
                             if (_selectionMade)
                             {
                                 [_delegate themeLegendDidChangeStatus];
                                 _selectionMade = NO;
                             }
                         }];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellID = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    
    if (!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:cellID];
    }
    
    for (UIView *views in cell.contentView.subviews)
    {
        if (views.tag == 666 || views.tag == 777 || views.tag == 888)
            [views removeFromSuperview];
    }
    
    ThemeLegendCell *tlc = (ThemeLegendCell *)_legend.cells[indexPath.row];
    
    NSMutableString *text = tlc.label.mutableCopy;
        
    if (_legend.appendClassCount)
    {
        NSMutableString *countString = [NSString stringWithFormat:@"%i", tlc.count].mutableCopy;
        
        while (countString.length < _countLength)
        {
            [countString insertString:@" "
                              atIndex:0];
        }
        
        [text appendString:[NSString stringWithFormat:@" (%@)", countString.copy]];
    }
    
    UILabel *textLabel = [[UILabel alloc] init];
    textLabel.textColor = UIColor.blackColor;
    textLabel.font = _font;
    textLabel.text = text.copy;
    textLabel.textAlignment = NSTextAlignmentLeft;
    textLabel.adjustsFontSizeToFitWidth = YES;
    textLabel.tag = 888;
    
    cell.layer.borderColor = UIColor.blackColor.CGColor;
    cell.layer.borderWidth = 0.5;
    
    NSDictionary *attributes = @{NSFontAttributeName:_font};
    
    CGRect textSize = [text boundingRectWithSize:self.frame.size
                                         options:NSStringDrawingUsesLineFragmentOrigin
                                      attributes:attributes
                                         context:nil];
    
    CGFloat textWidth = ceil(textSize.size.width);
    CGFloat textOriginX = MAX((tableView.frame.size.width - textWidth), 4.0);
    
    if (_legend.usePointSymbols)
    {
        CGFloat imageSize = (_rowHeight * 0.7);
        
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(4.0, (_rowHeight * 0.15),
                                                                               imageSize, imageSize)];
        
        imageView.image = imageFromSymbol(tlc.symbol, imageSize, _legend.symbolDefaultColor);
        imageView.tag = 777;
        [cell.contentView addSubview:imageView];
        
        textOriginX = MAX(textOriginX, ((imageView.frame.origin.x + imageView.frame.size.width) + 4.0));
    }
    
    textWidth = MIN(textWidth, (tableView.frame.size.width - textOriginX));
    textLabel.frame = CGRectMake(textOriginX, 0.0, textWidth, _rowHeight);
    [cell.contentView addSubview:textLabel];
    
    if (!_legend.usePointSymbols)
    {
        CGFloat barMargin = 4.0;
        CGFloat barWidth = (((tableView.frame.size.width - textWidth) - (barMargin * 2.0)) * tlc.symbolWidth);
        
        UIImageView *barView = [[UIImageView alloc] initWithFrame:
                                CGRectMake(barMargin, (_rowHeight * 0.15), barWidth, (_rowHeight * 0.7))];
        
        if (_legend.useClassColors)
            barView.image = [UIImage imageFromColor:tlc.symbolColor];
        
        else
            barView.image = [UIImage imageFromColor:_legend.symbolDefaultColor];
        
        barView.layer.borderColor = UIColor.blackColor.CGColor;
        barView.layer.borderWidth = 1.0;
        barView.tag = 666;
        [cell.contentView addSubview:barView];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView
  willDisplayCell:(UITableViewCell *)cell
forRowAtIndexPath:(NSIndexPath *)indexPath
{
    ThemeLegendCell *tlc = (ThemeLegendCell *)_legend.cells[indexPath.row];
    
    if (tlc.status)
    {
        [tableView selectRowAtIndexPath:indexPath
                               animated:NO
                         scrollPosition:UITableViewScrollPositionNone];
    }
}

- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    ThemeLegendCell *tlc = (ThemeLegendCell *)_legend.cells[indexPath.row];
    tlc.status = YES;
    
    if (_delegate)
    {
        if (!_isExpanded)
            [_delegate themeLegendDidChangeStatus];
        
        else
            _selectionMade = YES;
    }
}

- (void)tableView:(UITableView *)tableView
didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    ThemeLegendCell *tlc = (ThemeLegendCell *)_legend.cells[indexPath.row];
    tlc.status = NO;
    
    if (!_isExpanded)
        [_delegate themeLegendDidChangeStatus];
    
    else
        _selectionMade = YES;
}

@end