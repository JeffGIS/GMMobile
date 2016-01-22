///  MGThemesVC.m
//  GMMobile

#import "MGThemesVC.h"
#import "CCodeLibrary/UserDefaults.h"
#import "ConfigurationControl.h"
#import "CCodeLibrary/UIImage+ImageFromColor.h"
#import "SymbolDictionary.h"
#import "MapViewController.h"
#import "CCodeLibrary/UserDefaults.h"

@interface MGThemesVC () <UITableViewDataSource,UITableViewDelegate,UIGestureRecognizerDelegate>

@property (weak, nonatomic) IBOutlet UITableView *topLeftTV;
@property (weak, nonatomic) IBOutlet UITableView *topRightTV;
@property (weak, nonatomic) IBOutlet UITableView *bottomLeftTV;
@property (weak, nonatomic) IBOutlet UITableView *bottomRightTV;

@property (nonatomic) CGFloat rowHeight, headerHeight, cornerRadius;
@property (nonatomic) UIFont *font, *headerFont;
@property (nonatomic) NSMutableArray *legends, *countLengths;
@property (nonatomic) MapViewController *mapVC;
@property (nonatomic) NSMutableArray *dragSelectedCells;
@property BOOL dragSelectActive, preventRefresh, firstTimeDrag;
@property NSUInteger currentRow, currentColorPalette;

@end

@implementation MGThemesVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _legends = ConfigurationControl.sharedInstance.legendList;
    self.view.backgroundColor = UserDefaults.defaults.appleBlue;
    _mapVC = (MapViewController *)CRAPI.sharedInstance.mapVC;
    _currentRow = _currentColorPalette = 0;
    
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
    {
        _headerHeight = 20.0;
        _cornerRadius = 4.0;
        
        _font = [UIFont fontWithName:@"CourierNewPS-BoldMT"
                                size:14.0];
        
        _headerFont = [UIFont boldSystemFontOfSize:14.0];
    }
    
    else
    {
        _headerHeight = 40.0;
        _cornerRadius = 10.0;
        
        _font = [UIFont fontWithName:@"CourierNewPS-BoldMT"
                                size:24.0];
        
        _headerFont = [UIFont boldSystemFontOfSize:28.0];
    }
    
    [self setupTableView:_topLeftTV
                     tag:1];
    
    [self setupTableView:_topRightTV
                     tag:2];
    
    [self setupTableView:_bottomLeftTV
                     tag:1];
    
    [self setupTableView:_bottomRightTV
                     tag:2];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    _legends = ConfigurationControl.sharedInstance.legendList;
    _countLengths = NSMutableArray.array;
    
    for (int i = 0; i < _legends.count; i++)
    {
        ThemeLegend *tl = (ThemeLegend *)_legends[i];
        NSUInteger length = 0;
        
        for (ThemeLegendCell *cells in tl.cells)
        {
            NSString *countString = [NSString stringWithFormat:@"%i", cells.count];
            length = MAX(length, countString.length);
        }
        
        [_countLengths insertObject:@(length)
                            atIndex:i];
    }
    
    [self reloadTableViews];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)reloadTableViews
{
    [_topRightTV reloadData];
    [_topLeftTV reloadData];
    [_bottomRightTV reloadData];
    [_bottomLeftTV reloadData];
}

- (void)setupTableView:(UITableView *)tableView
                   tag:(NSUInteger)tag
{
    tableView.delegate = self;
    tableView.dataSource = self;
    tableView.backgroundColor = UIColor.grayColor;
    tableView.bounces = NO;
    tableView.layer.borderColor = UIColor.blackColor.CGColor;
    tableView.layer.borderWidth = (_cornerRadius / 4.0);
    tableView.layer.cornerRadius = _cornerRadius;
    tableView.delaysContentTouches = NO;
    tableView.allowsMultipleSelection = YES;
    tableView.separatorColor = UIColor.clearColor;
    tableView.separatorInset = UIEdgeInsetsZero;
    tableView.tag = tag;
    
    UILongPressGestureRecognizer *lpgr = [[UILongPressGestureRecognizer alloc]
                                          initWithTarget:self
                                          action:@selector(tlmoLongPressed:)];
    
    lpgr.minimumPressDuration = 1.0;
    lpgr.delegate = self;
    [tableView addGestureRecognizer:lpgr];
}

- (void)tlmoLongPressed:(UILongPressGestureRecognizer *)gesture
{
    UITableView *tv = (UITableView *)gesture.view;
    
    switch (gesture.state)
    {
        case UIGestureRecognizerStateEnded:
        {
            _dragSelectActive = NO;
            
            for (NSIndexPath *indexPaths in _dragSelectedCells)
            {
                UITableViewCell *cell = [tv cellForRowAtIndexPath:indexPaths];
                cell.backgroundColor = UIColor.whiteColor;
                cell.selectionStyle = UITableViewCellSelectionStyleGray;
                
                if (cell.selected)
                {
                    [self tableView:tv
          didDeselectRowAtIndexPath:indexPaths];
                }
                
                else
                {
                    [self tableView:tv
            didSelectRowAtIndexPath:indexPaths];
                }
                
                cell.selected = !cell.selected;
            }
            
            _mapVC.fromIndex = self.tabBarController.selectedIndex;
            _mapVC.fromLegends = YES;
            self.tabBarController.selectedIndex = 0;
            _preventRefresh = NO;
        }
            break;
            
        case UIGestureRecognizerStateBegan:
        {
            _dragSelectActive = _preventRefresh = YES;
            _dragSelectedCells = NSMutableArray.array;
            _firstTimeDrag = YES;
        }
            
        default:
        {
            CGPoint point = [gesture locationInView:tv];
            CGPoint superpoint = [gesture locationInView:self.view];
            
            if (CGRectContainsPoint(tv.frame, superpoint))
            {
                NSUInteger row = (NSUInteger)((point.y - _headerHeight) / tv.rowHeight);
                
                if (_firstTimeDrag)
                {
                    _currentRow = row;
                    _firstTimeDrag = NO;
                }
                
                else if (row != _currentRow)
                {
                    _currentRow = row;
                }
                
                else
                    return;
                
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:_currentRow
                                                            inSection:0];
                
                if (![_dragSelectedCells containsObject:indexPath])
                {
                    UITableViewCell *cell = [tv cellForRowAtIndexPath:indexPath];
                    cell.backgroundColor = UserDefaults.defaults.lightBlue;
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;
                    [_dragSelectedCells addObject:indexPath];
                }
                
                else
                {
                    indexPath = (NSIndexPath *)_dragSelectedCells.lastObject;
                    UITableViewCell *cell = [tv cellForRowAtIndexPath:indexPath];
                    cell.backgroundColor = UIColor.whiteColor;
                    cell.selectionStyle = UITableViewCellSelectionStyleGray;
                    [_dragSelectedCells removeObject:indexPath];
                }
            }
        }
            break;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    ThemeLegend *tl = (ThemeLegend *)_legends[tableView.tag - 1];
    tableView.rowHeight = (CGFloat)((tableView.frame.size.height - _headerHeight) / tl.numCells);
    return (NSInteger)tl.numCells;
}

- (CGFloat)tableView:(UITableView *)tableView
heightForHeaderInSection:(NSInteger)section
{
    return _headerHeight;
}

- (UIView *)tableView:(UITableView *)tableView
viewForHeaderInSection:(NSInteger)section
{
    ThemeLegend *tl = (ThemeLegend *)_legends[tableView.tag - 1];
    
    CGFloat margin = 48.0;
    
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
    {
        margin = 16.0;
        
        if (UIApplication.sharedApplication.statusBarOrientation == UIDeviceOrientationLandscapeLeft ||
            UIApplication.sharedApplication.statusBarOrientation == UIDeviceOrientationLandscapeRight)
        {
            margin = 12.0;
        }
    }
    
    CGFloat tvWidth = ((self.view.frame.size.width - margin) / 2.0);
    
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, tvWidth, _headerHeight)];
    headerView.backgroundColor = UIColor.blackColor;
    headerView.contentMode = UIViewContentModeCenter;
    
    if (![headerView.subviews containsObject:[headerView viewWithTag:(tableView.tag * 333)]])
    {
        UIButton *titleButton = [[UIButton alloc] initWithFrame:headerView.frame];
        titleButton.titleLabel.textAlignment = NSTextAlignmentCenter;
        titleButton.titleLabel.font = _headerFont;
        titleButton.tag = (tableView.tag * 333);
        
        [titleButton setTitleColor:UIColor.whiteColor
                          forState:UIControlStateNormal];
        
        if (tl.titles.count > 1 || tl.hasColors)
        {
            [titleButton setTitleColor:UIColor.greenColor
                              forState:UIControlStateHighlighted];
            
            [titleButton addTarget:self
                            action:@selector(showLegendOptions:)
                  forControlEvents:UIControlEventTouchUpInside];
        }
        
        else
        {
            [titleButton setTitleColor:UIColor.redColor
                              forState:UIControlStateHighlighted];
        }
        
        [titleButton setTitle:tl.title
                     forState:UIControlStateNormal];
        
        [headerView addSubview:titleButton];
    }
    
    if (![headerView.subviews containsObject:[headerView viewWithTag:(tableView.tag * 111)]])
    {
        UIButton *addToMap = [UIButton buttonWithType:UIButtonTypeCustom];
        addToMap.tag = (tableView.tag * 111);
        addToMap.imageView.contentMode = UIViewContentModeScaleAspectFit;
        addToMap.imageEdgeInsets = UIEdgeInsetsMake(2.0, 2.0, 2.0, 2.0);
        addToMap.selected = tl.drawOnMap;
        
        addToMap.frame = CGRectMake((headerView.frame.size.width - (headerView.frame.size.height * 2.0)), 0.0,
                                    (headerView.frame.size.height * 2.0), headerView.frame.size.height);
        
        [addToMap setImage:[UIImage imageWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"greenPlusSign"
                                                                                          ofType:@"png"]]
                  forState:UIControlStateNormal];
        
        [addToMap setImage:[UIImage imageWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"redMinusSign"
                                                                                          ofType:@"png"]]
                  forState:UIControlStateSelected];
        
        [addToMap addTarget:self
                     action:@selector(addLegend:)
           forControlEvents:UIControlEventTouchUpInside];
        
        [headerView addSubview:addToMap];
    }
    
    return headerView;
}

- (void)showLegendOptions:(UIButton *)button
{
    ThemeLegend *tl = _legends[(button.tag / 333) - 1];
    self.tabBarController.tabBar.userInteractionEnabled = NO;
    
    [UIView animateWithDuration:0.25
                     animations:^{
                         self.tabBarController.tabBar.alpha = 0.3;
                     }];
    
    NSMutableArray *textArray = NSMutableArray.array;
    [textArray addObject:@"Cancel"];
    [textArray addObject:@"Color Symbols\nUsing Exising Colors\nFor This Legend"];
    [textArray addObject:@"Color Symbols\nBy Selecting Colors\nFor This Legend"];
    
    
    if (tl.titles.count > 1)
        [textArray addObject:@"Select Legend Title"];
    
    NVAlertView *alert = [NVAlertView showLargeAlertViewinView:self.view
                                                      delegate:self
                                                         title:[NSString stringWithFormat:@"Legend Options for\n%@",
                                                                tl.title]
                                               buttonTextArray:textArray
                                              destructiveIndex:1];
    
    alert.identifier = @"TopLevelAlert";
    alert.tag = button.tag;
}

- (void)alertView:(NVAlertView *)alertView
didTapButtonAtIndex:(NSInteger)buttonIndex
{
    NSUInteger index = ((alertView.tag / 333) - 1);
    ThemeLegend *tl = (ThemeLegend *)_legends[index];
    
    [alertView hideLargeAlertView:YES];
    
    if (buttonIndex > 0)
    {
        if ([alertView.identifier isEqualToString:@"TopLevelAlert"])
        {
            if (buttonIndex == 1)//Apply Existing Colors
            {
                
            }
            
            if (buttonIndex == 2)//Select Colors Option
            {
                NVAlertView *alert = [NVAlertView showLargeAlertViewinView:alertView.superview
                                                                  delegate:self
                                                                     title:@"Select Color Scheme"
                                                           buttonTextArray:NVColorSet.colorOptions
                                                          destructiveIndex:1];
                
                alert.identifier = @"ColorOptionsAlert";
                alert.tag = alertView.tag;
            }
            
            else if (buttonIndex == 3)//Titles Option
            {
                NSMutableArray *textArray = NSMutableArray.array;
                [textArray addObject:@"Cancel"];
                [textArray addObjectsFromArray:tl.titles.copy];
                
                NVAlertView *alert = [NVAlertView showLargeAlertViewinView:alertView.superview
                                                                  delegate:self
                                                                     title:@"Select Legend Title"
                                                           buttonTextArray:textArray
                                                          destructiveIndex:1];
                
                alert.identifier = @"TitlesAlert";
                alert.tag = alertView.tag;
            }
            
            return;
        }
        
        else if ([alertView.identifier isEqualToString:@"TitlesAlert"])
        {
            tl.currentTitleIndex = (int)(buttonIndex - 1);
            [self reloadTableViews];
        }
        
        else if ([alertView.identifier isEqualToString:@"ColorOptionsAlert"])
        {
            switch (buttonIndex)
            {
                case NVColorOptionReds:
                {
                    NSArray *colorArray = [NVColorSet redsArrayWithNumComponents:tl.numCells];
                    
                    for (int i = 0; i < tl.numCells; i++)
                    {
                        ThemeLegendCell *tlc = (ThemeLegendCell *)tl.cells[i];
                        tlc.symbolColor = (NVColor *)colorArray[i];
                    }
                    
                    [self reloadTableViews];
                }
                    break;
                    
                case NVColorOptionGreens:
                {
                    NSArray *colorArray = [NVColorSet greensArrayWithNumComponents:tl.numCells];
                    
                    for (int i = 0; i < tl.numCells; i++)
                    {
                        ThemeLegendCell *tlc = (ThemeLegendCell *)tl.cells[i];
                        tlc.symbolColor = (NVColor *)colorArray[i];
                    }
                    
                    [self reloadTableViews];
                }
                    break;
                    
                case NVColorOptionBlues:
                {
                    NSArray *colorArray = [NVColorSet bluesArrayWithNumComponents:tl.numCells];
                    
                    for (int i = 0; i < tl.numCells; i++)
                    {
                        ThemeLegendCell *tlc = (ThemeLegendCell *)tl.cells[i];
                        tlc.symbolColor = (NVColor *)colorArray[i];
                    }
                    
                    [self reloadTableViews];
                }
                    break;
                    
                case NVColorOptionRandom:
                {
                    NVAlertView *alert = [NVAlertView showLargeAlertViewinView:alertView.superview
                                                                      delegate:self
                                                                         title:@"Select Color Palette"
                                                               buttonTextArray:NVColorSet.randomColorPaletteOptions
                                                              destructiveIndex:1];
                    
                    alert.identifier = @"RandomColorAlert";
                    alert.tag = alertView.tag;
                    return;
                }
                    break;
                    
                case NVColorOptionCustom:
                    break;
                    
                default:
                    break;
            }
        }
        
        else if ([alertView.identifier isEqualToString:@"RandomColorAlert"] ||
                 [alertView.identifier isEqualToString:@"RandomColorConfirmation"])
        {
            
            if ([alertView.identifier isEqualToString:@"RandomColorAlert"])
                _currentColorPalette = buttonIndex;
            
            NSArray *colorArray = [NVColorSet randomColorArrayOfType:_currentColorPalette
                                                       numComponents:tl.numCells];
            
            for (int i = 0; i < tl.numCells; i++)
            {
                ThemeLegendCell *tlc = (ThemeLegendCell *)tl.cells[i];
                tlc.symbolColor = (NVColor *)colorArray[i];
            }
            
            [self reloadTableViews];
            
            NVAlertView *alert = [NVAlertView showLargeAlertViewinView:self.view
                                                              delegate:self
                                                                 title:@"Confirm Random Color Selection"
                                                       buttonTextArray:@[@"OK", @"Try Again"]
                                                      destructiveIndex:0];
            
            alert.overlayView.backgroundColor = UIColor.clearColor;
            alert.backgroundColor = NVColor.gainsboroColor;
            alert.layer.borderColor = UIColor.blackColor.CGColor;
            alert.layer.borderWidth = 2.0;
            alert.buttonBorderColor = UIColor.grayColor;
            alert.identifier = @"RandomColorConfirmation";
            alert.tag = alertView.tag;
        }
    }
    
    [UIView animateWithDuration:0.25
                     animations:^{
                         self.tabBarController.tabBar.alpha = 1.0;
                     }];
    
    self.tabBarController.tabBar.userInteractionEnabled = YES;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"
                                                            forIndexPath:indexPath];
    
    if (!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:@"Cell"];
    }
    
    ThemeLegend *tl = (ThemeLegend *)_legends[tableView.tag - 1];
    ThemeLegendCell *tlc = (ThemeLegendCell *)tl.cells[indexPath.row];
    
    NSMutableString *text = tlc.label.mutableCopy;
    
    if (tl.appendClassCount)
    {
        NSMutableString *countString = NSMutableString.string;
        
        if (tlc.status)
        {
            [countString insertString:@"X"
                              atIndex:0];
        }
        
        else
        {
            [countString insertString:[NSString stringWithFormat:@"%i", tlc.count]
                              atIndex:0];
        }
        
        while (countString.length < [_countLengths[(tableView.tag - 1)] integerValue])
        {
            if (tlc.status)
            {
                [countString insertString:@"X"
                                  atIndex:0];
            }
            
            else
            {
                [countString insertString:@" "
                                  atIndex:0];
            }
        }
        
        [text appendString:[NSString stringWithFormat:@" (%@)", countString.copy]];
    }
    
    cell.layer.borderColor = UIColor.blackColor.CGColor;
    cell.layer.borderWidth = 0.5;
    cell.contentView.backgroundColor = UIColor.clearColor;
    cell.textLabel.backgroundColor = UIColor.clearColor;
    cell.textLabel.textColor = UIColor.blackColor;
    cell.textLabel.font = _font;
    cell.textLabel.text = text.copy;
    cell.textLabel.textAlignment = NSTextAlignmentLeft;
    cell.textLabel.adjustsFontSizeToFitWidth = YES;
    
    CGFloat symbolSize = 52.0;
    
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
        symbolSize = 28.0;
    
    if (tl.usePointSymbols)
        cell.imageView.image = imageFromSymbol(tlc.symbol, symbolSize, tlc.symbolColor);
    
    return cell;
}

- (void)tableView:(UITableView *)tableView
  willDisplayCell:(UITableViewCell *)cell
forRowAtIndexPath:(NSIndexPath *)indexPath
{
    ThemeLegend *tl = (ThemeLegend *)_legends[tableView.tag - 1];
    ThemeLegendCell *tlc = (ThemeLegendCell *)tl.cells[indexPath.row];
    
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
    if (!_dragSelectActive)
    {
        ThemeLegend *tl = (ThemeLegend *)_legends[tableView.tag - 1];
        ThemeLegendCell *tlc = (ThemeLegendCell *)tl.cells[indexPath.row];
        tlc.status = YES;
        
        if (!_preventRefresh)
        {
            _mapVC.fromIndex = self.tabBarController.selectedIndex;
            _mapVC.fromLegends = YES;
            self.tabBarController.selectedIndex = 0;
        }
    }
}

- (void)tableView:(UITableView *)tableView
didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (!_dragSelectActive)
    {
        ThemeLegend *tl = (ThemeLegend *)_legends[tableView.tag - 1];
        ThemeLegendCell *tlc = (ThemeLegendCell *)tl.cells[indexPath.row];
        tlc.status = NO;
        
        if (!_preventRefresh)
        {
            _mapVC.fromIndex = self.tabBarController.selectedIndex;
            _mapVC.fromLegends = YES;
            self.tabBarController.selectedIndex = 0;
        }
    }
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
                                duration:(NSTimeInterval)duration
{
    [self reloadTableViews];
    
    for (NVAlertView *alert in self.view.subviews)
    {
        if ([alert isKindOfClass:NVAlertView.class])
        {
            [self.view bringSubviewToFront:alert];
            [alert willRotateWithDuration:duration];
        }
    }
}

- (void)addLegend:(UIButton *)button
{
    ThemeLegend *tl = _legends[(button.tag / 111) - 1];
    
    if (!button.selected)
        tl.drawOnMap = button.selected = YES;
    
    else
        tl.drawOnMap = button.selected = NO;
}


@end