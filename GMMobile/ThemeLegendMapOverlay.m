//  ThemeLegendMapOverlay.m
//  GMMobile

#import "ThemeLegendMapOverlay.h"
#import "CCodeLibrary/SymbolDictionary.h"
#import "CCodeLibrary/UIImage+ImageFromColor.h"
#import "CCodeLibrary/UserDefaults.h"
#import "ConfigurationControl.h"

@interface ThemeLegendMapOverlay () <UITableViewDataSource,UITableViewDelegate,NVAlertViewDelegate,UIGestureRecognizerDelegate>

@property (weak, nonatomic) id <ThemeLegendMapOverlayDelegate> delegate;
@property (nonatomic) NSUInteger countLength;
@property (nonatomic) UITabBar *tabBar;
@property (nonatomic) CGRect previousFrame, previousScrollFrame;
@property (nonatomic) NSMutableArray *dragSelectedCells;
@property BOOL dragSelectActive, preventRefresh, firstTimeDrag, hideButtons, blockLongPress;
@property NSUInteger currentRow;
@property (nonatomic) UIButton *titleButton;
@property (nonatomic) CGFloat avgPctOfMax, medianPctOfMax, stdDev1Lower, stdDev1Upper, stdDev2Lower, stdDev2Upper, minSymbolWidth;
@property (nonatomic) CGPoint previousContentOffset;
@property (nonatomic) UILongPressGestureRecognizer *longPress;
@property (nonatomic) UITapGestureRecognizer *tap;
@property (nonatomic) UIPanGestureRecognizer *drag;
@property (nonatomic) UIImageView *deleteView;

@end

@implementation ThemeLegendMapOverlay

+ (CGFloat)rowHeight
{
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
        return 22.0;
    
    else
        return 32.0;
}

+ (UIFont *)headerFont
{
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
        return [UIFont systemFontOfSize:11.0];
    
    else
        return [UIFont systemFontOfSize:18.0];
}

+ (UIFont *)expandedHeaderFont
{
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
        return [UIFont systemFontOfSize:16.0];
    
    else
        return [UIFont systemFontOfSize:32.0];
}

+ (UIFont *)expandedFont
{
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
        return [UIFont fontWithName:@"CourierNewPS-BoldMT" size:18.0];
    
    else
        return [UIFont fontWithName:@"CourierNewPS-BoldMT" size:32.0];
}

+ (UIFont *)font
{
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
        return [UIFont fontWithName:@"CourierNewPS-BoldMT" size:14.0];
    
    else
        return [UIFont fontWithName:@"CourierNewPS-BoldMT" size:18.0];
}

+ (CGFloat)width
{
    /*if (ConfigurationControl.sharedInstance.currentApp == HCConfigMetroProp)
    {
        if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
            return 160.0;
        
        else
            return 292.0;
    }
    
    else*/
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
        return 118.0;
    
    else
        return 236.0;
}

+ (ThemeLegendMapOverlay *)drawLegend:(ThemeLegend *)legend
                              withTag:(NSInteger)tag
                             delegate:(id)delegate
                               inView:(UIView *)view
                             atOrigin:(CGPoint)origin
                          hideButtons:(BOOL)hideButtons
{
    if (!view || !delegate)
    {
        NSLog(@"ThemeLegendMapOverlay ERROR:Cannot set delegate or view to nil");
        return nil;
    }
    
    if (![delegate respondsToSelector:@selector(themeLegendDidChangeStatus:)] ||
        ![delegate respondsToSelector:@selector(themeLegendWasDraggedOffLeftSide)] ||
        ![delegate respondsToSelector:@selector(themeLegendWasDraggedOffRightSide)] ||
        ![delegate respondsToSelector:@selector(themeLegendIsOffMap)] ||
        ![delegate respondsToSelector:@selector(statusBarHeight:)])
    {
        NSLog(@"ThemeLegendMapOverlay ERROR:Delegate must respond to all non-optional selectors in protocol");
        return nil;
    }
    
    if (!legend.numCells)
    {
        NSLog(@"ThemeLegendMapOverlay ERROR:Cannot draw if legend has no cells");
        return nil;
    }
    
    ThemeLegendMapOverlay *tlmo = [[ThemeLegendMapOverlay alloc] init];
    tlmo.legend = legend;
    tlmo.backgroundColor = UIColor.clearColor;
    tlmo.tag = tag;
    tlmo.isExpanded = tlmo.dragSelectActive = tlmo.preventRefresh = tlmo.firstTimeDrag = NO;
    tlmo.hideButtons = hideButtons;
    tlmo.delegate = delegate;
    tlmo.tabBar = view.parentViewController.tabBarController.tabBar;
    tlmo.previousFrame = tlmo.previousScrollFrame = CGRectZero;
    tlmo.currentRow = tlmo.currentColorPalette = 0;
    tlmo.previousContentOffset = CGPointZero;
    tlmo.minSymbolWidth = 1.0;
    tlmo.blockLongPress = NO;
    tlmo.dragMargin = 10.0;
    
    for (ThemeLegendCell *cells in tlmo.legend.cells)
    {
        NSString *countString = [NSString stringWithFormat:@"%i", cells.count];
        tlmo.countLength = MAX(tlmo.countLength, countString.length);
    }
    
    tlmo.rowHeight = ThemeLegendMapOverlay.rowHeight;
    tlmo.headerHeight = tlmo.legend.headerHeight;
    tlmo.width = ThemeLegendMapOverlay.width;

    CGFloat height = ((tlmo.legend.numCells * tlmo.rowHeight) + tlmo.headerHeight);
    tlmo.frame = CGRectMake(origin.x, origin.y, tlmo.width, height);
    
    tlmo.tableView = UITableView.new;
    tlmo.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    tlmo.tableView.delegate = tlmo;
    tlmo.tableView.dataSource = tlmo;
    tlmo.tableView.backgroundColor = UIColor.blackColor;
    tlmo.tableView.rowHeight = tlmo.rowHeight;
    tlmo.tableView.scrollEnabled = NO;
    
    if (tlmo.legend.selectionMode == SEL_MODE_COMPARE)
        tlmo.tableView.layer.borderColor = UIColor.greenColor.CGColor;
    
    else
        tlmo.tableView.layer.borderColor = UIColor.blackColor.CGColor;
    
    tlmo.tableView.layer.borderWidth = 2.0;
    tlmo.tableView.delaysContentTouches = NO;
    tlmo.tableView.allowsSelection = NO;
    tlmo.tableView.separatorColor = UIColor.clearColor;
    tlmo.tableView.separatorInset = UIEdgeInsetsZero;
    tlmo.tableView.layoutMargins = UIEdgeInsetsZero;
    
    tlmo.longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:tlmo
                                                                   action:@selector(tlmoLongPressed:)];
    [tlmo.tableView addGestureRecognizer:tlmo.longPress];
    
    UIPinchGestureRecognizer *pgr = [[UIPinchGestureRecognizer alloc] initWithTarget:tlmo
                                                                              action:@selector(tlmoPinched:)];
    [tlmo addGestureRecognizer:pgr];
    
    tlmo.tap = [[UITapGestureRecognizer alloc] initWithTarget:tlmo action:@selector(legendTapped:)];
    tlmo.tap.numberOfTouchesRequired = 1;
    [tlmo.tableView addGestureRecognizer:tlmo.tap];
    
    [tlmo addSubview:tlmo.tableView];
    [tlmo.tableView constrainToView:tlmo leading:0.0 trailing:0.0 top:0.0 bottom:0.0];
    [view addSubview:tlmo];
    
    if (tlmo.legend.hasOverlay)
    {
        int sum = 0, max = 0;
        NSMutableArray<NSNumber *> *countArray = NSMutableArray.array;
        
        for (ThemeLegendCell *tlc in tlmo.legend.cells)
        {
            sum+= tlc.count;
            max = MAX(max, tlc.count);
            tlmo.minSymbolWidth = MIN(tlmo.minSymbolWidth, tlc.symbolWidth);
            [countArray addObject:[NSNumber numberWithInt:tlc.count]];
        }
        
        NSSortDescriptor *sortAscending = [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES];
        [countArray sortUsingDescriptors:[NSArray arrayWithObject:sortAscending]];
        
        if (max)
        {
            CGFloat avgValue = (sum / (CGFloat)tlmo.legend.numCells);
            tlmo.avgPctOfMax = (avgValue / (CGFloat)max);
            tlmo.avgPctOfMax = ((tlmo.avgPctOfMax - tlmo.minSymbolWidth) / (1.0 - tlmo.minSymbolWidth));
            NSInteger middle = (countArray.count / 2);
            CGFloat stdDev = 0.0;
            
            if (countArray.count % 2)
                tlmo.medianPctOfMax = ((countArray[middle].intValue) / (CGFloat)max);
            
            else
            {
                int value1 = (countArray[middle].intValue);
                int value2 = (countArray[middle - 1].intValue);
                tlmo.medianPctOfMax = (((value1 + value2) / 2.0) / (CGFloat)max);
            }
            
            tlmo.medianPctOfMax = ((tlmo.medianPctOfMax - tlmo.minSymbolWidth) / (1.0 - tlmo.minSymbolWidth));
            
            for (ThemeLegendCell *tlc in tlmo.legend.cells)
                stdDev += pow((avgValue - tlc.count), 2);
            
            stdDev = sqrt(stdDev / (CGFloat)tlmo.legend.numCells);
            tlmo.stdDev1Lower = ((avgValue - stdDev) / (CGFloat)max);
            tlmo.stdDev1Upper = ((avgValue + stdDev) / (CGFloat)max);
            tlmo.stdDev2Lower = ((avgValue - (stdDev * 2.0)) / (CGFloat)max);
            tlmo.stdDev2Upper = ((avgValue + (stdDev * 2.0)) / (CGFloat)max);
            tlmo.stdDev1Lower = ((tlmo.stdDev1Lower - tlmo.minSymbolWidth) / (1.0 - tlmo.minSymbolWidth));
            tlmo.stdDev1Upper = ((tlmo.stdDev1Upper - tlmo.minSymbolWidth) / (1.0 - tlmo.minSymbolWidth));
            tlmo.stdDev2Lower = ((tlmo.stdDev2Lower - tlmo.minSymbolWidth) / (1.0 - tlmo.minSymbolWidth));
            tlmo.stdDev2Upper = ((tlmo.stdDev2Upper - tlmo.minSymbolWidth) / (1.0 - tlmo.minSymbolWidth));
        }
    }
    tlmo.drag = [[UIPanGestureRecognizer alloc] initWithTarget:tlmo
                                                        action:@selector(legendDragged:)];
    
    tlmo.drag.delegate = tlmo;
    tlmo.drag.delaysTouchesBegan = YES;
    
    if (ConfigurationControl.sharedInstance.currentApp != HCConfigMetroProp)
    {
        tlmo.deleteView = UIImageView.new;
        [tlmo setupImageView:tlmo.deleteView image:@"redX"];
        [tlmo.deleteView constrainToView:tlmo leading:0.0 trailing:(-tlmo.width / 2) top:0.0 bottom:0.0];
        tlmo.deleteView.contentMode = UIViewContentModeScaleToFill;
    }

    tlmo.moveRightView = UIImageView.new;
    [tlmo setupImageView:tlmo.moveRightView image:@"redArrowRight"];
    [tlmo.moveRightView constrainToView:tlmo leading:0.0 trailing:0.0 top:0.0 bottom:0.0];
    tlmo.moveRightView.contentMode = UIViewContentModeScaleAspectFit;
    
    tlmo.moveLeftView = UIImageView.new;
    [tlmo setupImageView:tlmo.moveLeftView image:@"redArrowLeft"];
    [tlmo.moveLeftView constrainToView:tlmo leading:0.0 trailing:0.0 top:0.0 bottom:0.0];
    tlmo.moveLeftView.contentMode = UIViewContentModeScaleAspectFit;
    
    return tlmo;
}

- (void)setupImageView:(UIImageView *)imageView
                 image:(NSString *)image
{
    imageView.translatesAutoresizingMaskIntoConstraints = NO;
    imageView.hidden = YES;
    imageView.alpha = 0.5;
    
    imageView.image = [UIImage imageWithContentsOfFile:[NSBundle.mainBundle pathForResource:image
                                                                                     ofType:@"png"]];
    
    [self addSubview:imageView];
}

- (void)tlmoLongPressed:(UILongPressGestureRecognizer *)gesture
{
    if (_blockLongPress)
        return;
    
    UITableView *tv = (UITableView *)gesture.view;
    CGPoint point = [gesture locationInView:tv];
    
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
                    ThemeLegendCell *tlc = (ThemeLegendCell *)_legend.cells[row];
                    
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
            }
            
            _preventRefresh = NO;
            [_delegate themeLegendDidChangeStatus:_dragSelectActive];
            _dragSelectActive = NO;
        }
            break;
        
        case UIGestureRecognizerStateBegan:
        {
            if (point.y > _headerHeight)
            {
                _dragSelectActive = YES;
                _dragSelectedCells = NSMutableArray.array;
                _firstTimeDrag = YES;
            }
            
            _preventRefresh = YES;
        }
            
        default:
        {
            if ((point.y > _headerHeight) && _dragSelectActive)
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
    return (NSInteger)_legend.numCells;
}

- (CGFloat)tableView:(UITableView *)tableView
heightForHeaderInSection:(NSInteger)section
{
    return _headerHeight;
}

- (UIView *)tableView:(UITableView *)tableView
viewForHeaderInSection:(NSInteger)section
{
    UIView *headerView = UIView.new;
    headerView.backgroundColor = UIColor.blackColor;
    headerView.contentMode = UIViewContentModeCenter;
    CGFloat size = 40.0;
    
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
        size = 32.0;
    
    if (![headerView.subviews containsObject:_titleButton])
    {
        if (!_titleButton)
        {
            _titleButton = [UIButton buttonWithType:UIButtonTypeCustom];
            _titleButton.translatesAutoresizingMaskIntoConstraints = NO;
            _titleButton.titleLabel.textAlignment = NSTextAlignmentCenter;
            _titleButton.titleLabel.adjustsFontSizeToFitWidth = YES;
            _titleButton.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
            _titleButton.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
            
            [_titleButton setTitleColor:UIColor.whiteColor
                               forState:UIControlStateNormal];
            
            if (_legend.titles.count > 1 || _legend.hasColors)
            {
                [_titleButton setTitleColor:UIColor.greenColor
                                   forState:UIControlStateHighlighted];
                
                [_titleButton addTarget:self
                                 action:@selector(showLegendOptions:)
                       forControlEvents:UIControlEventTouchUpInside];
            }
            
            else
            {
                [_titleButton setTitleColor:UIColor.redColor
                                   forState:UIControlStateHighlighted];
            }
            
            [_titleButton setTitle:_legend.title forState:UIControlStateNormal];
            [_titleButton addGestureRecognizer:_drag];
        }
        
        [headerView addSubview:_titleButton];
        
        CGFloat margin = 4.0;
        
        if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
            margin = 2.0;
             
        
        [_titleButton constrainToView:headerView leading:margin trailing:-margin top:margin bottom:-margin];
    }
    
    if (_isExpanded)
        _titleButton.titleLabel.font = ThemeLegendMapOverlay.expandedHeaderFont;
    
    else
        _titleButton.titleLabel.font = ThemeLegendMapOverlay.headerFont;
    
    return headerView;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

- (void)legendDragged:(UIPanGestureRecognizer *)gesture
{
    if (_isExpanded)
        return;
    
    CGFloat statusBarHeight = [self statusBarHeight:UIApplication.sharedApplication.statusBarOrientation];
    UIView *superview = self.superview;
    CGRect frame = self.frame;
    
    BOOL inRemovalPos = ((frame.origin.x + (frame.size.width / 2.0)) > superview.frame.size.width);
    BOOL inLeftDraggedPos = (frame.origin.x < -_dragMargin);
    BOOL inRightDraggedPos = ((frame.origin.x + frame.size.width) > superview.frame.size.width);
    
    if (gesture.state == UIGestureRecognizerStateBegan)
        _blockLongPress = YES;
    
    else if (gesture.state == UIGestureRecognizerStateEnded)
    {
        CGPoint location = [gesture locationInView:superview];
        
        _tableView.layer.borderColor = UIColor.blackColor.CGColor;
        _tableView.layer.borderWidth = 2.0;
        
        /*if (CRAPI.sharedInstance.currentApp == HCConfigMetroProp)
        {
            CGFloat margin = 8.0, size = 52.0;
            
            if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
                margin = 4.0, size = 44;
            
            if (location.x > (superview.frame.size.width - (size + (margin * 2.0))) &&
                location.y < (size + statusBarHeight + (margin * 2.0)))
            {
                if ([_delegate respondsToSelector:@selector(themeLegendDidWantMinimize)])
                    [_delegate themeLegendDidWantMinimize];
            }
            
            else
            {
                margin = 2.0;
                CGPoint center = self.center;
                center.x = MAX(center.x, (frame.size.width * 0.5) + margin);
                center.x = MIN(center.x, superview.frame.size.width - (frame.size.width * 0.5) - margin);
                center.y = MAX(center.y, (frame.size.height * 0.5) + margin);
                center.y = MIN(center.y, superview.frame.size.height - (frame.size.height * 0.5) - margin);
                self.center = center;
                
                if (UIApplication.sharedApplication.statusBarOrientation == UIDeviceOrientationLandscapeLeft ||
                    UIApplication.sharedApplication.statusBarOrientation == UIDeviceOrientationLandscapeRight)
                {
                    _legend.landscapeMapOrigin = frame.origin;
                    _legend.isDraggedLandscape = YES;
                }
                
                else
                {
                    _legend.portraitMapOrigin = frame.origin;
                    _legend.isDraggedPortrait = YES;
                }
            }
        }
        
        else*/
        
        if (CRAPI.sharedInstance.currentApp == HCConfigMetroProp)
        {
            if (_legend.drawOnMap)
                inRightDraggedPos = (inRightDraggedPos || inRemovalPos);
            
            inRemovalPos = NO;
        }
        
        if (inRemovalPos)
            _legend.drawOnMap = NO;
        
        else if (_delegate.themeLegendIsOffMap)
        {
            if (inLeftDraggedPos)
                [_delegate themeLegendWasDraggedOffLeftSide];
        }
        
        else
        {
            if (inRightDraggedPos)
                [_delegate themeLegendWasDraggedOffRightSide];
            
            else
            {
                CGFloat yPos = MIN(MAX(frame.origin.y, statusBarHeight),
                                   (superview.frame.size.height - frame.size.height));
                
                CGPoint origin = CGPointMake(MAX(frame.origin.x, 0.0), yPos);
                
                if (UIApplication.sharedApplication.statusBarOrientation == UIDeviceOrientationLandscapeLeft ||
                    UIApplication.sharedApplication.statusBarOrientation == UIDeviceOrientationLandscapeRight)
                {
                    _legend.landscapeMapOrigin = origin;
                    _legend.isDraggedLandscape = YES;
                }
                
                else
                {
                    _legend.portraitMapOrigin = origin;
                    _legend.isDraggedPortrait = YES;
                }
            }
        }
        
        [_delegate themeLegendDidChangeStatus:NO];
        _blockLongPress = NO;
    }
    
    else
    {
        CGPoint translation = [gesture translationInView:superview];
        BOOL deleteHidden = YES;
        
        if (_delegate.themeLegendIsOffMap)
            self.center = CGPointMake((self.center.x + translation.x), self.center.y);
        
        else
            self.center = CGPointMake((self.center.x + translation.x), (self.center.y + translation.y));
        
        [gesture setTranslation:CGPointZero inView:superview];
        
        if (ConfigurationControl.sharedInstance.currentApp != HCConfigMetroProp)
            deleteHidden = _deleteView.hidden = !inRemovalPos;
        
        if (_delegate.themeLegendIsOffMap)
        {
            if ([_delegate respondsToSelector:@selector(updateLeftArrowVisibility:)])
                [_delegate updateLeftArrowVisibility:!inLeftDraggedPos];
        }
        
        else
        {
            if ([_delegate respondsToSelector:@selector(updateRightArrowVisibility:)])
                [_delegate updateRightArrowVisibility:!inRightDraggedPos || !deleteHidden];
        }
    }
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
    
    switch (_legend.selectionMode)
    {
        case SEL_MODE_SELECT:
            [textArray addObject:@"Switch to Compare Mode"];
            break;
        case SEL_MODE_COMPARE:
            [textArray addObject:@"Switch to Selection Mode"];
            break;
        default:break;
    }
    
    if (!_legend.usePointSymbols)
    {
        if (_legend.hasOverlay)
            [textArray addObject:@"Disable Stats Overlay"];
        
        else
            [textArray addObject:@"Enable Stats Overlay"];
    }
    
    [textArray addObject:@"Color Symbols\nUsing Exising Colors\nFor This Legend"];
    [textArray addObject:@"Color Symbols\nBy Selecting Colors\nFor This Legend"];
    [textArray addObject:@"Zoom to Item With\nMaximum Value"];
    
    NSMutableArray *idArray = NSMutableArray.array;
    [idArray addObject:[NSNumber numberWithInteger:TLTCancel]];
    [idArray addObject:[NSNumber numberWithInteger:TLTSwitchMode]];
    [idArray addObject:[NSNumber numberWithInteger:TLTOverlay]];
    [idArray addObject:[NSNumber numberWithInteger:TLTApplyExistingColors]];
    [idArray addObject:[NSNumber numberWithInteger:TLTSelectColors]];
    [idArray addObject:[NSNumber numberWithInteger:TLTZoomToMax]];
    
    if (_legend.titles.count > 1)
    {
        [textArray addObject:@"Select Legend Title"];
        [idArray addObject:[NSNumber numberWithInteger:TLTTitles]];
    }
    
    NVAlertView *alert = [NVAlertView showLargeAlertViewinView:superview
                                                      delegate:self
                                                         title:[NSString stringWithFormat:@"Legend Options for\n%@",
                                                                _legend.title]
                                               buttonTextArray:textArray
                                              destructiveIndex:1];
    alert.buttonIdentifiers = idArray;
    alert.identifier = @"TopLevelAlert";
    
    if (_isExpanded)
        _tabBar.alpha = 0.0;
    
    if ([_delegate respondsToSelector:@selector(clearVectorView)])
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
    
    if ([_delegate respondsToSelector:@selector(clearVectorView)])
        [_delegate clearVectorView];
}

- (void)alertView:(NVAlertView *)alertView
didTapButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex > 0)
    {
        if ([alertView.identifier isEqualToString:@"TopLevelAlert"])
        {
            if (alertView.buttonIdentifiers.count > buttonIndex)
            {
                NSNumber *num = alertView.buttonIdentifiers[buttonIndex];
                buttonIndex = num.integerValue;
            }
            
            switch (buttonIndex)
            {
                case TLTSwitchMode:
                    _legend.selectionMode = (_legend.selectionMode == SEL_MODE_SELECT) ? SEL_MODE_COMPARE : SEL_MODE_SELECT;
                    [ConfigurationControl.sharedInstance clearCompareModeForLegendsOtherThanLegend:_legend];
                    [_delegate themeLegendDidChangeStatus:YES];
                    break;
                case TLTOverlay:
                    _legend.hasOverlay = !_legend.hasOverlay;
                    [_delegate themeLegendDidChangeStatus:YES];
                    break;
                case TLTApplyExistingColors:
                    break;
                case TLTSelectColors:{
                    NVAlertView *alert = [NVAlertView showLargeAlertViewinView:alertView.superview
                                                                      delegate:self
                                                                         title:@"Select Color Scheme"
                                                               buttonTextArray:NVColorSet.colorOptions
                                                              destructiveIndex:1];
                    
                    alert.identifier = @"ColorOptionsAlert";
                    break;}
                case TLTTitles:{
                    NSMutableArray *textArray = NSMutableArray.array;
                    [textArray addObject:@"Cancel"];
                    [textArray addObjectsFromArray:_legend.titles.copy];
                    
                    NVAlertView *alert = [NVAlertView showLargeAlertViewinView:alertView.superview
                                                                      delegate:self
                                                                         title:@"Select Legend Title"
                                                               buttonTextArray:textArray
                                                              destructiveIndex:1];
                    
                    alert.identifier = @"TitlesAlert";
                    break;}
                case TLTZoomToMax:{
                    MNMXCORD bnds = _legend.maxValBounds;
                    
                    if ([_delegate respondsToSelector:@selector(zoomToBounds:)])
                        [_delegate zoomToBounds:bnds];
                    break;}
            }
            
            [alertView hideLargeAlertView:YES];
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
                case NVColorOptionReds:{
                    NSArray *colorArray = [NVColorSet redsArrayWithNumComponents:_legend.numCells];
                    
                    for (int i = 0; i < _legend.numCells; i++)
                    {
                        ThemeLegendCell *tlc = (ThemeLegendCell *)_legend.cells[i];
                        tlc.symbolColor = (NVColor *)colorArray[i];
                    }
                    
                    [_tableView reloadData];
                    break;}
                case NVColorOptionGreens:{
                    NSArray *colorArray = [NVColorSet greensArrayWithNumComponents:_legend.numCells];
                    
                    for (int i = 0; i < _legend.numCells; i++)
                    {
                        ThemeLegendCell *tlc = (ThemeLegendCell *)_legend.cells[i];
                        tlc.symbolColor = (NVColor *)colorArray[i];
                    }
                    
                    [_tableView reloadData];
                    break;}
                case NVColorOptionBlues:{
                    NSArray *colorArray = [NVColorSet bluesArrayWithNumComponents:_legend.numCells];
                    
                    for (int i = 0; i < _legend.numCells; i++)
                    {
                        ThemeLegendCell *tlc = (ThemeLegendCell *)_legend.cells[i];
                        tlc.symbolColor = (NVColor *)colorArray[i];
                    }
                    
                    [_tableView reloadData];
                    break;}
                case NVColorOptionRandom:{
                    NVAlertView *alert = [NVAlertView showLargeAlertViewinView:alertView.superview
                                                                      delegate:self
                                                                         title:@"Select Color Palette"
                                                               buttonTextArray:NVColorSet.randomColorPaletteOptions
                                                              destructiveIndex:1];
                    
                    alert.identifier = @"RandomColorAlert";
                    [alertView hideLargeAlertView:YES];
                    return;break;}
                case NVColorOptionCustom:
                    break;
                default:break;
            }
        }
        
        else if ([alertView.identifier isEqualToString:@"RandomColorAlert"] ||
                 [alertView.identifier isEqualToString:@"RandomColorConfirmation"])
        {
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
            
            [_delegate randomColorsSelectedWithOption:_currentColorPalette
                                       forThemeLegend:self];
            
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
            
            [alertView hideLargeAlertView:YES];
            return;
        }
    }
    
    if (!_isExpanded)
    {
        [_delegate themeLegendDidChangeStatus:YES];
        
        [UIView animateWithDuration:0.25
                         animations:^{
                             _tabBar.alpha = 1.0;
                         }];
        
        _tabBar.userInteractionEnabled = YES;
    }
    
    [alertView hideLargeAlertView:YES];
    
    if (_isExpanded)
        _tabBar.alpha = 0.0;
}

- (void)expandLegend
{
    CGFloat statusBarHeight = [self statusBarHeight:UIApplication.sharedApplication.statusBarOrientation];
    
    if (!_isExpanded)
    {
        if (_delegate && [_delegate respondsToSelector:@selector(themeLegendWillExpand)])
            [_delegate themeLegendWillExpand];
        
        _isExpanded = YES;
        CGRect bounds = UIScreen.mainScreen.bounds;
        CGFloat longestSide = MAX(bounds.size.height, bounds.size.width);
        CGFloat shortestSide = MIN(bounds.size.height, bounds.size.width);
        self.translatesAutoresizingMaskIntoConstraints = NO;

        CGSize superSize = self.superview.frame.size;
        CGFloat contentOffset = 0.0, expandCorrection = 0.0;
        
        if ([self.superview isKindOfClass:UIScrollView.class])
        {
            UIScrollView *legendScroll = (UIScrollView *)self.superview;
            [legendScroll.superview bringSubviewToFront:self.superview];
            [legendScroll bringSubviewToFront:self];
            legendScroll.scrollEnabled = NO;
            _previousScrollFrame = legendScroll.frame;
            _previousContentOffset = legendScroll.contentOffset;
            
            superSize = legendScroll.superview.frame.size;
            expandCorrection = (legendScroll.contentSize.height - longestSide);
            contentOffset = MIN(legendScroll.contentOffset.y, expandCorrection);
            contentOffset = MAX(contentOffset, 0.0);
        }
        
        _previousFrame = self.frame;
        
        _rowHeight = MIN((ThemeLegendMapOverlay.rowHeight * 4.0),
                         ((shortestSide * 0.95) / (_legend.numCells + 1)));
        
        _headerHeight = _rowHeight;
        _tableView.rowHeight = _rowHeight;
        _tabBar.userInteractionEnabled = NO;
        CGFloat legendHeight = (_rowHeight * (_legend.numCells + 1));
        
        if ([self.superview isKindOfClass:UIScrollView.class])
        {
            UIScrollView *legendScroll = (UIScrollView *)self.superview;
            
            [legendScroll constrainToView:legendScroll.superview leading:0.0
                                 trailing:0.0 top:0.0 bottom:_tabBar.frame.size.height];
        }
        
        else
            contentOffset += (_tabBar.frame.size.height / 2.0);

        _tabBar.alpha = 0.0;
        
        [self constrainLeadingToAnchor:self.superview.centerXAnchor constant:(-shortestSide * 0.475)];
        [self constrainTrailingToAnchor:self.superview.centerXAnchor constant:(shortestSide * 0.475)];
        [self constrainTopToAnchor:self.superview.centerYAnchor constant:((-legendHeight / 2.0) + contentOffset)];
        [self constrainBottomToAnchor:self.superview.centerYAnchor constant:((legendHeight / 2.0) + contentOffset)];
        
        for (ThemeLegendMapOverlay *tlmos in self.superview.subviews)
        {
            if ([tlmos isKindOfClass:ThemeLegendMapOverlay.class] && tlmos != self)
                tlmos.alpha = 0.0;
        }
        
        [_tableView performSelector:@selector(reloadData) withObject:nil afterDelay:0.05];
    }
    
    else
    {
        _isExpanded = NO;
        [self removeAllConstraints];
        self.translatesAutoresizingMaskIntoConstraints = YES;
        
        _rowHeight = ThemeLegendMapOverlay.rowHeight;
        _headerHeight = _legend.headerHeight;
        
        _tabBar.userInteractionEnabled = YES;
        _tableView.rowHeight = _rowHeight;
        _tabBar.alpha = 1.0;
        
        if ([self.superview isKindOfClass:UIScrollView.class])
        {
            UIScrollView *legendScroll = (UIScrollView *)self.superview;
            [legendScroll removeAllConstraints];
            [legendScroll constrainLeadingToAnchor:legendScroll.superview.trailingAnchor constant:-_previousScrollFrame.size.width];
            [legendScroll constrainTrailingToAnchor:legendScroll.superview.trailingAnchor];
            [legendScroll constrainTopToAnchor:legendScroll.superview.topAnchor constant:statusBarHeight];
            [legendScroll constrainBottomToAnchor:legendScroll.superview.bottomAnchor];
            [legendScroll setContentOffset:_previousContentOffset animated:NO];
            
            self.frame = _previousFrame;
        }
        
        else if (UIApplication.sharedApplication.statusBarOrientation == UIDeviceOrientationLandscapeLeft ||
                 UIApplication.sharedApplication.statusBarOrientation == UIDeviceOrientationLandscapeRight)
        {
            self.frame = CGRectMake(_legend.landscapeMapOrigin.x, _legend.landscapeMapOrigin.y,
                                    _previousFrame.size.width, _previousFrame.size.height);
        }
        
        else
        {
            self.frame = CGRectMake(_legend.portraitMapOrigin.x, _legend.portraitMapOrigin.y,
                                    _previousFrame.size.width, _previousFrame.size.height);
        }
        
        for (ThemeLegendMapOverlay *tlmos in self.superview.subviews)
        {
            if ([tlmos isKindOfClass:ThemeLegendMapOverlay.class] && tlmos != self)
                tlmos.alpha = 1.0;
        }
        
        [_tableView reloadData];
        
        if ([self.superview isKindOfClass:UIScrollView.class])
        {
            UIScrollView *legendScroll = (UIScrollView *)self.superview;
            legendScroll.scrollEnabled = YES;
        }
        
        if (_delegate && [_delegate respondsToSelector:@selector(themeLegendDidShrink)])
            [_delegate themeLegendDidShrink];
        
        [_delegate themeLegendDidChangeStatus:NO];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellID = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    int row = (int)indexPath.row;
    
    if (!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:cellID];
    }
    
    for (UIView *views in cell.contentView.subviews)
    {
        if (views.tag == 666 || views.tag == 777 || views.tag == 888 || views.tag == 999 ||
            views.tag == 998 || views.tag == 997 || views.tag == 996)
            [views removeFromSuperview];
    }
    
    ThemeLegendCell *tlc = (ThemeLegendCell *)_legend.cells[row];
    
    NSMutableString *text = tlc.label.mutableCopy;
    CGFloat margin = 4.0;
    
    if (_legend.appendClassCount)
    {
        NSMutableString *countString = NSMutableString.string;
        
        if (tlc.status)
            [countString insertString:[NSString stringWithFormat:@"%i", tlc.count] atIndex:0];
        
        else
            [countString insertString:@"X" atIndex:0];
        
        while (countString.length < _countLength)
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
    
    if (tlc.status == TLC_STATUS_ON || tlc.status == TLC_STATUS_COMPARE)
    {
        cell.backgroundColor = UIColor.whiteColor;
        
        if (tlc.status == TLC_STATUS_COMPARE)
        {
            if (_legend.selectionMode == SEL_MODE_SELECT)
                tlc.status = TLC_STATUS_ON;
            
            else
            {
                cell.layer.borderColor = _legend.symbolDefaultColor.CGColor;
                cell.layer.borderWidth = (cell.frame.size.height / 12);
            }
        }
    }
    
    else
        cell.backgroundColor = UIColor.lightGrayColor;
    
    UILabel *textLabel = UILabel.new;
    textLabel.translatesAutoresizingMaskIntoConstraints = NO;
    textLabel.textColor = UIColor.blackColor;
    
    if (_isExpanded)
        textLabel.font = ThemeLegendMapOverlay.expandedFont;
    
    else
        textLabel.font = ThemeLegendMapOverlay.font;
    
    textLabel.text = text.copy;
    textLabel.textAlignment = NSTextAlignmentCenter;
    textLabel.adjustsFontSizeToFitWidth = YES;
    textLabel.backgroundColor = UIColor.clearColor;
    textLabel.numberOfLines = 1;
    textLabel.tag = 888;
    
    cell.textLabel.backgroundColor = UIColor.clearColor;
    cell.contentView.backgroundColor = UIColor.clearColor;
    cell.contentView.translatesAutoresizingMaskIntoConstraints = NO;
    [cell.contentView constrainToView:cell leading:0.0 trailing:0.0 top:0.0 bottom:0.0];
    
    NSDictionary *attributes = @{NSFontAttributeName:textLabel.font};
    
    CGRect textSize = [text boundingRectWithSize:cell.frame.size
                                         options:NSStringDrawingUsesLineFragmentOrigin
                                      attributes:attributes
                                         context:nil];
    
    CGFloat textWidth = ceil(textSize.size.width);
    CGFloat textOriginX = MAX((tableView.frame.size.width - textWidth), margin);
    
    if (_legend.usePointSymbols)
    {
        CGFloat imageSize = (_rowHeight * 0.7);
        textOriginX = (imageSize + (margin * 2.0));
        textWidth = (self.frame.size.width - textOriginX);
        
        UIImageView *imageView = UIImageView.new;
        imageView.translatesAutoresizingMaskIntoConstraints = NO;
        imageView.tag = 777;
        
        if (_legend.useClassColors)
            imageView.image = imageFromSymbol(tlc.symbol, imageSize, tlc.symbolColor);
        
        else
            imageView.image = imageFromSymbol(tlc.symbol, imageSize, _legend.symbolDefaultColor);
        
        [cell.contentView addSubview:imageView];
        
        [imageView constrainToView:cell.contentView leading:margin trailing:(-textWidth - margin)
                               top:(_rowHeight * 0.15) bottom:(-_rowHeight * 0.15)];
    }
    
    else
    {
        textWidth = MIN(textWidth, (tableView.frame.size.width * 0.85));
        textOriginX = (tableView.frame.size.width - textWidth);
        
        if (!_legend.showSymbolAsBarChart)
            tlc.symbolWidth = 1.0;
        
        UIView *barView = UIView.new;
        barView.translatesAutoresizingMaskIntoConstraints = NO;
        barView.layer.borderColor = UIColor.blackColor.CGColor;
        barView.layer.borderWidth = 1.0;
        barView.tag = 666;
        
        if (_legend.useClassColors)
            barView.backgroundColor = tlc.symbolColor;
        
        else
            barView.backgroundColor = _legend.symbolDefaultColor;
        
        [cell.contentView addSubview:barView];
        
        if (_legend.hasOverlay)
        {
            CGFloat newSymbolWidth = ((tlc.symbolWidth - _minSymbolWidth) / (1.0 - _minSymbolWidth));
            CGFloat barMask = (((tableView.frame.size.width - textWidth) - (margin * 2.0)) * (1 - newSymbolWidth));
            
            [barView constrainToView:cell.contentView leading:margin trailing:(-textWidth - barMask - margin)
                                 top:(tableView.rowHeight * 0.15) bottom:(-tableView.rowHeight * 0.15)];
            
            CGFloat mask = ((tableView.frame.size.width - textWidth) - (margin * 2.0));
            CGFloat avgMask = (mask * (1 - _avgPctOfMax));
            CGFloat medianMask = (mask * (1 - _medianPctOfMax));
            CGFloat upperStdDev1Mask =  (mask * (1 - _stdDev1Upper));
            CGFloat lowerStdDev1Mask = (mask * _stdDev1Lower);
            CGFloat upperStdDev2Mask =  (mask * (1 - _stdDev2Upper));
            CGFloat lowerStdDev2Mask = (mask * _stdDev2Lower);
            
            UIView *avgView = UIView.new;
            avgView.translatesAutoresizingMaskIntoConstraints = NO;
            avgView.backgroundColor = UIColor.redColor;
            avgView.tag = 999;
            
            [cell.contentView addSubview:avgView];
            [avgView constrainTopToAnchor:cell.contentView.topAnchor];
            [avgView constrainBottomToAnchor:cell.contentView.bottomAnchor];
            
            [avgView constrainTrailingToAnchor:cell.contentView.trailingAnchor
                                      constant:(-textWidth - avgMask - margin + 1.0)];
            
            [avgView constrainWidthToConstant:2.0];
            
            UIView *medianView = UIView.new;
            medianView.translatesAutoresizingMaskIntoConstraints = NO;
            medianView.backgroundColor = UIColor.blueColor;
            medianView.tag = 998;
            
            [cell.contentView addSubview:medianView];
            [medianView constrainTopToAnchor:cell.contentView.topAnchor];
            [medianView constrainBottomToAnchor:cell.contentView.bottomAnchor];
            
            [medianView constrainTrailingToAnchor:cell.contentView.trailingAnchor
                                         constant:(-textWidth - medianMask - margin + 1.0)];
            
            [medianView constrainWidthToConstant:2.0];
            
            UIView *stdDev1View = UIView.new;
            stdDev1View.translatesAutoresizingMaskIntoConstraints = NO;
            stdDev1View.backgroundColor = UIColor.blackColor;
            stdDev1View.alpha = 0.05;
            stdDev1View.tag = 997;
            
            [cell.contentView addSubview:stdDev1View];
            [stdDev1View constrainTopToAnchor:cell.contentView.topAnchor];
            [stdDev1View constrainBottomToAnchor:cell.contentView.bottomAnchor];
            
            [stdDev1View constrainTrailingToAnchor:cell.contentView.trailingAnchor
                                          constant:(-textWidth - upperStdDev1Mask - margin + 1.0)];
            
            [stdDev1View constrainLeadingToAnchor:cell.contentView.leadingAnchor
                                         constant:(margin + lowerStdDev1Mask + 1.0)];
            
            UIView *stdDev2View = UIView.new;
            stdDev2View.translatesAutoresizingMaskIntoConstraints = NO;
            stdDev2View.backgroundColor = UIColor.blackColor;
            stdDev2View.alpha = 0.05;
            stdDev2View.tag = 996;
            
            [cell.contentView addSubview:stdDev2View];
            [stdDev2View constrainTopToAnchor:cell.contentView.topAnchor];
            [stdDev2View constrainBottomToAnchor:cell.contentView.bottomAnchor];
            
            [stdDev2View constrainTrailingToAnchor:cell.contentView.trailingAnchor
                                          constant:(-textWidth - upperStdDev2Mask - margin + 1.0)];
            
            [stdDev2View constrainLeadingToAnchor:cell.contentView.leadingAnchor
                                         constant:(margin + lowerStdDev2Mask + 1.0)];
        }
        
        else
        {
            CGFloat barMask = (((tableView.frame.size.width - textWidth) - (margin * 2.0)) * (1 - tlc.symbolWidth));
            
            [barView constrainToView:cell.contentView leading:margin trailing:(-textWidth - barMask - margin)
                                 top:(tableView.rowHeight * 0.15) bottom:(-tableView.rowHeight * 0.15)];
        }
    }
    
    [cell.contentView addSubview:textLabel];
    [textLabel constrainToView:cell.contentView leading:textOriginX trailing:0.0 top:0.0 bottom:0.0];
    
    return cell;
}

- (void)setThemeLegendCellStatusTo:(int)status
                          forClass:(NSInteger)class
                   andThemeWithTag:(NSInteger)tag
{
    ThemeLegendCell *tlc = (ThemeLegendCell *)_legend.cells[class];
    tlc.status = status;
}

- (void)turnOnJustThisRow:(NSInteger)row
              inTableView:(UITableView *)tableView
{
    for (int irow = 0; irow < _legend.numCells; irow++)
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
        ThemeLegendCell *tlc = (ThemeLegendCell *)_legend.cells[row];
        
        switch (_legend.selectionMode)
        {
            case SEL_MODE_SELECT:
                tlc.status = (tlc.status == TLC_STATUS_ON) ? TLC_STATUS_OFF : TLC_STATUS_ON;
                break;
            case SEL_MODE_COMPARE:
                tlc.status = (tlc.status == TLC_STATUS_COMPARE) ? TLC_STATUS_ON : TLC_STATUS_COMPARE;
                break;
            default:break;
        }
        
        if (!_preventRefresh && _delegate)
            [_delegate themeLegendDidChangeStatus:YES];
    }
}

- (CGFloat)statusBarHeight:(UIInterfaceOrientation)orientation
{
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
    {
        if (orientation == UIDeviceOrientationLandscapeLeft || orientation == UIDeviceOrientationLandscapeRight)
            return 0.0;
    }
    
    return 20.0;
}

- (void)tlmoPinched:(UIPinchGestureRecognizer *)gesture
{
    if (gesture.state == UIGestureRecognizerStateEnded)
        [self expandLegend];
}

- (void)disableSelect
{
    [self disableMultipleSelect];
    [_tableView removeGestureRecognizer:_tap];
}

- (void)disableMultipleSelect
{
    [_tableView removeGestureRecognizer:_longPress];
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if (_isExpanded && (gestureRecognizer == _drag))
        return NO;
    
    else
        return YES;
}

@end
