//  MapToolbar.m
//  GMMobile

#import "MapToolbar.h"

@interface MapToolbar ()

@property (nonatomic) UIButton *zoomExtent, *userLocation;
@property (nonatomic) UISegmentedControl *mapType, *splitScreenSetting;
@property (nonatomic) UISwitch *annotationOption;

@end

@implementation MapToolbar

//this is the designated initializer
- (id)initWithView:(UIView *)view
{
    self = [super init];
    
    if (self)
    {
        self.opaque = NO;
        self.backgroundColor = UserDefaults.defaults.appleBlue;
        self.frame = CGRectMake(0.0, 0.0, 537.0, 63.0);
        self.center = CGPointMake((view.frame.size.width / 2.0), 52.0);
        self.layer.borderWidth = 2.0;
        self.layer.borderColor = UIColor.blackColor.CGColor;
    }
    
    CGFloat buttonSize = 47.0, switchHeight = 31.0, switchWidth = 51.0, segControlHeight = 29.0, mtscWidth = 128.0;
    CGFloat buttonMargin = 8.0, switchMargin = 16.0, segControlMargin = 17.0, ssscWidth = 216.0;
    
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
    
    _splitScreenSetting.frame = CGRectMake(((buttonSize * 2.0) + (buttonMargin * 5.0) + switchWidth + mtscWidth),
                                           segControlMargin, ssscWidth, segControlHeight);
    
    [_splitScreenSetting addTarget:self
                            action:@selector(splitScreenSettingSelected:)
                  forControlEvents:UIControlEventValueChanged];
    
    [self formatSegControl:_splitScreenSetting];
    [self addSubview:_splitScreenSetting];
    
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
    if (_delegate)
        [_delegate mapToolbarDidSelectUserLocation];
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

@end