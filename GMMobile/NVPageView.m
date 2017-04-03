//  NVPageView.m
//  GMMobile

#import "NVPageView.h"
#import "CCodeLibrary/UserDefaults.h"
#import "ConfigurationControl.h"
#import "CCodeLibrary/UIImage+ImageFromColor.h"
#import "CCodeLibrary/SymbolDictionary.h"
#import "MapViewController.h"
#import "CCodeLibrary/UserDefaults.h"
#import "NVPageController.h"

@interface NVPageView () <UITableViewDataSource, UITableViewDelegate>

@property NSUInteger numLegends, startingIndex, currentRow, currentColorPalette;
@property (nonatomic, copy) NSArray *legends;
@property (nonatomic) CGFloat headerHeight, cornerRadius, innerMargin, outerMargin, pageControlMargin;
@property (nonatomic) UIFont *font, *headerFont;
@property (nonatomic) NSMutableArray *countLengths, *dragSelectedCells;
@property (nonatomic) MapViewController *mapVC;
@property BOOL dragSelectActive, firstTimeDrag;
@property NVPageViewArrangement pageArrangement;
@property (nonatomic) NVPageController *controller;

@end

@implementation NVPageView

+ (instancetype)pageViewWithNumLegends:(NSUInteger)numLegends
                         startingIndex:(NSUInteger)startingIndex
                       pageArrangement:(NVPageViewArrangement)pageArrangement
                            controller:(NVPageController *)controller;
{
    NVPageView *nvpv = NVPageView.new;
    nvpv.numLegends = numLegends;
    nvpv.startingIndex = startingIndex;
    nvpv.pageArrangement = pageArrangement;
    nvpv.controller = controller;
    return nvpv;
}

- (void)loadView
{
    UIView *view = [[UIView alloc] initWithFrame:UIScreen.mainScreen.bounds];
    view.backgroundColor = UserDefaults.defaults.appleBlue;
    self.view = view;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _legends = ConfigurationControl.sharedInstance.legendList;
    _mapVC = (MapViewController *)CRAPI.sharedInstance.mapVC;
    _currentRow = _currentColorPalette = 0;
    
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
    {
        _headerHeight = 26.0;
        _cornerRadius = _innerMargin = _outerMargin = 4.0;
        _pageControlMargin = 12.0;
        _font = [UIFont fontWithName:@"CourierNewPS-BoldMT" size:14.0];
        _headerFont = [UIFont boldSystemFontOfSize:14.0];
    }
    
    else
    {
        _headerHeight = 44.0;
        _cornerRadius = _innerMargin = 10.0;
        _outerMargin = 20.0;
        _pageControlMargin = 30.0;
        _font = [UIFont fontWithName:@"CourierNewPS-BoldMT" size:24.0];
        _headerFont = [UIFont boldSystemFontOfSize:28.0];
    }
    
    for (int i = 0; i < _numLegends; i++)
    {
        UITableView *tv = UITableView.new;
        tv.translatesAutoresizingMaskIntoConstraints = NO;
        [self setupTableView:tv tag:(i + 1)];
        [self.view addSubview:tv];
        UITapGestureRecognizer *tap1 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(legendTapped:)];
        tap1.numberOfTouchesRequired = 1;
        [tv addGestureRecognizer:tap1];
        UITapGestureRecognizer *tap2 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(legendTapped:)];
        tap2.numberOfTouchesRequired = 2;
        [tv addGestureRecognizer:tap2];
    }
    
    switch (_pageArrangement)
    {
        case NVPageViewArrangementFit1:
            [[self.view viewWithTag:1] constrainLeadingToAnchor:self.view.leadingAnchor constant:_outerMargin];
            [[self.view viewWithTag:1] constrainTrailingToAnchor:self.view.trailingAnchor constant:-_outerMargin];
            [[self.view viewWithTag:1] constrainTopToAnchor:self.view.topAnchor constant:_outerMargin];
            [[self.view viewWithTag:1] constrainBottomToAnchor:self.view.bottomAnchor constant:-_pageControlMargin];
            break;
            
        case NVPageViewArrangementFit2:
        {
            CGFloat numCells1 = (CGFloat)[(ThemeLegend *)_legends[_startingIndex] numCells];
            CGFloat numCells2 = (CGFloat)[(ThemeLegend *)_legends[_startingIndex + 1] numCells];
            CGFloat multiplier = ((numCells1 + (1.5 / numCells1)) / (numCells2 + (1.5 / numCells2)));
            
            if (isnan(multiplier))
                return;
            
            [[self.view viewWithTag:1] constrainLeadingToAnchor:self.view.leadingAnchor constant:_outerMargin];
            [[self.view viewWithTag:1] constrainTrailingToAnchor:self.view.trailingAnchor constant:-_outerMargin];
            [[self.view viewWithTag:2] constrainLeadingToAnchor:[self.view viewWithTag:1].leadingAnchor];
            [[self.view viewWithTag:2] constrainTrailingToAnchor:[self.view viewWithTag:1].trailingAnchor];
            [[self.view viewWithTag:1] constrainHeightToAnchor:[self.view viewWithTag:2].heightAnchor multiplier:multiplier];
            [[self.view viewWithTag:1] constrainTopToAnchor:self.view.topAnchor constant:_outerMargin];
            [[self.view viewWithTag:1] constrainBottomToAnchor:[self.view viewWithTag:2].topAnchor constant:-_innerMargin];
            [[self.view viewWithTag:2] constrainBottomToAnchor:self.view.bottomAnchor constant:-_pageControlMargin];
        }
            break;
            
        case NVPageViewArrangementFit3:
        {
            CGFloat numCells1 = (CGFloat)[(ThemeLegend *)_legends[_startingIndex] numCells];
            CGFloat numCells2 = (CGFloat)[(ThemeLegend *)_legends[_startingIndex + 1] numCells];
            CGFloat numCells3 = (CGFloat)[(ThemeLegend *)_legends[_startingIndex + 2] numCells];
            
            CGFloat multiplier1 = ((numCells1 + (1.5 / numCells1)) / (numCells2 + (1.5 / numCells2)));
            CGFloat multiplier2 = ((numCells2 + (1.5 / numCells2)) / (numCells3 + (1.5 / numCells3)));
            
            if (isnan(multiplier1) || isnan(multiplier2))
                return;
            
            [[self.view viewWithTag:1] constrainLeadingToAnchor:self.view.leadingAnchor constant:_outerMargin];
            [[self.view viewWithTag:1] constrainTrailingToAnchor:self.view.trailingAnchor constant:-_outerMargin];
            [[self.view viewWithTag:2] constrainLeadingToAnchor:[self.view viewWithTag:1].leadingAnchor];
            [[self.view viewWithTag:2] constrainTrailingToAnchor:[self.view viewWithTag:1].trailingAnchor];
            [[self.view viewWithTag:3] constrainLeadingToAnchor:[self.view viewWithTag:1].leadingAnchor];
            [[self.view viewWithTag:3] constrainTrailingToAnchor:[self.view viewWithTag:1].trailingAnchor];
            [[self.view viewWithTag:1] constrainHeightToAnchor:[self.view viewWithTag:2].heightAnchor multiplier:multiplier1];
            [[self.view viewWithTag:1] constrainTopToAnchor:self.view.topAnchor constant:_outerMargin];
            [[self.view viewWithTag:1] constrainBottomToAnchor:[self.view viewWithTag:2].topAnchor constant:-_innerMargin];
            [[self.view viewWithTag:2] constrainHeightToAnchor:[self.view viewWithTag:3].heightAnchor multiplier:multiplier2];
            [[self.view viewWithTag:3] constrainTopToAnchor:[self.view viewWithTag:2].bottomAnchor constant:_innerMargin];
            [[self.view viewWithTag:3] constrainBottomToAnchor:self.view.bottomAnchor constant:-_pageControlMargin];
        }
            break;
            
        case NVPageViewArrangementFit5Columns2:
        {
            CGFloat numCells1 = (CGFloat)[(ThemeLegend *)_legends[_startingIndex] numCells];
            CGFloat numCells2 = (CGFloat)[(ThemeLegend *)_legends[_startingIndex + 1] numCells];
            CGFloat numCells3 = (CGFloat)[(ThemeLegend *)_legends[_startingIndex + 2] numCells];
            CGFloat numCells4 = (CGFloat)[(ThemeLegend *)_legends[_startingIndex + 3] numCells];
            CGFloat numCells5 = (CGFloat)[(ThemeLegend *)_legends[_startingIndex + 4] numCells];
            
            CGFloat multiplier1 = ((numCells1 + (1.5 / numCells1)) / (numCells2 + (1.5 / numCells2)));
            CGFloat multiplier3 = ((numCells4 + (1.5 / numCells4)) / (numCells5 + (1.5 / numCells5)));
            
            if (isnan(multiplier1) || isnan(multiplier3))
                return;
            
            CGFloat leftPacked = (numCells1 + numCells2 + numCells3);
            CGFloat rightPacked = (numCells3 + numCells4 + numCells5);
            
            [[self.view viewWithTag:1] constrainTopToAnchor:self.view.topAnchor constant:_outerMargin];
            [[self.view viewWithTag:1] constrainLeadingToAnchor:self.view.leadingAnchor constant:_outerMargin];
            [[self.view viewWithTag:2] constrainLeadingToAnchor:[self.view viewWithTag:1].leadingAnchor];
            [[self.view viewWithTag:1] constrainHeightToAnchor:[self.view viewWithTag:2].heightAnchor multiplier:multiplier1];
            [[self.view viewWithTag:1] constrainBottomToAnchor:[self.view viewWithTag:2].topAnchor constant:-_innerMargin];
            [[self.view viewWithTag:4] constrainTrailingToAnchor:self.view.trailingAnchor constant:-_innerMargin];
            [[self.view viewWithTag:5] constrainTrailingToAnchor:[self.view viewWithTag:4].trailingAnchor];
            [[self.view viewWithTag:4] constrainHeightToAnchor:[self.view viewWithTag:5].heightAnchor multiplier:multiplier3];
            [[self.view viewWithTag:4] constrainBottomToAnchor:[self.view viewWithTag:5].topAnchor constant:-_innerMargin];
            [[self.view viewWithTag:5] constrainBottomToAnchor:self.view.bottomAnchor constant:-_pageControlMargin];
            [[self.view viewWithTag:1] constrainWidthToAnchor:[self.view viewWithTag:2].widthAnchor];
            [[self.view viewWithTag:2] constrainWidthToAnchor:[self.view viewWithTag:3].widthAnchor];
            [[self.view viewWithTag:3] constrainWidthToAnchor:[self.view viewWithTag:4].widthAnchor];
            [[self.view viewWithTag:4] constrainWidthToAnchor:[self.view viewWithTag:5].widthAnchor];
            
            if (leftPacked <= rightPacked) //3+2 arrangement
            {
                CGFloat multiplier2 = ((numCells2 + (1.5 / numCells2)) / (numCells3 + (1.5 / numCells3)));
                
                if (isnan(multiplier2))
                    return;
                
                [[self.view viewWithTag:2] constrainHeightToAnchor:[self.view viewWithTag:3].heightAnchor multiplier:multiplier2];
                [[self.view viewWithTag:2] constrainBottomToAnchor:[self.view viewWithTag:3].topAnchor constant:-_innerMargin];
                [[self.view viewWithTag:1] constrainTrailingToAnchor:[self.view viewWithTag:4].leadingAnchor constant:-_innerMargin];
                [[self.view viewWithTag:2] constrainTrailingToAnchor:[self.view viewWithTag:1].trailingAnchor];
                [[self.view viewWithTag:3] constrainTrailingToAnchor:[self.view viewWithTag:1].trailingAnchor];
                [[self.view viewWithTag:3] constrainLeadingToAnchor:[self.view viewWithTag:1].leadingAnchor];
                [[self.view viewWithTag:3] constrainBottomToAnchor:[self.view viewWithTag:5].bottomAnchor];
                [[self.view viewWithTag:4] constrainTopToAnchor:[self.view viewWithTag:1].topAnchor];
                [[self.view viewWithTag:5] constrainLeadingToAnchor:[self.view viewWithTag:4].leadingAnchor];
            }
            
            else //2+3 arrangement
            {
                CGFloat multiplier2 = ((numCells3 + (1.5 / numCells3)) / (numCells4 + (1.5 / numCells4)));
                
                if (isnan(multiplier2))
                    return;
                
                [[self.view viewWithTag:3] constrainHeightToAnchor:[self.view viewWithTag:4].heightAnchor multiplier:multiplier2];
                [[self.view viewWithTag:3] constrainBottomToAnchor:[self.view viewWithTag:4].topAnchor constant:-_innerMargin];
                [[self.view viewWithTag:1] constrainTrailingToAnchor:[self.view viewWithTag:3].leadingAnchor constant:-_innerMargin];
                [[self.view viewWithTag:2] constrainTrailingToAnchor:[self.view viewWithTag:1].trailingAnchor];
                [[self.view viewWithTag:3] constrainTrailingToAnchor:[self.view viewWithTag:4].trailingAnchor];
                [[self.view viewWithTag:2] constrainBottomToAnchor:[self.view viewWithTag:5].bottomAnchor];
                [[self.view viewWithTag:3] constrainTopToAnchor:[self.view viewWithTag:1].topAnchor];
                [[self.view viewWithTag:4] constrainLeadingToAnchor:[self.view viewWithTag:3].leadingAnchor];
                [[self.view viewWithTag:5] constrainLeadingToAnchor:[self.view viewWithTag:3].leadingAnchor];
            }
        }
            
        default:
            break;
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    _legends = ConfigurationControl.sharedInstance.legendList;
    _countLengths = NSMutableArray.array;
    
    for (int i = 0; i < _numLegends; i++)
    {
        ThemeLegend *tl = (ThemeLegend *)_legends[i + _startingIndex];
        NSUInteger length = 0;
        
        for (ThemeLegendCell *cells in tl.cells)
        {
            NSString *countString = [NSString stringWithFormat:@"%i", cells.count];
            length = MAX(length, countString.length);
        }
        
        [_countLengths insertObject:@(length) atIndex:i];
    }
    
    [self reloadTableViews];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)reloadTableViews
{
    for (UITableView *tvs in self.view.subviews)
    {
        if ([tvs isKindOfClass:UITableView.class])
            [tvs reloadData];
    }
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
    tableView.allowsSelection = NO;
    tableView.allowsMultipleSelection = NO;
    tableView.separatorColor = UIColor.clearColor;
    tableView.separatorInset = UIEdgeInsetsZero;
    tableView.tag = tag;
    
    UILongPressGestureRecognizer *lpgr = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                                       action:@selector(tlmoLongPressed:)];
    
    [tableView addGestureRecognizer:lpgr];
}

- (void)tlmoLongPressed:(UILongPressGestureRecognizer *)gesture
{
    UITableView *tv = (UITableView *)gesture.view;
    
    switch (gesture.state)
    {
        case UIGestureRecognizerStateEnded:
        {
            if (_dragSelectedCells.count)
            {
                for (NSIndexPath *indexPaths in _dragSelectedCells)
                {
                    UITableViewCell *cell = [tv cellForRowAtIndexPath:indexPaths];
                    cell.backgroundColor = UIColor.whiteColor;
                    NSInteger row = indexPaths.row;
                    ThemeLegend *tl = (ThemeLegend *)_legends[((tv.tag - 1) + _startingIndex)];
                    ThemeLegendCell *tlc = (ThemeLegendCell *)tl.cells[row];
                    
                    if (_dragSelectedCells.count == 1)
                        [self turnOnJustThisRow:row inTableView:tv];
                    
                    else
                    {
                        if (tlc.status)
                            [self setThemeLegendCellStatusTo:0 forClass:row andThemeWithTag:tv.tag];
                        
                        else
                            [self setThemeLegendCellStatusTo:1 forClass:row andThemeWithTag:tv.tag];
                    }
                }
                
                [self refreshMapView];
            }
            
            _dragSelectActive = NO;
        }
            break;
            
        case UIGestureRecognizerStateBegan:
        {
            _dragSelectActive = _firstTimeDrag = YES;
            _dragSelectedCells = NSMutableArray.array;
        }
            
        default:
        {
            CGPoint point = [gesture locationInView:tv];
            CGPoint superpoint = [gesture locationInView:self.view];
            
            if (CGRectContainsPoint(tv.frame, superpoint) && point.y > _headerHeight)
            {
                NSInteger row = (NSInteger)((point.y - _headerHeight) / tv.rowHeight);
                
                if (_firstTimeDrag)
                {
                    _currentRow = row;
                    _firstTimeDrag = NO;
                }
                
                else if (row != _currentRow)
                    _currentRow = row;
                
                else
                    return;
                
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:_currentRow inSection:0];
                
                if (![_dragSelectedCells containsObject:indexPath])
                {
                    UITableViewCell *cell = [tv cellForRowAtIndexPath:indexPath];
                    cell.backgroundColor = UserDefaults.defaults.lightBlue;
                    [_dragSelectedCells addObject:indexPath];
                }
                
                else
                {
                    indexPath = (NSIndexPath *)_dragSelectedCells.lastObject;
                    UITableViewCell *cell = [tv cellForRowAtIndexPath:indexPath];
                    cell.backgroundColor = UIColor.whiteColor;
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
    ThemeLegend *tl = (ThemeLegend *)_legends[((tableView.tag - 1) + _startingIndex)];
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
    ThemeLegend *tl = (ThemeLegend *)_legends[((tableView.tag - 1) + _startingIndex)];
    
    CGFloat tvWidth = ((self.view.frame.size.width - (_innerMargin + (_outerMargin * 2.0))) /
                       [self numColumnsFromArrangement:_pageArrangement]);
    
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, tvWidth, _headerHeight)];
    headerView.backgroundColor = UIColor.blackColor;
    headerView.contentMode = UIViewContentModeCenter;
    
    if (![headerView.subviews containsObject:[headerView viewWithTag:(tableView.tag * 333)]])
    {
        UIButton *titleButton = [UIButton buttonWithType:UIButtonTypeCustom];
        titleButton.translatesAutoresizingMaskIntoConstraints = NO;
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
        [titleButton constrainTopToAnchor:headerView.topAnchor];
        [titleButton constrainBottomToAnchor:headerView.bottomAnchor];
        [titleButton constrainCenterXToAnchor:headerView.centerXAnchor];
    }
    
    if (![headerView.subviews containsObject:[headerView viewWithTag:(tableView.tag * 111)]])
    {
        UIButton *addToMap = [UIButton buttonWithType:UIButtonTypeCustom];
        addToMap.translatesAutoresizingMaskIntoConstraints = NO;
        addToMap.tag = (tableView.tag * 111);
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
        
        [headerView addSubview:addToMap];
        [addToMap constrainTopToAnchor:headerView.topAnchor];
        [addToMap constrainBottomToAnchor:headerView.bottomAnchor];
        [addToMap constrainLeadingToAnchor:headerView.trailingAnchor constant:(-headerView.frame.size.height - _innerMargin)];
        [addToMap constrainTrailingToAnchor:headerView.trailingAnchor  constant:-_innerMargin];
    }
    
    return headerView;
}

- (void)showLegendOptions:(UIButton *)button
{
    ThemeLegend *tl = _legends[(((button.tag / 333) - 1) + _startingIndex)];
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
    [_controller disablePaging];
}

- (void)alertView:(NVAlertView *)alertView
didTapButtonAtIndex:(NSInteger)buttonIndex
{
    NSInteger index = ((alertView.tag / 333) - 1);
    ThemeLegend *tl = (ThemeLegend *)_legends[index + _startingIndex];
    BOOL disablePaging = NO;
    
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
            [_controller disablePaging];
            disablePaging = YES;
            
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
    
    if (!disablePaging)
        [_controller enablePaging];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"CustomCell";
    
    UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:cellIdentifier];
    }
    
    for (UIView *views in cell.contentView.subviews)
    {
        if (views.tag == 666 || views.tag == 777 || views.tag == 888)
            [views removeFromSuperview];
    }
    
    ThemeLegend *tl = (ThemeLegend *)_legends[((tableView.tag - 1) + _startingIndex)];
    ThemeLegendCell *tlc = (ThemeLegendCell *)tl.cells[indexPath.row];
    NSMutableString *text = tlc.label.mutableCopy;
    
    if (tl.appendClassCount)
    {
        NSMutableString *countString = NSMutableString.string;
        
        if (tlc.status)
            [countString insertString:[NSString stringWithFormat:@"%i", tlc.count] atIndex:0];
        
        else
            [countString insertString:@"X" atIndex:0];
        
        while (countString.length < [_countLengths[(tableView.tag - 1)] integerValue])
        {
            if (tlc.status)
                [countString insertString:@" " atIndex:0];
            
            else
                [countString insertString:@"X" atIndex:0];
        }
        
        [text appendString:[NSString stringWithFormat:@" (%@)", countString.copy]];
    }
    
    cell.layer.borderColor = UIColor.blackColor.CGColor;
    cell.layer.borderWidth = 0.5;
    
    if (tlc.status)
    {
        cell.backgroundColor = UIColor.whiteColor;
        
        if (tlc.status == 2)
        {
            cell.layer.borderColor = tl.symbolDefaultColor.CGColor;
            cell.layer.borderWidth = 6.0;
        }
    }
    
    else
        cell.backgroundColor = UIColor.lightGrayColor;
    
    UILabel *textLabel = UILabel.new;
    textLabel.translatesAutoresizingMaskIntoConstraints = NO;
    textLabel.textColor = UIColor.blackColor;
    textLabel.font = _font;
    textLabel.text = text.copy;
    textLabel.textAlignment = NSTextAlignmentLeft;
    textLabel.adjustsFontSizeToFitWidth = YES;
    textLabel.backgroundColor = UIColor.clearColor;
    textLabel.tag = 888;
    
    [cell.contentView addSubview:textLabel];
    [textLabel constrainTopToAnchor:cell.contentView.topAnchor];
    [textLabel constrainBottomToAnchor:cell.contentView.bottomAnchor];
    
    cell.contentView.backgroundColor = UIColor.clearColor;
    cell.textLabel.backgroundColor = UIColor.clearColor;
    
    NSDictionary *attributes = @{NSFontAttributeName:_font};
    
    CGRect textSize = [text boundingRectWithSize:cell.contentView.frame.size
                                         options:NSStringDrawingUsesLineFragmentOrigin
                                      attributes:attributes
                                         context:nil];
    
    CGFloat textWidth = ceil(textSize.size.width);
    
    if (tl.usePointSymbols)
    {
        UIImageView *imageView = UIImageView.new;
        
        if (tl.useClassColors)
            imageView.image = imageFromSymbol(tlc.symbol, tableView.rowHeight, tlc.symbolColor);
        
        else
            imageView.image = imageFromSymbol(tlc.symbol, tableView.rowHeight, tl.symbolDefaultColor);
        
        imageView.tag = 777;
        imageView.translatesAutoresizingMaskIntoConstraints = NO;
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        
        [cell.contentView addSubview:imageView];
        [imageView constrainTopToAnchor:cell.contentView.topAnchor constant:(tableView.rowHeight * 0.1)];
        [imageView constrainBottomToAnchor:cell.contentView.bottomAnchor constant:(-tableView.rowHeight * 0.1)];
        [imageView constrainLeadingToAnchor:cell.contentView.leadingAnchor constant:10.0];
        [textLabel constrainLeadingToAnchor:imageView.trailingAnchor constant:10.0];
    }
    
    else
    {
        [textLabel constrainLeadingToAnchor:cell.contentView.trailingAnchor constant:(-textWidth - 10.0)];
        CGFloat barMargin = 10.0;
        CGFloat barWidth = (((tableView.frame.size.width - textWidth) - (barMargin * 3.0)) * tlc.symbolWidth);
        
        UIImageView *barView = [[UIImageView alloc] initWithFrame:
                                CGRectMake(barMargin, (tableView.rowHeight * 0.15), barWidth, (tableView.rowHeight * 0.7))];
        
        if (tl.useClassColors)
            barView.image = [UIImage imageFromColor:tlc.symbolColor];
        
        else
            barView.image = [UIImage imageFromColor:tl.symbolDefaultColor];
        
        barView.layer.borderColor = UIColor.blackColor.CGColor;
        barView.layer.borderWidth = 1.0;
        barView.tag = 666;
        [cell.contentView addSubview:barView];
    }
    
    return cell;

}

- (void)setThemeLegendCellStatusTo:(int)status
                          forClass:(NSInteger)class
                   andThemeWithTag:(NSInteger)tag
{
    ThemeLegend *tl = (ThemeLegend *)_legends[((tag - 1) + _startingIndex)];
    ThemeLegendCell *tlc = (ThemeLegendCell *)tl.cells[class];
    tlc.status = status;
}

- (void)turnOnJustThisRow:(NSInteger)row
              inTableView:(UITableView *)tableView
{
    ThemeLegend *tl = (ThemeLegend *)_legends[((tableView.tag - 1) + _startingIndex)];
    
    for (int irow = 0; irow < tl.numCells; irow++)
        [self setThemeLegendCellStatusTo:0 forClass:irow andThemeWithTag:tableView.tag];
    
    [self setThemeLegendCellStatusTo:1 forClass:row andThemeWithTag:tableView.tag];
}

- (void)legendTapped:(UITapGestureRecognizer *)gesture
{
    UITableView *tv = (UITableView *)gesture.view;
    CGPoint point = [gesture locationInView:tv];
    
    if (point.y > _headerHeight)
    {
        NSInteger row = (NSInteger)((point.y - _headerHeight) / tv.rowHeight);
        ThemeLegend *tl = (ThemeLegend *)_legends[((tv.tag - 1) + _startingIndex)];
        ThemeLegendCell *tlc = (ThemeLegendCell *)tl.cells[row];
        
        if (tlc.status == 2)
        {
            if (gesture.numberOfTouches == 2)
                [self setThemeLegendCellStatusTo:1 forClass:row andThemeWithTag:tv.tag];
            
            else
                [self setThemeLegendCellStatusTo:0 forClass:row andThemeWithTag:tv.tag];
        }
        
        else if (tlc.status == 1)
        {
            if (gesture.numberOfTouches == 2)
                [self setThemeLegendCellStatusTo:2 forClass:row andThemeWithTag:tv.tag];
            
            else
                [self setThemeLegendCellStatusTo:0 forClass:row andThemeWithTag:tv.tag];
        }
        
        else
            [self setThemeLegendCellStatusTo:(int)gesture.numberOfTouches forClass:row andThemeWithTag:tv.tag];
        
         [self refreshMapView];
    }
}

- (void)refreshMapView
{
    _mapVC.fromIndex = self.tabBarController.selectedIndex;
    _mapVC.fromLegends = YES;
    self.tabBarController.selectedIndex = 0;
}

- (void)addLegend:(UIButton *)button
{
    ThemeLegend *tl = _legends[(((button.tag / 111) - 1) + _startingIndex)];
    
    if (!button.selected)
        tl.drawOnMap = button.selected = YES;
    
    else
        tl.drawOnMap = button.selected = NO;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
                                duration:(NSTimeInterval)duration
{
    for (NVAlertView *alert in self.view.subviews)
    {
        if ([alert isKindOfClass:NVAlertView.class])
            [self.view bringSubviewToFront:alert];
    }
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self reloadTableViews];
}

- (NSInteger)numColumnsFromArrangement:(NVPageViewArrangement)arrangement
{
    NSInteger numColumns = 0;
    
    switch (arrangement)
    {
        case NVPageViewArrangementFit1:
        case NVPageViewArrangementFit2:
        case NVPageViewArrangementFit3:
        case NVPageViewArrangementFit4:
        case NVPageViewArrangementFit5:
        case NVPageViewArrangementFit6:
            numColumns = 1;
            break;
            
        case NVPageViewArrangementFit2Columns2:
        case NVPageViewArrangementFit3Columns2:
        case NVPageViewArrangementFit4Columns2:
        case NVPageViewArrangementFit5Columns2:
        case NVPageViewArrangementFit6Columns2:
            numColumns = 2;
            break;
            
        case NVPageViewArrangementFit3Columns3:
        case NVPageViewArrangementFit4Columns3:
        case NVPageViewArrangementFit5Columns3:
        case NVPageViewArrangementFit6Columns3:
            numColumns = 3;
            break;
            
        case NVPageViewArrangementFit4Columns4:
        case NVPageViewArrangementFit5Columns4:
        case NVPageViewArrangementFit6Columns4:
            numColumns = 4;
            break;
            
        case NVPageViewArrangementFit5Columns5:
        case NVPageViewArrangementFit6Columns5:
            numColumns = 5;
            break;
            
        case NVPageViewArrangementFit6Columns6:
            numColumns = 6;
            break;
            
        default:
            break;
    }
    
    return numColumns;
}

@end
