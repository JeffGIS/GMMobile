//
//  CompassViewController.m
//  NVMobile
//
//  Created by Jeff Smith on 10/21/22.
//  Copyright © 2022 GSSi. All rights reserved.
//
#import "CompassViewController.h"
#import "DTMData.h"
//#import "NVCoordinateLibrary/proj_api.h"
#include "CCodeLibrary/PROJ.H"
#include "CVTCoord.h"

DPOINT saveFromUTM, saveToUTM;

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
@property CGFloat screenW, screenH, heightFactor, widthFactor, radius;
@property (nonatomic) CLLocationManager *locationManager;
@property id oldLocationManagerDelegate;
@property UILabel *directionLabel;
@property NSMutableArray * userWaypointLabels;
@property NSMutableArray * tickShapes;
@property CGPoint po;
@property LLPOINT currentPoint;
@property NSArray <UserWaypoint*> *userWaypointArray;
@property double maxWaypointDist;
@property CLHeading*  nowHeading;
@property CGFloat currentHeading;
@property CGFloat lastResetHeading;
@property int infoLabelOption;
@property int currentRoutePointNumber;
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
@property DPOINT fromUTM, toUTM, atUTM;
@property NSTimer * offCourseTimer;
@property BOOL goLeft;
@property double offDist;
@property int leftOrRight;
@property int minTimerDelay,maxTimerDelay;
@property CGFloat timerDelay;
@property double notifyDist;
@property int currentTimerDelay;
@property int nearDist;
@property int atDistance;
@property NSMutableArray * forecastDates;
@property NSArray * currentForecast;
@property time_t displayTime;


@end

@implementation CompassViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _wd = WeatherData.new;
    _currentWindSpeed = -1;
    CGRect r = self.view.frame;
    r = UIScreen.mainScreen.bounds;
    _statusBarHeight = UIApplication.sharedApplication.windows[0].safeAreaInsets.top;
    _screenH = UIScreen.mainScreen.bounds.size.height;
    _screenW = UIScreen.mainScreen.bounds.size.width;
    _heightFactor = _screenH / 568.0;
    _widthFactor = _screenW / 320.0;
    _heightExpansion = 4;
    _lastToDist = 0;
    _forward = TRUE;
    _lastResetHeading = 0;
    [self configUI];
    InitProj4CoordConv (FALSE);
    _maxTimerDelay = 60;
    _minTimerDelay = 10;
    _timerDelay = _maxTimerDelay;
    _currentTimerDelay = 0;
    _notifyDist = 10;
    _nearDist = 50;
    _atDistance = 40;
    _closeDistance = 100;
    _displayTime = 0;

}
-(BOOL) shouldAutorotate
{
    return FALSE;
}

-(void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    return;
}

-(void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    _maxWaypointDist = 5.0 * METERS_PER_MILE;
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
    //[self DrawCompass];
    //if (CLLocationManager.locationServicesEnabled && CLLocationManager.headingAvailable)
    {
        [_locationManager startUpdatingLocation];
        [_locationManager startUpdatingHeading];
    }
    _offDist = 0;
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [_locationManager stopUpdatingHeading];
    [_locationManager stopUpdatingLocation];
    _locationManager.delegate = _oldLocationManagerDelegate;
    //InitProj4CoordConv (TRUE);

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
        if (PointInSuperView(location,_infoLabel,_profileView))
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
-(void)configUI
{
    CGRect frame;
    CGRect selfViewFrame = self.view.frame;
    int top = UIApplication.sharedApplication.windows[0].safeAreaInsets.top;
    int left = UIApplication.sharedApplication.windows[0].safeAreaInsets.left;
    int right = self.view.frame.size.width - UIApplication.sharedApplication.windows[0].safeAreaInsets.right;
    int bottom = self.view.frame.size.height - UIApplication.sharedApplication.windows[0].safeAreaInsets.bottom;
    self.view.backgroundColor = UIColor.blackColor;
    [self.view setMultipleTouchEnabled:YES];
    _singleFingerTap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                            action:@selector(handleSingleTap:)];

    _dScaView = UIView.new;
    _dScaView.backgroundColor = UIColor.blackColor;
    _dScaView.frame = CGRectMake(0,0.1*_screenH,_screenW,_screenW);
    _levelView = UIView.new;
    _levelView.frame = CGRectMake (0,0,_dScaView.frame.size.width / 2 - 80*_widthFactor, 1);
    _levelView.center = CGPointMake(_dScaView.frame.size.width / 2,_dScaView.frame.size.height / 2);
    _levelView.backgroundColor = UIColor.whiteColor;
    _verticalView = UIView.new;
    _verticalView.frame = CGRectMake (0,0,1,_dScaView.frame.size.height / 2 - 80*_widthFactor);
    _verticalView.center = CGPointMake(_dScaView.frame.size.width / 2,_dScaView.frame.size.height / 2);
    _verticalView.backgroundColor = UIColor.whiteColor;
    _lineView = UIView.new;
    _lineView.frame = CGRectMake (self.view.frame.size.width / 2 - 1.5, 0.05*_screenH,5,65);
    _lineView.backgroundColor = UIColor.whiteColor;
    _compassTriangleView = UIView.new;
    _compassTriangleView.frame = CGRectMake(0,0,_screenW,_screenW);
    _compassTriangleView.backgroundColor = UIColor.clearColor;
    _profileView = UIView.new;
    frame = CGRectMake(0, IDNINT(380*_heightFactor), _screenW,IDNINT(130*_heightFactor)+UIApplication.sharedApplication.windows[0].safeAreaInsets.bottom-24);
    //frame.origin.y = bottom - frame.size.height;
    _profileView.frame = frame;
    _profileView.backgroundColor = UIColor.whiteColor;
    _selectDateLabel = UILabel.new;
    frame = CGRectMake(0, _profileView.frame.origin.y - 68, _screenW,56);
    _selectDateLabel.frame = frame;
    _selectDateLabel.backgroundColor = UIColor.lightGrayColor;
    _selectDateLabel.textColor = UIColor.blackColor;
    _selectDateLabel.font =[UIFont systemFontOfSize: 32];
    _selectDateLabel.textAlignment = NSTextAlignmentCenter;
    _selectDateLabel.numberOfLines = 0;
    _selectDateLabel.adjustsFontSizeToFitWidth = YES;
    _selectDateLabel.text = @"Current Date and Time";

    _infoLabel = UILabel.new;
    _infoLabel.frame = CGRectMake (0,0,_profileView.frame.size.width,_profileView.frame.size.height/2);
    _infoLabel.backgroundColor = UIColor.blackColor;
    _infoLabel.textColor = UIColor.whiteColor;
    _infoLabel.font =[UIFont systemFontOfSize: 42];
    _infoLabel.textAlignment = NSTextAlignmentCenter;
    _infoLabel.numberOfLines = 0;
    _infoLabel.adjustsFontSizeToFitWidth = YES;
    [_profileView addSubview:_infoLabel];
    _dScaView.clipsToBounds = true;
    _dScaView.layer.cornerRadius = _dScaView.frame.size.width / 2;
    _backgroundView = UIView.new;
    _backgroundView.frame = CGRectMake (0,0,_dScaView.frame.size.width,_dScaView.frame.size.height);
    _backgroundView.backgroundColor = UIColor.blackColor;
    [_dScaView addSubview:_backgroundView];
    [_dScaView addSubview:_levelView];
    [_dScaView addSubview:_verticalView];
    [self.view insertSubview:_lineView atIndex:0];
    [_dScaView addSubview:_compassTriangleView];

    _optionsButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _optionsButton.imageView.contentMode = UIViewContentModeScaleAspectFill;
    _optionsButton.backgroundColor = UIColor.whiteColor;
    _optionsButton.frame = CGRectMake(left,top,40,40);

    [_optionsButton setImage:[UIImage imageWithContentsOfFile:
                      [NSBundle.mainBundle pathForResource:@"list"
                                                    ofType:@"png"]]
                forState:UIControlStateNormal];
    [_optionsButton addTarget:self
                               action:@selector(optionsButtonTapped)
                     forControlEvents:UIControlEventTouchUpInside];
    [self.view  addSubview:_optionsButton];
    
    _weatherLabel = UILabel.new;
    _weatherLabel.frame = CGRectMake(right-160,top,160,55);
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

    _sunRiseSetLabel = UILabel.new;
    _sunRiseSetLabel.frame = CGRectMake(left+50,top,120,55);
    _sunRiseSetLabel.backgroundColor = UIColor.blackColor;
    _sunRiseSetLabel.textColor = UIColor.whiteColor;
    _sunRiseSetLabel.font =[UIFont systemFontOfSize: 20];
    _sunRiseSetLabel.adjustsFontSizeToFitWidth = YES;
    _sunRiseSetLabel.textAlignment = NSTextAlignmentCenter;
    _sunRiseSetLabel.numberOfLines = 3;
    _sunRiseSetLabel.text = @"Sunrise:5:31\nSunset:7:33";
    [self.view  addSubview:_sunRiseSetLabel];

    
    [self.view addSubview:_dScaView];
    [self.view addSubview:_profileView];
    [self.view addSubview:_selectDateLabel];
    [self.view setUserInteractionEnabled:YES];
    [self.view addGestureRecognizer:_singleFingerTap];

    [self configScaleDial];
}

-(void) optionsButtonTapped
{
    HuntingData *hd = HuntingData.new;
    NSMutableArray *optionList = NSMutableArray.array;
    NSArray <UserWaypoint*> *routePointArray = [hd getWaypointsOfType:@"RoutePoint"];
    if (routePointArray.count > 0)
        [optionList addObject:@"Start Route"];
    [optionList addObject:@"Get Weather Data"];
    [optionList addObject:@"Set Profile Exageration to 1"];
    [optionList addObject:@"Set Profile Exageration to 2"];
    [optionList addObject:@"Set Profile Exageration to 4"];
    [_dScaView setUserInteractionEnabled:NO];
    [_backgroundView setUserInteractionEnabled:NO];
    [_profileView setUserInteractionEnabled:NO];
    [self.view setMultipleTouchEnabled:NO];
    [_singleFingerTap setEnabled:NO];
    NVPopoverTableView *nvptv = [NVPopoverTableView showPopoverTableViewInView:self.view
                                                                      delegate:self
                                                                         title:@"Compass Options"
                                                                     textArray:optionList
                                                                 includeCancel:YES];
    nvptv.allowsSubtitle = NO;
     

}

-(void) weatherButtonTapped
{
    [self getWeatherData];
    [self configUI];
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

- (void) configScaleDial
{
    //return;
    CGFloat degree_360 = M_PI;
    
    CGFloat degree_180  = degree_360 / 2;
    
    CGFloat angle = degree_360 / 90;
    
    NSArray * directionArray = @[@"N", @"E", @"S", @"W"];
    
    _po = CGPointMake (_dScaView.frame.size.width / 2, _dScaView.frame.size.height / 2);
    _radius = _dScaView.frame.size.width / 2 - 90*_widthFactor/2;
    
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
                shapeLayer.lineWidth = 20*_widthFactor;
            }
            else
            {
                shapeLayer.baseColor = UIColor.lightGrayColor;
                shapeLayer.strokeColor = shapeLayer.baseColor.CGColor;
                shapeLayer.lineWidth = 20*_widthFactor;
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
            label.center = point;
            label.textColor = UIColor.whiteColor;
            label.font = [UIFont systemFontOfSize: 12];
            label.textAlignment = NSTextAlignmentCenter;
            if (i)
            {
                label.text = tickText;
                label.backgroundColor = UIColor.blackColor;
            }
            else
            {
                //label.font = [UIFont boldSystemFontOfSize: 26];
                //label.text = @"^";
                //label.textColor = UIColor.redColor;
                label.backgroundColor = UIColor.blackColor;
                [self DrawRedTriangleView:label];
            }
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
-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations
{
    static bool first = true;
    for (CLLocation * loc in locations)
    {
        _currentPoint.lat = loc.coordinate.latitude;
        _currentPoint.lon = loc.coordinate.longitude;
        if (first)
            [self getWeatherData];
        first = false;

    }
    [self removeUserWaypoints];
    [self addUserWaypoints:_currentPoint];
}
- (void)locationManager:(CLLocationManager *)manager
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

-(Bool) locationManagerShouldDisplayHeadingCalibration:(CLLocationManager*)manager
{
    return true;
}

-(void) locationManager:(CLLocationManager*) manager
       didFailWithError:(NSError*) error
{
    NSLog(@"Location manager error");
}

-(void) locationManager:(CLLocationManager*)manager
 didChangeAuthorization:(CLAuthorizationStatus)status
{
    NSLog(@"Location manager changed autorization");
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
    LLPOINT p1,p2;
    p1 = currentPoint;
    p2 = currentPoint;
    p2.lon -= 1;
    double az = HeadingFromAZ(AZMLatLon (p1,p2));
    az = HeadingFromAZ(AZMLatLon (p2,p1));
    _userWaypointLabels = NSMutableArray.new;
    int userWaypointIndex = _backgroundView.subviews.count;
    for (UserWaypoint* waypoint in _userWaypointArray)
    {
        if (waypoint.displayOnCompass)
        {
            double dist = ArcDistanceLL(waypoint.latlon, currentPoint);
            if ((dist < _maxWaypointDist && ![waypoint.type isEqual:@"RoutePoint"]) || waypoint.refno == CRAPI.sharedInstance.currentSelectedWaypoint)
            {
                double az = AZMLatLon (currentPoint,waypoint.latlon);
                double azd = RadiansToDegrees (az);
                double az2 = HeadingFromAZ (az);
                double az2d = RadiansToDegrees (az2);
                double maxScale = 1.0-.2*_widthFactor;
                double scale = maxScale;
                NSString *  tickText = waypoint.name;
                
                CGFloat textAngle = az;
                
                if (dist < _closeDistance)
                {
                    scale = maxScale * (dist/_closeDistance);
                }
                CGPoint point  = [self calculateTextPositonWithArcCenter: _po andAngle: textAngle andScale: scale];
                
                // UILabel
                UILabel* label = UILabel.new;
                CGFloat factor = 1;
                CGFloat fontSize = 12;
                label.text = tickText;
                label.font = [UIFont systemFontOfSize: fontSize];
                label.textAlignment = NSTextAlignmentCenter;
                if ([waypoint.type isEqual:@"Vehicle"])
                {
                    factor = 1.2;
                    fontSize = 24;
                    label.backgroundColor = UIColor.greenColor;
                    label.textColor = UIColor.blackColor;
                    label.font = [UIFont boldSystemFontOfSize: fontSize * factor];
                }
                else if ([waypoint.type isEqual:@"CompassPoint"])
                {
                    factor = 1.2;
                    fontSize = 12;
                    label.backgroundColor = UIColor.blueColor;
                    label.textColor = UIColor.whiteColor;
                    label.font = [UIFont boldSystemFontOfSize: fontSize * factor];
                }
                else
                {
                    label.backgroundColor = UIColor.lightGrayColor;
                    label.textColor = UIColor.blackColor;
                }
                if (waypoint.refno == CRAPI.sharedInstance.currentSelectedWaypoint)
                {
                    label.backgroundColor = UIColor.redColor;
                    label.textColor = UIColor.whiteColor;
                    factor = 1.2;
                    label.font = [UIFont boldSystemFontOfSize: fontSize * factor];
                }
                label.frame = CGRectMake(point.x,point.y, factor*30*_widthFactor,factor*30*_widthFactor);
                label.center = point;
                label.clipsToBounds = true;
                label.layer.cornerRadius = label.frame.size.width / 2;
                
                [_backgroundView addSubview:label];
                [_userWaypointLabels addObject:label];
            }
        }
    }
    //add sun
    time_t iTime = NSDate.date.timeIntervalSince1970;
    CGFloat sunAlt;
    if (_displayTime != 0)
        iTime = _displayTime;
    CGFloat sunAz = [self getAzOfSun:iTime
                         altitude:&sunAlt];
    UILabel* label = UILabel.new;
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
    CGPoint point  = [self calculateTextPositonWithArcCenter: _po andAngle: sunAz andScale: 1.24];
    label.textAlignment = NSTextAlignmentCenter;
    int fontSize = 20;
    label.text = [NSString stringWithFormat:@"%i",degreesAboveHorizon];
    label.backgroundColor = sunColor;
    label.textColor = UIColor.blackColor;
    label.font = [UIFont boldSystemFontOfSize: fontSize * factor];
    label.frame = CGRectMake(point.x,point.y, factor*28*_widthFactor,factor*28*_widthFactor);
    label.center = point;
    label.clipsToBounds = true;
    label.layer.cornerRadius = label.frame.size.width / 2;
    
    [_backgroundView addSubview:label];
    [_userWaypointLabels addObject:label];
//add wind
    if (_currentWindSpeed > -1)
    {
        CGFloat windSpeed =  _currentWindSpeed;
        CGFloat factor = 1.8;
        CGFloat windDir = DegreesToRadians (_currentWindDirection);
        windDir = LTWOPI (windDir - HALFPI);
        CGPoint point  = [self calculateTextPositonWithArcCenter: _po andAngle: windDir andScale: 1.22];
        UIImageView *wind = [[UIImageView alloc] initWithFrame:CGRectMake(point.x,point.y, factor*30*_widthFactor,factor*20*_widthFactor)];
        UILabel *windLabel = [[UILabel alloc] initWithFrame:CGRectMake(point.x,point.y, factor*30*_widthFactor,factor*20*_widthFactor)];
        wind.backgroundColor = UIColor.clearColor;
        windLabel.backgroundColor = UIColor.clearColor;
        UIColor *blue = [[UIColor alloc] initWithRed:0.0
                                               green:0
                                                blue:1
                                               alpha:1];
        
        UIImage *img = [SymbolDictionary imageOfArrow:wind.frame
                                            lineWidth:2
                                            lineColor:UIColor.whiteColor
                                            fillColor:blue
                                             withText:nil];
        wind.image = img;//[UIImage imageWithContentsOfFile:                      [NSBundle.mainBundle pathForResource:@"windArrow"                                                    ofType:@"png"]];
        
        //wind.frame = CGRectMake(point.x,point.y, factor*30*_widthFactor,factor*30*_widthFactor);
        wind.center = point;
        wind.clipsToBounds = true;
        windLabel.text = [NSString stringWithFormat:@"%i",_currentWindSpeed];
        windLabel.textColor = UIColor.whiteColor;
        windLabel.textAlignment = NSTextAlignmentCenter;
        windLabel.center = point;
        //wind.layer.cornerRadius = wind.frame.size.width / 2;
        wind.transform = CGAffineTransformMakeRotation( windDir-HALFPI);
        windLabel.transform = CGAffineTransformMakeRotation( windDir-HALFPI);
        if (_currentWindSpeed == 0)
        {
            [wind setHidden:YES];
            [windLabel setHidden:YES];
        }
        [_userWaypointLabels addObject:wind];
        idebug = _backgroundView.subviews.count;
        iii = _userWaypointLabels.count;
        [_backgroundView addSubview:wind];
        [_backgroundView addSubview:windLabel];
        [_userWaypointLabels addObject:windLabel];
    }
    [self resetDirection:_lastResetHeading];
 
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
        if (CRAPI.sharedInstance.currentSelectedWaypoint > 0)
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

        if (setRed)
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
    
    [self offCourseNotification:0
                      withDelay:0];
    _lastToDist = 0;
    switch (_infoLabelOption)
    {
        case 2: //make current pt focus
            _ignoreAtWaypoint = -1;
            _forward = TRUE;
            _lastToDist = 0;
            if (CRAPI.sharedInstance.currentSelectedWaypoint > 0)
                CRAPI.sharedInstance.currentSelectedWaypoint = -1;
            else
                CRAPI.sharedInstance.currentSelectedWaypoint = CRAPI.sharedInstance.currentFocusWaypoint;
            break;
        case 1: //make next route point focus
        {
            if (_currentRoutePointNumber > 0)
            {
                [hd deleteWaypointWithRefno:_currentRoutePointNumber];
                NSArray <UserWaypoint*> *routePointArray = [hd getWaypointsOfType:@"RoutePoint"];
                if (routePointArray.count > 0)
                {
                    CRAPI.sharedInstance.currentSelectedWaypoint = routePointArray[0].refno;
                    _currentRoutePointNumber = routePointArray[0].refno;
                }
                else
                {
                    CRAPI.sharedInstance.currentSelectedWaypoint = -1;
                    _currentRoutePointNumber = 0;
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
            NVPopoverTableView *nvptv = [NVPopoverTableView showPopoverTableViewInView:self.view
                                                                              delegate:self
                                                                                 title:@"Compass Point Options"
                                                                             textArray:optionList
                                                                         includeCancel:YES];
            nvptv.allowsSubtitle = NO;
             
            
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
        _selectDateLabel.text = [NSString stringWithFormat:@"Current Time\n%@",date];
    }

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
        HuntingData *hd = HuntingData.new;
        if ([text isEqualToString:@"Start Route"])
        {
            NSArray <UserWaypoint*> *routePointArray = [hd getWaypointsOfType:@"RoutePoint"];
            UserWaypoint* waypoint = routePointArray[0];
            CRAPI.sharedInstance.currentSelectedWaypoint = waypoint.refno;
        }
        if ([text isEqualToString:@"Get Weather Data"])
        {
            [self getWeatherData];
            //NSString * weather = [CRAPI.sharedInstance getWeatherDataAtLatlon:_currentPoint];
            iii = 1;
        }
        else if ([text isEqualToString:@"Set Profile Exageration to 1"])
            _heightExpansion = 1;
        else if ([text isEqualToString:@"Set Profile Exageration to 2"])
            _heightExpansion = 2;
        else if ([text isEqualToString:@"Set Profile Exageration to 4"])
            _heightExpansion = 4;
    }
    [popoverTableView hide:YES];
    [_singleFingerTap setEnabled:YES];

}
- (void) getForcastWeatherData
{
    [_singleFingerTap setEnabled:NO];

    [_wd getWeatherforecast:_currentPoint
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
    NVPopoverTableView *nvptv =
    [NVPopoverTableView showPopoverTableViewInView:self.view
                                          delegate:self
                                             title:@"Select a Date and Time"
                                         textArray:_forecastDates
                                     includeCancel:YES];
    nvptv.identifier = @"forecast";
    nvptv.parseTextToButtons = NO;
    
}

-(void) getWeatherData
{
    [_wd getCurrentWeather:_currentPoint delegate:self];
}
- (void)weatherDataDidReturnData:(WeatherRecord*)data
{
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
    if (abs (setDiff) > abs (riseDiff))
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
    DPOINT pt = LLPointToDPoint(_currentPoint);
    GetAltitudeAndAzOfSun (pt,0,iTime,&Altitude,&Az);
    *pAlt = Altitude;
    rtn = DegreesToRadians (Az-90);
    return rtn;
}
-(void) popoverTableViewDidCancel:(NVPopoverTableView *)popoverTableView
{
    [popoverTableView hide:YES];
    [_singleFingerTap setEnabled:YES];

}

-(void) profileViewPicked:(CGPoint)atPoint
{
    return;
    DTMData * dtm = DTMData.new;
    BOOL opened = [dtm open];
    LLPOINT llPoint;
    static int opt = 0;
    
    double elv = [dtm getElevation:&llPoint];
    [dtm close:opened];
    //[self offCourseNotification:opt++];
    if (opt > 2)
        opt = 0;
    return;
}
-(void) update
{
    UIDevice * device = UIDevice.currentDevice;
    CGFloat magneticHeading = [self heading:_nowHeading.magneticHeading fromOrirntation: device.orientation];
    
    CGFloat trueHeading = [self heading:_nowHeading.trueHeading fromOrirntation: device.orientation];
    
    CGFloat headi = -1.0 * M_PI * _nowHeading.magneticHeading / 180.0;
    //_infoLabel.text = @"\(Int(magneticHeading))";
    [self resetDirection:headi];
    _lastResetHeading = headi;

    CLLocationDirection theHeading = _nowHeading.magneticHeading > 0 ? _nowHeading.magneticHeading : _nowHeading.trueHeading;
    theHeading = _nowHeading.trueHeading;
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
    
    _infoLabel.text = [NSString stringWithFormat:@"%i %@",angle,directionLabelText];
    _infoLabelOption = 0;
    CRAPI.sharedInstance.currentFocusWaypoint = -1;
    [self removeProfileLayers];
    for (UserWaypoint* waypoint in _userWaypointArray)
    {
        if (waypoint.displayOnCompass && waypoint.refno != _ignoreAtWaypoint)
        {
            if (![waypoint.type isEqual:@"RoutePoint"] || waypoint.refno == CRAPI.sharedInstance.currentSelectedWaypoint)
            {
                double dist = ArcDistanceLL(waypoint.latlon, _currentPoint);
                double wpaz = HeadingFromAZ(AZMLatLon (_currentPoint,waypoint.latlon));
                waypoint.headingInDeg = RadiansToDegrees (wpaz);
                double curAz = DegreesToRadians(theHeading);
                if (dist / METERS_PER_YARD < _atDistance)
                {
                    _infoLabel.text = [NSString stringWithFormat:@"At %@: (%.0f yards)",waypoint.name,dist/ METERS_PER_YARD];
                    _infoLabel.textColor = UIColor.whiteColor;
                    if ([waypoint.type isEqual:@"RoutePoint"])
                        _currentRoutePointNumber = waypoint.refno;
                    else
                        _currentRoutePointNumber = 0;
                    CRAPI.sharedInstance.currentFocusWaypoint = waypoint.refno;
                    _infoLabelOption = 1;
                    break;
                }
                else
                {
                    double daz = DeltaAZD(wpaz, curAz);
                    if ((CRAPI.sharedInstance.currentSelectedWaypoint <= 0 && fabs (daz) < 0.2) || waypoint.refno == CRAPI.sharedInstance.currentSelectedWaypoint)
                    {
                        _maxElev= _maxGrade = 0;
                        NSString *units = @"miles";
                        CRAPI.sharedInstance.currentFocusWaypoint = waypoint.refno;
                        if (CRAPI.sharedInstance.currentSelectedWaypoint > 0)
                            [self displayProfile:_currentPoint
                                          to:waypoint.latlon
                                 checkOffset:waypoint.refno == CRAPI.sharedInstance.currentSelectedWaypoint];
                        else
                            [self displayProfile:_currentPoint
                                          to:waypoint.latlon
                                 checkOffset:NO];
                        if (dist / METERS_PER_YARD < _nearDist)
                        {
                            units = @"yards";
                            dist = dist / METERS_PER_YARD;
                            _infoLabel.text = [NSString stringWithFormat:@"Near %@: %.0f %@",waypoint.name,dist,units];
                        }
                        else
                        {
                            dist = dist / METERS_PER_MILE;
                            int offDist = IDNINT(_offDist / METERS_PER_YARD);
                            NSString *offsetText = @"";
                            NSString *offDir = @"L";
                            if (offDist > 0)
                            {
                                if (_leftOrRight == RIGHT)
                                    offDir = @"R";
                                offsetText = [NSString stringWithFormat:@"(%i YARDS %@)",offDist,offDir];
                            }
                            _infoLabel.text = [NSString stringWithFormat:@"%@: %.2f %@%@\nMin Elev:%i MaxElev:%i\nMax Grade:%.2f",waypoint.name,dist,units,offsetText,IDNINT(_minElev),IDNINT(_maxElev),_maxGrade];
                        }
                        if (_offCourseTimer)
                            _infoLabel.textColor = UIColor.orangeColor;
                        else
                            _infoLabel.textColor = UIColor.whiteColor;

                        _infoLabelOption = 2;
                        break;
                    }
                }
            }
        }
        
    }
    [self setDateAndTimeLabel];

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
-(void) displayProfile:(LLPOINT)atLL
                    to:(LLPOINT)toLL
           checkOffset:(BOOL) checkOff
{
    static LLPOINT fromLL = {0};
    static LLPOINT lastToLL = {0};
    CGRect frame = _profileView.frame;
    CAShapeLayer *profileLayer;
    NSArray <UIColor*>* gradeColors = @[UIColor.blueColor,UIColor.greenColor,UIColor.orangeColor,UIColor.redColor];

    [self removeProfileLayers];
    _profileLayers = NSMutableArray.new;
    
    if (fromLL.lat == 0 || ArcDistanceLL(toLL,lastToLL) > 1)
    {
        lastToLL = toLL;
        fromLL = atLL;
        [self showAsRouteOnMap:fromLL
                          toLL:toLL];
    }
    _fromUTM.x = fromLL.lon;
    _fromUTM.y = fromLL.lat;
    _toUTM.x = toLL.lon;
    _toUTM.y = toLL.lat;
    _atUTM.x = atLL.lon;
    _atUTM.y = atLL.lat;
    int nPixels = frame.size.width;
    ConvertCoord(&_fromUTM, LATLONPROJECTION, UTM15PROJECTION);
    ConvertCoord(&_toUTM, LATLONPROJECTION, UTM15PROJECTION);
    ConvertCoord(&_atUTM, LATLONPROJECTION, UTM15PROJECTION);
    double distToDest = ldistp(_atUTM, _toUTM)/ METERS_PER_YARD;
    if (distToDest < _atDistance)
    {
        [self offCourseNotification:0
                          withDelay:0];
    }
    else if (checkOff && [self checkIfOffRoute:_atUTM])
    {
        
    }

    double groundDist = ldistp(_fromUTM, _atUTM) + ldistp (_atUTM,_toUTM);
    double atDist = ldistp(_fromUTM, _atUTM);
    int toDist = IDNINT(ldistp(_atUTM, _toUTM)/4);
    if (_lastToDist && toDist > _lastToDist)
        _forward = FALSE;
    if (_lastToDist && toDist < _lastToDist)
        _forward = TRUE;
    if (_lastToDist != toDist)
        _lastToDist = toDist;
    double xPct = atDist/groundDist;
    double feetPerPixel = groundDist / nPixels;
    int nFromPixels = nPixels * (atDist / groundDist);
    int nToPixels = nPixels * ((groundDist - atDist) / groundDist);
    LPDPOINT pt = malloc ((nPixels+1) * sizeof (DPOINT) + 8);
    int npt = 0;
    pt[npt++] = _fromUTM;
    double xInc = (_atUTM.x - _fromUTM.x)/nFromPixels;
    double yInc = (_atUTM.y - _fromUTM.y)/nFromPixels;
    for (int i = 1; i < nFromPixels; i++)
    {
        pt[npt] = pt[npt-1];
        pt[npt].x += xInc;
        pt[npt++].y += yInc;
    }

    pt[npt++] = _atUTM;
    xInc = (_toUTM.x - _atUTM.x)/nToPixels;
    yInc = (_toUTM.y - _atUTM.y)/nToPixels;
    for (int i = 1; i < nToPixels; i++)
    {
        pt[npt] = pt[npt-1];
        pt[npt].x += xInc;
        pt[npt++].y += yInc;
    }
    nPixels = npt;
    DTMData * dtm = DTMData.new;
    BOOL opened = [dtm open];

    LPDOUBLE pElev = malloc (nPixels * sizeof(double) + 4);
    LPDOUBLE pGrade = malloc (nPixels * sizeof(double) + 4);
    CGPoint * pPoint = malloc (nPixels * sizeof(CGPoint) + 4);
    _minElev = DBL_MAX;
    _maxElev = DBL_MIN;
    _maxGrade = 0;
    double grade;
    
    for (int i=0;i<nPixels;i++)
    {
        pElev[i] = [dtm getElevation:&pt[i]];
        _minElev = MIN (_minElev,pElev[i]);
        _maxElev = MAX (_maxElev,pElev[i]);
        pPoint[i].x = i;
        if (i)
        {
            grade = fabs((pElev[i]-pElev[i-1])/feetPerPixel);
            pGrade[i-1] = grade;
            _maxGrade = max (_maxGrade,pGrade[i-1]);
        }
    }
    double profileImageHeight = _profileView.frame.size.height - _infoLabel.frame.size.height;
    double profileImageWidth = _profileView.frame.size.width;
    double profileImageTop = _profileView.frame.origin.y + _infoLabel.frame.size.height;
    double atLoc = profileImageWidth * xPct;
    double factor = _heightExpansion * nPixels / (groundDist);
    double centerY = profileImageHeight/2 - (_maxElev - _minElev) / 2 * factor;
    double atY = profileImageWidth;
    for (int i=0;i<nPixels;i++)
    {
        pPoint[i].y = profileImageHeight + centerY + (_maxElev - pElev[i]) * factor;
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
        int gradeLevel = GetGradeLevel (pGrade[i]);
        if (gradeLevel != lastLevel)
        {
            if (lastLevel != -1)
            {
                [profilePath addLineToPoint:pPoint[i]];
                profileLayer.path = profilePath.CGPath;
                [_profileView.layer addSublayer:profileLayer];
                [_profileLayers addObject:profileLayer];
            }
            profileLayer = CAShapeLayer.layer;
            profilePath = UIBezierPath.new;
            profileLayer.fillColor = UIColor.clearColor.CGColor;
            profileLayer.lineWidth = lineWidth;
            profileLayer.strokeColor = gradeColors[gradeLevel].CGColor;
            [profilePath moveToPoint:pPoint[i]];
            nlines = 0;
        }
        else
        {
            [profilePath addLineToPoint:pPoint[i]];
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
    free (pElev);
    free (pGrade);
    free (pt);
    [dtm close:opened];
    
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
    return;
}
int GetGradeLevel (double grade)
{
    int rtn = 0;
    if (grade > 0.1)
        rtn = 1;
    if (grade > 0.15)
        rtn = 2;
    if (grade > 0.2)
        rtn = 3;
    return rtn;
}
-(void) offCourseNotification:(int) opt
                    withDelay:(CGFloat) delay
{
    static int currentTimerOpt = 0;
    int intDelay = max (IDNINT (delay/_minTimerDelay) * _minTimerDelay,_minTimerDelay);
    
    if (opt == currentTimerOpt && intDelay == _currentTimerDelay)
        return;
    _goLeft = FALSE;
    currentTimerOpt = opt;
    _currentTimerDelay = intDelay;
    if (_offCourseTimer)
        [_offCourseTimer invalidate];
    switch (opt)
    {
        default:
        case 0:
            _offCourseTimer = nil;
            break;
        case RIGHT: //go left
            _goLeft = TRUE;
        case LEFT: //go right
            if (!_offCourseTimer)
                _offCourseTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(offCourseNotificationPlay:) userInfo:nil repeats:NO];
            _offCourseTimer = [NSTimer scheduledTimerWithTimeInterval:_currentTimerDelay target:self selector:@selector(offCourseNotificationPlay:) userInfo:nil repeats:YES];
            break;
    }
    return;

}
-(void) offCourseNotificationPlay:(NSTimer *) timer
{
    if (_goLeft)
    {
        NSString *soundFile = [NSString stringWithUTF8String:"///System/Library/Audio/UISounds/short_double_low.caf"];
        SystemSoundID soundID;
        NSURL *url = [NSURL URLWithString:soundFile];
        AudioServicesCreateSystemSoundID((__bridge CFURLRef _Nonnull)(url), &soundID);
        AudioServicesPlaySystemSound(soundID);
        [self performSelector:@selector(vibrate)
                   withObject:nil
                   afterDelay:0.5];
        [self performSelector:@selector(vibrate)
                   withObject:nil
                   afterDelay:2];
        [self performSelector:@selector(vibrate)
                   withObject:nil
                   afterDelay:3];
    }
    else
    {
        NSString *soundFile = [NSString stringWithUTF8String:"///System/Library/Audio/UISounds/short_double_high.caf"];
        SystemSoundID soundID;
        NSURL *url = [NSURL URLWithString:soundFile];
        AudioServicesCreateSystemSoundID((__bridge CFURLRef _Nonnull)(url), &soundID);
        AudioServicesPlaySystemSound(soundID);
        [self performSelector:@selector(vibrate)
                   withObject:nil
                   afterDelay:0.5];
        [self performSelector:@selector(vibrate)
                   withObject:nil
                   afterDelay:1.5];
        [self performSelector:@selector(vibrate)
                   withObject:nil
                   afterDelay:3];
    }
}
-(void) vibrate
{
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
}

-(BOOL) checkIfOffRouteTest:(LLPOINT) atLL
{
    DPOINT atUTM;
    _fromUTM = saveFromUTM;
    _toUTM = saveToUTM;
    atUTM.x = atLL.lon;
    atUTM.y = atLL.lat;
    ConvertCoord(&atUTM, LATLONPROJECTION, UTM15PROJECTION);
    [self checkIfOffRoute:atUTM];
}
-(BOOL) checkIfOffRoute:(DPOINT) currentPoint
{
    BOOL offRoute = FALSE;
    DPOINT Line[2];
    DPOINT IntPoint;
    saveFromUTM = _fromUTM;
    saveToUTM = _toUTM;
    
    Line[0] = _fromUTM;
    Line[1] = _toUTM;
    if (GetPerpendicularIntersect (&currentPoint,Line,&IntPoint,TRUE,&_leftOrRight))
    {
        _offDist = ldistpp (&currentPoint,&IntPoint);
        _offDist /= METERS_PER_YARD;
        if (_offDist > _notifyDist)
        {
            _timerDelay = max (_minTimerDelay,(_notifyDist/_offDist) * _maxTimerDelay);
            [self offCourseNotification:_leftOrRight
                              withDelay:_timerDelay];
        }
        else
        /*{
            static double d = 5;
            _timerDelay = max (_minTimerDelay,(_notifyDist/d) * _maxTimerDelay);
            d += 2;
            [self offCourseNotification:_leftOrRight
                              withDelay:_timerDelay];

        }*/
            [self offCourseNotification:0
                              withDelay:0];
    }
    else
    {
        _offDist = 0;
        [self offCourseNotification:0
                          withDelay:0];
    }
    return offRoute;
}
- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

-(void) showAsRouteOnMap:(LLPOINT)fromLL
                    toLL:(LLPOINT)toLL
{
    CRAPI.sharedInstance.currentRoute = NSMutableArray.new;
    CGPoint llp = {0};
    llp.y = fromLL.lat;
    llp.x = fromLL.lon;
    NSNumber *routePoint = [NSNumber valueWithCGPoint:llp];
    [CRAPI.sharedInstance.currentRoute addObject:routePoint];
    llp.y = toLL.lat;
    llp.x = toLL.lon;
    routePoint = [NSNumber valueWithCGPoint:llp];
    [CRAPI.sharedInstance.currentRoute addObject:routePoint];
    return;
}
@end
