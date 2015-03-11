//  MapToolbar.m
//  GMMobile

#import "MapToolbar.h"

@interface MapToolbar ()

@property (nonatomic) UIButton *zoomExtent, *userLocation;
@property (nonatomic) UISegmentedControl *mapType, *splitScreenSetting;
@property (nonatomic) UISwitch *annotationOption;
@property (nonatomic) BOOL myLocationEnabled;
@property (nonatomic) CGSize size;

@end

@implementation MapToolbar

- (id)init
{
    self = [super init];
    
    if (self)
    {
        if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
            _size = CGSizeMake(232.0, 83.0);
        
        else
            _size = CGSizeMake(517.0, 63.0);
        
        self.opaque = NO;
        self.backgroundColor = UserDefaults.defaults.appleBlue;
        self.frame = CGRectMake(0.0, 0.0, _size.width, _size.height);
        self.layer.borderWidth = 2.0;
        self.layer.borderColor = UIColor.blackColor.CGColor;
        
        CGFloat buttonSize = 47.0, switchHeight = 31.0, switchWidth = 51.0, segControlHeight = 29.0, mtscWidth = 128.0;
        CGFloat buttonMargin = 8.0, switchMargin = 16.0, segControlMargin = 17.0, ssscWidth = 196.0;
        
        if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
        {
            buttonSize = 39.0, buttonMargin = 5.0, switchMargin = 9.0, segControlMargin = 10.0;
            mtscWidth = 78.0, ssscWidth = 166.0;
            _mapType = [[UISegmentedControl alloc] initWithItems:@[@"Stnd", @"Hybd"]];
        }
        
        else
            _mapType = [[UISegmentedControl alloc] initWithItems:@[@"Standard", @"Hybrid"]];
        
        _userLocation = [[UIButton alloc] initWithFrame:CGRectMake(buttonMargin, buttonMargin, buttonSize, buttonSize)];
        
        [_userLocation setImage:[UIImage imageWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"userLocation"
                                                                                               ofType:@"png"]]
                       forState:UIControlStateNormal];
        
        [_userLocation addTarget:self
                          action:@selector(userLocationSelected:)
                forControlEvents:UIControlEventTouchUpInside];
        
        _userLocation.imageEdgeInsets = UIEdgeInsetsMake(5.0, 5.0, 5.0, 5.0);
        [self formatButton:_userLocation];
        [self addSubview:_userLocation];
        
        _zoomExtent = [[UIButton alloc] initWithFrame:CGRectMake((buttonSize + (buttonMargin * 2.0)),
                                                                 buttonMargin, buttonSize, buttonSize)];
        
        [_zoomExtent setImage:[UIImage imageWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"zoom"
                                                                                             ofType:@"png"]]
                     forState:UIControlStateNormal];
        
        [_zoomExtent addTarget:self
                        action:@selector(zoomExtentSelected:)
              forControlEvents:UIControlEventTouchUpInside];
        
        _zoomExtent.imageEdgeInsets = UIEdgeInsetsMake(-2.0, -2.0, -2.0, -2.0);
        [self formatButton:_zoomExtent];
        [self addSubview:_zoomExtent];
        
        _annotationOption = [[UISwitch alloc] initWithFrame:CGRectMake(((buttonSize * 2.0) + (buttonMargin * 3.0)),
                                                                       switchMargin, switchWidth, switchHeight)];
        
        [_annotationOption addTarget:self
                              action:@selector(annotationOptionSelected:)
                    forControlEvents:UIControlEventValueChanged];
        
        _annotationOption.on = YES;
        _annotationOption.tintColor = UIColor.redColor;
        [self addSubview:_annotationOption];
        
        _mapType.selectedSegmentIndex = 0;
        
        _mapType.frame = CGRectMake(((buttonSize * 2.0) + (buttonMargin * 4.0) + switchWidth),
                                    segControlMargin, mtscWidth, segControlHeight);
        
        [_mapType addTarget:self
                     action:@selector(mapTypeSelected:)
           forControlEvents:UIControlEventValueChanged];
        
        [self formatSegControl:_mapType];
        [self addSubview:_mapType];
        
        _splitScreenSetting = [[UISegmentedControl alloc] initWithItems:@[@"Full", @"Split", @"Tri", @"Bottom"]];
        _splitScreenSetting.selectedSegmentIndex = 0;
        
        if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
        {
            _splitScreenSetting.frame = CGRectMake(buttonMargin, (buttonSize + (buttonMargin * 2.0)),
                                                   (_size.width - (buttonMargin * 2.0)), segControlHeight);
        }
        
        else
        {
            _splitScreenSetting.frame = CGRectMake(((buttonSize * 2.0) + (buttonMargin * 5.0) + switchWidth + mtscWidth),
                                                   segControlMargin, ssscWidth, segControlHeight);
        }
        
        [_splitScreenSetting addTarget:self
                                action:@selector(splitScreenSettingSelected:)
                      forControlEvents:UIControlEventValueChanged];
        
        [self formatSegControl:_splitScreenSetting];
        [self addSubview:_splitScreenSetting];
        
        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                                     action:@selector(mapToolbarDragged:)];
        
        panGesture.delegate = self;
        [self addGestureRecognizer:panGesture];
    }
    
    return self;
}

- (void)formatButton:(UIButton *)button
{
    button.backgroundColor = UIColor.whiteColor;
    button.layer.cornerRadius = 10.0;
    button.layer.borderColor = UIColor.blackColor.CGColor;
    button.layer.borderWidth = 2.0;
}

- (void)formatSegControl:(UISegmentedControl *)segControl
{
    segControl.backgroundColor = UIColor.whiteColor;
    segControl.tintColor = UIColor.blackColor;
    segControl.layer.cornerRadius = 4.0;
    segControl.layer.borderColor = UIColor.blackColor.CGColor;
    segControl.layer.borderWidth = 2.0;
    segControl.layer.masksToBounds = YES;
}

- (void)userLocationSelected:(UIButton *)button
{
    _myLocationEnabled = !_myLocationEnabled;
    
    if (_myLocationEnabled)
        _userLocation.backgroundColor = UIColor.greenColor;
    
    else
        _userLocation.backgroundColor = UIColor.whiteColor;
    
    if (_delegate)
        [_delegate mapToolbarDidSelectUserLocation:_myLocationEnabled];
}

- (void)deselectMyLocationButton
{
    _userLocation.backgroundColor = UIColor.whiteColor;
    _myLocationEnabled = NO;
}

- (void)zoomExtentSelected:(UIButton *)button
{
    if (_delegate)
        [_delegate mapToolbarDidSelectZoomExtent];
}

- (void)annotationOptionSelected:(UISwitch *)annotationSwitch
{
    if (_delegate)
        [_delegate mapToolbarDidSelectAnnotationOption:annotationSwitch.on];
}

- (void)mapTypeSelected:(UISegmentedControl *)segControl
{
    if (_delegate)
        [_delegate mapToolbarDidSelectMapType:segControl.selectedSegmentIndex];
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
    CGFloat buttonSize = 47.0, buttonMargin = 8.0, frameHeight = (_size.height * 1.6);
    
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
    {
        buttonSize = 39.0, buttonMargin = 5.0;
        frameHeight = _size.height;
    }
    
    self.frame = CGRectMake(0.0, 0.0, frameHeight,
                            ((buttonSize * 2.0) + (buttonMargin * 6.0) +
                             _annotationOption.frame.size.height + (_mapType.frame.size.height * 2.0)));
    
    CGFloat switchMargin = ((self.frame.size.width - _annotationOption.frame.size.width) / 2.0);
    CGFloat buttonSideMargin = ((self.frame.size.width - buttonSize) / 2.0);
    CGFloat scWidth = (self.frame.size.width - (buttonMargin * 1.6));
    
    _userLocation.frame = CGRectMake(buttonSideMargin, buttonMargin, buttonSize, buttonSize);
    
    _zoomExtent.frame = CGRectMake(buttonSideMargin, (buttonSize + (buttonMargin * 2.0)),
                                   buttonSize, buttonSize);
    
    _annotationOption.frame = CGRectMake(switchMargin, ((buttonSize * 2.0) + (buttonMargin * 3.0)),
                                         _annotationOption.frame.size.width, _annotationOption.frame.size.height);
    
    _mapType.frame = CGRectMake((buttonMargin / 1.6),
                                ((buttonSize * 2.0) + (buttonMargin * 4.0) + _annotationOption.frame.size.height),
                                scWidth, _mapType.frame.size.height);
    
    [_mapType setTitle:@"Stnd"
     forSegmentAtIndex:0];
    
    [_mapType setTitle:@"Hybd"
     forSegmentAtIndex:1];
    
    _splitScreenSetting.frame = CGRectMake((buttonMargin / 1.6),
                                           ((buttonSize * 2.0) + (buttonMargin * 5.0) +
                                            _annotationOption.frame.size.height + _mapType.frame.size.height),
                                           scWidth, _splitScreenSetting.frame.size.height);
    
    [_splitScreenSetting setTitle:@"F"
                forSegmentAtIndex:0];
    
    [_splitScreenSetting setTitle:@"S"
                forSegmentAtIndex:1];
    
    [_splitScreenSetting setTitle:@"T"
                forSegmentAtIndex:2];
    
    [_splitScreenSetting setTitle:@"B"
                forSegmentAtIndex:3];
}

- (void)animateToHorizontalOrientation
{
    self.frame = CGRectMake(0.0, 0.0, _size.width, _size.height);
    
    CGFloat buttonSize = 47.0, switchHeight = 31.0, switchWidth = 51.0, segControlHeight = 29.0, mtscWidth = 128.0;
    CGFloat buttonMargin = 8.0, switchMargin = 16.0, segControlMargin = 17.0, ssscWidth = 196.0;
    
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
    {
        buttonSize = 39.0, buttonMargin = 5.0, switchMargin = 9.0, segControlMargin = 10.0;
        mtscWidth = 78.0, ssscWidth = 166.0;
        
        _splitScreenSetting.frame = CGRectMake(buttonMargin, (buttonSize + (buttonMargin * 2.0)),
                                               (_size.width - (buttonMargin * 2.0)), segControlHeight);
    }
    
    else
    {
        [_mapType setTitle:@"Standard"
         forSegmentAtIndex:0];
    
        [_mapType setTitle:@"Hybrid"
         forSegmentAtIndex:1];
        
        _splitScreenSetting.frame = CGRectMake(((buttonSize * 2.0) + (buttonMargin * 5.0) + switchWidth + mtscWidth),
                                               segControlMargin, ssscWidth, segControlHeight);
    }
    
    _userLocation.frame = CGRectMake(buttonMargin, buttonMargin, buttonSize, buttonSize);
    
    _zoomExtent.frame = CGRectMake((buttonSize + (buttonMargin * 2.0)),
                                   buttonMargin, buttonSize, buttonSize);
    
    _annotationOption.frame = CGRectMake(((buttonSize * 2.0) + (buttonMargin * 3.0)),
                                         switchMargin, switchWidth, switchHeight);
    
    _mapType.frame = CGRectMake(((buttonSize * 2.0) + (buttonMargin * 4.0) + switchWidth),
                                segControlMargin, mtscWidth, segControlHeight);
    
    [_splitScreenSetting setTitle:@"Full"
                forSegmentAtIndex:0];
    
    [_splitScreenSetting setTitle:@"Split"
                forSegmentAtIndex:1];
    
    [_splitScreenSetting setTitle:@"Tri"
                forSegmentAtIndex:2];
    
    [_splitScreenSetting setTitle:@"Bottom"
                forSegmentAtIndex:3];
}

@end