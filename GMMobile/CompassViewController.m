//
//  CompassViewController.m
//  NVMobile
//
//  Created by Jeff Smith on 10/21/22.
//  Copyright © 2022 GSSi. All rights reserved.
//

#import "CompassViewController.h"
#import "DTMData.h"

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
@property int infoLabelOption;
@property int currentRoutePointNumber;
@property float atDistance;
@property float closeDistance;
@property int statusBarHeight;
@property UIButton *optionsButton;
@property UILabel *weatherLabel;
@property UIButton *weatherButton;
@property WeatherData * wd;
@property int currentWindSpeed;
@property int currentTemp;
@property float currentWindDirection;
@property NSString *currentWeatherDesc;
@property int skipRot;

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
    _atDistance = 15;
    _closeDistance = 100;
    _skipRot = 0;

    [self configUI];
        
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
    _locationManager.headingFilter = kCLHeadingFilterNone;
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
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [_locationManager stopUpdatingHeading];
    [_locationManager stopUpdatingLocation];
    _locationManager.delegate = _oldLocationManagerDelegate;
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
    int top = UIApplication.sharedApplication.windows[0].safeAreaInsets.top;
    int left = UIApplication.sharedApplication.windows[0].safeAreaInsets.left;
    int right = self.view.frame.size.width - UIApplication.sharedApplication.windows[0].safeAreaInsets.right;
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
    _profileView.frame =CGRectMake(0, 380*_heightFactor, _screenW,130*_heightFactor);
    _profileView.backgroundColor = UIColor.whiteColor;
    _infoLabel = UILabel.new;
    _infoLabel.frame = CGRectMake (0,0,_profileView.frame.size.width,_profileView.frame.size.height/2);
    _infoLabel.backgroundColor = UIColor.blackColor;
    _infoLabel.textColor = UIColor.whiteColor;
    _infoLabel.font =[UIFont systemFontOfSize: 42];
    _infoLabel.textAlignment = NSTextAlignmentCenter;
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
    _weatherLabel.backgroundColor = UIColor.clearColor;
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

    [self.view addSubview:_dScaView];
    [self.view addSubview:_profileView];
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
        if (i++ && i < n-_skipRot)
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
    int iTime = NSDate.timeIntervalSinceReferenceDate;
    CGFloat sunAlt;
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
    if ( _currentWindSpeed > 0)
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
        [_userWaypointLabels addObject:wind];
        [_backgroundView addSubview:wind];
        [_backgroundView addSubview:windLabel];
        [_userWaypointLabels addObject:windLabel];
        _skipRot = 1;
    }

 
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
    
    switch (_infoLabelOption)
    {
        case 2: //make current pt focus
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
- (void)popoverTableView:(NVPopoverTableView *)popoverTableView
    didSelectRowWithText:(NSString *)text
                 atIndex:(NSInteger)index
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
        ii = 1;
    }
    [popoverTableView hide:YES];
    [_singleFingerTap setEnabled:YES];

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
    [NSOperationQueue.mainQueue addOperationWithBlock:^{
        _weatherLabel.text = [NSString stringWithFormat:@"Temp:%i deg\nWind:%i mph\n%@",_currentTemp,_currentWindSpeed,_currentWeatherDesc];
   }];

    //3.35,"deg":213,"gust":3.12}
   return;
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
    DTMData * dtm = DTMData.new;
    BOOL opened = [dtm open];
    LLPOINT llPoint;
    
    double elv = [dtm getElevation:&llPoint];
    [dtm close:opened];
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
    
    for (UserWaypoint* waypoint in _userWaypointArray)
    {
        if (waypoint.displayOnCompass)
        {
            if (![waypoint.type isEqual:@"RoutePoint"] || waypoint.refno == CRAPI.sharedInstance.currentSelectedWaypoint)
            {
                double dist = ArcDistanceLL(waypoint.latlon, _currentPoint);
                double wpaz = HeadingFromAZ(AZMLatLon (_currentPoint,waypoint.latlon));
                waypoint.headingInDeg = RadiansToDegrees (wpaz);
                double curAz = DegreesToRadians(theHeading);
                if (dist < _atDistance && [waypoint.type isEqual:@"RoutePoint"])
                {
                    _infoLabel.text = [NSString stringWithFormat:@"At %@: (%.0f meters)",waypoint.name,dist];
                    _infoLabel.textColor = UIColor.redColor;
                    if ([waypoint.type isEqual:@"RoutePoint"])
                        _currentRoutePointNumber = waypoint.refno;
                    else
                        _currentRoutePointNumber = 0;
                    _infoLabelOption = 1;
                    break;
                }
                else
                {
                    double daz = DeltaAZD(wpaz, curAz);
                    if (fabs (daz) < 0.2)
                    {
                        NSString *units = @"miles";
                        CRAPI.sharedInstance.currentFocusWaypoint = waypoint.refno;
                        if (dist / METERS_PER_MILE < 0.1)
                        {
                            units = @"yards";
                            dist = dist / METERS_PER_YARD;
                            _infoLabel.text = [NSString stringWithFormat:@"%@: %.0f %@",waypoint.name,dist,units];
                        }
                        else
                        {
                            dist = dist / METERS_PER_MILE;
                            _infoLabel.text = [NSString stringWithFormat:@"%@: %.2f %@",waypoint.name,dist,units];
                        }
                        _infoLabel.textColor = UIColor.whiteColor;
                       _infoLabelOption = 2;
                        
                    }
                }
            }
        }
        
    }
    
}


- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

@end
