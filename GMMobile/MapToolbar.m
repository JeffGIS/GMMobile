//  MapToolbar.m
//  GMMobile

#import "MapToolbar.h"

@interface MapToolbar ()

@property (nonatomic) UIButton *extentsButton, *userLocationButton, *legendsButton, *digitizeButton;
@property (nonatomic) UISegmentedControl *mapTypeSC, *platSC;
@property (nonatomic) UISwitch *markerSwitch;
@property (nonatomic) CGSize size;
@property BOOL configChanged, myLocationEnabled, platOverride;
@property (nonatomic) CGFloat buttonSize, switchHeight, switchWidth, SCHeight, mapTypeSCWidth, mapTypeSCVertWidth;
@property (nonatomic) CGFloat buttonMargin, switchMargin, SCMargin, platSCWidth, platSCVertWidth;

@end

@implementation MapToolbar
{
    BOOL _previousConfig[NUMMapToolbarProperty];
}

+ (MapToolbar *)showMapToolbarWithCenter:(CGPoint)center
                                    view:(UIView *)view
                                delegate:(id)delegate;
{
    MapToolbar *mt = [[MapToolbar alloc] init];
    mt.configChanged = mt.myLocationEnabled = mt.platOverride = NO;
    
    //set default configuration
    [mt setConfigurationProperty:MapToolbarPropertyWantUserLocation
                           value:YES];
    
    [mt setConfigurationProperty:MapToolbarPropertyWantExtents
                           value:YES];
    
    [mt setConfigurationProperty:MapToolbarPropertyWantMarkerSwitch
                           value:YES];
    
    [mt setConfigurationProperty:MapToolbarPropertyWantPlat
                           value:NO];
    
    [mt setConfigurationProperty:MapToolbarPropertyWantDigitize
                           value:NO];
    
    [mt setConfigurationProperty:MapToolbarPropertyWantMapType
                           value:NO];
    
    [mt setConfigurationProperty:MapToolbarPropertyWantLegends
                           value:NO];
    
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
    mt.orientation = MapToolbarOrientationTop;
    
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
    
    self.frame = CGRectMake(0.0, 0.0, xCount, yCount);
    
    for (UIView *views in self.subviews)
        views.center = CGPointMake(self.center.x, views.center.y);
    
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
    CGFloat xCount = _buttonMargin;
    
    if (_wantUserLocation)
    {
        _userLocationButton.frame = CGRectMake(xCount, _buttonMargin, _buttonSize, _buttonSize);
        xCount += (_buttonMargin + _buttonSize);
    }
    
    if (_wantExtents)
    {
        _extentsButton.frame = CGRectMake(xCount, _buttonMargin, _buttonSize, _buttonSize);
        xCount += (_buttonMargin + _buttonSize);
    }
    
    if (_wantLegends)
    {
        _legendsButton.frame = CGRectMake(xCount, _buttonMargin, _buttonSize, _buttonSize);
        xCount += (_buttonMargin + _buttonSize);
    }
    
    if (_wantDigitize)
    {
        _digitizeButton.frame = CGRectMake(xCount, _buttonMargin, _buttonSize, _buttonSize);
        xCount += (_buttonMargin + _buttonSize);
    }
    
    if (_wantMarkerSwitch)
    {
        _markerSwitch.frame = CGRectMake(xCount, _switchMargin, _switchWidth, _switchHeight);
        xCount += (_buttonMargin + _switchWidth);
    }
    
    if (_wantMapType)
    {
        _mapTypeSC.frame = CGRectMake(xCount, _SCMargin, _mapTypeSCWidth, _SCHeight);
        xCount += (_buttonMargin + _mapTypeSCWidth);
    }
    
    if (_wantPlat)
    {
        _platSC.frame = CGRectMake(xCount, _SCMargin, _platSCWidth, _SCHeight);
        xCount += (_buttonMargin + _platSCWidth);
    }
    
    if (xCount < 20.0)
        xCount = 0.0;
    
    self.frame = CGRectMake((self.center.x - (xCount / 2.0)),
                                (self.center.y - (_size.height / 2.0)), xCount, _size.height);
    
    [_mapTypeSC setTitle:@"Standard"
       forSegmentAtIndex:0];
    
    [_mapTypeSC setTitle:@"Hybrid"
       forSegmentAtIndex:1];
    
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

- (void)platViewMode:(MapViewScreenSetting)screenSetting
{
    [self setPreviousConfiguration];
    
    _wantDigitize = _wantExtents = _wantLegends = _wantMapType =
    _wantMarkerSwitch = _wantUserLocation = NO;
    
    _wantPlat = _configChanged = YES;
    
    [UIView animateWithDuration:0.25
                     animations:^{
                         [self configure:screenSetting];
                     }];
}

- (void)normalMode:(MapViewScreenSetting)screenSetting
{
    [self getPreviousConfiguration];
    
    if (_platOverride)
        _wantPlat = NO;
    
    _configChanged = YES;
    _platOverride = NO;
    
    [UIView animateWithDuration:0.25
                     animations:^{
                         [self configure:screenSetting];
                     }];
}

- (void)setPreviousConfiguration
{
    _previousConfig[MapToolbarPropertyWantUserLocation] = _wantUserLocation;
    _previousConfig[MapToolbarPropertyWantPlat] = _wantPlat;
    _previousConfig[MapToolbarPropertyWantMarkerSwitch] = _wantMarkerSwitch;
    _previousConfig[MapToolbarPropertyWantMapType] = _wantMapType;
    _previousConfig[MapToolbarPropertyWantLegends] = _wantLegends;
    _previousConfig[MapToolbarPropertyWantExtents] = _wantExtents;
    _previousConfig[MapToolbarPropertyWantDigitize] = _wantDigitize;
}

- (void)getPreviousConfiguration
{
    _wantUserLocation = _previousConfig[MapToolbarPropertyWantUserLocation];
    _wantPlat = _previousConfig[MapToolbarPropertyWantPlat];
    _wantMarkerSwitch = _previousConfig[MapToolbarPropertyWantMarkerSwitch];
    _wantMapType = _previousConfig[MapToolbarPropertyWantMapType];
    _wantLegends = _previousConfig[MapToolbarPropertyWantLegends];
    _wantExtents = _previousConfig[MapToolbarPropertyWantExtents];
    _wantDigitize = _previousConfig[MapToolbarPropertyWantDigitize];
}

- (void)setConfigurationProperty:(MapToolbarProperty)property
                           value:(BOOL)value
{
    switch (property)
    {
        case MapToolbarPropertyWantPlat:
            _wantPlat = value;
            break;
            
        case MapToolbarPropertyWantDigitize:
            _wantDigitize = value;
            break;
            
        case MapToolbarPropertyWantMapType:
            _wantMapType = value;
            break;
            
        case MapToolbarPropertyWantUserLocation:
            _wantUserLocation = value;
            break;
            
        case MapToolbarPropertyWantExtents:
            _wantExtents = value;
            break;
            
        case MapToolbarPropertyWantLegends:
            _wantLegends = value;
            break;
            
        case MapToolbarPropertyWantMarkerSwitch:
            _wantMarkerSwitch = value;
            break;
            
        case MapToolbarPropertyWantDefault:
            break;
            
        default:
            break;
    }
    
    _configChanged = YES;
}

- (void)configure:(MapViewScreenSetting)screenSetting
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
        {
            self.frame = CGRectMake(0.0, (self.center.y - (yCount / 2.0)),
                                    xCount, yCount);
        }
        
        else
        {
            self.frame = CGRectMake((self.superview.frame.size.width - xCount),
                                    (self.center.y - (yCount / 2.0)), xCount, yCount);
        }
        
        for (UIView *views in self.subviews)
            views.center = CGPointMake(self.center.x, views.center.y);
    }
    
    NSLog(@"%ld,%d", (long)screenSetting, _wantPlat);
    
    if (screenSetting != MapViewScreenSettingFullscreen && !_wantPlat)
    {
        _platOverride = YES;
        [self splitScreenSettingSelected:MapViewScreenSettingFullscreen];
        _platSC.selectedSegmentIndex = MapViewScreenSettingFullscreen;
    }
    
    //_wantLegends controls a pulldown list of available legends which display with the MarkerView class
}

@end