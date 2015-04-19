//  MapToolbar.m
//  GMMobile

#import "MapToolbar.h"

@interface MapToolbar ()

@property (nonatomic) UIButton *extentsButton, *userLocationButton, *legendsButton, *digitizeButton;
@property (nonatomic) UISegmentedControl *mapTypeSC, *platSC;
@property (nonatomic) UISwitch *markerSwitch;
@property (nonatomic) CGSize size;
@property BOOL configChanged, myLocationEnabled, platMode;
@property BOOL wantPlat, wantDigitize, wantMapType, wantUserLocation, wantExtents, wantLegends, wantMarkerSwitch;
@property (nonatomic) CGFloat buttonSize, switchHeight, switchWidth, SCHeight, mapTypeSCWidth, mapTypeSCVertWidth;
@property (nonatomic) CGFloat buttonMargin, switchMargin, SCMargin, platSCWidth, platSCVertWidth;

@end

@implementation MapToolbar

+ (MapToolbar *)showMapToolbarWithCenter:(CGPoint)center
                                    view:(UIView *)view
                                delegate:(id)delegate
                             orientation:(MapToolbarOrientation)orientation;
{
    MapToolbar *mt = [[MapToolbar alloc] init];
    mt.configChanged = NO;
    
    //set default configuration
    mt.wantUserLocation = mt.wantExtents = mt.wantMarkerSwitch = YES;
    mt.wantPlat = mt.wantDigitize = mt.wantMapType = mt.wantLegends = NO;
    
    //set internal sizes for all devices
    mt.buttonSize = 47.0, mt.switchHeight = 31.0, mt.switchWidth = 51.0, mt.SCHeight = 29.0, mt.mapTypeSCWidth = 128.0;
    mt.buttonMargin = 8.0, mt.switchMargin = 16.0, mt.SCMargin = 17.0, mt.platSCWidth = 196.0;
    mt.mapTypeSCVertWidth = 76.0, mt.platSCVertWidth = 112.0;
    
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
    {
        //reset internal sizes for iPhone
        mt.buttonSize = 39.0, mt.buttonMargin = 5.0, mt.switchMargin = 9.0, mt.SCMargin = 10.0;
        mt.mapTypeSCWidth = 78.0, mt.platSCWidth = 166.0;
    }
    
    //set default size for either iPhone or iPad
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
        mt.size = CGSizeMake(149.0, 49.0);
    
    else
        mt.size = CGSizeMake(177.0, 63.0);
    
    mt.backgroundColor = UserDefaults.defaults.appleBlue;
    mt.frame = CGRectMake(0.0, 0.0, mt.size.width, mt.size.height);
    mt.center = center;
    mt.layer.borderWidth = 2.0;
    mt.layer.borderColor = UIColor.blackColor.CGColor;
    mt.delegate = delegate;
    
    [view addSubview:mt];
    
    mt.userLocationButton = [[UIButton alloc] initWithFrame:CGRectMake(mt.buttonMargin, mt.buttonMargin,
                                                                       mt.buttonSize, mt.buttonSize)];
    
    [mt setupButton:mt.userLocationButton
         imageTitle:@"userLocation"
         edgeInsets:UIEdgeInsetsMake(5.0, 5.0, 5.0, 5.0)
             target:mt
           selector:@selector(userLocationSelected:)];

    //add user location button by default
    [mt addSubview:mt.userLocationButton];
    
    mt.extentsButton = [[UIButton alloc] initWithFrame:CGRectMake((mt.buttonSize + (mt.buttonMargin * 2.0)),
                                                                  mt.buttonMargin, mt.buttonSize, mt.buttonSize)];
    
    [mt setupButton:mt.extentsButton
         imageTitle:@"zoom"
         edgeInsets:UIEdgeInsetsMake(-2.0, -2.0, -2.0, -2.0)
             target:mt
           selector:@selector(extentsSelected:)];
  
    //add extents button by default
    [mt addSubview:mt.extentsButton];
    
    mt.markerSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(((mt.buttonSize * 2.0) + (mt.buttonMargin * 3.0)),
                                                                 mt.switchMargin, mt.switchWidth, mt.switchHeight)];
    
    [mt.markerSwitch addTarget:mt
                        action:@selector(markerSwitchSelected:)
              forControlEvents:UIControlEventValueChanged];
    
    mt.markerSwitch.on = YES;
    mt.markerSwitch.tintColor = UIColor.redColor;
    
    //add marker switch by default
    [mt addSubview:mt.markerSwitch];
    
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
        mt.mapTypeSC = [[UISegmentedControl alloc] initWithItems:@[@"Stnd", @"Hybd"]];
    
    else
        mt.mapTypeSC = [[UISegmentedControl alloc] initWithItems:@[@"Standard", @"Hybrid"]];
    
    [mt setupSegControl:mt.mapTypeSC
   selectedSegmentIndex:0
                 target:mt
               selector:@selector(mapTypeSelected:)];
    
    //map type SC is NOT added by default
    
    mt.digitizeButton = [[UIButton alloc] init];
    
    [mt setupButton:mt.digitizeButton
         imageTitle:@"digitize"
         edgeInsets:UIEdgeInsetsMake(5.0, 5.0, 5.0, 5.0)
             target:mt
           selector:@selector(digitizeSelected:)];
    
    //digitize button is NOT added by default
    
    mt.legendsButton = [[UIButton alloc] init];
    
    [mt setupButton:mt.legendsButton
         imageTitle:@"list"
         edgeInsets:UIEdgeInsetsZero
             target:mt
           selector:@selector(legendsSelected:)];
    
    //legends button is NOT added by default
    
    mt.platSC = [[UISegmentedControl alloc] initWithItems:@[@"Full", @"Split", @"Tri", @"Plat"]];
    
    [mt setupSegControl:mt.platSC
   selectedSegmentIndex:MapViewScreenSettingFullscreen
                 target:mt
               selector:@selector(splitScreenSettingSelected:)];
    
    //plat SC is NOT added by default
    
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:mt
                                                                                 action:@selector(mapToolbarDragged:)];
    
    panGesture.delegate = mt;
    [mt addGestureRecognizer:panGesture];
    
    return mt;
}

- (void)setupButton:(UIButton *)button
         imageTitle:(NSString *)imageTitle
         edgeInsets:(UIEdgeInsets)edgeInsets
             target:(id)target
           selector:(SEL)selector
{
    button.imageEdgeInsets = edgeInsets;
    button.backgroundColor = UIColor.whiteColor;
    button.layer.cornerRadius = 10.0;
    button.layer.borderColor = UIColor.blackColor.CGColor;
    button.layer.borderWidth = 2.0;
    
    [button setImage:[UIImage imageWithContentsOfFile:[NSBundle.mainBundle pathForResource:imageTitle
                                                                                    ofType:@"png"]]
            forState:UIControlStateNormal];
    
    [button addTarget:target
               action:selector
     forControlEvents:UIControlEventTouchUpInside];
}

- (void)setupSegControl:(UISegmentedControl *)segControl
   selectedSegmentIndex:(NSInteger)selectedSegmentIndex
                 target:(id)target
               selector:(SEL)selector
{
    segControl.backgroundColor = UIColor.whiteColor;
    segControl.tintColor = UIColor.blackColor;
    segControl.layer.cornerRadius = 4.0;
    segControl.layer.borderColor = UIColor.blackColor.CGColor;
    segControl.layer.borderWidth = 2.0;
    segControl.layer.masksToBounds = YES;
    segControl.selectedSegmentIndex = MapViewScreenSettingFullscreen;
    
    [segControl addTarget:target
                   action:selector
         forControlEvents:UIControlEventValueChanged];
}

- (void)userLocationSelected:(UIButton *)button
{
    _myLocationEnabled = !_myLocationEnabled;
    
    if (_myLocationEnabled)
        _userLocationButton.backgroundColor = UIColor.greenColor;
    
    else
        _userLocationButton.backgroundColor = UIColor.whiteColor;
    
    if (_delegate)
        [_delegate mapToolbarDidSelectUserLocation:_myLocationEnabled];
}

- (void)deselectMyLocationButton
{
    _userLocationButton.backgroundColor = UIColor.whiteColor;
    _myLocationEnabled = NO;
}

- (void)extentsSelected:(UIButton *)button
{
    if (_delegate)
        [_delegate mapToolbarDidSelectZoomExtent];
}

- (void)markerSwitchSelected:(UISwitch *)markerSwitch
{
    if (_delegate)
        [_delegate mapToolbarDidSelectMarkerSwitch:markerSwitch.on];
}

- (void)mapTypeSelected:(UISegmentedControl *)segControl
{
    if (_delegate)
        [_delegate mapToolbarDidSelectMapType:segControl.selectedSegmentIndex];
}

- (void)digitizeSelected:(UIButton *)button
{
    if (_delegate)
        [_delegate mapToolbarDidSelectDigitize];
}

- (void)legendsSelected:(UIButton *)button
{
    if (_delegate)
        [_delegate mapToolbarDidSelectLegends];
}

- (void)splitScreenSettingSelected:(UISegmentedControl *)segControl
{
    if (_delegate)
        [_delegate mapToolbarDidSelectSplitScreenSetting:segControl.selectedSegmentIndex];
}

- (void)mapToolbarDragged:(UIPanGestureRecognizer *)gesture
{
    CGPoint translation = [gesture translationInView:gesture.view.superview];
    
    if (gesture.state == UIGestureRecognizerStateBegan ||
        gesture.state == UIGestureRecognizerStateChanged)
    {
        gesture.view.center = CGPointMake(gesture.view.center.x + translation.x,
                                          gesture.view.center.y + translation.y);
        
        [gesture setTranslation:CGPointZero
                         inView:self];
    }
    
    else if (gesture.state == UIGestureRecognizerStateEnded)
    {
        if (_delegate)
            [_delegate mapToolbarDidFinishDrag];
    }
}

- (void)animateToVerticalOrientation
{
    CGFloat yCount = _buttonMargin;
    CGFloat xCount = 0.0;
    
    if (_wantUserLocation)
    {
        _userLocationButton.frame = CGRectMake(_buttonMargin, yCount, _buttonSize, _buttonSize);
        yCount += (_buttonMargin + _buttonSize);
        xCount = max(xCount, (_buttonMargin * 2.0) + _buttonSize);
    }
    
    if (_wantExtents)
    {
        _extentsButton.frame = CGRectMake(_buttonMargin, yCount, _buttonSize, _buttonSize);
        yCount += (_buttonMargin + _buttonSize);
        xCount = max(xCount, (_buttonMargin * 2.0) + _buttonSize);
    }
    
    if (_wantLegends)
    {
        _legendsButton.frame = CGRectMake(_buttonMargin, yCount, _buttonSize, _buttonSize);
        yCount += (_buttonMargin + _buttonSize);
        xCount = max(xCount, (_buttonMargin * 2.0) + _buttonSize);
    }
    
    if (_wantDigitize)
    {
        _digitizeButton.frame = CGRectMake(_buttonMargin, yCount, _buttonSize, _buttonSize);
        yCount += (_buttonMargin + _buttonSize);
        xCount = max(xCount, (_buttonMargin * 2.0) + _buttonSize);
    }
    
    if (_wantMarkerSwitch)
    {
        _markerSwitch.frame = CGRectMake(_buttonMargin, yCount, _switchWidth, _switchHeight);
        yCount += (_buttonMargin + _switchHeight);
        xCount = max(xCount, (_buttonMargin * 2.0) + _switchWidth);
    }
    
    if (_wantMapType)
    {
        _mapTypeSC.frame = CGRectMake(_buttonMargin, yCount, _mapTypeSCVertWidth, _SCHeight);
        yCount += (_buttonMargin + _SCHeight);
        xCount = max(xCount, (_buttonMargin * 2.0) + _mapTypeSCVertWidth);
    }
    
    if (_wantPlat)
    {
        _platSC.frame = CGRectMake(_buttonMargin, yCount, _platSCVertWidth, _SCHeight);
        yCount += (_buttonMargin + _SCHeight);
        xCount = max(xCount, (_buttonMargin * 2.0) + _platSCVertWidth);
    }
    
    if (yCount < 20.0)
        yCount = 0.0;
    
    if (_platMode)
    {
        _platSC.frame = CGRectMake(_buttonMargin, _buttonMargin,
                                   _platSCVertWidth, _SCHeight);
        
        self.frame = CGRectMake(0.0, 0.0, (_platSC.frame.size.width + (_buttonMargin * 2.0)),
                                (_platSC.frame.size.height + (_buttonMargin * 2.0)));
    }
    
    else
        self.frame = CGRectMake(0.0, 0.0, xCount, yCount);
    
    [_mapTypeSC setTitle:@"Stnd"
       forSegmentAtIndex:0];
    
    [_mapTypeSC setTitle:@"Hybd"
       forSegmentAtIndex:1];
    
    [_platSC setTitle:@"F"
    forSegmentAtIndex:0];
    
    [_platSC setTitle:@"S"
    forSegmentAtIndex:1];
    
    [_platSC setTitle:@"T"
    forSegmentAtIndex:2];
    
    [_platSC setTitle:@"P"
    forSegmentAtIndex:3];
}

- (void)animateToHorizontalOrientation
{
    CGFloat buttonSize = 47.0, switchHeight = 31.0, switchWidth = 51.0, segControlHeight = 29.0, mtscWidth = 128.0;
    CGFloat buttonMargin = 8.0, switchMargin = 16.0, segControlMargin = 17.0, ssscWidth = 196.0;
    
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
    {
        buttonSize = 39.0, buttonMargin = 5.0, switchMargin = 9.0, segControlMargin = 10.0;
        mtscWidth = 78.0, ssscWidth = 166.0;
        
        if (_platMode)
        {
            _platSC.frame = CGRectMake(buttonMargin, buttonMargin,
                                              (_size.width - (buttonMargin * 2.0)), segControlHeight);
        }
        
        else
        {
            _platSC.frame = CGRectMake(buttonMargin, (buttonSize + (buttonMargin * 2.0)),
                                              (_size.width - (buttonMargin * 2.0)), segControlHeight);
        }
    }
    
    else
    {
        [_mapTypeSC setTitle:@"Standard"
           forSegmentAtIndex:0];
        
        [_mapTypeSC setTitle:@"Hybrid"
           forSegmentAtIndex:1];
        
        if (_platMode)
        {
            _platSC.frame = CGRectMake(buttonMargin, segControlMargin,
                                              ssscWidth, segControlHeight);
        }
        
        else
        {
            _platSC.frame = CGRectMake(((buttonSize * 2.0) + (buttonMargin * 5.0) + switchWidth + mtscWidth),
                                              segControlMargin, ssscWidth, segControlHeight);
        }
    }
    
    if (_platMode)
    {
        if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
        {
            self.frame = CGRectMake(0.0, 0.0, _platSC.frame.size.width + (buttonMargin * 2.0),
                                    _platSC.frame.size.height + (buttonMargin * 2.0));
        }
        
        else
        {
            self.frame = CGRectMake(0.0, 0.0, _platSC.frame.size.width +
                                    (buttonMargin * 2.0),  _size.height);
        }
    }
    
    else
        self.frame = CGRectMake(0.0, 0.0, _size.width, _size.height);
    
    _userLocationButton.frame = CGRectMake(buttonMargin, buttonMargin, buttonSize, buttonSize);
    
    _extentsButton.frame = CGRectMake((buttonSize + (buttonMargin * 2.0)),
                                         buttonMargin, buttonSize, buttonSize);
    
    _markerSwitch.frame = CGRectMake(((buttonSize * 2.0) + (buttonMargin * 3.0)),
                                     switchMargin, switchWidth, switchHeight);
    
    _mapTypeSC.frame = CGRectMake(((buttonSize * 2.0) + (buttonMargin * 4.0) + switchWidth),
                                  segControlMargin, mtscWidth, segControlHeight);
    
    [_platSC setTitle:@"Full"
           forSegmentAtIndex:0];
    
    [_platSC setTitle:@"Split"
           forSegmentAtIndex:1];
    
    [_platSC setTitle:@"Tri"
           forSegmentAtIndex:2];
    
    [_platSC setTitle:@"Plat"
           forSegmentAtIndex:3];
}

- (void)splitScreenSelectedSegmentIndex:(NSInteger)index
{
    _platSC.selectedSegmentIndex = index;
}

- (void)platViewMode
{
    CGFloat height = self.frame.size.height;
    CGPoint center = self.center;
    _userLocationButton.hidden = YES;
    _extentsButton.hidden = YES;
    _markerSwitch.hidden = YES;
    _mapTypeSC.hidden = YES;
    _platMode = YES;
    
    [self orientToolbar];
    
    if (_orientation == MapToolbarOrientationTop ||
        _orientation == MapToolbarOrientationBottom)
    {
        CGFloat heightDiff = (self.frame.size.height - height);
        
        if (heightDiff != 0.0)
        {
            if (_orientation == MapToolbarOrientationTop)
                center = CGPointMake(center.x, center.y + (heightDiff / 2.0));
            
            else
                center = CGPointMake(center.x, center.y - (heightDiff / 2.0));
        }
    }
        
    self.center = center;
}

- (void)normalMode
{
    CGFloat height = self.frame.size.height;
    CGPoint center = self.center;
    _userLocationButton.hidden = NO;
    _extentsButton.hidden = NO;
    _markerSwitch.hidden = NO;
    _mapTypeSC.hidden = NO;
    _platMode = NO;
    
    [self orientToolbar];
    
    if (_orientation == MapToolbarOrientationTop ||
        _orientation == MapToolbarOrientationBottom)
    {
        CGFloat heightDiff = (self.frame.size.height - height);
        
        if (heightDiff != 0.0)
        {
            if (_orientation == MapToolbarOrientationTop)
                center = CGPointMake(center.x, center.y + (heightDiff / 2.0));
            
            else
                center = CGPointMake(center.x, center.y - (heightDiff / 2.0));
        }
    }
    
    self.center = center;
}

- (void)orientToolbar
{
    if (_orientation == MapToolbarOrientationLeft ||
        _orientation == MapToolbarOrientationRight)
    {
        [self animateToVerticalOrientation];
    }
    
    else
        [self animateToHorizontalOrientation];
}

- (void)willRotateWithDuration:(NSTimeInterval)duration
                  tabBarHeight:(CGFloat)tabBarHeight
               statusBarHeight:(CGFloat)statusBarHeight
{
    CGRect superviewFrame = self.superview.frame;
    
    switch (_orientation)
    {
        case MapToolbarOrientationTop:
        {
            [UIView animateWithDuration:duration
                             animations:^{
                                 self.center = CGPointMake(((superviewFrame.size.height + tabBarHeight) / 2.0),
                                                           (statusBarHeight + (self.frame.size.height / 2.0)));
                                 
                             }];
        }
            break;
            
        case MapToolbarOrientationBottom:
        {
            [UIView animateWithDuration:duration
                             animations:^{
                                 self.center = CGPointMake(((superviewFrame.size.height + tabBarHeight) / 2.0),
                                                           ((superviewFrame.size.width - tabBarHeight) -
                                                            (self.frame.size.height / 2.0)));
                             }];
        }
            break;
            
        case MapToolbarOrientationLeft:
        {
            [UIView animateWithDuration:duration
                             animations:^{
                                 self.center = CGPointMake((self.frame.size.width / 2.0),
                                                           ((superviewFrame.size.width - tabBarHeight) / 2.0));
                             }];
        }
            break;
            
        case MapToolbarOrientationRight:
        {
            [UIView animateWithDuration:duration
                             animations:^{
                                 self.center = CGPointMake(((superviewFrame.size.height + tabBarHeight) -
                                                            (self.frame.size.width / 2.0)),
                                                           ((superviewFrame.size.width - tabBarHeight) / 2.0));
                             }];
        }
            break;
            
        case MapToolbarOrientationDefault:
            break;
    }
}

- (void)hide
{
    [UIView animateWithDuration:0.25
                     animations:^{
                         self.alpha = 0.0;
                     }];
}

- (void)show
{
    [UIView animateWithDuration:0.25
                     animations:^{
                         self.alpha = 1.0;
                     }];
}

- (void)setConfigurationProperty:(MapToolbarProperty)property
                           value:(BOOL)value
{
    switch (property)
    {
        case MapToolbarPropertyWantPlat:
            if (_wantPlat != value)
            {
                _configChanged = YES;
                _wantPlat = value;
            }
            
            break;
            
        case MapToolbarPropertyWantDigitize:
            if (_wantDigitize != value)
            {
                _configChanged = YES;
                _wantDigitize = value;
            }
            
            break;
            
        case MapToolbarPropertyWantMapType:
            if (_wantMapType != value)
            {
                _configChanged = YES;
                _wantMapType = value;
            }
            
            break;
            
        case MapToolbarPropertyWantUserLocation:
            if (_wantUserLocation != value)
            {
                _configChanged = YES;
                _wantUserLocation = value;
            }
            
            break;
            
        case MapToolbarPropertyWantExtents:
            if (_wantExtents != value)
            {
                _configChanged = YES;
                _wantExtents = value;
            }
            
            break;
            
        case MapToolbarPropertyWantLegends:
            if (_wantLegends != value)
            {
                _configChanged = YES;
                _wantLegends = value;
            }
            
            break;
            
        case MapToolbarPropertyWantMarkerSwitch:
            if (_wantMarkerSwitch != value)
            {
                _configChanged = YES;
                _wantMarkerSwitch = value;
            }
            
            break;
            
        case MapToolbarPropertyWantDefault:
            NSLog(@"ERROR: No MapToolbar Property Type");
            break;
    }
}

- (void)configure
{
    if (!_configChanged)
        return;
    
    _configChanged = NO;
    
    if (_orientation == MapToolbarOrientationTop ||
        _orientation == MapToolbarOrientationBottom)
    {
        CGFloat xCount = _buttonMargin;
        
        if (_wantUserLocation)
        {
            _userLocationButton.frame = CGRectMake(xCount, _buttonMargin, _buttonSize, _buttonSize);
            
            if (![self.subviews containsObject:_userLocationButton])
                [self addSubview:_userLocationButton];
            
            xCount += (_buttonMargin + _buttonSize);
        }
        
        else
        {
            if ([self.subviews containsObject:_userLocationButton])
                [_userLocationButton removeFromSuperview];
        }
        
        if (_wantExtents)
        {
            _extentsButton.frame = CGRectMake(xCount, _buttonMargin, _buttonSize, _buttonSize);
            
            if (![self.subviews containsObject:_extentsButton])
                [self addSubview:_extentsButton];
            
            xCount += (_buttonMargin + _buttonSize);
        }
        
        else
        {
            if ([self.subviews containsObject:_extentsButton])
                [_extentsButton removeFromSuperview];
        }
        
        if (_wantLegends)
        {
            _legendsButton.frame = CGRectMake(xCount, _buttonMargin, _buttonSize, _buttonSize);
            
            if (![self.subviews containsObject:_legendsButton])
                [self addSubview:_legendsButton];
            
            xCount += (_buttonMargin + _buttonSize);
        }
        
        else
        {
            if ([self.subviews containsObject:_legendsButton])
                [_legendsButton removeFromSuperview];
        }
        
        if (_wantDigitize)
        {
            _digitizeButton.frame = CGRectMake(xCount, _buttonMargin, _buttonSize, _buttonSize);
            
            if (![self.subviews containsObject:_digitizeButton])
                [self addSubview:_digitizeButton];
            
            xCount += (_buttonMargin + _buttonSize);
        }
        
        else
        {
            if ([self.subviews containsObject:_digitizeButton])
                [_digitizeButton removeFromSuperview];
        }
        
        if (_wantMarkerSwitch)
        {
            _markerSwitch.frame = CGRectMake(xCount, _switchMargin, _switchWidth, _switchHeight);
            
            if (![self.subviews containsObject:_markerSwitch])
                [self addSubview:_markerSwitch];
            
            xCount += (_buttonMargin + _switchWidth);
        }
        
        else
        {
            if ([self.subviews containsObject:_markerSwitch])
                [_markerSwitch removeFromSuperview];
        }
        
        if (_wantMapType)
        {
            _mapTypeSC.frame = CGRectMake(xCount, _SCMargin, _mapTypeSCWidth, _SCHeight);
            
            if (![self.subviews containsObject:_mapTypeSC])
                [self addSubview:_mapTypeSC];
            
            xCount += (_buttonMargin + _mapTypeSCWidth);
        }
        
        else
        {
            if ([self.subviews containsObject:_mapTypeSC])
                [_mapTypeSC removeFromSuperview];
        }
        
        if (_wantPlat)
        {
            _platSC.frame = CGRectMake(xCount, _SCMargin, _platSCWidth, _SCHeight);
            
            if (![self.subviews containsObject:_platSC])
                [self addSubview:_platSC];
            
            xCount += (_buttonMargin + _platSCWidth);
        }
        
        else
        {
            if ([self.subviews containsObject:_platSC])
                [_platSC removeFromSuperview];
        }
        
        if (xCount < 20.0)
            xCount = 0.0;
        
        self.frame = CGRectMake((self.center.x - (xCount / 2.0)),
                                (self.center.y - (_size.height / 2.0)), xCount, _size.height);
    }
    
    else
    {
        CGFloat yCount = _buttonMargin;
        CGFloat xCount = 0.0;
        
        if (_wantUserLocation)
        {
            _userLocationButton.frame = CGRectMake(_buttonMargin, yCount, _buttonSize, _buttonSize);
            
            if (![self.subviews containsObject:_userLocationButton])
                [self addSubview:_userLocationButton];
            
            yCount += (_buttonMargin + _buttonSize);
            xCount = max(xCount, (_buttonMargin * 2.0) + _buttonSize);
        }
        
        else
        {
            if ([self.subviews containsObject:_userLocationButton])
                [_userLocationButton removeFromSuperview];
        }
        
        if (_wantExtents)
        {
            _extentsButton.frame = CGRectMake(_buttonMargin, yCount, _buttonSize, _buttonSize);
            
            if (![self.subviews containsObject:_extentsButton])
                [self addSubview:_extentsButton];
            
            yCount += (_buttonMargin + _buttonSize);
            xCount = max(xCount, (_buttonMargin * 2.0) + _buttonSize);
        }
        
        else
        {
            if ([self.subviews containsObject:_extentsButton])
                [_extentsButton removeFromSuperview];
        }
        
        if (_wantLegends)
        {
            _legendsButton.frame = CGRectMake(_buttonMargin, yCount, _buttonSize, _buttonSize);
            
            if (![self.subviews containsObject:_legendsButton])
                [self addSubview:_legendsButton];
            
            yCount += (_buttonMargin + _buttonSize);
            xCount = max(xCount, (_buttonMargin * 2.0) + _buttonSize);
        }
        
        else
        {
            if ([self.subviews containsObject:_legendsButton])
                [_legendsButton removeFromSuperview];
        }
        
        if (_wantDigitize)
        {
            _digitizeButton.frame = CGRectMake(_buttonMargin, yCount, _buttonSize, _buttonSize);
            
            if (![self.subviews containsObject:_digitizeButton])
                [self addSubview:_digitizeButton];
            
            yCount += (_buttonMargin + _buttonSize);
            xCount = max(xCount, (_buttonMargin * 2.0) + _buttonSize);
        }
        
        else
        {
            if ([self.subviews containsObject:_digitizeButton])
                [_digitizeButton removeFromSuperview];
        }
        
        if (_wantMarkerSwitch)
        {
            _markerSwitch.frame = CGRectMake(_buttonMargin, yCount, _switchWidth, _switchHeight);
            
            if (![self.subviews containsObject:_markerSwitch])
                [self addSubview:_markerSwitch];
            
            yCount += (_buttonMargin + _switchHeight);
            xCount = max(xCount, (_buttonMargin * 2.0) + _switchWidth);
        }
        
        else
        {
            if ([self.subviews containsObject:_markerSwitch])
                [_markerSwitch removeFromSuperview];
        }
        
        if (_wantMapType)
        {
            _mapTypeSC.frame = CGRectMake(_buttonMargin, yCount, _mapTypeSCVertWidth, _SCHeight);
            
            if (![self.subviews containsObject:_mapTypeSC])
                [self addSubview:_mapTypeSC];
            
            yCount += (_buttonMargin + _SCHeight);
            xCount = max(xCount, (_buttonMargin * 2.0) + _mapTypeSCVertWidth);
        }
        
        else
        {
            if ([self.subviews containsObject:_mapTypeSC])
                [_mapTypeSC removeFromSuperview];
        }
        
        if (_wantPlat)
        {
            _platSC.frame = CGRectMake(_buttonMargin, yCount, _platSCVertWidth, _SCHeight);
            
            if (![self.subviews containsObject:_platSC])
                [self addSubview:_platSC];
            
            yCount += (_buttonMargin + _SCHeight);
            xCount = max(xCount, (_buttonMargin * 2.0) + _platSCVertWidth);
        }
        
        else
        {
            if ([self.subviews containsObject:_platSC])
                [_platSC removeFromSuperview];
        }
        
        if (yCount < 20.0)
            yCount = 0.0;
        
        if (_orientation == MapToolbarOrientationLeft)
            self.frame = CGRectMake(0.0, (self.center.y - (yCount / 2.0)), xCount, yCount);
        
        else
            self.frame = CGRectMake((self.superview.frame.size.width - xCount), (self.center.y - (yCount / 2.0)), xCount, yCount);
    }
    
    //configures the toolbar based on the values of _wantPlat, _wantDigitize, _wantMapType, _wantUserLocation _wantLegends and _wantExtents
    //_wantLegends controls a pulldown list of available legends which display with the MarkeView class
}

@end