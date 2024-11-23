//
//  CompassViewController.m
//  NVMobile
//
//  Created by Jeff Smith on 10/21/22.
//  Copyright © 2022 GSSi. All rights reserved.
//
int ii=0;
#import "CompassViewController.h"
#import "DTMData.h"
//#import "NVCoordinateLibrary/proj_api.h"
#include "CCodeLibrary/PROJ.H"
#include "CCodeLibrary/shr.h"

@interface CompassShapeLayer: CAShapeLayer
@property UIColor *baseColor;
@property UIColor *currentColor;
@property CGFloat heading;
@end
@implementation CompassShapeLayer
@end

@interface CompassViewController ()
@property UITapGestureRecognizer * singleFingerTap;
@property UIView *backgroundView;
@property UIView *dScaView;
@property UIView *compassTriangleView;
@property UIView *levelView;
@property UIView *verticalView;
@property UIView *lineView;
@property UIView *redTriangleView;
@property UIView *profileView;
@property UILabel *selectDateLabel;
@property UIImageView *stickManView;
@property UILabel *infoLabel;
@property CGFloat screenW, screenH, heightFactor, widthFactor;
@property (nonatomic) CGFloat radius;
@property (nonatomic) TrackLocationManager *locationManager;
@property id oldLocationManagerDelegate;
@property UILabel *directionLabel;
@property NSMutableArray * userWaypointLabels;
@property NSMutableArray * tickShapes;
@property CGPoint po;
@property LLPOINT currentFocusWaypointLL;
@property NSArray <UserWaypoint*> *userWaypointArray;
@property double maxWaypointDist;
@property double maxVehicleDist;
@property CLHeading*  nowHeading;
@property CGFloat currentHeading;
@property CGFloat lastResetHeading;
@property int infoLabelOption;
@property int ignoreAtWaypoint;
@property float closeDistance;
@property int statusBarHeight;
@property UIButton *optionsButton;
@property UILabel *weatherLabel;
@property UILabel *sunRiseSetLabel;
@property UIButton *weatherButton;
@property WeatherData * wd;
@property int currentWindSpeed;
@property int currentTemp;
@property float currentWindDirection;
@property NSString *currentWeatherDesc;
@property double heightExpansion;
@property double minElev;
@property double maxElev;
@property double maxGrade;
@property NSMutableArray *profileLayers;
@property int lastToDist;
@property BOOL forward;
@property NSMutableArray * forecastDates;
@property NSArray * currentForecast;
@property time_t displayTime;
@property UIImageView *wind;
@property UILabel *windLabel;
@property UILabel *sunLabel;
@property CGFloat tickLineWidth1, tickLineWidth2;
@property WeatherRecord* currentWeatherRecord;
@property NSTimer * minuteTimer;
@property BOOL firstMinute;
@property NVPopoverTableView *nvptv;
@property double GPSHeading;
@property double GPSHeadingFromPoints;
@property BOOL isVisible;

@end

@implementation CompassViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _wd = WeatherData.new;
    _currentWindSpeed = -1;
    _heightExpansion = 2;
    _lastToDist = 0;
    _forward = TRUE;
    _lastResetHeading = 0;
    _GPSHeading = 1000;
    _GPSHeadingFromPoints = 1000;
    [self configUI];
    _displayTime = 0;
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(resignedActive)
                                               name:@"didResignActive"
                                             object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(becameActive)
                                               name:@"didBecomeActive"
                                             object:nil];

}
-(BOOL) shouldAutorotate
{
    return FALSE;
}

-(void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    if (_nvptv)
    {
        if (_nvptv.isVisible)
        return;
    }
    [self destroyUI];
    [self configUI];
    [self updateWeather];
}

-(void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    
    CRAPI.sharedInstance.routeBearing = nil;
    _maxWaypointDist = 5.0 * METERS_PER_MILE;
    _maxVehicleDist = 10 * METERS_PER_MILE;
    _locationManager = [CRAPI.sharedInstance getLocationManager];
    _locationManager.headingFilter = 1;
    _locationManager.headingOrientation = CLDeviceOrientationFaceUp;
    _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    _oldLocationManagerDelegate = _locationManager.delegate;
    _locationManager.delegate = self;
    HuntingData *hd = HuntingData.new;
    
    _userWaypointArray = [hd getWaypoints];

}
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    NSLog(@"Compass did appear");
    _isVisible = TRUE;
    CRAPI.sharedInstance.firstTimeZoomToCentract = NO;
    //[self DrawCompass];
    //if (CLLocationManager.locationServicesEnabled && CLLocationManager.headingAvailable)
    {
        [_locationManager startUpdatingLocation];
        [_locationManager startUpdatingHeading];
    }
    _locationManager.offDist = 0;
    _locationManager.currentPoint = CRAPI.sharedInstance.currentGPSLocation;
    [self addUserWaypoints:_locationManager.currentPoint];
    [self getWeatherData];
    [self startMinuteTimer:TRUE];
    return;
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    NSLog (@"Compass will disappear");
    [self removeUserWaypoints];
    [self removeProfileLayers];
    [_locationManager stopUpdatingHeading];
    if (_locationManager.delegate ==  self)
        _locationManager.delegate = nil;
    if (!CRAPI.sharedInstance.inFollowingRouteMode && !CRAPI.sharedInstance.locationTrackingEnabled)
        [_locationManager stopUpdatingLocation];
    //InitProj4CoordConv (TRUE);
    if (_minuteTimer)
        [_minuteTimer invalidate];

}

-(void) viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    NSLog (@"Compass did disappear");
    _isVisible = FALSE;
}

- (void)resignedActive
{
    NSLog (@"Compass resign active:isVisible = %i",_isVisible);
    if (_isVisible)
    {
        if (_locationManager.delegate == self)
            _locationManager.delegate = nil;
        [_locationManager stopUpdatingHeading];
        [self removeUserWaypoints];
        [self removeProfileLayers];
        if (!CRAPI.sharedInstance.inFollowingRouteMode && !CRAPI.sharedInstance.locationTrackingEnabled)
            [_locationManager stopUpdatingLocation];
    }
    return;
}

- (void)becameActive
{
    NSLog (@"Compass become active:isVisible = %i",_isVisible);

    if (_isVisible)
    {
        NSArray *savedLocations = [_locationManager retrieveSavedLocations];
        _locationManager.delegate = self;
        [_locationManager startUpdatingHeading];
        [_locationManager startUpdatingLocation];
        [self getWeatherData];
        [self startMinuteTimer:TRUE];

    }
    return;
}

-(void) startMinuteTimer:(BOOL) firstTime
{
    CGFloat seconds = 60;
    _firstMinute = firstTime;
    if (firstTime)
    {
        time_t itime = NSDate.date.timeIntervalSince1970;
        seconds = 60 - (itime % 60);
    }
    [_minuteTimer invalidate];
    _minuteTimer = [NSTimer scheduledTimerWithTimeInterval:seconds
                                                      target:self
                                                  selector:@selector(updateMinute:)
                                                    userInfo:nil
                                                     repeats:YES];

}
- (void) updateMinute:(NSTimer*)timer
{
    if (_firstMinute)
    {
        [_minuteTimer invalidate];
        [self startMinuteTimer:FALSE];
    }
    [self setDateAndTimeLabel];
    [self updateWeather];
}
BOOL PointInSuperView (CGPoint pt,UIView* view,UIView* superView)
{
    BOOL rtn = FALSE;
    if (superView)
    {
        if (PointInView (pt,superView))
        {
            CGRect viewFrame = view.frame;
            CGRect superFrame = superView.frame;
            
            viewFrame.origin.x += superFrame.origin.x;
            viewFrame.origin.y += superFrame.origin.y;
            rtn = PointInCGRect(pt,viewFrame);
        }
    }
    else
        rtn  = PointInView (pt,view);
    
    return rtn;
}
//The event handling method
- (void)handleSingleTap:(UITapGestureRecognizer *)sender
{
    if (sender.state == UIGestureRecognizerStateEnded)
    {
        int numTouches = sender.numberOfTouches;
        CGPoint location = [sender locationInView:sender.view];
        CGPoint locationInView;
        NSLog([NSString stringWithFormat:@"Tap at:%f %f",location.x,location.y]);
        if (PointInSuperView(location,_infoLabel,self.view))
        {
            NSLog (@"In infoLabel");
            locationInView = [sender locationOfTouch:0 inView:_infoLabel];
            [self infoLabelPicked:locationInView];
        }
        else if (PointInSuperView(location,_selectDateLabel,self.view))
        {
            NSLog (@"In selectdateLabel");
            [self getForcastWeatherData];
        }
        else if (PointInSuperView(location,_profileView,self.view))
        {
            NSLog (@"In profileView");
            locationInView = [sender locationOfTouch:0 inView:_profileView];
            [self profileViewPicked:locationInView];
        }
        else if (PointInSuperView(location,_dScaView,self.view))
            NSLog (@"In dScaView");
        else if (PointInSuperView(location,self.view,nil))
            NSLog (@"In main view");
        
    }
}
- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}
CGRect getCGRect (NSString * rectName,CGRect rect)
{
    CGRect rtn = rect;
//    return rtn;
    NSLog (@"if ([rectName isEqual:@\"%@\"])\n\trtn = CGRectMake(%.1f, %.1f, %.1f, %.1f);", rectName,rect.origin.x,rect.origin.y,rect.size.width,rect.size.height);
    if ([rectName isEqual:@"_dScaView.frame"])
        rtn = CGRectMake (0.0, 138.9, 428.0, 428.0);
    else if ([rectName isEqual:@"_levelView.frame"])
        rtn = CGRectMake(0.0, 0.0, 107.0, 1.0);
    else if ([rectName isEqual:@"_verticalView.frame"])
        rtn = CGRectMake(0.0, 0.0, 1.0, 107.0);
    else if ([rectName isEqual:@"_lineView.frame"])
        rtn = CGRectMake(212.5, 46.3, 5.0, 65.0);
    else if ([rectName isEqual:@"_profileView.frame"])
        rtn = CGRectMake(0.0, 620.0, 428.0, 222.0);
    else if ([rectName isEqual:@"_selectDateLabel.frame"])
        rtn = CGRectMake(0.0, 552.0, 428.0, 56.0);
    else if ([rectName isEqual:@"_infoLabel.frame"])
        rtn = CGRectMake(0.0, 0.0, 428.0, 111.0);
    else if ([rectName isEqual:@"_backgroundView.frame"])
            rtn = CGRectMake(0.0, 0.0, 428.0, 428.0);
    else if ([rectName isEqual:@"_optionsButton.frame"])
        rtn = CGRectMake(0.0, 47.0, 40.0, 40.0);
    else if ([rectName isEqual:@"_weatherLabel.frame"])
        rtn = CGRectMake(268.0, 47.0, 160.0, 55.0);
    else if ([rectName isEqual:@"_sunRiseSetLabel.frame"])
        rtn = CGRectMake(50.0, 47.0, 120.0, 55.0);
    else
        NSLog (@"Missing rect template %@",rectName);

    return rtn;
}
-(void)configUI
{
    CGRect r = self.view.frame;
    CGRect frame;
    UITabBarController *tabBarController = [UITabBarController new];
    CGFloat tabBarHeight = tabBarController.tabBar.frame.size.height;
    r = UIScreen.mainScreen.bounds;
    _statusBarHeight = UIApplication.sharedApplication.windows[0].safeAreaInsets.top;
    _screenH = UIScreen.mainScreen.bounds.size.height;
    _screenW = UIScreen.mainScreen.bounds.size.width;
    _heightFactor = _screenH / 926;
    _widthFactor = _screenW / 428;

    int top = UIApplication.sharedApplication.windows[0].safeAreaInsets.top;
    int left = UIApplication.sharedApplication.windows[0].safeAreaInsets.left;
    int right = self.view.frame.size.width - UIApplication.sharedApplication.windows[0].safeAreaInsets.right;
    int bottom = self.view.frame.size.height - UIApplication.sharedApplication.windows[0].safeAreaInsets.bottom - tabBarHeight;
    CGRect selfViewFrame = CGRectMake(left, top, right,bottom);
    CGRect templateFrame = CGRectMake(0, 47, 428, 892);
    //NSLog (@"%.1f, %.1f, %.1f, %.1f",selfViewFrame.origin.x,selfViewFrame.origin.y,selfViewFrame.size.width,selfViewFrame.size.height);
    HANDLE hTranRect = STRANCGRect (templateFrame,selfViewFrame);

    self.view.backgroundColor = UIColor.blackColor;
    [self.view setMultipleTouchEnabled:YES];
    _singleFingerTap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                            action:@selector(handleSingleTap:)];
    _optionsButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _optionsButton.imageView.contentMode = UIViewContentModeScaleAspectFill;
    _optionsButton.backgroundColor = UIColor.whiteColor;
    _optionsButton.frame = CGRectMake(left,top,50*_heightFactor,50*_heightFactor);

    [_optionsButton setImage:[UIImage imageWithContentsOfFile:
                      [NSBundle.mainBundle pathForResource:@"list"
                                                    ofType:@"png"]]
                forState:UIControlStateNormal];
    [_optionsButton addTarget:self
                               action:@selector(optionsButtonTapped)
                     forControlEvents:UIControlEventTouchUpInside];
    [self.view  addSubview:_optionsButton];

    _sunRiseSetLabel = UILabel.new;
    _sunRiseSetLabel.frame = CGRectMake(_optionsButton.frame.origin.x+_optionsButton.frame.size.width,top,160*_widthFactor,_optionsButton.frame.size.height);
    _sunRiseSetLabel.backgroundColor = UIColor.blackColor;
    _sunRiseSetLabel.textColor = UIColor.whiteColor;
    _sunRiseSetLabel.font =[UIFont systemFontOfSize: 20];
    _sunRiseSetLabel.adjustsFontSizeToFitWidth = YES;
    _sunRiseSetLabel.textAlignment = NSTextAlignmentCenter;
    _sunRiseSetLabel.numberOfLines = 3;
    _sunRiseSetLabel.text = @"Sunrise:5:31\nSunset:7:33";
    [self.view  addSubview:_sunRiseSetLabel];

    _weatherLabel = UILabel.new;
    frame = _sunRiseSetLabel.frame;
    frame.origin.x = right - frame.size.width - _optionsButton.frame.size.width/2;
    _weatherLabel.frame = frame;
    _weatherLabel.backgroundColor = UIColor.blackColor;
    _weatherLabel.textColor = UIColor.whiteColor;
    _weatherLabel.font =[UIFont systemFontOfSize: 20];
    _weatherLabel.adjustsFontSizeToFitWidth = YES;
    _weatherLabel.textAlignment = NSTextAlignmentCenter;
    _weatherLabel.numberOfLines = 3;
    _weatherLabel.text = @"";
     _weatherButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_weatherButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    //_weatherButton.imageView.contentMode = UIViewContentModeScaleAspectFill;
    _weatherButton.backgroundColor = UIColor.clearColor;
    _weatherButton.frame = _weatherLabel.frame;
    _weatherButton.layer.borderColor = UIColor.whiteColor.CGColor;
    _weatherButton.layer.borderWidth = 0;

    [_weatherButton addTarget:self
                               action:@selector(weatherButtonTapped)
                     forControlEvents:UIControlEventTouchUpInside];
    [self.view  addSubview:_weatherLabel];
    [self.view  addSubview:_weatherButton];


    
    _dScaView = UIView.new;
    _dScaView.backgroundColor = UIColor.clearColor;
    float w = min(_screenW,_screenH/2);
    float h = min(_screenW,_screenH/2);
    float lft = _screenW / 2 - w / 2;
    _dScaView.frame = CGRectMake(lft,_sunRiseSetLabel.frame.origin.y+_sunRiseSetLabel.frame.size.height,w,h);
//    _dScaView.frame = TranCGRect(getCGRect(@"_dScaView.frame",_dScaView.frame),hTranRect);
    _dScaView.frame = CGRectMake(_dScaView.frame.origin.x,_dScaView.frame.origin.y,
                                 min(_dScaView.frame.size.width,_dScaView.frame.size.height),min(_dScaView.frame.size.width,_dScaView.frame.size.height));
    _lineView = UIView.new;
    _lineView.frame = CGRectMake (self.view.frame.size.width / 2 - 2*_widthFactor, top,4*_widthFactor,_dScaView.frame.origin.y-top);
    _lineView.backgroundColor = UIColor.whiteColor;
    _compassTriangleView = UIView.new;
    _compassTriangleView.frame = TranCGRect(CGRectMake(0,0,_screenW,_screenW),hTranRect);
    _compassTriangleView.backgroundColor = UIColor.clearColor;
    _profileView = UIView.new;
    float selectDateLabelHeight = 68 * _heightFactor;
    frame = CGRectMake(0, _dScaView.frame.origin.y+_dScaView.frame.size.height+selectDateLabelHeight, _screenW,IDNINT(130*_heightFactor)+UIApplication.sharedApplication.windows[0].safeAreaInsets.bottom-24);
    //frame.origin.y = bottom - frame.size.height;
    _selectDateLabel = UILabel.new;
    frame = CGRectMake(0, _dScaView.frame.origin.y + _dScaView.frame.size.height, _screenW,selectDateLabelHeight);
    _selectDateLabel.frame = frame;
    _selectDateLabel.backgroundColor = UIColor.lightGrayColor;
    _selectDateLabel.textColor = UIColor.blackColor;
    _selectDateLabel.font =[UIFont systemFontOfSize: 32];
    _selectDateLabel.textAlignment = NSTextAlignmentCenter;
    _selectDateLabel.numberOfLines = 0;
    _selectDateLabel.adjustsFontSizeToFitWidth = YES;
    _selectDateLabel.text = @"Current Date and Time";
    frame.origin.y = _selectDateLabel.frame.origin.y + _selectDateLabel.frame.size.height;
    frame.size.height = bottom - frame.origin.y;
    _profileView.frame = frame;
    _profileView.backgroundColor = [UIColor colorWithRed:235/255.0
                                                   green:245/255.0
                                                    blue:235/255.0
                                                   alpha:1];

    _infoLabel = UILabel.new;
    _infoLabel.frame = CGRectMake (0,_profileView.frame.origin.y,_profileView.frame.size.width,_profileView.frame.size.height/2);
    _profileView.frame = CGRectMake (_profileView.frame.origin.x,_profileView.frame.origin.y + _profileView.frame.size.height/2,_profileView.frame.size.width,_profileView.frame.size.height/2);
    _infoLabel.backgroundColor = UIColor.clearColor;
    _infoLabel.textColor = UIColor.whiteColor;
    _infoLabel.font =[UIFont systemFontOfSize: 42];
    _infoLabel.textAlignment = NSTextAlignmentCenter;
    _infoLabel.numberOfLines = 0;
    _infoLabel.adjustsFontSizeToFitWidth = YES;
    //_dScaView.clipsToBounds = true;
    _dScaView.layer.cornerRadius = min(_dScaView.frame.size.width,_dScaView.frame.size.height) / 2;
    _backgroundView = UIView.new;
    _backgroundView.frame = CGRectMake (0,0,_dScaView.frame.size.width,_dScaView.frame.size.height);
    _backgroundView.backgroundColor = UIColor.clearColor;
    [_dScaView addSubview:_backgroundView];
    [self.view insertSubview:_lineView atIndex:0];
    [_dScaView addSubview:_compassTriangleView];

    
    [self.view addSubview:_dScaView];
    [self.view addSubview:_infoLabel];
    [self.view addSubview:_profileView];
    [self.view addSubview:_selectDateLabel];
    [self.view setUserInteractionEnabled:YES];
    [self.view addGestureRecognizer:_singleFingerTap];

    [self configScaleDial:hTranRect];
    _levelView = UIView.new;
    _levelView.frame = CGRectMake (0,0,_radius*0.75, 1);
    _levelView.center = CGPointMake(_dScaView.frame.size.width / 2,_dScaView.frame.size.height / 2);
    _levelView.backgroundColor = UIColor.whiteColor;
    _verticalView = UIView.new;
    _verticalView.frame = CGRectMake (0,0,1,_levelView.frame.size.width);
    _verticalView.center = CGPointMake(_dScaView.frame.size.width / 2,_dScaView.frame.size.height / 2);
    _verticalView.backgroundColor = UIColor.whiteColor;
    [_dScaView addSubview:_levelView];
    [_dScaView addSubview:_verticalView];

    CloseTRANS2 (&hTranRect);
}
 -(void) destroyUI
{
    [self.view removeGestureRecognizer:_singleFingerTap];
    [_optionsButton removeFromSuperview];

    [_weatherLabel removeFromSuperview];
    [_weatherButton removeFromSuperview];

    [_sunRiseSetLabel removeFromSuperview];

    [_backgroundView removeFromSuperview];
    [_lineView removeFromSuperview];
    [_compassTriangleView removeFromSuperview];

    [_levelView removeFromSuperview];
    [_verticalView removeFromSuperview];
    [_dScaView removeFromSuperview];
    [_infoLabel removeFromSuperview];
    [_profileView removeFromSuperview];
    [_selectDateLabel removeFromSuperview];

}
-(void) optionsButtonTapped
{
    HuntingData *hd = HuntingData.new;
    NSMutableArray *optionList = NSMutableArray.array;
    NSArray <UserWaypoint*> *routePointArray = [hd getWaypointsOfType:@"RoutePoint"];
    if (routePointArray.count > 0)
    {
        if (CRAPI.sharedInstance.inFollowingRouteMode)
            [optionList addObject:@"Exit Route"];
        else
            [optionList addObject:@"Start Route"];
    }
    [optionList addObject:@"Get Weather Data"];
    [optionList addObject:@"Set Profile Exageration to 1"];
    [optionList addObject:@"Set Profile Exageration to 2"];
    [optionList addObject:@"Set Profile Exageration to 5"];
    [optionList addObject:@"Set Profile Exageration to 10"];
    [_dScaView setUserInteractionEnabled:NO];
    [_backgroundView setUserInteractionEnabled:NO];
    [_profileView setUserInteractionEnabled:NO];
    [self.view setMultipleTouchEnabled:NO];
    [_singleFingerTap setEnabled:NO];

    _nvptv = [NVPopoverTableView showPopoverTableViewInView:self.view
                                                                      delegate:self
                                                                         title:@"Compass Options"
                                                                     textArray:optionList
                                                                 includeCancel:YES];
    _nvptv.allowsSubtitle = NO;
     

}

-(void) weatherButtonTapped
{
    [self getWeatherData];
//    [self configUI];
}

- (UIImage *)imageByDrawingCircleOnImage:(UIImage *)image
{
    // begin a graphics context of sufficient size
    UIGraphicsBeginImageContext(image.size);
    
    // draw original image into the context
    [image drawAtPoint:CGPointZero];
    
    // get the context for CoreGraphics
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    // set stroking color and draw circle
    [[UIColor redColor] setStroke];
    
    // make circle rect 5 px from border
    CGRect circleRect = CGRectMake(0, 0,
                                   image.size.width,
                                   image.size.height);
    circleRect = CGRectInset(circleRect, 5, 5);
    
    // draw circle
    CGContextStrokeEllipseInRect(ctx, circleRect);
    
    // make image out of bitmap context
    UIImage *retImage = UIGraphicsGetImageFromCurrentImageContext();
    
    // free the context
    UIGraphicsEndImageContext();
    
    return retImage;
}

-(CGPoint) calculateTextPositonWithArcCenter: (CGPoint) center
                                    andAngle:(CGFloat) angle
                                    andScale:(CGFloat) scale
{
    CGFloat x = _radius * scale * cosf((angle));
    CGFloat y = _radius * scale * sinf((angle));
    CGPoint rtn = CGPointMake (center.x + x,center.y + y);
    return rtn;
}
-(CGPoint) calculateTextPositonWithArcCenter: (CGPoint) center
                                    andAngle:(CGFloat) angle
                                    andDistance:(CGFloat) dist
{
    CGFloat x = dist * cosf((angle));
    CGFloat y = dist * sinf((angle));
    CGPoint rtn = CGPointMake (center.x + x,center.y + y);
    return rtn;
}

//MARK: - Update multiple times
-(void) resetDirection:(CGFloat) heading
{
    _backgroundView.transform = CGAffineTransformMakeRotation(heading);
    int i=0;
    int n = _backgroundView.subviews.count;
    for (UILabel *label in _backgroundView.subviews)
    {
        if (i++ && i < n-1)
            label.transform = CGAffineTransformMakeRotation( -heading);
    }
    //_backgroundView.subviews[1].transform =  CGAffineTransformIdentity;
}
-(void) setRadius:(CGFloat)radius
{
    _radius = radius;
}
- (void) configScaleDialold:(HANDLE)hTranRect
{
    //return;
    CGFloat degree_360 = M_PI;
    
    CGFloat degree_180  = degree_360 / 2;
    
    CGFloat angle = degree_360 / 90;
    
    NSArray * directionArray = @[@"N", @"E", @"S", @"W"];
    
    _po = CGPointMake (_dScaView.frame.size.width / 2, _dScaView.frame.size.height / 2);
//    _radius = _dScaView.frame.size.width / 2 - 90*_widthFactor/2;
    self.radius = min(_dScaView.frame.size.width,_dScaView.frame.size.height) / 2 - 100*_widthFactor/2;
    int tickLineWidth1 = IDNINT(_radius * 0.13);
    int tickLineWidth2 = IDNINT(_radius * 0.14);

    //create 2 degree ticks
    _tickShapes = NSMutableArray.new;
    for (int i=0;i< 180;i++)
    {
        CGFloat startAngle  = -(degree_180 + degree_360 / 180 / 2) + angle * i;
        CGFloat endAngle  = startAngle + angle / 2;
        
        UIBezierPath *bezPath = [UIBezierPath bezierPathWithArcCenter:_po radius:_radius startAngle:startAngle endAngle:endAngle clockwise:true];
        
        //if (i % 45 != 0)
        {
            CompassShapeLayer * shapeLayer = CompassShapeLayer.new;
            
            if (i % 15 == 0)
            {
                shapeLayer.baseColor = UIColor.whiteColor;
                shapeLayer.strokeColor = shapeLayer.baseColor.CGColor;
                shapeLayer.lineWidth = tickLineWidth2;
            }
            else
            {
                shapeLayer.baseColor = UIColor.lightGrayColor;
                shapeLayer.strokeColor = shapeLayer.baseColor.CGColor;
                shapeLayer.lineWidth = tickLineWidth1;
            }
            shapeLayer.currentColor = shapeLayer.baseColor;
            shapeLayer.path = bezPath.CGPath;
            shapeLayer.fillColor = UIColor.clearColor.CGColor;
            shapeLayer.heading = i * 2 + 1;
            [_backgroundView.layer addSublayer:shapeLayer];
            [_tickShapes addObject:shapeLayer];
        }
    }
    //create 30 degree labels
    for (int i=0;i< 180;i++)
    {
        if (i % 15 == 0)
        {
            CGFloat startAngle  = -(degree_180 + degree_360 / 180 / 2) + angle * i;
            CGFloat endAngle  = startAngle + angle / 2;
            NSString *  tickText = [NSString stringWithFormat:@"%i",i * 2];
            
            CGFloat textAngle = startAngle + (endAngle - startAngle) / 2;
            
            CGPoint point  = [self calculateTextPositonWithArcCenter: _po andAngle: textAngle andScale: 1.0+.2*_widthFactor];
            
            // UILabel
            UILabel* label = UILabel.new;
            label.frame = CGRectMake(point.x,point.y, 30*_widthFactor,30*_widthFactor*_widthFactor/2);
            label.textColor = UIColor.whiteColor;
            label.font = [UIFont systemFontOfSize: 12];
            label.textAlignment = NSTextAlignmentCenter;
            if (i)
            {
                label.text = tickText;
                label.backgroundColor = UIColor.blackColor;
                label.frame = CGRectMake(point.x,point.y, tickLineWidth2*2,tickLineWidth2);
            }
            else
            {
                //label.font = [UIFont boldSystemFontOfSize: 26];
                //label.text = @"^";
                //label.textColor = UIColor.redColor;
                label.backgroundColor = UIColor.blackColor;
                [self DrawRedTriangleView:label];
            }
            label.center = point;
            [_backgroundView addSubview:label];
            
            if (i % 45 == 0)
            {
                //create NESW labels
                NSString * tickText = directionArray[i / 45];
                
                CGPoint point2  = [self calculateTextPositonWithArcCenter: _po andAngle: textAngle andScale: 1];
                // UILabel
                UILabel * label2 = UILabel.new;
                label2.frame = CGRectMake (point2.x, point2.y,30*_widthFactor,30*_widthFactor);
                label2.center = point2;
                label2.text = tickText;
                label2.textColor = UIColor.whiteColor;
                label2.font = [UIFont boldSystemFontOfSize: 26];
                label2.textAlignment = NSTextAlignmentCenter;
                label2.backgroundColor = UIColor.clearColor;
                
                if ([tickText isEqual:@"N"])
                {
                    
                }
                [_backgroundView addSubview:label2];
            }
        }
    }
}

- (void) configScaleDial:(HANDLE)hTranRect
{
    //return;
    CGFloat degree_360 = M_PI;
    
    CGFloat degree_180  = degree_360 / 2;
    
    CGFloat angle = degree_360 / 90;
    
    NSArray * directionArray = @[@"N", @"E", @"S", @"W"];

    _tickLineWidth1 = min(_dScaView.frame.size.width,_dScaView.frame.size.height) * 0.05;
    _tickLineWidth2 = min(_dScaView.frame.size.width,_dScaView.frame.size.height) * 0.06;
    _po = CGPointMake (_dScaView.frame.size.width / 2, _dScaView.frame.size.height / 2);
    self.radius = min(_dScaView.frame.size.width,_dScaView.frame.size.height) / 2 - _tickLineWidth2*2.5;
    CGRect radiusRect = CGRectMake(0, 0, _radius, _radius);
    radiusRect = TranCGRect(radiusRect,hTranRect);
    //_radius = min (radiusRect.size.width,radiusRect.size.height)/2;
    //create 2 degree ticks
    _tickShapes = NSMutableArray.new;
    for (int i=0;i< 180;i++)
    {
        CGFloat startAngle  = -(degree_180 + degree_360 / 180 / 2) + angle * i;
        CGFloat endAngle  = startAngle + angle / 2;
        
        UIBezierPath *bezPath = [UIBezierPath bezierPathWithArcCenter:_po radius:_radius startAngle:startAngle endAngle:endAngle clockwise:true];
        
        //if (i % 45 != 0)
        {
            CompassShapeLayer * shapeLayer = CompassShapeLayer.new;
            
            if (i % 15 == 0)
            {
                shapeLayer.baseColor = UIColor.whiteColor;
                shapeLayer.strokeColor = shapeLayer.baseColor.CGColor;
                shapeLayer.lineWidth = _tickLineWidth2;
            }
            else
            {
                shapeLayer.baseColor = UIColor.lightGrayColor;
                shapeLayer.strokeColor = shapeLayer.baseColor.CGColor;
                shapeLayer.lineWidth = _tickLineWidth1;
            }
            shapeLayer.currentColor = shapeLayer.baseColor;
            shapeLayer.path = bezPath.CGPath;
            shapeLayer.fillColor = UIColor.clearColor.CGColor;
            shapeLayer.heading = i * 2 + 1;
            [_backgroundView.layer addSublayer:shapeLayer];
            [_tickShapes addObject:shapeLayer];
        }
    }
    //create 30 degree labels
    for (int i=0;i< 180;i++)
    {
        if (i % 15 == 0)
        {
            CGFloat startAngle  = -(degree_180 + degree_360 / 180 / 2) + angle * i;
            CGFloat endAngle  = startAngle + angle / 2;
            NSString *  tickText = [NSString stringWithFormat:@"%i",i * 2];
            
            CGFloat textAngle = startAngle + (endAngle - startAngle) / 2;
            
            CGPoint point  = [self calculateTextPositonWithArcCenter: _po andAngle: textAngle andDistance:_radius + _tickLineWidth2 * 1.2];
            //point  = [self calculateTextPositonWithArcCenter: _po andAngle: textAngle andScale: 1.0+.2*_widthFactor];
            // UILabel
            UILabel* label = UILabel.new;
            label.textColor = UIColor.whiteColor;
            label.font = [UIFont systemFontOfSize: 12];
            label.textAlignment = NSTextAlignmentCenter;
            if (i)
            {
                label.frame = CGRectMake(point.x,point.y, _tickLineWidth2*1.5,_tickLineWidth2);
                label.text = tickText;
                label.backgroundColor = UIColor.blackColor;
            }
            else
            {
                point  = [self calculateTextPositonWithArcCenter: _po andAngle: textAngle andDistance:_radius + _tickLineWidth2 * 1.35];
                label.frame = CGRectMake(point.x,point.y, _tickLineWidth2*1.8,1.5*_tickLineWidth2);
                label.backgroundColor = UIColor.blackColor;
                [self DrawRedTriangleView:label];
            }
            label.center = point;

            [_backgroundView addSubview:label];
            
            if (i % 45 == 0)
            {
                //create NESW labels
                NSString * tickText = directionArray[i / 45];
                
                CGPoint point2  = [self calculateTextPositonWithArcCenter: _po andAngle: textAngle andScale: 1];
                // UILabel
                UILabel * label2 = UILabel.new;
                label2.frame = CGRectMake (point2.x, point2.y,30*_widthFactor,30*_widthFactor);
                label2.center = point2;
                label2.text = tickText;
                label2.textColor = UIColor.whiteColor;
                label2.font = [UIFont boldSystemFontOfSize: 26];
                label2.textAlignment = NSTextAlignmentCenter;
                label2.backgroundColor = UIColor.clearColor;
                
                if ([tickText isEqual:@"N"])
                {
                    
                }
                [_backgroundView addSubview:label2];
            }
        }
    }
}

-(void) DrawRedTriangleView:(UILabel*) label
{
    CGFloat w = label.frame.size.width;
    CGFloat h = label.frame.size.height;
    
    
    UIBezierPath *trianglePath = UIBezierPath.new;
    CGPoint point2 = CGPointMake( 0,  h);
    [trianglePath moveToPoint: point2];
    point2 = CGPointMake(w / 2, 0);
    [trianglePath addLineToPoint: point2];
    point2 = CGPointMake(w,h);
    [trianglePath addLineToPoint:point2];
    [trianglePath closePath];
    CAShapeLayer *triangleLayer = CAShapeLayer.layer;
    triangleLayer.path = trianglePath.CGPath;
    triangleLayer.fillColor = UIColor.redColor.CGColor;
    [label.layer addSublayer:triangleLayer];
}
-(CGFloat) heading:(CGFloat)heading fromOrirntation:(UIDeviceOrientation) orientation
{
    
    CGFloat realHeading = heading;
    
    switch (orientation)
    {
        case UIDeviceOrientationPortrait:
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            realHeading = heading - 180;
            break;
        case UIDeviceOrientationLandscapeLeft:
            realHeading = heading + 90;
            break;
        case UIDeviceOrientationLandscapeRight:
            realHeading = heading - 90;
            break;
        default:
            break;
    }
    if (realHeading > 360)
    {
        realHeading -= 360;
    }
    else if (realHeading < 0.0)
    {
        realHeading += 366;
    }
    return realHeading;
}
-(void)locationManager:(TrackLocationManager *)manager didUpdateLocations:(LLPOINT)llpt
            GPSHeading:(double)gpsHeading

{
    static bool first = true;
    
    [CRAPI.sharedInstance setGPSLocation:_locationManager.currentPoint from:2];
    TrackRoutePoint *routePoint = TrackRoutePoint.new;
    routePoint.time = NSDate.timeIntervalSinceReferenceDate;
    routePoint.latlon = llpt;
    routePoint.GPSHeading = gpsHeading;
    if (first)
        [self getWeatherData];
    first = false;
    _GPSHeading = gpsHeading;
    _GPSHeadingFromPoints = _locationManager.GPSHeadingFromPoints;
    [self removeUserWaypoints];
    [self addUserWaypoints:_locationManager.currentPoint];
    if (_locationManager.inSimulationMode)
        [self update];
}
- (void)locationManager:(TrackLocationManager *)manager
       didUpdateHeading:(CLHeading *)newHeading
{
    
    if (newHeading.headingAccuracy > 0)
    {
        
        _nowHeading = newHeading;
        [self performSelectorOnMainThread:@selector(update)
                               withObject:nil
                            waitUntilDone:NO];
    }
}

-(void) removeUserWaypoints
{
    if (_userWaypointLabels)
    {
        for (UILabel * label in _userWaypointLabels)
        {
            [label removeFromSuperview];
        }
    }
}
double HeadingFromAZ (double az)
{
    double heading = az + HALFPI;
    heading = LTWOPI (heading);
    return heading;
}
-(int)addUserWaypoints:(LLPOINT)currentPoint
{
    [self removeUserWaypoints];

    LLPOINT p1,p2;
    p1 = currentPoint;
    p2 = currentPoint;
    p2.lon -= 1;
    double az = HeadingFromAZ(AZMLatLon (p1,p2));
    az = HeadingFromAZ(AZMLatLon (p2,p1));
    _userWaypointLabels = NSMutableArray.new;
    int userWaypointIndex = _backgroundView.subviews.count;
    _closeDistance = 1;
    for (UserWaypoint* waypoint in _userWaypointArray)
    {
        if (CRAPI.sharedInstance.inFollowingRouteMode)
        {
            if ([waypoint.type isEqual:@"RoutePoint"] && waypoint.refno != CRAPI.sharedInstance.currentSelectedWaypoint)
            {
                continue;
            }
        }
        waypoint.currentDistance = ArcDistanceLL(waypoint.latlon, currentPoint);
        if (waypoint.currentDistance < _maxWaypointDist)
        {
            _closeDistance = max (_closeDistance,waypoint.currentDistance);
        }
    }
    NSArray *sorted = [_userWaypointArray sortedArrayUsingComparator:^(id obj1, id obj2){
        if ([obj1 isKindOfClass:[UserWaypoint class]] && [obj2 isKindOfClass:[UserWaypoint class]]) {
            UserWaypoint *s1 = obj1;
            UserWaypoint *s2 = obj2;

            if (s1.currentDistance > s2.currentDistance) {
                return (NSComparisonResult)NSOrderedAscending;
            } else if (s1.currentDistance < s2.currentDistance) {
                return (NSComparisonResult)NSOrderedDescending;
            }
        }
        return (NSComparisonResult)NSOrderedSame;
    }];

    int wpNum = 1;
    for (UserWaypoint* waypoint in sorted)
    {
        if (waypoint.displayOnCompass)
        {
            double dist = waypoint.currentDistance;
            if (([waypoint.type isEqual:@"Vehicle"] && dist < _maxVehicleDist)||
                (dist < _maxWaypointDist || ([waypoint.type isEqual:@"RoutePoint"] && CRAPI.sharedInstance.inFollowingRouteMode)) || waypoint.refno == CRAPI.sharedInstance.currentSelectedWaypoint)
            {
                double az = AZMLatLon (currentPoint,waypoint.latlon);
                double azd = RadiansToDegrees (az);
                double az2 = HeadingFromAZ (az);
                double az2d = RadiansToDegrees (az2);
                double maxScale = 1.0-.2*_widthFactor;
                double scale = maxScale;
                NSString *  tickText = [NSString stringWithFormat:@"%i",wpNum++];
                
                CGFloat textAngle = az;
                if (CRAPI.sharedInstance.inFollowingRouteMode)
                {
                    if ([waypoint.type isEqual:@"RoutePoint"])
                    {
                        _closeDistance = ArcDistanceLL(waypoint.latlon, _locationManager.fromPoint);
                        tickText = waypoint.name;
                    }
                }
                if (dist < _closeDistance)
                {
                    scale = maxScale * (dist/_closeDistance);
                }
                scale = 0.77;
                CGPoint point  = [self calculateTextPositonWithArcCenter: _po andAngle: textAngle andScale: scale];
                
                // UILabel
                UILabel* label = UILabel.new;
                CGFloat factor = 1;
                CGFloat fontSize = 10;
                label.text = tickText;
                label.font = [UIFont systemFontOfSize: fontSize];
                label.textAlignment = NSTextAlignmentCenter;
                label.adjustsFontSizeToFitWidth = YES;
                label.backgroundColor = UIColor.lightGrayColor;
                label.textColor = UIColor.blackColor;
                if ([waypoint.type isEqual:@"Vehicle"])
                {
                    factor = 1.6;
                    fontSize = 10;
                    label.text = @"V";
                    label.backgroundColor = UIColor.greenColor;
                    label.textColor = UIColor.blackColor;
                    label.font = [UIFont boldSystemFontOfSize: fontSize * factor];
                }
                else if ([waypoint.type isEqual:@"CompassPoint"])
                {
                    factor = 1.5;
                    fontSize = 10;
                    label.backgroundColor = UIColor.blueColor;
                    label.textColor = UIColor.whiteColor;
                    label.font = [UIFont boldSystemFontOfSize: fontSize * factor];
                }
                if (waypoint.refno == CRAPI.sharedInstance.currentSelectedWaypoint)
                {
                    label.backgroundColor = UIColor.orangeColor;
                    label.textColor = UIColor.blackColor;
                    factor = 1.6;
                    label.font = [UIFont boldSystemFontOfSize: fontSize * factor];
                }
                else if ([waypoint.type isEqual:@"RoutePoint"])
                    continue;
                label.frame = CGRectMake(point.x,point.y, factor*_tickLineWidth2,factor*_tickLineWidth2);
                label.center = point;
                label.clipsToBounds = true;
                label.layer.cornerRadius = label.frame.size.width / 2;
                
                [_backgroundView addSubview:label];
                [_userWaypointLabels addObject:label];
            }
        }
    }
    [self addSun];
    [self addWind];
    [self resetDirection:_lastResetHeading];
}

- (void) addSun
{
    if (_sunLabel)
    {
        [_userWaypointLabels removeObject:_sunLabel];
        [_sunLabel removeFromSuperview];
    }
    time_t iTime = NSDate.date.timeIntervalSince1970;
    CGFloat sunAlt;
    if (_displayTime != 0)
        iTime = _displayTime;
    CGFloat sunAz = [self getAzOfSun:iTime
                         altitude:&sunAlt];
    _sunLabel = UILabel.new;
    CGFloat factor = 1.2;
    int degreesAboveHorizon = IDNINT (sunAlt);
    CGFloat pctYellow;
    
    if (degreesAboveHorizon < -6)
        pctYellow = 0.2;
    else if (degreesAboveHorizon < 0)
        pctYellow = 0.2 + 0.4 * (6 + degreesAboveHorizon)/ 6.0;
    else if (degreesAboveHorizon < 6)
        pctYellow = 0.2 + 0.4 + 0.3 * degreesAboveHorizon / 6.0;
    else
        pctYellow = 0.9;
    UIColor *sunColor = [UIColor colorWithRed:1 green:1 blue:0 alpha:pctYellow];
    //CGPoint point  = [self calculateTextPositonWithArcCenter: _po andAngle: sunAz andScale: 1.24];
    CGPoint point  = [self calculateTextPositonWithArcCenter: _po andAngle: sunAz andDistance:_radius + _tickLineWidth2*1.45];

    _sunLabel.textAlignment = NSTextAlignmentCenter;
    int fontSize = 20;
    _sunLabel.text = [NSString stringWithFormat:@"%i",degreesAboveHorizon];
    _sunLabel.backgroundColor = sunColor;
    _sunLabel.textColor = UIColor.blackColor;
    _sunLabel.font = [UIFont boldSystemFontOfSize: fontSize * factor];
    _sunLabel.frame = CGRectMake(point.x,point.y, _tickLineWidth2*2,_tickLineWidth2*2);
    _sunLabel.center = point;
    _sunLabel.clipsToBounds = true;
    _sunLabel.layer.cornerRadius = _sunLabel.frame.size.width / 2;
    
    [_backgroundView addSubview:_sunLabel];
    [_userWaypointLabels addObject:_sunLabel];

}
- (void) addWind
{
    if (_wind)
    {
        [_userWaypointLabels removeObject:_wind];
        [_userWaypointLabels removeObject:_windLabel];
        [_wind removeFromSuperview];
        [_windLabel removeFromSuperview];
    }
    CGFloat windSpeed =  _currentWindSpeed;
    CGFloat factor = 1.8;
    CGFloat windDir = DegreesToRadians (_currentWindDirection);
    windDir = LTWOPI (windDir - HALFPI);
    CGPoint point  = [self calculateTextPositonWithArcCenter: _po andAngle: windDir andDistance:_radius + _tickLineWidth2*1.4];
    CGRect frame = _dScaView.frame;
    CGFloat windWidth = _tickLineWidth2 * 2;
    _wind = [[UIImageView alloc] initWithFrame:CGRectMake(point.x,point.y, windWidth,windWidth)];
    _windLabel = [[UILabel alloc] initWithFrame:_wind.frame];
    _wind.backgroundColor = UIColor.clearColor;
    _windLabel.backgroundColor = UIColor.clearColor;
    UIColor *blue = [[UIColor alloc] initWithRed:0.0
                                           green:0
                                            blue:1
                                           alpha:1];
    
    UIImage *img = [SymbolDictionary imageOfArrow:_wind.frame
                                        lineWidth:2
                                        lineColor:UIColor.whiteColor
                                        fillColor:blue
                                         withText:nil];
    _wind.image = img;//[UIImage imageWithContentsOfFile:                      [NSBundle.mainBundle pathForResource:@"windArrow"                                                    ofType:@"png"]];
    
    //wind.frame = CGRectMake(point.x,point.y, factor*30*_widthFactor,factor*30*_widthFactor);
    _wind.center = point;
    _wind.clipsToBounds = true;
    _windLabel.text = [NSString stringWithFormat:@"%i",_currentWindSpeed];
    _windLabel.textColor = UIColor.whiteColor;
    _windLabel.textAlignment = NSTextAlignmentCenter;
    _windLabel.center = point;
    //wind.layer.cornerRadius = wind.frame.size.width / 2;
    _wind.transform = CGAffineTransformMakeRotation( windDir-HALFPI);
    _windLabel.transform = CGAffineTransformMakeRotation( windDir-HALFPI);
    if (_currentWindSpeed < 1)
    {
        [_wind setHidden:YES];
        [_windLabel setHidden:YES];
    }
    [_userWaypointLabels addObject:_wind];
    idebug = _backgroundView.subviews.count;
    iii = _userWaypointLabels.count;
    [_backgroundView addSubview:_wind];
    [_backgroundView addSubview:_windLabel];
    [_userWaypointLabels addObject:_windLabel];
}
-(CGFloat) getSelectedWaypointHeading
{
    CGFloat rtn = 0;
    for (UserWaypoint* waypoint in _userWaypointArray)
    {
        if (waypoint.refno == CRAPI.sharedInstance.currentSelectedWaypoint)
            rtn = waypoint.headingInDeg;
    };
    return rtn;
}
-(void) createRedTicks
{
    CGFloat wpAz = 0;
    
    double curHead = _currentHeading;
    double wpHead = [self getSelectedWaypointHeading];
    double minHead = min (curHead,wpHead);
    double maxHead = max (curHead,wpHead);
    int opt = 1;
    if (maxHead - minHead > 180)
        opt = 2;
    int numRed = 0;
    for (CompassShapeLayer* shapeLayer in _tickShapes)
    {
        double tickHead = shapeLayer.heading;
        BOOL setRed = FALSE;
        BOOL setGreen = FALSE;
//        BOOL setBlue = FALSE;

        if (tickHead-1 <= _GPSHeadingFromPoints && tickHead + 1 >= _GPSHeadingFromPoints)
            setGreen = TRUE;
        else if (CRAPI.sharedInstance.currentSelectedWaypoint > 0)
        {
            if (opt == 1)
            {
                if (tickHead  >= minHead && tickHead  <= maxHead)
                    setRed = TRUE;
            }
            else
            {
                if (tickHead  > maxHead || tickHead < minHead)
                    setRed = TRUE;
            }
        }
        else
            _lineView.backgroundColor = UIColor.whiteColor;

        if (setGreen)
        {
            shapeLayer.strokeColor = UIColor.greenColor.CGColor;
            shapeLayer.currentColor = UIColor.greenColor;
        }
/*        else if (setBlue)
        {
            shapeLayer.strokeColor = UIColor.blueColor.CGColor;
            shapeLayer.currentColor = UIColor.blueColor;
        }
 */
        else if (setRed)
        {
            numRed++;
            if (shapeLayer.currentColor != UIColor.redColor)
            {
                shapeLayer.strokeColor = UIColor.redColor.CGColor;
                shapeLayer.currentColor = UIColor.redColor;
            }
        }
        else
        {
            if (shapeLayer.currentColor != shapeLayer.baseColor)
            {
                shapeLayer.strokeColor = shapeLayer.baseColor.CGColor;
                shapeLayer.currentColor = shapeLayer.baseColor;
            }
        }
    }
    if (numRed > 2)
        _lineView.backgroundColor = UIColor.redColor;
    else
        _lineView.backgroundColor = UIColor.whiteColor;

}
-(void) infoLabelPicked:(CGPoint)atPoint
{
    HuntingData *hd = HuntingData.new;
    
    [_locationManager setOffCourseSound:0
                 withVolume:0];

    _lastToDist = 0;
    switch (_infoLabelOption)
    {
        case 2: //make current pt focus
            _ignoreAtWaypoint = -1;
            _forward = TRUE;
            _lastToDist = 0;
            if (CRAPI.sharedInstance.currentSelectedWaypoint > 0 &&
                CRAPI.sharedInstance.currentSelectedWaypoint != CRAPI.sharedInstance.currentFocusWaypoint)
            {
                CRAPI.sharedInstance.currentSelectedWaypoint = -1;
                [self removeAsRouteOnMap];
            }
            else
            {
                int focWP = CRAPI.sharedInstance.currentFocusWaypoint;
                CRAPI.sharedInstance.currentSelectedWaypoint = focWP;
                [_locationManager createTwoPointRoute:_locationManager.currentPoint toLL:_currentFocusWaypointLL];
            }
            [self removeUserWaypoints];
            [self addUserWaypoints:_locationManager.currentPoint];
            break;
        case 1: //make next route point focus
        {
            if (_locationManager.currentRoutePointNumber > 0)
            {
                UserWaypoint *wp = [hd getWaypointWithRefno:_locationManager.currentRoutePointNumber];
                _locationManager.fromPoint = wp.latlon;
                NSArray <UserWaypoint*> *routePointArray = [hd getWaypointsOfType:@"RoutePoint"
                                                             withRefnoGreaterThan:_locationManager.currentRoutePointNumber];
                if (routePointArray.count > 0)
                {
                    CRAPI.sharedInstance.currentSelectedWaypoint = routePointArray[0].refno;
                    _locationManager.currentRoutePointNumber = routePointArray[0].refno;
                }
                else
                {
                    CRAPI.sharedInstance.currentSelectedWaypoint = -1;
                    _locationManager.currentRoutePointNumber = 0;
                }
                _userWaypointArray = [hd getWaypoints];
            }
            else
            {
                _ignoreAtWaypoint = CRAPI.sharedInstance.currentFocusWaypoint;
                [hd setWaypointCompassStatus:_ignoreAtWaypoint
                            displayOnCompass:NO];
                CRAPI.sharedInstance.currentSelectedWaypoint = -1;
                CRAPI.sharedInstance.currentFocusWaypoint = -1;
                _userWaypointArray = [hd getWaypoints];
                [self update];
            }
        }
            break;
        default:
        {
            
            NSMutableArray *optionList = NSMutableArray.array;
            NSArray <UserWaypoint*> *routePointArray = [hd getWaypointsOfType:@"RoutePoint"];
            if (routePointArray.count > 0)
                [optionList addObject:@"Start Route"];
            [_dScaView setUserInteractionEnabled:NO];
            [_backgroundView setUserInteractionEnabled:NO];
            [_profileView setUserInteractionEnabled:NO];
            [self.view setMultipleTouchEnabled:NO];
            [_singleFingerTap setEnabled:NO];
            _nvptv = [NVPopoverTableView showPopoverTableViewInView:self.view
                                                                              delegate:self
                                                                                 title:@"Compass Point Options"
                                                                             textArray:optionList
                                                                         includeCancel:YES];
            _nvptv.allowsSubtitle = NO;
             
            
        }
           break;
    }

    return;
}

- (void) setDateAndTimeLabel
{
    if (!_displayTime)
    {
        time_t itime = NSDate.date.timeIntervalSince1970;
        NSString * date = textAfter ([WeatherData forecastDayandTime:itime],@"Today ");
        dispatch_async(dispatch_get_main_queue(), ^{
            if (CRAPI.sharedInstance.amBuildingTrackRoute)
                _selectDateLabel.backgroundColor = UIColor.lightGrayColor;
            else
                _selectDateLabel.backgroundColor = UIColor.whiteColor;
            _selectDateLabel.text = [NSString stringWithFormat:@"Current Time\n%@",date];

        });
    }

}

-(void) popoverTableViewDidCancel:(NVPopoverTableView *)popoverTableView
{
    [popoverTableView hide:YES];
    [_singleFingerTap setEnabled:YES];

}


- (void)popoverTableView:(NVPopoverTableView *)popoverTableView
    didSelectRowWithText:(NSString *)text
                 atIndex:(NSInteger)index
{
    if ([popoverTableView.identifier isEqual:@"forecast"])
    {
        NSString *time = textAfter(text,@"|");
        int currentTime = NSDate.date.timeIntervalSince1970;

        if (time)
        {
            time_t itime = time.integerValue;
            if (itime)
            {
                WeatherRecord* data  = [WeatherData getRecordFromForecast:_currentForecast atTime:itime];
                NSString * date = [WeatherData forecastDayandTime:data.timeStamp];
                _displayTime = itime;
                _selectDateLabel.text = date;
                [self weatherDataDidReturnData:data];
            }
            else
            {
                _displayTime = 0;
                [self setDateAndTimeLabel];
                [self getWeatherData];
           }
        }
    }
    else
    {
        if ([text isEqualToString:@"Exit Route"])
        {
            [_locationManager exitRouteMode];
            _locationManager.offDist = 0;

        }
        else if ([text isEqualToString:@"Start Route"])
        {
            [_locationManager startRoute];
        }
        else if ([text isEqualToString:@"Get Weather Data"])
        {
            [self getWeatherData];
            //NSString * weather = [CRAPI.sharedInstance getWeatherDataAtLatlon:_currentPoint];
            iii = 1;
        }
        else if ([text isEqualToString:@"Set Profile Exageration to 1"])
            _heightExpansion = 1;
        else if ([text isEqualToString:@"Set Profile Exageration to 2"])
            _heightExpansion = 2;
        else if ([text isEqualToString:@"Set Profile Exageration to 5"])
            _heightExpansion = 5;
        else if ([text isEqualToString:@"Set Profile Exageration to 10"])
            _heightExpansion = 10;
    }
    [popoverTableView hide:YES];
    [_singleFingerTap setEnabled:YES];

}

- (void)didInitiateRoute:(TrackLocationManager *)manager
{
    [self displayProfile:_locationManager.fromPoint
                      to:_locationManager.firstRoutePoint];
    [self removeUserWaypoints];
    [self addUserWaypoints:_locationManager.currentPoint];
}
- (void) getForcastWeatherData
{
    [_singleFingerTap setEnabled:NO];

    [_wd getWeatherforecast:_locationManager.currentPoint
                           forTime:0
                          delegate:self];

}
- (void)weatherDataDidReturnforecast:(NSArray *)forecast
{
    _currentForecast = forecast;
    _forecastDates = [WeatherData getDatesFromforecast:forecast];
    [self performSelectorOnMainThread:@selector(displayforecast)
                           withObject:nil
                        waitUntilDone:NO];

}
-(void) displayforecast
{
    _nvptv =
    [NVPopoverTableView showPopoverTableViewInView:self.view
                                          delegate:self
                                             title:@"Select a Date and Time"
                                         textArray:_forecastDates
                                     includeCancel:YES];
    _nvptv.identifier = @"forecast";
    _nvptv.parseTextToButtons = NO;
    
}

-(void) getWeatherData
{
    [_wd getCurrentWeather:_locationManager.currentPoint delegate:self];
}
- (void)weatherDataDidReturnData:(WeatherRecord*)data
{
    _currentWeatherRecord = data;
    [self updateWeather];
}

- (void) updateWeather
{
    if (!_currentWeatherRecord)
    {
        [self getWeatherData];
        return;
    }
    WeatherRecord* data = _currentWeatherRecord;
    _currentTemp = data.temp;
    _currentWindSpeed = data.windSpeed;
    _currentWindDirection = data.windDir;
    _currentWeatherDesc = data.desc;
    NSString * sunRise = @"";
    NSString * sunSet = @"";
    if (data.sunRise > 0)
    {
        sunRise = [WeatherData forecastDayandTime:data.sunRise];
        sunSet = [WeatherData forecastDayandTime:data.sunSet];
    }

    [NSOperationQueue.mainQueue addOperationWithBlock:^{
        _weatherLabel.text = [NSString stringWithFormat:@"Temp:%i deg\nWind:%i mph\n%@",_currentTemp,_currentWindSpeed,_currentWeatherDesc];
        if (sunRise.length > 0)
        {
            NSString * riseText = textAfter(sunRise, @"Today ");
            NSString * setText = textAfter(sunSet, @"Today ");
            NSString * sinceUntilText = [self getSinceUntilText:data.sunRise
                                                        setText:data.sunSet];
            _sunRiseSetLabel.text = [NSString stringWithFormat:@"Sunrise:%@\nSunset:%@\n%@",riseText,setText,sinceUntilText];
        }
        [self addSun];
        [self addWind];
   }];

    //3.35,"deg":213,"gust":3.12}
   return;
}

- (NSString*) getSinceUntilText:(time_t)riseTime
                        setText:(time_t)setTime
{
    NSString * rtn = @"";
    time_t now = NSDate.date.timeIntervalSince1970;
    long riseDiff = now - riseTime;
    long setDiff = setTime - now;
    NSString * sinceUntil = @"since";
    if (riseDiff < 0)
    {
        if (riseDiff < 0)
            sinceUntil = @"until";
        riseDiff = abs (riseDiff) / 60;
        int mins = riseDiff % 60;
        int hours = riseDiff / 60;
        if (hours)
        {
            NSString * hourText = @"hr";
            if (hours > 1)
                hourText = @"hrs";
            if (mins)
                rtn = [NSString stringWithFormat:@"%i %@ %i min %@",hours,hourText, mins,sinceUntil];
            else
                rtn = [NSString stringWithFormat:@"%i %@ %@",hours,hourText,sinceUntil];
        }
        else
        {
            rtn = [NSString stringWithFormat:@"%i minutes %@",mins,sinceUntil];
        }
    }
    else
    {
        if (setDiff > 0)
            sinceUntil = @"until";
        setDiff = abs (setDiff) / 60;
        int mins = setDiff % 60;
        int hours = setDiff / 60;
        if (hours)
        {
            NSString * hourText = @"hr";
            if (hours > 1)
                hourText = @"hrs";
            if (mins)
                rtn = [NSString stringWithFormat:@"%i %@ %i min %@",hours,hourText, mins,sinceUntil];
            else
                rtn = [NSString stringWithFormat:@"%i %@ %@",hours,hourText,sinceUntil];
        }
        else
        {
            rtn = [NSString stringWithFormat:@"%i minutes %@",mins,sinceUntil];
        }
    }
    return rtn;
}
- (void)weatherDataDidReturnError:(NSString *) message
{
    
}
- (CGFloat) getAzOfSun:(time_t)iTime
              altitude:(CGFloat*)pAlt
{
    struct tm tmtime = *localtime (&iTime);
    CGFloat rtn = 100;
    
    double Altitude=0, Az;
    DPOINT pt = LLPointToDPoint(_locationManager.currentPoint);
    GetAltitudeAndAzOfSun (pt,0,iTime,&Altitude,&Az);
    *pAlt = Altitude;
    rtn = DegreesToRadians (Az-90);
    return rtn;
}
-(void) profileViewPicked:(CGPoint)atPoint
{
    return;
    DTMData * dtm = DTMData.new;
    BOOL opened = [dtm open:0];
    LLPOINT llPoint;
    static int opt = 0;
    
    double elv = [dtm getElevation:&llPoint];
    [dtm close:opened];
    //[self offCourseNotification:opt++];
    if (opt > 2)
        opt = 0;
    return;
}

- (void) setInfoLabelText:(NSString*)text
{
    if (text.length > 100)
        iii = 1;
    if (![text containsString:@"\n"])
        text = [NSString stringWithFormat:@"%@\n%@",text,_locationManager.currentMotionActivity];
    dispatch_async(dispatch_get_main_queue(), ^{
                _infoLabel.text = text;
            });
    
}
-(void) update
{
    static BOOL inUpdate = FALSE;
    if (inUpdate)
        return;
    inUpdate = TRUE;
    UIDevice * device = UIDevice.currentDevice;
    //CGFloat magneticHeading = [self heading:_nowHeading.magneticHeading fromOrirntation: device.orientation];
    
    //CGFloat trueHeading = [self heading:_nowHeading.trueHeading fromOrirntation: device.orientation];
    CGFloat head = _nowHeading.trueHeading;
    if (head < 0)
        head = _nowHeading.magneticHeading;
    CGFloat headi = -1.0 * M_PI * head / 180.0;
    //_infoLabel.text = @"\(Int(magneticHeading))";
    [self resetDirection:headi];
    _lastResetHeading = headi;

    CLLocationDirection theHeading = _nowHeading.magneticHeading > 0 ? _nowHeading.magneticHeading : _nowHeading.trueHeading;
    _currentHeading = theHeading;
    [self createRedTicks];

    NSString * directionLabelText;
    int angle = IDNINT(theHeading);
    
    directionLabelText = @"N";
    if (theHeading > 22.5)
        directionLabelText = @"NE";
    if (theHeading > 90 - 22.5)
        directionLabelText = @"E";
    if (theHeading > 90 + 22.5)
        directionLabelText = @"SE";
    if (theHeading > 180 - 22.5)
        directionLabelText = @"S";
    if (theHeading > 180 + 22.5)
        directionLabelText = @"SW";
    if (theHeading > 270 - 22.5)
        directionLabelText = @"W";
    if (theHeading > 270 + 22.5)
        directionLabelText = @"NW";
    if (theHeading > 270 + 45)
        directionLabelText = @"N";
    
    //[self setInfoLabelText:[NSString stringWithFormat:@"%i %@\n%.2f %.2f",angle,directionLabelText,_GPSHeading,_GPSHeadingFromPoints]];
    [self setInfoLabelText:[NSString stringWithFormat:@"%i %@",angle,directionLabelText]];
    _infoLabelOption = 0;
    CRAPI.sharedInstance.currentFocusWaypoint = -1;
    [self removeProfileLayers];
    for (UserWaypoint* waypoint in _userWaypointArray)
    {
        if ([waypoint.type isEqual:@"Vehicle"])
            ii = 1;
        if (waypoint.displayOnCompass && waypoint.refno != _ignoreAtWaypoint)
        {
            if (![waypoint.type isEqual:@"RoutePoint"] || waypoint.refno == CRAPI.sharedInstance.currentSelectedWaypoint)
            {
                double dist = ArcDistanceLL(waypoint.latlon, _locationManager.currentPoint);
                if (dist < _maxWaypointDist || ([waypoint.type isEqual:@"Vehicle"] && dist < _maxVehicleDist))
                {
                    double wpaz = HeadingFromAZ(AZMLatLon (_locationManager.currentPoint,waypoint.latlon));
                    waypoint.headingInDeg = RadiansToDegrees (wpaz);
                    double curAz = DegreesToRadians(theHeading);
                    if (dist / METERS_PER_YARD < _locationManager.atDistance && ![waypoint.type isEqual:@"Vehicle"] )
                    {
                        [self setInfoLabelText:[NSString stringWithFormat:@"At %@: (%.0f yards)",waypoint.name,dist/ METERS_PER_YARD]];
                        _infoLabel.textColor = UIColor.whiteColor;
                        if ([waypoint.type isEqual:@"RoutePoint"])
                            _locationManager.currentRoutePointNumber = waypoint.refno;
                        else
                            _locationManager.currentRoutePointNumber = 0;
                        CRAPI.sharedInstance.currentFocusWaypoint = waypoint.refno;
                        _currentFocusWaypointLL = waypoint.latlon;
                        _infoLabelOption = 1;
                        break;
                    }
                    else
                    {
                        double daz = DeltaAZD(wpaz, curAz);
                        if ((CRAPI.sharedInstance.currentSelectedWaypoint <= 0 && fabs (daz) < 0.2) || waypoint.refno == CRAPI.sharedInstance.currentSelectedWaypoint)
                        {
                            BOOL haveProfile = FALSE;
                            _maxElev= _maxGrade = 0;
                            NSString *units = @"miles";
                            CRAPI.sharedInstance.currentFocusWaypoint = waypoint.refno;
                            if (CRAPI.sharedInstance.currentSelectedWaypoint > 0)
                                haveProfile = [self displayProfile:_locationManager.currentPoint
                                                                to:waypoint.latlon];
                            else
                            {
                                _locationManager.fromPoint = _locationManager.currentPoint;
                                haveProfile = [self displayProfile:_locationManager.currentPoint
                                                                to:waypoint.latlon];
                            }
                            if (dist / METERS_PER_YARD < _locationManager.nearDistance && ![waypoint.type isEqual:@"Vehicle"] )
                            {
                                units = @"yards";
                                dist = dist / METERS_PER_YARD;
                                [self setInfoLabelText:[NSString stringWithFormat:@"Near %@: %.0f %@",waypoint.name,dist,units]];
                            }
                            else
                            {
                                int offDist = IDNINT(_locationManager.offDist / METERS_PER_YARD);
                                NSString *offsetText = @"";
                                NSString *offDir = @"L";
                                if (offDist != 0)
                                {
                                    if (_locationManager.leftOrRight == RIGHT)
                                        offDir = @"R";
                                    offsetText = [NSString stringWithFormat:@"(%i YARDS %@)",offDist,offDir];
                                }
                                NSString * infoLabelText = @"";
                                if (dist < METERS_PER_MILE/10)
                                {
                                    units = @"yards";
                                    dist = dist / METERS_PER_YARD;
                                    infoLabelText = [NSString stringWithFormat:@"%@: %.0f %@%@",waypoint.name,dist,units,offsetText];
                                }
                                else
                                {
                                    dist = dist / METERS_PER_MILE;
                                    infoLabelText = [NSString stringWithFormat:@"%@: %.2f %@%@",waypoint.name,dist,units,offsetText];
                                }
                                if (haveProfile)
                                {
                                    NSString * ilt = [NSString stringWithFormat:@"\n%Min Elev:%i MaxElev:%i\nMax Grade:%.0f",IDNINT(_minElev),IDNINT(_maxElev),_maxGrade];
                                    
                                    infoLabelText = [infoLabelText stringByAppendingString:ilt];
                                }
                                [self setInfoLabelText:infoLabelText];
                            }
                            _infoLabel.textColor = UIColor.whiteColor;
                            
                            _infoLabelOption = 2;
                            break;
                        }
                    }
                }
            }
        }
        
    }
    [self setDateAndTimeLabel];
    inUpdate = FALSE;
    return;
}
-(void) removeProfileLayers
{
    for (CAShapeLayer *profileLayer in _profileLayers)
    {
        if (profileLayer)
            [profileLayer removeFromSuperlayer];
    }
    [_stickManView removeFromSuperview];
}

-(double) calcGrade:(double *)pElev
                 at:(int) at
          numPoints:(int) np
            nullElv:(double) nullElv
         ftPerPixel:(double) feetPerPixel
{
    double grade = 1000;
    int span = 5;
    double minElev = pElev[at];
    double maxElev = pElev[at];
    int mini = at;
    int maxi = at;
    int numi = 1;
    int n = at;
    int j = span;
    int nPix = 1;
    while (n && j--)
    {
        n--;
        if (pElev[n] == nullElv)
            n = 0;
        else
        {
            minElev = min (minElev,pElev[n]);
            maxElev = max (maxElev,pElev[n]);
            nPix++;
        }
    }
    n = at;
    j = span;
    while (n && j--)
    {
        if (n < np)
        {
            if (pElev[n] == nullElv)
                n = 0;
            else
            {
                minElev = min (minElev,pElev[n]);
                maxElev = max (maxElev,pElev[n]);
                nPix++;
                n++;
            }
        }
        else
            n = 0;
    }
    grade = min (1000,100.0 * fabs((maxElev - minElev)/(feetPerPixel * nPix)));
    return grade;
}
-(BOOL) displayProfile:(LLPOINT)atLL
                    to:(LLPOINT)toLL
{
    BOOL rtn = FALSE;
    LLPOINT fromLL = {0};
    static LLPOINT lastToLL = {0};
    CGRect frame = _profileView.frame;
    CAShapeLayer *profileLayer;
    NSArray <UIColor*>* gradeColors = @[UIColor.blueColor,UIColor.greenColor,UIColor.orangeColor,UIColor.cyanColor,UIColor.redColor,UIColor.blackColor];

    [self removeProfileLayers];
    _profileLayers = NSMutableArray.new;
    
    fromLL = _locationManager.fromPoint;
    lastToLL = toLL;
    DPOINT fromUTM = LLPointToDPoint (fromLL);
    DPOINT toUTM = LLPointToDPoint (toLL);
    DPOINT atUTM = LLPointToDPoint (atLL);
    int nPixels = frame.size.width;
    ConvertCoord(&fromUTM, LATLONPROJECTION, UTM15PROJECTION);
    ConvertCoord(&toUTM, LATLONPROJECTION, UTM15PROJECTION);
    ConvertCoord(&atUTM, LATLONPROJECTION, UTM15PROJECTION);
    _locationManager.fromUTM = fromUTM;
    _locationManager.toUTM = toUTM;
    _locationManager.atUTM = atUTM;

    double groundDist = ldistp(_locationManager.fromUTM, _locationManager.atUTM) + ldistp (_locationManager.atUTM,_locationManager.toUTM);
    double atDist = ldistp(_locationManager.fromUTM, _locationManager.atUTM);
    int toDist = IDNINT(ldistp(_locationManager.atUTM,_locationManager.toUTM)/4);
    if (_lastToDist && toDist > _lastToDist)
        _forward = FALSE;
    if (_lastToDist && toDist < _lastToDist)
        _forward = TRUE;
    if (_lastToDist != toDist)
        _lastToDist = toDist;
    double xPct = atDist/groundDist;
    double feetPerHorizontalPixel = groundDist / nPixels;
    double pixelsPerHorizontalFoot = nPixels / groundDist;
    int nFromPixels = nPixels * (atDist / groundDist);
    int nToPixels = nPixels * ((groundDist - atDist) / groundDist);
    LPDPOINT pt = malloc ((nPixels+1) * sizeof (DPOINT) + 8);
    int npt = 0;
    pt[npt++] = _locationManager.fromUTM;
    double xInc = (_locationManager.atUTM.x - _locationManager.fromUTM.x)/nFromPixels;
    double yInc = (_locationManager.atUTM.y - _locationManager.fromUTM.y)/nFromPixels;
    for (int i = 1; i < nFromPixels; i++)
    {
        pt[npt] = pt[npt-1];
        pt[npt].x += xInc;
        pt[npt++].y += yInc;
    }

    pt[npt++] = _locationManager.atUTM;
    xInc = (_locationManager.toUTM.x - _locationManager.atUTM.x)/nToPixels;
    yInc = (_locationManager.toUTM.y - _locationManager.atUTM.y)/nToPixels;
    for (int i = 1; i < nToPixels; i++)
    {
        pt[npt] = pt[npt-1];
        pt[npt].x += xInc;
        pt[npt++].y += yInc;
    }
    nPixels = npt;
    DTMData * dtm = DTMData.new;
    MNMXCORD bounds = PolyBounds(pt, npt);

    BOOL opened = [dtm open:&bounds];

    LPDOUBLE pElev = malloc (nPixels * sizeof(double) + 4);
    LPDOUBLE pGrade = malloc (nPixels * sizeof(double) + 4);
    CGPoint * pPoint = malloc (nPixels * sizeof(CGPoint) + 4);
    _minElev = DBL_MAX;
    _maxElev = -DBL_MAX;
    _maxGrade = 0;
    double grade;
    
    for (int i=0;i<nPixels;i++)
    {
//        DPOINT ptx={492061,4937127};
//        double e =[dtm getElevation:&ptx];
        pElev[i] = [dtm getElevation:&pt[i]];
//        if (pElev[i]>1200)
//            ptx = pt[i];
        if (pElev[i] != dtm.NullElv)
        {
            rtn = TRUE;
            _minElev = MIN (_minElev,pElev[i]);
            _maxElev = MAX (_maxElev,pElev[i]);
            pPoint[i].x = i;
        }
    }
    [dtm close:opened];

    SmoothProfile (pPoint,nPixels,2);
    for (int i=0;i<nPixels;i++)
    {
        if (i)
        {
            if (pElev[i-1] != dtm.NullElv)
            {
                grade = [self calcGrade:pElev
                                     at:i
                              numPoints:nPixels
                                nullElv:dtm.NullElv
                             ftPerPixel:feetPerHorizontalPixel];
                pGrade[i-1] = grade;
                _maxGrade = max (_maxGrade,pGrade[i-1]);
            }
            else
                pGrade[i-1] = 1000;
        }

    }
    if (rtn)
    {
        CGRect frame = _profileView.frame;
        double elevDiff = _maxElev - _minElev;
        double profileImageHeight = _profileView.frame.size.height;
        double profileImageWidth = _profileView.frame.size.width;
        double profileImageBottom = profileImageHeight;
        double atLoc = profileImageWidth * xPct;
        double pixelsPerVerticalFoot = 0;
        double atY = profileImageWidth;
        if (elevDiff > 0)
            pixelsPerVerticalFoot = profileImageHeight / elevDiff;
        if (_heightExpansion * pixelsPerHorizontalFoot < pixelsPerVerticalFoot)
            pixelsPerVerticalFoot = _heightExpansion * pixelsPerHorizontalFoot;
        for (int i=0;i<nPixels;i++)
        {
            pPoint[i].y = profileImageBottom - (pElev[i]-_minElev) * pixelsPerVerticalFoot;
            if ((i < (nPixels - 1)) && pPoint[i].x <= atLoc && pPoint[i+1].x >= atLoc)
                atY = pPoint[i].y;
        }
        int i = 0;
        int nlines = 0;
        int gradeLevel;
        int lastLevel = -1;
        int lineWidth = 5;
        UIBezierPath *profilePath;
        do
        {
            CGPoint pnt = pPoint[i];
            int gradeLevel = GetGradeLevel (pGrade[i]);
            if (gradeLevel != lastLevel)
            {
                if (lastLevel != -1)
                {
                    //pnt.y =70;
                    [profilePath addLineToPoint:pnt];
                    profileLayer.path = profilePath.CGPath;
                    [_profileView.layer addSublayer:profileLayer];
                    [_profileLayers addObject:profileLayer];
                }
                profileLayer = CAShapeLayer.layer;
                profilePath = UIBezierPath.new;
                profileLayer.fillColor = UIColor.clearColor.CGColor;
                profileLayer.lineWidth = lineWidth;
                profileLayer.strokeColor = gradeColors[gradeLevel].CGColor;
                //[sepnt.y = 10;
                [profilePath moveToPoint:pnt];
                nlines = 0;
            }
            else
            {
                //pnt.y = 50;
                [profilePath addLineToPoint:pnt];
                nlines++;
            }
            lastLevel = gradeLevel;
            i++;
        }while (i < nPixels);
        //[profilePath closePath];
        if (nlines >0)
        {
            profileLayer.path = profilePath.CGPath;
            [_profileView.layer addSublayer:profileLayer];
            [_profileLayers addObject:profileLayer];
        }
        if (CRAPI.sharedInstance.currentSelectedWaypoint > 0)
        {
            UIImage * stickManImage = [UIImage imageWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"StickManT"
                                                                                                     ofType:@"png"]];
            CGPoint point;
            point.x = _profileView.frame.size.width/2;
            point.y = _profileView.frame.size.height/2;
            double stickManHeight = stickManImage.size.height/5;
            double stickManWidth = stickManImage.size.width/5;
            CGRect stickManRect = CGRectMake(atLoc,atY-stickManHeight,stickManWidth,stickManHeight);
            _stickManView = [[UIImageView alloc] initWithFrame:stickManRect];
            _stickManView.contentMode = UIViewContentModeScaleToFill;
            _stickManView.backgroundColor = UIColor.clearColor;
            if (!_forward)
                _stickManView.transform = CGAffineTransformScale(CGAffineTransformIdentity,-1,1);
            
            _stickManView.image = stickManImage;
            [_profileView addSubview:_stickManView];
        }
    }
    free (pElev);
    free (pGrade);
    free (pt);
    
    return rtn;
}
int GetGradeLevel (double grade)
{
    int rtn = 0;
    if (grade < 5)
        rtn = 0;
    else if (grade < 10)
        rtn = 1;
    else if (grade < 15)
        rtn = 2;
    else if (grade < 20)
        rtn = 3;
    else if (grade < 30)
        rtn = 4;
    else
        rtn = 5;
    return rtn;
}


- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (void) removeAsRouteOnMap
{
    CRAPI.sharedInstance.currentRoute = nil;
    CRAPI.sharedInstance.routeBearing = nil;
}


- (void) traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    return;
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

@end
