//  MapToolbar.m
//  GMMobile

#import "MapToolbar.h"

@interface MapToolbar ()

@property (nonatomic) UIButton *zoomExtent, *userLocation;
@property (nonatomic) UISegmentedControl *mapType, *splitScreenSetting;
@property (nonatomic) UISwitch *annotationOption;
@property (nonatomic) BOOL myLocationEnabled;

@end

@implementation MapToolbar

- (id)init
{
    self = [super init];
    
    CGFloat frameHeight, frameWidth;
    
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
        frameHeight = 83.0, frameWidth = 282.0;
    
    else
        frameHeight = 63.0, frameWidth = 537.0;
    
    if (self)
    {
        self.opaque = NO;
        self.backgroundColor = UserDefaults.defaults.appleBlue;
        self.frame = CGRectMake(0.0, 0.0, frameWidth, frameHeight);
        self.layer.borderWidth = 2.0;
        self.layer.borderColor = UIColor.blackColor.CGColor;
        
        CGFloat buttonSize = 47.0, switchHeight = 31.0, switchWidth = 51.0, segControlHeight = 29.0, mtscWidth = 128.0;
        CGFloat buttonMargin = 8.0, switchMargin = 16.0, segControlMargin = 17.0, ssscWidth = 216.0;
        
        if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
            buttonSize = 39.0, buttonMargin = 5.0, switchMargin = 9.0, segControlMargin = 10.0;
        
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
        
        _mapType = [[UISegmentedControl alloc] initWithItems:@[@"Standard", @"Hybrid"]];
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
                                                   (frameWidth - (buttonMargin * 2.0)), segControlHeight);
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

@end