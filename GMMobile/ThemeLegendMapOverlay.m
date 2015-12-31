//  ThemeLegendMapOverlay.m
//  GMMobile

#import "ThemeLegendMapOverlay.h"
#import "SymbolDictionary.h"
#import "CCodeLibrary/UIImage+ImageFromColor.h"
#import "CCodeLibrary/UserDefaults.h"

@interface ThemeLegendMapOverlay ()

@property (nonatomic) UIFont *font, *headerFont;
@property (nonatomic) NSUInteger countLength;
@property (nonatomic) UITabBar *tabBar;
@property (nonatomic) CGRect previousFrame, previousScrollFrame;
@property (nonatomic) NSMutableArray *dragSelectedCells;
@property BOOL dragSelectActive, preventRefresh, firstTimeDrag;
@property NSUInteger currentRow;

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
    tlmo.isExpanded = tlmo.dragSelectActive = NO;
    tlmo.preventRefresh = tlmo.firstTimeDrag = NO;
    tlmo.rowHeight = 26.0;
    tlmo.delegate = delegate;
    tlmo.tabBar = tabBar;
    tlmo.previousFrame = tlmo.previousScrollFrame = CGRectZero;
    tlmo.currentRow = tlmo.currentColorPalette = 0;
    
    tlmo.font = [UIFont fontWithName:@"CourierNewPS-BoldMT"
                                size:18.0];
    
    tlmo.headerFont = [UIFont boldSystemFontOfSize:18.0];
    
    for (ThemeLegendCell *cells in tlmo.legend.cells)
    {
        NSString *countString = [NSString stringWithFormat:@"%i", cells.count];
        tlmo.countLength = MAX(tlmo.countLength, countString.length);
    }
    
    CGFloat height = ((tlmo.legend.numCells + 1) * tlmo.rowHeight);
    tlmo.width = 232.0;
    
    tlmo.frame = CGRectMake(origin.x, origin.y, tlmo.width, height);
    
    tlmo.tableView = [[UITableView alloc] initWithFrame:tlmo.bounds
                                                  style:UITableViewStylePlain];
    
    tlmo.tableView.delegate = tlmo;
    tlmo.tableView.dataSource = tlmo;
    tlmo.tableView.backgroundColor = UIColor.blackColor;
    tlmo.tableView.rowHeight = tlmo.rowHeight;
    tlmo.tableView.scrollEnabled = NO;
    tlmo.tableView.layer.borderColor = UIColor.blackColor.CGColor;
    tlmo.tableView.layer.borderWidth = 2.0;
    tlmo.tableView.delaysContentTouches = NO;
    tlmo.tableView.allowsMultipleSelection = YES;
    tlmo.tableView.separatorColor = UIColor.clearColor;
    tlmo.tableView.separatorInset = UIEdgeInsetsZero;
    tlmo.tableView.layoutMargins = UIEdgeInsetsZero;
    
    UILongPressGestureRecognizer *lpgr = [[UILongPressGestureRecognizer alloc]
                                          initWithTarget:tlmo
                                          action:@selector(tlmoLongPressed:)];
    
    lpgr.minimumPressDuration = 1.0;
    lpgr.delegate = tlmo;
    [tlmo.tableView addGestureRecognizer:lpgr];
    
    [tlmo addSubview:tlmo.tableView];
    [view addSubview:tlmo];
    
    return tlmo;
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
                UITableViewCell *cell = [_tableView cellForRowAtIndexPath:indexPaths];
                cell.backgroundColor = UIColor.whiteColor;
                cell.selectionStyle = UITableViewCellSelectionStyleGray;
                
                if (cell.selected)
                {
                    [self tableView:_tableView
          didDeselectRowAtIndexPath:indexPaths];
                }
               
                else
                {
                    [self tableView:_tableView
            didSelectRowAtIndexPath:indexPaths];
                }
                
                cell.selected = !cell.selected;
            }
            
            _preventRefresh = NO;
            
            if (_delegate)
                [_delegate themeLegendDidChangeStatus:YES];
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
            
            if (CGRectContainsPoint(tv.frame, point))
            {
                NSUInteger row = (NSUInteger)(point.y / tv.rowHeight);
                
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
                
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:(_currentRow - 1)
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
    
    if (![headerView.subviews containsObject:[headerView viewWithTag:(self.tag * 333)]])
    {
        UIButton *titleButton = [[UIButton alloc] initWithFrame:headerView.frame];
        titleButton.titleLabel.textAlignment = NSTextAlignmentCenter;
        titleButton.titleLabel.font = _headerFont;
        titleButton.tag = (self.tag * 333);
        
        [titleButton setTitleColor:UIColor.whiteColor
                          forState:UIControlStateNormal];
        
        if (_legend.titles.count > 1 || _legend.hasColors)
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
        
        [titleButton setTitle:_legend.title
                     forState:UIControlStateNormal];
        
        [headerView addSubview:titleButton];
    }
    
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
    
    if (![headerView.subviews containsObject:[headerView viewWithTag:(self.tag * 222)]] && !_isExpanded)
    {
        UIButton *dragButton = [UIButton buttonWithType:UIButtonTypeCustom];
        dragButton.tag = (self.tag * 222);
        dragButton.imageView.contentMode = UIViewContentModeScaleToFill;
        dragButton.imageEdgeInsets = UIEdgeInsetsMake(2.0, 8.0, 2.0, 8.0);
        
        dragButton.frame = CGRectMake(0.0, 0.0,(headerView.frame.size.height * 2.0),
                                      headerView.frame.size.height);
        
        [dragButton setImage:[UIImage imageWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"dragIcon"
                                                                                            ofType:@"png"]]
                    forState:UIControlStateNormal];
        
        [dragButton addTarget:self
                       action:@selector(legendWasDragged:withEvent:)
             forControlEvents:UIControlEventTouchDragInside];
        
        [dragButton addTarget:self
                       action:@selector(dragButtonBegin:)
             forControlEvents:UIControlEventTouchDown];
        
        [dragButton addTarget:self
                       action:@selector(dragButtonEnd:)
             forControlEvents:UIControlEventTouchUpInside|UIControlEventTouchUpOutside];
        
        [headerView addSubview:dragButton];
    }
    
    return headerView;
}

- (void)showLegendOptions:(UIButton *)button
{
    _tabBar.userInteractionEnabled = NO;
    
    [UIView animateWithDuration:0.25
                     animations:^{
                         _tabBar.alpha = 0.3;
                     }];
    
    UIView *superview = self.superview;
    
    if ([self.superview isKindOfClass:UIScrollView.class])
        superview = self.superview.superview;
    
    NSMutableArray *textArray = NSMutableArray.array;
    [textArray addObject:@"Cancel"];
    [textArray addObject:@"Color Symbols\nUsing Exising Colors\nFor This Legend"];
    [textArray addObject:@"Color Symbols\nBy Selecting Colors\nFor This Legend"];
    
    
    if (_legend.titles.count > 1)
        [textArray addObject:@"Select Legend Title"];
    
    NVAlertView *alert = [NVAlertView showLargeAlertViewinView:superview
                                                      delegate:self
                                                         title:[NSString stringWithFormat:@"Legend Options for\n%@",
                                                                _legend.title]
                                               buttonTextArray:textArray
                                              destructiveIndex:1];
    
    alert.identifier = @"TopLevelAlert";
    
    if (_delegate && [_delegate respondsToSelector:@selector(clearVectorView)])
        [_delegate clearVectorView];
}

- (void)displayRandomColorAlertInView:(UIView *)view
{
    NVAlertView *alert = [NVAlertView showLargeAlertViewinView:view
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
    
    if (_delegate && [_delegate respondsToSelector:@selector(clearVectorView)])
        [_delegate clearVectorView];
}

- (void)alertView:(NVAlertView *)alertView
didTapButtonAtIndex:(NSInteger)buttonIndex
{
    
    if (buttonIndex > 0)
    {
        if ([alertView.identifier isEqualToString:@"TopLevelAlert"])
        {
            [alertView hideLargeAlertView:YES];
            
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
            }
            
            else if (buttonIndex == 3)//Titles Option
            {
                NSMutableArray *textArray = NSMutableArray.array;
                [textArray addObject:@"Cancel"];
                [textArray addObjectsFromArray:_legend.titles.copy];
                
                NVAlertView *alert = [NVAlertView showLargeAlertViewinView:alertView.superview
                                                                  delegate:self
                                                                     title:@"Select Legend Title"
                                                           buttonTextArray:textArray
                                                          destructiveIndex:1];
                
                alert.identifier = @"TitlesAlert";
            }
            
            return;
        }
        
        else if ([alertView.identifier isEqualToString:@"TitlesAlert"])
        {
            _legend.currentTitleIndex = (int)(buttonIndex - 1);
            [_tableView reloadData];
        }
        
        else if ([alertView.identifier isEqualToString:@"ColorOptionsAlert"])
        {
            switch (buttonIndex)
            {
                case NVColorOptionReds:
                {
                    NSArray *colorArray = [NVColorSet redsArrayWithNumComponents:_legend.numCells];
                    
                    for (int i = 0; i < _legend.numCells; i++)
                    {
                        ThemeLegendCell *tlc = (ThemeLegendCell *)_legend.cells[i];
                        tlc.symbolColor = (NVColor *)colorArray[i];
                    }
                    
                    [_tableView reloadData];
                }
                    break;
                    
                case NVColorOptionGreens:
                {
                    NSArray *colorArray = [NVColorSet greensArrayWithNumComponents:_legend.numCells];
                    
                    for (int i = 0; i < _legend.numCells; i++)
                    {
                        ThemeLegendCell *tlc = (ThemeLegendCell *)_legend.cells[i];
                        tlc.symbolColor = (NVColor *)colorArray[i];
                    }
                    
                    [_tableView reloadData];
                }
                    break;
                    
                case NVColorOptionBlues:
                {
                    NSArray *colorArray = [NVColorSet bluesArrayWithNumComponents:_legend.numCells];
                    
                    for (int i = 0; i < _legend.numCells; i++)
                    {
                        ThemeLegendCell *tlc = (ThemeLegendCell *)_legend.cells[i];
                        tlc.symbolColor = (NVColor *)colorArray[i];
                    }
                    
                    [_tableView reloadData];
                }
                    break;
                    
                case NVColorOptionRandom:
                {
                    [alertView hideLargeAlertView:YES];
                    
                    NVAlertView *alert = [NVAlertView showLargeAlertViewinView:alertView.superview
                                                                      delegate:self
                                                                         title:@"Select Color Palette"
                                                               buttonTextArray:NVColorSet.randomColorPaletteOptions
                                                              destructiveIndex:1];
                    
                    alert.identifier = @"RandomColorAlert";
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
            
            [alertView hideLargeAlertView:YES];
            
            if ([alertView.identifier isEqualToString:@"RandomColorAlert"])
                _currentColorPalette = buttonIndex;
            
            NSArray *colorArray = [NVColorSet randomColorArrayOfType:_currentColorPalette
                                                       numComponents:_legend.numCells];
            
            for (int i = 0; i < _legend.numCells; i++)
            {
                ThemeLegendCell *tlc = (ThemeLegendCell *)_legend.cells[i];
                tlc.symbolColor = (NVColor *)colorArray[i];
            }
            
            [_tableView reloadData];
            
            if (_delegate)
            {
                [_delegate randomColorsSelectedWithOption:_currentColorPalette
                                           forThemeLegend:self];
            }
            
            if (!_isExpanded)
            {
                if (![alertView.identifier isEqualToString:@"RandomColorConfirmation"])
                {
                    [UIView animateWithDuration:0.25
                                     animations:^{
                                         _tabBar.alpha = 1.0;
                                     }];
                }
                
                _tabBar.userInteractionEnabled = YES;
            }
            
            return;
        }
    }
    
    [alertView hideLargeAlertView:YES];
    
    if (!_isExpanded)
    {
        if (_delegate)
            [_delegate themeLegendDidChangeStatus:YES];
        
        [UIView animateWithDuration:0.25
                         animations:^{
                             _tabBar.alpha = 1.0;
                         }];
        
        _tabBar.userInteractionEnabled = YES;
    }
}

- (void)dragButtonBegin:(UIButton *)button
{
    _previousFrame = self.frame;
    
    if (self.superview.superview)
        [self.superview.superview bringSubviewToFront:self.superview];
    
    [self.superview bringSubviewToFront:self];
}

- (void)dragButtonEnd:(UIButton *)button
{
    CGFloat originXTrans = fabs(self.frame.origin.x - _previousFrame.origin.x);
    CGFloat originYTrans = fabs(self.frame.origin.y - _previousFrame.origin.y);
    
    BOOL significantMove = ((originXTrans > self.frame.size.width) ||
                            (originYTrans > self.frame.size.height));
    
    if (self.superview.superview)
        [self.superview.superview sendSubviewToBack:self.superview];
    
    if ((self.frame.origin.x + self.frame.size.width) > self.superview.frame.size.width && _delegate)
        [_delegate themeLegendWasDraggedOffRightSide];
    
    else if (self.frame.origin.x < 0.0 && _delegate)
        [_delegate themeLegendWasDraggedOffLeftSide];
    
    else if (UIApplication.sharedApplication.statusBarOrientation == UIDeviceOrientationLandscapeLeft ||
             UIApplication.sharedApplication.statusBarOrientation == UIDeviceOrientationLandscapeRight)
    {
        if (significantMove || _legend.isDraggedLandscape)
        {
            _legend.landscapeMapOrigin = self.frame.origin;
            _legend.isDraggedLandscape = YES;
        }
    }
        
    else
    {
        if (significantMove || _legend.isDraggedPortrait)
        {
            _legend.portraitMapOrigin = self.frame.origin;
            _legend.isDraggedPortrait = YES;
        }
    }
    
    if (_delegate)
        [_delegate themeLegendDidChangeStatus:NO];
}

- (void)legendWasDragged:(UIButton *)button
               withEvent:(UIEvent *)event
{
    UITouch *touch = [[event touchesForView:button] anyObject];
    CGPoint previousLocation = [touch previousLocationInView:button];
    CGPoint location = [touch locationInView:button];
    CGFloat deltaX = (location.x - previousLocation.x);
    CGFloat deltaY = (location.y - previousLocation.y);
    
    self.center = CGPointMake(self.center.x + deltaX, self.center.y + deltaY);
}

- (void)expandLegend:(UIButton *)button
{
    if (!_isExpanded)
    {
        if (_delegate && [_delegate respondsToSelector:@selector(clearVectorView)])
            [_delegate clearVectorView];
        
        CGRect bounds = UIScreen.mainScreen.bounds;
        CGFloat longestSide = MAX(bounds.size.height, bounds.size.width);
        
        UIView *overlayView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, longestSide, longestSide)];
        overlayView.backgroundColor = UIColor.blackColor;
        overlayView.alpha = 0.0;
        overlayView.tag = 123456789;
        
        CGFloat statusBarHeight = [self statusBarHeight:UIApplication.sharedApplication.statusBarOrientation];
        CGSize superSize = self.superview.frame.size;
        CGFloat contentOffset = 0.0;
        
        if ([self.superview isKindOfClass:UIScrollView.class])
        {
            UIScrollView *legendScroll = (UIScrollView *)self.superview;
            
            if (![legendScroll.superview.subviews containsObject:[legendScroll viewWithTag:123456789]])
            {
                [legendScroll.superview addSubview:overlayView];
                [legendScroll.superview bringSubviewToFront:self.superview];
                [legendScroll bringSubviewToFront:self];
                legendScroll.scrollEnabled = NO;
                _previousScrollFrame = legendScroll.frame;
                
                superSize = legendScroll.superview.frame.size;
                contentOffset = (legendScroll.contentOffset.y - statusBarHeight);
            }
        }
        
        else if (![self.superview.subviews containsObject:[self.superview viewWithTag:123456789]])
        {
            [self.superview addSubview:overlayView];
            [self.superview bringSubviewToFront:self];
        }
        
        _previousFrame = self.frame;
        CGFloat maxRowHeight = (((superSize.height - statusBarHeight) - 8.0) / (_legend.numCells + 1));
        _rowHeight = MIN((_rowHeight * 2.0), maxRowHeight);
        _tableView.rowHeight = _rowHeight;
        _tabBar.userInteractionEnabled = NO;
        CGFloat height = ((_legend.numCells + 1) * _rowHeight);
        
        _font = [UIFont fontWithName:@"CourierNewPS-BoldMT"
                                size:36.0];
        
        _headerFont = [UIFont boldSystemFontOfSize:36.0];
        
        UIButton *dragButton = [self viewWithTag:(self.tag * 222)];
        dragButton.enabled = NO;
        
        [UIView animateWithDuration:0.25
                         animations:^{
                             overlayView.alpha = 0.7;
                             _tabBar.alpha = 0.3;
                             dragButton.alpha = 0.0;
                             
                             if ([self.superview isKindOfClass:UIScrollView.class])
                             {
                                 UIScrollView *legendScroll = (UIScrollView *)self.superview;
                                 legendScroll.frame = overlayView.frame;
                                 
                                 legendScroll.center = CGPointMake(legendScroll.center.x,
                                                                   (legendScroll.superview.center.y + (_tabBar.frame.size.height / 2.0)));
                             }
                             
                             self.frame = CGRectMake((superSize.width * 0.1),
                                                     ((((superSize.height - height) + statusBarHeight) / 2.0) + contentOffset),
                                                     (superSize.width * 0.8), height);
                             
                             _tableView.frame = self.bounds;
                             
                             for (ThemeLegendMapOverlay *tlmos in self.superview.subviews)
                             {
                                 if ([tlmos isKindOfClass:ThemeLegendMapOverlay.class] && tlmos != self)
                                     tlmos.alpha = 0.0;
                             }
                             
                         } completion:^(BOOL finished) {
                             [_tableView reloadData];
                             _isExpanded = YES;
                             button.selected = YES;
                         }];
    }
    
    else
    {
        UIView *overlayView = nil;
        
        if ([self.superview isKindOfClass:UIScrollView.class])
            overlayView = [self.superview.superview viewWithTag:123456789];
        
        else
            overlayView = [self.superview viewWithTag:123456789];
        
        _tabBar.userInteractionEnabled = YES;
        _rowHeight /= 2.0;
        _tableView.rowHeight = _rowHeight;
        
        _font = [UIFont fontWithName:@"CourierNewPS-BoldMT"
                                size:18.0];
        
        _headerFont = [UIFont boldSystemFontOfSize:18.0];
        
        [UIView animateWithDuration:0.25
                         animations:^{
                             overlayView.alpha = 0.0;
                             _tabBar.alpha = 1.0;
                             
                             if ([self.superview isKindOfClass:UIScrollView.class])
                             {
                                 self.superview.frame =
                                 CGRectMake((self.superview.superview.frame.size.width - _previousScrollFrame.size.width),
                                 _previousScrollFrame.origin.y, _previousScrollFrame.size.width,
                                 self.superview.superview.frame.size.height);
                                 
                                 self.frame = _previousFrame;
                             }
                             
                             else if (UIApplication.sharedApplication.statusBarOrientation == UIDeviceOrientationLandscapeLeft ||
                                      UIApplication.sharedApplication.statusBarOrientation == UIDeviceOrientationLandscapeRight)
                             {
                                 
                                 
                                 self.frame = CGRectMake(_legend.landscapeMapOrigin.x,
                                                         _legend.landscapeMapOrigin.y,
                                                         _previousFrame.size.width,
                                                         _previousFrame.size.height);
                             }
                             
                             else
                             {
                                 self.frame = CGRectMake(_legend.portraitMapOrigin.x,
                                                         _legend.portraitMapOrigin.y,
                                                         _previousFrame.size.width,
                                                         _previousFrame.size.height);
                             }
                             
                             _tableView.frame = self.bounds;
                             
                             for (ThemeLegendMapOverlay *tlmos in self.superview.subviews)
                             {
                                 if ([tlmos isKindOfClass:ThemeLegendMapOverlay.class] && tlmos != self)
                                     tlmos.alpha = 1.0;
                             }
                             
                         } completion:^(BOOL finished) {
                             [overlayView removeFromSuperview];
                             [_tableView reloadData];
                             _isExpanded = NO;
                             button.selected = NO;
                             
                             if ([self.superview isKindOfClass:UIScrollView.class])
                             {
                                 UIScrollView *legendScroll = (UIScrollView *)self.superview;
                                 legendScroll.scrollEnabled = YES;
                             }
                             
                             if (!_preventRefresh && _delegate)
                                 [_delegate themeLegendDidChangeStatus:YES];
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
    
    UILabel *textLabel = [[UILabel alloc] init];
    textLabel.textColor = UIColor.blackColor;
    textLabel.font = _font;
    textLabel.text = text.copy;
    textLabel.textAlignment = NSTextAlignmentCenter;
    textLabel.adjustsFontSizeToFitWidth = YES;
    textLabel.backgroundColor = UIColor.clearColor;
    textLabel.tag = 888;
    
    cell.layer.borderColor = UIColor.blackColor.CGColor;
    cell.layer.borderWidth = 0.5;
    cell.contentView.backgroundColor = UIColor.clearColor;
    cell.textLabel.backgroundColor = UIColor.clearColor;
    
    NSDictionary *attributes = @{NSFontAttributeName:_font};
    
    CGRect textSize = [text boundingRectWithSize:cell.contentView.frame.size
                                         options:NSStringDrawingUsesLineFragmentOrigin
                                      attributes:attributes
                                         context:nil];
    
    CGFloat textWidth = ceil(textSize.size.width);
    CGFloat textOriginX = MAX((tableView.frame.size.width - textWidth), 4.0);
    
    if (_legend.usePointSymbols)
    {
        CGFloat imageSize = (_rowHeight * 0.7);
        CGFloat symbolSize = 52.0;
        
        if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
            symbolSize = 36.0;
        
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(4.0, (_rowHeight * 0.15),
                                                                               imageSize, imageSize)];
        
        if (_legend.useClassColors)
            imageView.image = imageFromSymbol(tlc.symbol, imageSize, tlc.symbolColor);
        
        else
            imageView.image = imageFromSymbol(tlc.symbol, imageSize, _legend.symbolDefaultColor);
        
        imageView.tag = 777;
        [cell.contentView addSubview:imageView];
        
        textOriginX = (MIN(imageView.frame.size.height, (imageView.frame.origin.x + imageView.frame.size.width)) + 4.0);
        textWidth = (self.frame.size.width - textOriginX);
    }
    
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
    if (!_dragSelectActive)
    {
        ThemeLegendCell *tlc = (ThemeLegendCell *)_legend.cells[indexPath.row];
        tlc.status = YES;
        
        if (!_preventRefresh && _delegate)
            [_delegate themeLegendDidChangeStatus:YES];
    }
}

- (void)tableView:(UITableView *)tableView
didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (!_dragSelectActive)
    {
        ThemeLegendCell *tlc = (ThemeLegendCell *)_legend.cells[indexPath.row];
        tlc.status = NO;
        
        if (!_preventRefresh && _delegate)
            [_delegate themeLegendDidChangeStatus:YES];
    }
}

- (CGFloat)statusBarHeight:(UIInterfaceOrientation)orientation
{
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
    {
        if (orientation == UIDeviceOrientationLandscapeLeft ||
            orientation == UIDeviceOrientationLandscapeRight)
        {
            return 0.0;
        }
    }
    
    return 20.0;
}

@end