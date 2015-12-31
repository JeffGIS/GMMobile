//  CrimeOptions1.m
//  GMMobile

#import "CrimeOptions1.h"
#import "CCodeLibrary/UserDefaults.h"
#import "ConfigurationControl.h"
#import "SymbolDictionary.h"
#import "MapViewController.h"
#import "CCodeLibrary/UserDefaults.h"

@interface CrimeOptions1 ()

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *deptView;

@property (nonatomic) NSMutableArray *legends;
@property (nonatomic) NSUInteger countLength;
@property (nonatomic) UIFont *font, *headerFont;
@property (nonatomic) CGFloat headerHeight, cornerRadius;
@property (nonatomic) UIButton *deptHeaderView;
@property (nonatomic) MapViewController *mapVC;
@property (nonatomic) NSMutableArray *dragSelectedCells;
@property BOOL dragSelectActive, preventRefresh, firstTimeDrag;
@property NSUInteger currentRow, currentColorPalette;

@end

@implementation CrimeOptions1

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _legends = ConfigurationControl.sharedInstance.legendList;
    self.view.backgroundColor = UserDefaults.defaults.appleBlue;
    _countLength = 0;
    _mapVC = (MapViewController *)CRAPI.sharedInstance.mapVC;
    _dragSelectActive = _preventRefresh = _firstTimeDrag = NO;
    _currentRow = _currentColorPalette = 0;
    
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
    {
        _headerHeight = 24.0;
        _cornerRadius = 4.0;
        
        _font = [UIFont fontWithName:@"CourierNewPS-BoldMT"
                                size:14.0];
        
        _headerFont = [UIFont boldSystemFontOfSize:18.0];
    }
    
    else
    {
        _headerHeight = 40.0;
        _cornerRadius = 10.0;
        
        _font = [UIFont fontWithName:@"CourierNewPS-BoldMT"
                                size:24.0];
        
        _headerFont = [UIFont boldSystemFontOfSize:28.0];
    }
    
    [self setupTableView];
    [self setupDeptView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    _legends = ConfigurationControl.sharedInstance.legendList;
    ThemeLegend *tl = (ThemeLegend *)_legends[0];
    
    for (ThemeLegendCell *cells in tl.cells)
    {
        NSString *countString = [NSString stringWithFormat:@"%i", cells.count];
        _countLength = MAX(_countLength, countString.length);
    }
    
    [_tableView reloadData];
    [self.view layoutIfNeeded];
    
    [self setupDeptViewComponents:_deptView.frame.size.width];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)setupDeptView
{
    ThemeLegend *tl = (ThemeLegend *)_legends[1];
    
    _deptView.backgroundColor = UIColor.whiteColor;
    _deptView.layer.cornerRadius = _cornerRadius;
    _deptView.layer.borderColor = UIColor.blackColor.CGColor;
    _deptView.layer.borderWidth =  (_cornerRadius / 4.0);
    _deptView.clipsToBounds = YES;
    
    _deptHeaderView = [[UIButton alloc] init];
    _deptHeaderView.titleLabel.textAlignment = NSTextAlignmentCenter;
    _deptHeaderView.titleLabel.font = _headerFont;
    _deptHeaderView.backgroundColor = UIColor.blackColor;
    _deptHeaderView.tag = 222;
    
    [_deptHeaderView setTitleColor:UIColor.whiteColor
                          forState:UIControlStateNormal];
    
    if (tl.titles.count > 1 || tl.hasColors)
    {
        [_deptHeaderView setTitleColor:UIColor.greenColor
                              forState:UIControlStateHighlighted];
        
        [_deptHeaderView addTarget:self
                            action:@selector(showLegendOptions:)
                  forControlEvents:UIControlEventTouchUpInside];
    }
    
    else
    {
        [_deptHeaderView setTitleColor:UIColor.redColor
                          forState:UIControlStateHighlighted];
    }
    
    [_deptHeaderView setTitle:tl.title
                     forState:UIControlStateNormal];
    
    if (![_deptView.subviews containsObject:[_deptView viewWithTag:222]])
        [_deptView addSubview:_deptHeaderView];
    
    if (![_deptHeaderView.subviews containsObject:[_deptHeaderView viewWithTag:7777]])
    {
        UIButton *addToMap = [UIButton buttonWithType:UIButtonTypeCustom];
        addToMap.tag = 7777;
        addToMap.imageView.contentMode = UIViewContentModeScaleAspectFit;
        addToMap.imageEdgeInsets = UIEdgeInsetsMake(2.0, 2.0, 2.0, 2.0);
        addToMap.selected = tl.drawOnMap;
        
        [addToMap setImage:[UIImage imageWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"greenPlusSign"
                                                                                          ofType:@"png"]]
                  forState:UIControlStateNormal];
        
        [addToMap setImage:[UIImage imageWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"redMinusSign"
                                                                                          ofType:@"png"]]
                  forState:UIControlStateSelected];
        
        [addToMap addTarget:self
                     action:@selector(addLegend:)
           forControlEvents:UIControlEventTouchUpInside];
        
        [_deptHeaderView addSubview:addToMap];
    }
    
    for (int i = 0; i < tl.cells.count; i++)
    {
        UIButton *deptButton = [UIButton buttonWithType:UIButtonTypeCustom];
        deptButton.layer.borderWidth = 0.5;
        deptButton.layer.borderColor = UIColor.blackColor.CGColor;
        deptButton.titleLabel.font = _font;
        deptButton.titleLabel.adjustsFontSizeToFitWidth = YES;
        deptButton.tag = (i + 1);
        
        [deptButton setTitleColor:UIColor.blackColor
                         forState:UIControlStateNormal];
        
        [deptButton addTarget:self
                       action:@selector(deptButtonTapped:)
             forControlEvents:UIControlEventTouchUpInside];
        
        [_deptView addSubview:deptButton];
    }
    
    UILongPressGestureRecognizer *lpgr = [[UILongPressGestureRecognizer alloc]
                                          initWithTarget:self
                                          action:@selector(deptViewLongPressed:)];
    
    lpgr.minimumPressDuration = 1.0;
    lpgr.delegate = self;
    [_deptView addGestureRecognizer:lpgr];
}

- (void)deptViewLongPressed:(UILongPressGestureRecognizer *)gesture
{
    UIView *deptView = gesture.view;
    ThemeLegend *tl = (ThemeLegend *)_legends[1];
    CGFloat buttonWidth = (deptView.frame.size.width / tl.cells.count);
    
    switch (gesture.state)
    {
        case UIGestureRecognizerStateEnded:
        {
            _dragSelectActive = NO;
            
            for (UIButton *deptButton in _dragSelectedCells)
            {
                deptButton.backgroundColor = UIColor.whiteColor;
                [self deptButtonTapped:deptButton];
            }
            
            _mapVC.fromIndex = self.tabBarController.selectedIndex;
            _mapVC.fromLegends = YES;
            self.tabBarController.selectedIndex = 0;
            _preventRefresh = NO;
        }
            break;
            
        case UIGestureRecognizerStateBegan:
            _dragSelectActive = _preventRefresh = YES;
            _dragSelectedCells = NSMutableArray.array;
            _firstTimeDrag = YES;
            
        default:
        {
            CGPoint point = [gesture locationInView:deptView];
            CGPoint superpoint = [gesture locationInView:self.view];
            
            if (CGRectContainsPoint(deptView.frame, superpoint))
            {
                NSUInteger buttonID = (NSUInteger)(point.x / buttonWidth);
                
                if (_firstTimeDrag)
                {
                    _currentRow = buttonID;
                    _firstTimeDrag = NO;
                }
                
                else if (buttonID != _currentRow)
                    _currentRow = buttonID;
                
                else
                    return;
                
                UIButton *deptButton = [deptView viewWithTag:(buttonID + 1)];
                
                if (![_dragSelectedCells containsObject:deptButton])
                {
                    deptButton.backgroundColor = UserDefaults.defaults.lightBlue;
                    [_dragSelectedCells addObject:deptButton];
                }
                
                else
                {
                    deptButton = (UIButton *)_dragSelectedCells.lastObject;
                    deptButton.backgroundColor = UIColor.whiteColor;
                    [_dragSelectedCells removeObject:deptButton];
                }
            }
        }
            break;
    }
}

- (void)deptButtonTapped:(UIButton *)button
{
    if (!_dragSelectActive)
    {
        ThemeLegend *tl = (ThemeLegend *)_legends[1];
        ThemeLegendCell *tlc = (ThemeLegendCell *)tl.cells[button.tag - 1];
        
        button.selected = tlc.status = !button.selected;
        
        if (!_preventRefresh)
        {
            _mapVC.fromIndex = self.tabBarController.selectedIndex;
            _mapVC.fromLegends = YES;
            self.tabBarController.selectedIndex = 0;
        }
    }
}

- (void)setupDeptViewComponents:(CGFloat)width
{
    _deptHeaderView.frame = CGRectMake(0.0, 0.0, width, _headerHeight);
    
    UIButton *addToMap = [_deptHeaderView viewWithTag:7777];
    
    addToMap.frame = CGRectMake((_deptHeaderView.frame.size.width - (_deptHeaderView.frame.size.height * 2.0)), 0.0,
                                (_deptHeaderView.frame.size.height * 2.0), _deptHeaderView.frame.size.height);
    
    ThemeLegend *tl = (ThemeLegend *)_legends[1];
    CGFloat buttonWidth = (width / tl.cells.count);
    
    for (UIButton *buttons in _deptView.subviews)
    {
        if ([buttons isKindOfClass:UIButton.class]
            && buttons.tag != 7777 && buttons.tag != 222)
        {
            buttons.frame = CGRectMake((buttonWidth * (buttons.tag - 1)), _headerHeight,
                                       buttonWidth,(_deptView.frame.size.height - _headerHeight));
            
            ThemeLegendCell *tlc = (ThemeLegendCell *)tl.cells[buttons.tag - 1];
            
            [buttons setTitle:[NSString stringWithFormat:@"%@ (%i)", tlc.label, tlc.count]
                     forState:UIControlStateNormal];
            
            buttons.selected = tlc.status;
            
            if (buttons.selected)
            {
                buttons.backgroundColor = UserDefaults.defaults.appleGray;
                
                [buttons setTitle:[NSString stringWithFormat:@"%@ (XX)", tlc.label]
                         forState:UIControlStateNormal];
            }
            
            else
            {
                buttons.backgroundColor = UIColor.clearColor;
                
                [buttons setTitle:[NSString stringWithFormat:@"%@ (%i)", tlc.label, tlc.count]
                         forState:UIControlStateNormal];
            }
        }
    }
}

- (void)setupTableView
{
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.backgroundColor = UIColor.grayColor;
    _tableView.bounces = NO;
    _tableView.layer.borderColor = UIColor.blackColor.CGColor;
    _tableView.layer.borderWidth = (_cornerRadius / 4.0);
    _tableView.layer.cornerRadius = _cornerRadius;
    _tableView.delaysContentTouches = NO;
    _tableView.allowsMultipleSelection = YES;
    _tableView.separatorColor = UIColor.clearColor;
    _tableView.separatorInset = UIEdgeInsetsZero;
    
    UILongPressGestureRecognizer *lpgr = [[UILongPressGestureRecognizer alloc]
                                          initWithTarget:self
                                          action:@selector(tlmoLongPressed:)];
    
    lpgr.minimumPressDuration = 1.0;
    lpgr.delegate = self;
    [_tableView addGestureRecognizer:lpgr];
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
                    _currentRow = row;
                
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
    _legends = ConfigurationControl.sharedInstance.legendList;
    ThemeLegend *tl = (ThemeLegend *)_legends[0];
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
    ThemeLegend *tl = (ThemeLegend *)_legends[0];
    
    CGFloat margin = 40.0;
    
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
    {
        margin = 16.0;
        
        if (UIApplication.sharedApplication.statusBarOrientation == UIDeviceOrientationLandscapeLeft ||
            UIApplication.sharedApplication.statusBarOrientation == UIDeviceOrientationLandscapeRight)
        {
            margin = 12.0;
        }
    }
    
    CGFloat tvWidth = (self.view.frame.size.width - margin);
    
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, tvWidth, _headerHeight)];
    headerView.backgroundColor = UIColor.blackColor;
    headerView.contentMode = UIViewContentModeCenter;
    
    if (![headerView.subviews containsObject:[headerView viewWithTag:111]])
    {
        UIButton *titleButton = [[UIButton alloc] initWithFrame:headerView.frame];
        titleButton.titleLabel.textAlignment = NSTextAlignmentCenter;
        titleButton.titleLabel.font = _headerFont;
        titleButton.tag = 111;
        
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
    
    if (![headerView.subviews containsObject:[headerView viewWithTag:3333]])
    {
        UIButton *addToMap = [UIButton buttonWithType:UIButtonTypeCustom];
        addToMap.tag = 3333;
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
    NSUInteger index = ((button.tag / 111) - 1);
    ThemeLegend *tl = (ThemeLegend *)_legends[index];
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
    NSUInteger index = ((alertView.tag / 111) - 1);
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
            [_tableView reloadData];
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
                    
                    [_tableView reloadData];
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
                    
                    [_tableView reloadData];
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
                    
                    [_tableView reloadData];
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
            
            [_tableView reloadData];
            
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
    
    ThemeLegend *tl = (ThemeLegend *)_legends[0];
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
        
        while (countString.length < _countLength)
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
    
    cell.textLabel.text = text.copy;
    
    cell.textLabel.textColor = UIColor.blackColor;
    cell.textLabel.font = _font;
    cell.textLabel.textAlignment = NSTextAlignmentLeft;
    cell.textLabel.adjustsFontSizeToFitWidth = YES;
    cell.textLabel.backgroundColor = UIColor.clearColor;
    cell.layer.borderColor = UIColor.blackColor.CGColor;
    cell.layer.borderWidth = 0.5;
    cell.contentView.backgroundColor = UIColor.clearColor;
    
    CGFloat symbolSize = 52.0;
    
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
        symbolSize = 36.0;
    
    cell.imageView.image = imageFromSymbol(tlc.symbol, symbolSize, tlc.symbolColor);
    
    return cell;
}

- (void)tableView:(UITableView *)tableView
  willDisplayCell:(UITableViewCell *)cell
forRowAtIndexPath:(NSIndexPath *)indexPath
{
    ThemeLegend *tl = (ThemeLegend *)_legends[0];
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
        ThemeLegend *tl = (ThemeLegend *)_legends[0];
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
        ThemeLegend *tl = (ThemeLegend *)_legends[0];
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
    [_tableView reloadData];
    
    CGFloat tabBarHeight = self.tabBarController.tabBar.frame.size.height;
    CGFloat margin = 40.0;
    
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
        margin = 12.0;
    
    [UIView animateWithDuration:duration animations:^{
        [self setupDeptViewComponents:((self.view.frame.size.height + tabBarHeight) - margin)];
    }];
    
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
    ThemeLegend *tl = nil;
    
    if (button.tag == 7777)
        tl = _legends[1];
    
    else
        tl = _legends[0];
    
    if (!button.selected)
        tl.drawOnMap = button.selected = YES;
    
    else
        tl.drawOnMap = button.selected = NO;
}

@end