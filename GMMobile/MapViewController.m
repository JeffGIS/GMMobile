//  MapViewController.m
//  GMMobile

#import "MapViewController.h"
#import "GSSiAnnotationView.h"
#import "WebKitViewController.h"

@interface MapViewController ()

//@property (nonatomic) GSSiTileOverlay *osmOverlay;
@property (nonatomic) GSSiTileOverlay *gmmOverlay;
@property (nonatomic) MKMapCamera *camera;
@property (nonatomic) UILongPressGestureRecognizer *longPress;
@property (nonatomic) CLLocationCoordinate2D target, selectedPIDCoords;
@property (nonatomic) BOOL clearAnnotations;
@property (nonatomic) NSArray *options;
@property (nonatomic) NSMutableArray *propertyReport;
@property (nonatomic) NSInteger tableViewSetting;
@property (nonatomic) CGFloat screenSize;
@property (nonatomic) UIColor *tableViewBackgroundColor;
@property (nonatomic) BOOL clearWhenDeselected, firstTime;
@property (nonatomic, copy) NSString *selectedPID;
@property (nonatomic, copy) NSString *selectedPlat;
@property int selectedPlatRefno;
@property (nonatomic) CGFloat currentScreenHeight, splitScreenBorderWidth, tabBarHeight;
@property (nonatomic) CGFloat heading, pitch, fov;
@property (nonatomic) MKMapView *mapView;
@property (nonatomic) VectorView *vectorView;
@property (nonatomic) UIImageView *secondImageView, *streetView;
@property (nonatomic) UIView *firstView;
@property (nonatomic) PlatView *platView;
@property (nonatomic) NSInteger screenSetting;
@property (nonatomic) GSSiAlertController *gssiAlert;
@property (nonatomic) MapToolbar *mapToolbar;

@end

@implementation MapViewController

@synthesize coordinate;
@synthesize boundingMapRect;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = UIColor.whiteColor;
    
    _gssiAlert = [[GSSiAlertController alloc] initWithViewController:self];
    _gssiAlert.delegate = self;
    
    _tableViewBackgroundColor = [UIColor colorWithRed:0.0
                                                green:0.0
                                                 blue:0.3
                                                alpha:1.0];
    
    _clearWhenDeselected = YES;
    _cityInnerBounds.origin.x = 64631097;
    _cityInnerBounds.origin.y = 96565088;
    _cityInnerBounds.size.width = 83010;
    _cityInnerBounds.size.height = 103220;
    _tabBarHeight = self.tabBarController.tabBar.frame.size.height;
    _firstTime = YES;
    
    _mapView = [[MKMapView alloc] init];
    _vectorView = [[VectorView alloc] init];
    
    CGFloat statusBarHeight = [self statusBarHeight:self.interfaceOrientation];
    CGFloat tabBarTop = self.tabBarController.tabBar.frame.origin.y;
    
    CGRect mapViewFrame = CGRectMake(0.0,
                                     statusBarHeight,
                                     self.view.frame.size.width,
                                     (tabBarTop - statusBarHeight));
    
    _vectorView.frame = _mapView.frame = mapViewFrame;
    _vectorView.userInteractionEnabled = NO;
    
    [self.view addSubview:_mapView];
    [self.view addSubview:_vectorView];
    
    _platView = [[PlatView alloc] init];
    _platView.delegate = self;
    _firstView = [[UIView alloc] init];
    _firstView.clipsToBounds = YES;
    
    _secondImageView = [[UIImageView alloc] init];
    _streetView = [[UIImageView alloc] init];
    _streetView.hidden = YES;
    _streetView.userInteractionEnabled = YES;
    
    UISwipeGestureRecognizer *upSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self
                                                                                  action:@selector(svUpSwiped:)];
    
    upSwipe.direction = UISwipeGestureRecognizerDirectionUp;
    upSwipe.delegate = self;
    [_streetView addGestureRecognizer:upSwipe];
    
    UISwipeGestureRecognizer *downSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self
                                                                                    action:@selector(svDownSwiped:)];
    
    downSwipe.direction = UISwipeGestureRecognizerDirectionDown;
    downSwipe.delegate = self;
    [_streetView addGestureRecognizer:downSwipe];
    
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                 action:@selector(svDoubleTapped:)];
    
    doubleTap.numberOfTapsRequired = 2;
    doubleTap.delegate = self;
    [_streetView addGestureRecognizer:doubleTap];
    
    UITapGestureRecognizer *twoFingerTap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                   action:@selector(svTwoFingerTapped:)];
    
    twoFingerTap.numberOfTouchesRequired = 2;
    twoFingerTap.delegate = self;
    [_streetView addGestureRecognizer:twoFingerTap];
    
    _firstView.frame = _secondImageView.frame = CGRectMake(0.0,
                                                           tabBarTop,
                                                           self.view.frame.size.width,
                                                           0.0);
    
    _secondImageView.backgroundColor = [UIColor colorWithRed:0.7
                                                       green:1.0
                                                        blue:0.7
                                                       alpha:1.0];
    
    _splitScreenBorderWidth = 2.0;
    
    _firstView.layer.borderColor = _secondImageView.layer.borderColor =
    _mapView.layer.borderColor = UIColor.darkGrayColor.CGColor;
    
    _firstView.layer.borderWidth = _secondImageView.layer.borderWidth = _splitScreenBorderWidth;
    
    [self.view addSubview:_firstView];
    [self.view addSubview:_secondImageView];
    [self.view addSubview:_streetView];
    
    _mapView.delegate = self;
    _mapView.showsUserLocation = YES;
    _mapView.mapType = MKMapTypeStandard;
    _target = CLLocationCoordinate2DMake(44.97, -93.27);
/*
    NSString *osm = @"http://tile.openstreetmap.org/{z}/{x}/{y}.png";
    _osmOverlay = [[GSSiTileOverlay alloc] initWithURLTemplate:osm];
    _osmOverlay.canReplaceMapContent = NO;
    _osmOverlay.minimumZ = 0;
    _osmOverlay.maximumZ = 19;
    _osmOverlay.type = @"OSM";
    
    if (CRAPI.sharedInstance.basemap == BasemapSettingOSM)
    {
        [_mapView addOverlay:_osmOverlay
                       level:MKOverlayLevelAboveLabels];
    }
*/
    NSString *gmm = @"http://www.gssidata.com/MPLS/{z}/{y}/{x}.png";
    //NSString *gmm = @"http://74.42.137.128/icons/MPLS/{z}/{y}/{x}.png";
    _gmmOverlay = [[GSSiTileOverlay alloc] initWithURLTemplate:gmm];
    _gmmOverlay.canReplaceMapContent = NO;
    _gmmOverlay.minimumZ = 12;
    _gmmOverlay.maximumZ = 21;
    _gmmOverlay.type = @"GMM";
    
    if (CRAPI.sharedInstance.GMTilesVisible)
    {
        [_mapView addOverlay:_gmmOverlay
                       level:MKOverlayLevelAboveLabels];
    }
    
    _longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                               action:@selector(didLongPressMap:)];
    _longPress.delegate = self;
    _longPress.minimumPressDuration = 0.25;
    [_mapView addGestureRecognizer:_longPress];
    
    [self extentZoom:NO];
    [self.view bringSubviewToFront:_vectorView];
    
    [self setupTableView];
    
    _mapToolbar = [[MapToolbar alloc] initWithView:self.view];
    _mapToolbar.delegate = self;
    [self.view addSubview:_mapToolbar];
}

- (MKCoordinateRegion)getRegionForPoint:(LLPOINT)pidCoord
                                 atZoom:(int)zoom
                                 inRect:(CGRect)rect
{
    MKCoordinateRegion region;
    int px,py;
    
    region.center.latitude = pidCoord.lat;
    region.center.longitude = pidCoord.lon;
    CGFloat lat,lon;
    CGFloat lat1, lon1, lat2, lon2;
    
    LatLongToPixelXY(pidCoord.lat, pidCoord.lon, zoom, &px,&py);
    PixelXYToLatLong(px+rect.size.width, py, zoom, &lat, &lon);
    region.span.longitudeDelta = lon - pidCoord.lon;
    PixelXYToLatLong(px, (py - rect.size.height / 2.0), zoom, &lat1, &lon1);
    PixelXYToLatLong(px, (py + rect.size.height / 2.0), zoom, &lat2, &lon2);
    region.span.latitudeDelta = (lat2 - lat1);
    return region;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (!_firstTime)
    {
        [self initTableView];
/*
        if (_osmOverlay)
        {
            [_mapView removeOverlay:_osmOverlay];
            
            if (!CRAPI.sharedInstance.GMTilesVisible)
            {
                _osmOverlay.maximumZ = 19;
                _osmOverlay.minimumZ = 0;
            }
            
            if (CRAPI.sharedInstance.basemap == BasemapSettingOSM)
            {
                [_mapView addOverlay:_osmOverlay
                               level:MKOverlayLevelAboveLabels];
            }
        }
*/
        if (_gmmOverlay)
        {
            [_mapView removeOverlay:_gmmOverlay];
            
            if (CRAPI.sharedInstance.GMTilesVisible)
            {
                [_mapView addOverlay:_gmmOverlay
                               level:MKOverlayLevelAboveLabels];
                
                _gmmOverlay.minimumZ = 12;
                _gmmOverlay.maximumZ = 21;
            }
        }
    }
    
    else
        _firstTime = NO;
    
    if (CRAPI.sharedInstance.GMMSetting == GMMSettingPID ||
        CRAPI.sharedInstance.GMMSetting == GMMSettingAddress ||
        CRAPI.sharedInstance.GMMSetting == GMMSettingPropOwner)
    {
        _tableView.hidden = YES;
        
        _selectedPID = CRAPI.sharedInstance.currentPID;
        PropertyData *propData = [[PropertyData alloc] init];
        LLPOINT pidPoint = [propData getPointForPID:_selectedPID];
        MNMXCORD bounds = [propData getBoundsForPID:_selectedPID];
        CLLocationCoordinate2D pidCoord;
        pidCoord.latitude = pidPoint.lat;
        pidCoord.longitude = pidPoint.lon;
        MKCoordinateRegion mapRegion;
        MKCoordinateRegion newRegion;
        
        CGRect rect = [_mapView convertRegion:_mapView.region
                                 toRectToView:nil];

        MKCoordinateSpan pidSpan = MKCoordinateSpanMake(fabs(bounds.ymx - bounds.ymn) * 1.5,
                                                        fabs(bounds.xmx - bounds.xmn) * 1.5);
        
        mapRegion = [self getRegionForPoint:pidPoint
                                     atZoom:21
                                     inRect:rect];
        
        if (mapRegion.span.longitudeDelta < pidSpan.longitudeDelta ||
            mapRegion.span.latitudeDelta < pidSpan.latitudeDelta)
        {
            newRegion = MKCoordinateRegionMake(pidCoord, pidSpan);
        }
        
        else
            newRegion = mapRegion;
        
        _camera = [MKMapCamera cameraLookingAtCenterCoordinate:pidCoord
                                             fromEyeCoordinate:pidCoord
                                                   eyeAltitude:(newRegion.span.latitudeDelta * 207360.0)];
        
        [_mapView setCamera:_camera
                   animated:YES];
        
        MKPointAnnotation *annotation = [[MKPointAnnotation alloc] init];
        annotation.coordinate = _selectedPIDCoords = pidCoord;
        
        switch (CRAPI.sharedInstance.GMMSetting)
        {
            case GMMSettingPID:
                annotation.title = _selectedPID;
                annotation.subtitle = [propData getOwnerNameForPID:_selectedPID];
                break;
                
            case GMMSettingAddress:
                annotation.title = _selectedPID;
                annotation.subtitle = CRAPI.sharedInstance.currentAddress;
                break;
                
            case GMMSettingPropOwner:
                annotation.title = _selectedPID;
                annotation.subtitle = CRAPI.sharedInstance.currentPropOwner;
                break;
        }

        [self addAnnotation:annotation];
        
        CRAPI.sharedInstance.GMMSetting = GMMSettingDefault;
    }
    
    else if (CRAPI.sharedInstance.GMMSetting == GMMSettingBoundaries)
    {
        [self extentZoom:YES];
        CRAPI.sharedInstance.GMMSetting = GMMSettingDefault;
    }
    
    else
    {
        [self refreshVectorView:_mapView.region
                         atZoom:_currentZoom];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    _currentScreenHeight = self.view.frame.size.height;
    [self clearVectorView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)extentZoom:(BOOL)animated
{
    MKCoordinateRegion region, newRegion;
    
    if (CRAPI.sharedInstance.currentOverallBoundaryRefno)
    {
        PropertyData *propData = [[PropertyData alloc] init];
        
        MNMXCORD bounds = [propData getBoundaryAreaBounds:
                           CRAPI.sharedInstance.currentOverallBoundaryRefno];
        
        region.center.latitude = (bounds.ymx + bounds.ymn) / 2.0;
        region.center.longitude = (bounds.xmx + bounds.xmn) / 2.0;
        region.span.latitudeDelta = (bounds.ymx - bounds.ymn);
        region.span.longitudeDelta = (bounds.xmx - bounds.xmn);
        
        [_mapView setRegion:region
                   animated:NO];
        
        newRegion = _mapView.region;
        
        CLLocationCoordinate2D boundsCoord = CLLocationCoordinate2DMake(((bounds.ymx + bounds.ymn) / 2.0),
                                                                        ((bounds.xmx + bounds.xmn) / 2.0));
        
        CGFloat latDelta = region.span.latitudeDelta * 1.05;

        _camera = [MKMapCamera cameraLookingAtCenterCoordinate:boundsCoord
                                             fromEyeCoordinate:boundsCoord
                                                   eyeAltitude:(latDelta * 207360.0)];
        
        [_mapView setCamera:_camera
                   animated:YES];
    }
    
    else
    {
        _camera = [MKMapCamera cameraLookingAtCenterCoordinate:_target
                                             fromEyeCoordinate:_target
                                                   eyeAltitude:36000.0];
        
        [_mapView setCamera:_camera
                   animated:animated];
    }
}

- (GSSiTileOverlayRenderer *)mapView:(MKMapView *)mapView
            rendererForOverlay:(id <GSSiOverlay>)overlay
{
    GSSiTileOverlayRenderer *renderer = [[GSSiTileOverlayRenderer alloc] initWithTileOverlay:overlay];
    return renderer;
}

- (void)mapView:(MKMapView *)mapView
regionWillChangeAnimated:(BOOL)animated
{
    [self clearVectorView];
}

- (void)mapView:(MKMapView *)mapView
regionDidChangeAnimated:(BOOL)animated
{
    //MKMapRect visRect = mapView.visibleMapRect;
    MKCoordinateRegion region = mapView.region;
    
    CGRect mrect = [mapView convertRegion:region
                             toRectToView:mapView.superview];
    
    CLLocationCoordinate2D latlon1 = [mapView convertPoint:mrect.origin
                                      toCoordinateFromView:mapView.superview];
    
    CGPoint lrpoint;
    lrpoint.x = (mrect.origin.x + mrect.size.width);
    lrpoint.y = (mrect.origin.y + mrect.size.height);
    
    CLLocationCoordinate2D latlon2 = [mapView convertPoint:lrpoint
                                      toCoordinateFromView:mapView.superview];
    
    DPOINT p1,p2;
    p1.x = latlon1.longitude;
    p1.y = latlon1.latitude;
    p2.x = latlon2.longitude;
    p2.y = latlon2.latitude;
    CGFloat d = ArcDistance(p1,p2);
    CGFloat currentScale = (d / LDIST(0, 0, mrect.size.width, mrect.size.height));
    //CGFloat wantScale = GroundResolution(latlon1.latitude, 19);
    _currentZoom = 0;
    
    while (GroundResolution(latlon1.latitude, _currentZoom) > currentScale)
        _currentZoom++;
    
    _camera = mapView.camera;
    //MKMapRect intRect = MKMapRectUnion(visRect, _cityInnerBounds);
    
    if (CRAPI.sharedInstance.GMTilesVisible)
    {
        /*if (MKMapRectEqualToRect(intRect, _cityInnerBounds))
            _osmOverlay.maximumZ = 12;
        
        else
            _osmOverlay.maximumZ = 19;*/
    }
    
    else
    {
        //_osmOverlay.maximumZ = 19;
        _gmmOverlay.minimumZ = _gmmOverlay.maximumZ = 0;
    }

    [self refreshVectorView:region
                     atZoom:_currentZoom];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

- (void)didLongPressMap:(UIGestureRecognizer *)gesture
{
    MKPointAnnotation *annotation = [[MKPointAnnotation alloc] init];
    
    if (gesture.state == UIGestureRecognizerStateBegan)
    {
        for (MKPointAnnotation *selAnnotation in _mapView.selectedAnnotations)
        {
            [_mapView deselectAnnotation:selAnnotation
                                animated:NO];
        }
        
        CGPoint pointPicked = [gesture locationInView:_mapView];
        
        CLLocationCoordinate2D coordPicked = [_mapView convertPoint:pointPicked
                                               toCoordinateFromView:_mapView];
        
        LLPOINT llp, llpSewer;
        llp.lat = coordPicked.latitude;
        llp.lon = coordPicked.longitude;
        llpSewer = llp;
        
        PropertyData *propData = [[PropertyData alloc] init];
        _selectedPID = [propData pickPID:&llp];
        SewerData *sewerData = [[SewerData alloc] init];
        _selectedPlatRefno = [sewerData pickSanPlat:&llpSewer];
        coordPicked.latitude = llp.lat;
        coordPicked.longitude = llp.lon;
        
        _clearWhenDeselected = NO;
        annotation.coordinate = _selectedPIDCoords = coordPicked;
        annotation.title = _selectedPID;
        annotation.subtitle = [propData getOwnerNameForPID:_selectedPID];
        [self addAnnotation:annotation];
    }
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView
            viewForAnnotation:(id <MKAnnotation>)annotation
{
    if ([annotation isKindOfClass:MKUserLocation.class])
        return nil;
    
    MKAnnotationView *annotationView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation
                                                                       reuseIdentifier:@"pin"];
    
    annotationView.canShowCallout = YES;
    
    CGFloat buttonSize = 40.0;
    UIButton *rightButton = [[UIButton alloc] initWithFrame:CGRectMake(0.0, 0.0, buttonSize, buttonSize)];
    UIButton *leftButton = [[UIButton alloc] initWithFrame:CGRectMake(0.0, 0.0, buttonSize, buttonSize)];
    
    [rightButton setImage:[UIImage imageWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"arrow"
                                                                                         ofType:@"png"]]
                 forState:UIControlStateNormal];
    
    [leftButton setImage:[UIImage imageWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"list"
                                                                                        ofType:@"png"]]
                forState:UIControlStateNormal];
    
    annotationView.rightCalloutAccessoryView = rightButton;
    annotationView.leftCalloutAccessoryView = leftButton;
    return annotationView;
}

- (void)mapView:(MKMapView *)mapView
 annotationView:(MKAnnotationView *)view
calloutAccessoryControlTapped:(UIControl *)control
{
    if (control == view.rightCalloutAccessoryView)
    {
        _tableViewSetting = PropertyTableViewSettingPropertyReport;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.allowsSelection = NO;
        _tableView.delaysContentTouches = YES;
        [_tableView reloadData];
        
        [_tableView scrollRectToVisible:CGRectMake(0.0, 0.0, 1.0, 1.0)
                               animated:NO];
    }
    
    else if (control == view.leftCalloutAccessoryView)
    {
        if ([self isHennepinCountyPID:view.annotation.title])
            _options = @[@"Property Report", @"Hennepin County Website", @"Rankings", @"Computed Values", @"Display Street View", @"Zoom to Census Area"];
        
        else
            _options = @[@"Property Report", @"Rankings", @"Computed Values", @"Display Street View", @"Zoom to Census Area"];
        
        _tableViewSetting = PropertyTableViewSettingOptions;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        _tableView.allowsSelection = YES;
        _tableView.delaysContentTouches = NO;
        [_tableView reloadData];
    }
    
    CGRect frame = _tableView.frame;
    _tableView.frame = CGRectMake(self.view.center.x, self.view.center.y, 0.0, 0.0);
    _tableView.hidden = NO;
    
    [UIView animateWithDuration:0.25
                     animations:^{
                         _tableView.frame = frame;
                     }];
}

- (void)mapView:(MKMapView *)mapView
didDeselectAnnotationView:(MKAnnotationView *)view
{
    if (_clearWhenDeselected == NO)
    {
        [_mapView selectAnnotation:view.annotation
                          animated:NO];
        
        _clearWhenDeselected = YES;
    }
}

- (void)mapView:(MKMapView *)mapView
didSelectAnnotationView:(MKAnnotationView *)view
{
    _selectedPID = view.annotation.title;
    PropertyData *propData = [[PropertyData alloc] init];
    
    _propertyReport = [propData getReport:PDSettingDefault
                                   forPID:_selectedPID];
}

- (void)addAnnotation:(id <MKAnnotation>)annotation
{
    if (_clearAnnotations)
    {
        for (id <MKAnnotation> annotation in _mapView.annotations)
        {
            if (![annotation isKindOfClass:MKUserLocation.class])
                [_mapView removeAnnotation:annotation];
        }
    }
    
    [_mapView addAnnotation:annotation];
    
    [_mapView selectAnnotation:annotation
                      animated:YES];
    
    PropertyData *propData = [[PropertyData alloc] init];
    
    _propertyReport = [propData getReport:PDSettingDefault
                                   forPID:_selectedPID];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    if (_tableView)
    {
        [_tableView reloadData];
    }
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
                                duration:(NSTimeInterval)duration
{
    CGFloat statusBarHeight = [self statusBarHeight:toInterfaceOrientation];
    
    CGRect frame1 = CGRectMake(0.0, statusBarHeight +
                               ((self.view.frame.size.width - _tabBarHeight - statusBarHeight) / 2.0),
                               (self.view.frame.size.height + _tabBarHeight),
                               ((self.view.frame.size.width - _tabBarHeight - statusBarHeight) / 2.0));
    
    CGRect frame2 = CGRectMake(0.0, statusBarHeight +
                               ((self.view.frame.size.width - _tabBarHeight - statusBarHeight) / 3.0),
                               (self.view.frame.size.height + _tabBarHeight),
                               ((self.view.frame.size.width - _tabBarHeight - statusBarHeight) / 3.0));
    
    CGRect frame3 = CGRectMake(0.0, statusBarHeight +
                               ((self.view.frame.size.width - _tabBarHeight - statusBarHeight) / 1.5),
                               ((self.view.frame.size.height + _tabBarHeight) / 2.0),
                               ((self.view.frame.size.width - _tabBarHeight - statusBarHeight) / 3.0));
    
    if (!_streetView.hidden)
    {
        [UIView animateWithDuration:duration
                         animations:^{
                             _streetView.frame =
                             CGRectMake((((self.view.frame.size.height + _tabBarHeight) - _screenSize) / 2.0),
                                        ((self.view.frame.size.width - _screenSize) / 2.0),
                                        _screenSize, _screenSize);
                         }];
    }
    
    switch (_screenSetting)
    {
        case MapViewScreenSettingFullscreen:
        {
            [UIView animateWithDuration:duration
                             animations:^{
                                 _mapView.layer.borderWidth = 0.0;
                                 
                                 _mapView.frame = _vectorView.frame =
                                 CGRectMake(0.0, statusBarHeight,
                                            (self.view.frame.size.height + _tabBarHeight),
                                            (self.view.frame.size.width - _tabBarHeight - statusBarHeight));
                             }];
        }
            break;
            
        case MapViewScreenSettingSplitScreen:
        {
            [UIView animateWithDuration:duration
                             animations:^{
                                 _mapView.layer.borderWidth = _splitScreenBorderWidth;
                                 
                                 _mapView.frame = _vectorView.frame =
                                 CGRectMake(0.0, statusBarHeight,
                                            (self.view.frame.size.height + _tabBarHeight),
                                            ((self.view.frame.size.width - _tabBarHeight - statusBarHeight) / 2.0));
                             }];
            
            [UIView animateWithDuration:duration
                             animations:^{
                                 _firstView.frame = frame1;
                             }];
        }
            break;
            
        case MapViewScreenSettingTriScreen:
        {
            [UIView animateWithDuration:duration
                             animations:^{
                                 _mapView.frame = _vectorView.frame =
                                 CGRectMake(0.0, statusBarHeight,
                                            (self.view.frame.size.height + _tabBarHeight),
                                            ((self.view.frame.size.width - _tabBarHeight - statusBarHeight) / 3.0));
                             }];
            
            [UIView animateWithDuration:duration
                             animations:^{
                                 _firstView.frame = frame2;
                             }];
            
            [UIView animateWithDuration:duration
                             animations:^{
                                 _secondImageView.frame =
                                 CGRectMake(0.0, statusBarHeight +
                                            ((self.view.frame.size.width - _tabBarHeight - statusBarHeight) / 1.5),
                                            (self.view.frame.size.height + _tabBarHeight),
                                            ((self.view.frame.size.width - _tabBarHeight - statusBarHeight) / 3.0));
                             }];
        }
            break;
            
        case MapViewScreenSettingSplitBottomScreen:
        {
            [UIView animateWithDuration:duration
                             animations:^{
                                 _mapView.frame = _vectorView.frame =
                                 CGRectMake(0.0, statusBarHeight,
                                            (self.view.frame.size.height + _tabBarHeight),
                                            ((self.view.frame.size.width - _tabBarHeight - statusBarHeight) / 1.5));
                             }];
            
            [UIView animateWithDuration:duration
                             animations:^{
                                 _firstView.frame = frame3;
                             }];
            
            [UIView animateWithDuration:duration
                             animations:^{
                                 _secondImageView.frame =
                                 CGRectMake(((self.view.frame.size.height + _tabBarHeight) / 2.0),
                                            statusBarHeight + ((self.view.frame.size.width - _tabBarHeight - statusBarHeight) / 1.5),
                                            ((self.view.frame.size.height + _tabBarHeight) / 2.0),
                                            ((self.view.frame.size.width - _tabBarHeight - statusBarHeight) / 3.0));
                             }];
        }
            break;
    }
}

- (void)clearVectorView
{
    _vectorView.displayData = 0;
    [_vectorView setNeedsDisplay];
}

- (void)refreshVectorView:(MKCoordinateRegion)region
                   atZoom:(int)zoom
{
    MNMXCORD llBounds;
    _vectorView.displayData = 1;
    llBounds.xmn = (region.center.longitude - region.span.longitudeDelta / 2.0);
    llBounds.xmx = (region.center.longitude + region.span.longitudeDelta / 2.0);
    llBounds.ymn = (region.center.latitude - region.span.latitudeDelta / 2.0);
    llBounds.ymx = (region.center.latitude + region.span.latitudeDelta / 2.0);
    _vectorView.latlonBounds = llBounds;
    _vectorView.zoom = zoom;
    [_vectorView setNeedsDisplay];
    
}

- (void)setupTableView
{
    _tableView.hidden = YES;
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.separatorInset = UIEdgeInsetsZero;
    _tableView.bounces = NO;
    _tableView.backgroundColor = _tableViewBackgroundColor;
    
    _screenSize = MIN(self.view.frame.size.width, self.view.bounds.size.height);
    _tableView.layer.cornerRadius = (_screenSize / 48.0);
    [self.view bringSubviewToFront:_tableView];
}

- (void)initTableView
{
    if (_tableView)
    {
        if (_currentScreenHeight != self.view.frame.size.height)
            [_tableView reloadData];
        
        if (_tableView.indexPathForSelectedRow)
        {
            [_tableView deselectRowAtIndexPath:_tableView.indexPathForSelectedRow
                                      animated:YES];
        }
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (UIView *)tableView:(UITableView *)tableView
viewForHeaderInSection:(NSInteger)section
{
    UILabel *headerLabel = [[UILabel alloc] init];
    headerLabel.frame = CGRectMake(0.0, 0.0, tableView.frame.size.width, [self getHeaderHeight]);
    headerLabel.font = [UIFont boldSystemFontOfSize:MAX((_screenSize / 21.0), 21.0)];
    headerLabel.textColor = UIColor.yellowColor;
    headerLabel.backgroundColor = _tableViewBackgroundColor;
    headerLabel.textAlignment = NSTextAlignmentCenter;
    
    switch (_tableViewSetting)
    {
        case PropertyTableViewSettingOptions:
            headerLabel.numberOfLines = 1;
            headerLabel.text = @"Options";
            break;
            
        case PropertyTableViewSettingPropertyReport:
            headerLabel.numberOfLines = 2;
            headerLabel.text = @"Property Report for\nTaxes Payable 2014";
            break;
    }
    
    return headerLabel;
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    NSInteger numberOfRows = 0;
    
    switch (_tableViewSetting)
    {
        case PropertyTableViewSettingOptions:
            numberOfRows = _options.count;
            break;
            
        case PropertyTableViewSettingPropertyReport:
            numberOfRows = _propertyReport.count;
            break;
    }
    
    return numberOfRows;
}

- (CGFloat)getHeaderHeight
{
    CGFloat headerHeight = MAX((_screenSize / 16.0), 30.0);
    
    if (_tableViewSetting == PropertyTableViewSettingPropertyReport)
        headerHeight *= 1.9;
    
    return headerHeight;
}

- (CGFloat)tableView:(UITableView *)tableView
heightForHeaderInSection:(NSInteger)section
{
    return [self getHeaderHeight];
}

- (CGFloat)tableView:(UITableView *)tableView
heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat rowHeight = MAX((_screenSize / 20.0), 28.0);
    
    if (_tableViewSetting == PropertyTableViewSettingOptions)
        rowHeight = MAX(((_tableView.frame.size.height - [self getHeaderHeight]) / _options.count), 1.0);
    
    else
    {
        NSString *textLabelText = [UserDefaults.defaults includeTextAfterFirstColon:_propertyReport[indexPath.row]];
        
        CGSize textSize = [textLabelText sizeWithAttributes:@{NSFontAttributeName:
                                                                  [UIFont systemFontOfSize:
                                                                   MAX((_screenSize / 28.0), 18.0)]}];
        
        CGFloat textToCellFit = (textSize.width / (tableView.frame.size.width * 0.6));
        
        if (textToCellFit > 1.0)
            rowHeight *= 1.9;
    }
    
    return rowHeight;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier
                                                            forIndexPath:indexPath];
    
    if (!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:identifier];
    }
    
    for (UILabel *label in cell.contentView.subviews)
        [label removeFromSuperview];
    
    cell.backgroundColor = UIColor.clearColor;
    cell.textLabel.textColor = UIColor.whiteColor;
    cell.textLabel.numberOfLines = 2;
    cell.textLabel.adjustsFontSizeToFitWidth = YES;
    cell.indentationLevel = 1;
    
    switch (_tableViewSetting)
    {
        case PropertyTableViewSettingOptions:
            cell.textLabel.font = [UIFont boldSystemFontOfSize:MAX((_screenSize / 21.0), 21.0)];
            cell.textLabel.textAlignment = NSTextAlignmentCenter;
            cell.textLabel.text = _options[indexPath.row];
            cell.indentationWidth = 0.0;
            break;
            
        case PropertyTableViewSettingPropertyReport:
            cell.textLabel.font = [UIFont systemFontOfSize:MAX((_screenSize / 28.0), 18.0)];
            
            cell.textLabel.text = [UserDefaults.defaults removeOpeningSpaces:
                                   [UserDefaults.defaults includeTextAfterFirstColon:
                                    _propertyReport[indexPath.row]]];
           
            
            cell.textLabel.textAlignment = NSTextAlignmentLeft;
            cell.indentationWidth = (cell.frame.size.width * 0.3);
            
            UILabel *rowHeader = [[UILabel alloc] initWithFrame:CGRectMake(4.0, 0.0,
                                                                           (cell.indentationWidth - 4.0),
                                                                           cell.frame.size.height)];
            
            rowHeader.text = [UserDefaults.defaults includeTextBeforeColon:_propertyReport[indexPath.row]];
            rowHeader.font = [UIFont boldSystemFontOfSize:MAX((_screenSize / 48.0), 11.5)];
            rowHeader.textAlignment = NSTextAlignmentRight;
            
            rowHeader.textColor = [UIColor colorWithRed:0.7
                                                  green:0.85
                                                   blue:1.0
                                                  alpha:1.0];
            rowHeader.numberOfLines = 2;
            cell.textLabel.adjustsFontSizeToFitWidth = YES;
            
            [cell.contentView addSubview:rowHeader];
            break;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[tableView cellForRowAtIndexPath:indexPath].textLabel.text
         isEqualToString:@"Property Report"])
    {
        _tableViewSetting = PropertyTableViewSettingPropertyReport;
        tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        tableView.allowsSelection = NO;
        tableView.delaysContentTouches = YES;
        
        [tableView reloadData];
        
        [tableView scrollRectToVisible:CGRectMake(0.0, 0.0, 1.0, 1.0)
                              animated:NO];
    }
    
    else if ([[tableView cellForRowAtIndexPath:indexPath].textLabel.text
              isEqualToString:@"Hennepin County Website"])
    {
        WebKitViewController *wkvc = [[WebKitViewController alloc] initWithPID:
                                      [UserDefaults.defaults removePIDPrefix:_selectedPID]];
        
        [self presentViewController:wkvc
                           animated:YES
                         completion:nil];
    }
    
    else if ([[tableView cellForRowAtIndexPath:indexPath].textLabel.text
              isEqualToString:@"Display Street View"])
    {
        _streetView.frame = _tableView.frame;
        _fov = 90.0, _pitch = 0.0;
        
        _streetView.image = [self getStreetViewImageAtCoords:_selectedPIDCoords
                                                       pitch:_pitch
                                                         fov:_fov];
        
        [self.view bringSubviewToFront:_streetView];
        
        for (UIView *view in self.view.subviews)
            view.hidden = YES;
        
        _streetView.hidden = NO;
        
        [UIView animateWithDuration:0.25
                         animations:^{
                             _streetView.frame =
                             CGRectMake(((self.view.frame.size.width - _screenSize) / 2.0),
                                        (((self.view.frame.size.height + _tabBarHeight) - _screenSize) / 2.0),
                                        _screenSize, _screenSize);
                             self.view.backgroundColor = UIColor.blackColor;
                             self.tabBarController.tabBar.alpha = 0.0;
                             UIApplication.sharedApplication.statusBarStyle = UIStatusBarStyleLightContent;
                             _exitStreetView.hidden = NO;
                         }];
    }
    
    else if ([[tableView cellForRowAtIndexPath:indexPath].textLabel.text
              isEqualToString:@"Zoom to Census Area"])
    {
        [_gssiAlert showAlertWithTitle:@"Zoom to Census Area"
                               message:[NSString stringWithFormat:@"Parcel %@", _selectedPID]
                     cancelButtonTitle:@"Cancel"
                     otherButtonTitles:@[@"Zoom to Block", @"Zoom to BlockGroup", @"Zoom to Tract"]
             destructiveButtonPosition:0];
    }
}

- (void)gssiAlert:(GSSiAlertController *)gssiAlert
clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (buttonIndex)
    {
        case CensusZoomSettingCancel:
            if (_tableView.indexPathForSelectedRow)
            {
                [_tableView deselectRowAtIndexPath:_tableView.indexPathForSelectedRow
                                          animated:YES];
            }
            
            break;
        
        case CensusZoomSettingBlock:
            [self dismissTableView];
            //implement zoom to block here
            break;
            
        case CensusZoomSettingBlockGroup:
            [self dismissTableView];
            //implement zoom to block group here
            break;
            
        case CensusZoomSettingTract:
            [self dismissTableView];
            //implement zoom to tract here
            break;
    }
}

- (IBAction)dismissStreetView:(id)sender
{
    [UIView animateWithDuration:0.25
                     animations:^{
                         _streetView.frame = CGRectMake(_tableView.frame.origin.x,
                                                        _tableView.frame.origin.y,
                                                        _tableView.frame.size.width,
                                                        _tableView.frame.size.height);
                         
                         self.view.backgroundColor = UIColor.whiteColor;
                         self.tabBarController.tabBar.alpha = 1.0;
                         UIApplication.sharedApplication.statusBarStyle = UIStatusBarStyleDefault;
                         
                         for (UIView *view in self.view.subviews)
                             view.hidden = NO;
                         
                         _exitStreetView.hidden = YES;
                     }
                     completion:^(BOOL finished){
                         [self.view sendSubviewToBack:_streetView];
                         _streetView.hidden = YES;
                         
                         if (_tableView.indexPathForSelectedRow)
                         {
                             [_tableView deselectRowAtIndexPath:_tableView.indexPathForSelectedRow
                                                       animated:YES];
                         }
                     }];
}

- (UIImage *)getStreetViewImageAtCoords:(CLLocationCoordinate2D)coord
                                  pitch:(CGFloat)pitch
                                    fov:(CGFloat)fov
{
    NSString *staticMapUrl = [NSString stringWithFormat:
                              @"http://maps.googleapis.com/maps/api/streetview?size=640x640&location=%f,%f&fov=%f&pitch=%f",
                              coord.latitude, coord.longitude, fov, pitch];
    
    NSURL *mapUrl = [NSURL URLWithString:[staticMapUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:mapUrl]];
    return image;
}

- (void)touchesBegan:(NSSet *)touches
           withEvent:(UIEvent *)event
{
    [self dismissTableView];
}

- (void)dismissTableView
{
    if (!_tableView.hidden)
    {
        CGRect frame = _tableView.frame;
        
        [UIView animateWithDuration:0.25
                         animations:^{
                             _tableView.frame = CGRectMake(self.view.center.x,
                                                           self.view.center.y,
                                                           0.0, 0.0);
                         }
                         completion:^(BOOL finished){
                             _tableView.hidden = YES;
                             _tableView.frame = frame;
                             _clearWhenDeselected = NO;
                         }];
    }
}

- (void)platViewPosition:(CGPoint)center
               fromFrame1:(CGRect)frame1
                 toFrame2:(CGRect)frame2
{
    if (![_firstView.subviews containsObject:_platView])
    {
        _platView.frame =  CGRectMake(0.0, 0.0,
                                      _firstView.frame.size.width,
                                      _firstView.frame.size.height);
    }
    
    else
    {
        _platView.center = CGPointMake(center.x - ((frame1.size.width - frame2.size.width) / 2.0),
                                       center.y - ((frame1.size.height - frame2.size.height) / 2.0));
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

- (IBAction)toggleMapType:(UISegmentedControl *)segmentedControl
{
    switch (segmentedControl.selectedSegmentIndex)
    {
        case 0:
            _mapView.mapType = MKMapTypeStandard;
            break;
            
        case 1:
            _mapView.mapType = MKMapTypeHybrid;
            break;
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
       shouldReceiveTouch:(UITouch *)touch
{
    if (gestureRecognizer == _longPress && (!_tableView.hidden))
        return NO;
    
    else
        return YES;
}

- (BOOL)isHennepinCountyPID:(NSString *)PID
{
    if (!([PID rangeOfString:@"053-"].location == NSNotFound))
        return YES;
    
    else
        return NO;
}

- (void)platViewDidTranslate:(CGPoint)translation
{
    CGPoint coordPoint = [_mapView convertCoordinate:_camera.centerCoordinate
                                       toPointToView:_mapView];
    
    CGPoint newPoint = CGPointMake(coordPoint.x - translation.x,
                                   coordPoint.y - translation.y);
    
    CLLocationCoordinate2D newCoord = [_mapView convertPoint:newPoint
                                        toCoordinateFromView:_mapView];
    
    _camera = [MKMapCamera cameraLookingAtCenterCoordinate:newCoord
                                         fromEyeCoordinate:newCoord
                                               eyeAltitude:_camera.altitude];
    
    [_mapView setCamera:_camera
               animated:NO];
}

- (void)platViewDidTransformScale:(CGFloat)transformationScale
{
    CLLocationCoordinate2D coord = _camera.centerCoordinate;
    CGFloat latDelta = (_mapView.region.span.latitudeDelta * (1.0 / transformationScale));
    
    _camera = [MKMapCamera cameraLookingAtCenterCoordinate:coord
                                         fromEyeCoordinate:coord
                                               eyeAltitude:(latDelta * 207360.0)];
    
    [_mapView setCamera:_camera
               animated:NO];
}

- (void)platViewDidDoubleTap
{
    CGFloat statusBarHeight = [self statusBarHeight:self.interfaceOrientation];
    CGFloat tabBarTop = self.tabBarController.tabBar.frame.origin.y;
    
    [UIView animateWithDuration:0.25
                     animations:^{
                         _mapView.layer.borderWidth = 0.0;
                         
                         _mapView.frame = _vectorView.frame =
                         CGRectMake(0.0,
                                    statusBarHeight,
                                    self.view.frame.size.width,
                                    (tabBarTop - statusBarHeight));
                     }];
    
    [UIView animateWithDuration:0.25
                     animations:^{
                         _firstView.frame = _secondImageView.frame =
                         CGRectMake(0.0,
                                    tabBarTop,
                                    self.view.frame.size.width, 0.0);
                     }
                     completion:^(BOOL finished){
                         [_platView removeFromSuperview];
                     }];
    
    _screenSetting = MapViewScreenSettingFullscreen;
}

- (void)svUpSwiped:(UISwipeGestureRecognizer *)gesture
{
    _pitch -= 10.0;
    
    _streetView.image = [self getStreetViewImageAtCoords:_selectedPIDCoords
                                                   pitch:_pitch
                                                     fov:_fov];
}

- (void)svDownSwiped:(UISwipeGestureRecognizer *)gesture
{
    _pitch += 10.0;
    
    _streetView.image = [self getStreetViewImageAtCoords:_selectedPIDCoords
                                                   pitch:_pitch
                                                     fov:_fov];
}

- (void)svDoubleTapped:(UITapGestureRecognizer *)gesture
{
    _fov -= 10.0;
    
    _streetView.image = [self getStreetViewImageAtCoords:_selectedPIDCoords
                                                   pitch:_pitch
                                                     fov:_fov];
}

- (void)svTwoFingerTapped:(UITapGestureRecognizer *)gesture
{
    _fov += 10.0;
    
    _streetView.image = [self getStreetViewImageAtCoords:_selectedPIDCoords
                                                   pitch:_pitch
                                                     fov:_fov];
}

- (void)mapToolbarDidSelectZoomExtent
{
    [_mapView setUserTrackingMode:MKUserTrackingModeNone
                         animated:NO];
    
    _mapView.rotateEnabled = YES;
    [self extentZoom:YES];
}

- (void)mapToolbarDidSelectUserLocation
{
    [_mapView setUserTrackingMode:MKUserTrackingModeFollowWithHeading
                         animated:YES];
    
    _mapView.rotateEnabled = NO;
}

- (void)mapToolbarDidSelectAnnotationOption:(BOOL)option
{
    if (option)
        _clearAnnotations = NO;
    
    else
        _clearAnnotations = YES;
}

- (void)mapToolbarDidSelectMapType:(NSInteger)mapType
{
    switch (mapType)
    {
        case MapTypeSettingStandard:
            _mapView.mapType = MKMapTypeStandard;
            break;
            
        case MapTypeSettingHybrid:
            _mapView.mapType = MKMapTypeHybrid;
            break;
    }
}

- (void)mapToolbarDidSelectSplitScreenSetting:(NSInteger)setting
{
    CGFloat statusBarHeight = [self statusBarHeight:self.interfaceOrientation];
    CGFloat tabBarTop = self.tabBarController.tabBar.frame.origin.y;
    CGPoint platViewCenter = _platView.center;
    
    CGRect frame0 = CGRectMake(0.0,
                               tabBarTop,
                               self.view.frame.size.width, 0.0);
    
    CGRect frame1 = CGRectMake(0.0,
                               (statusBarHeight + ((tabBarTop - statusBarHeight) / 2.0)),
                               self.view.frame.size.width,
                               ((tabBarTop - statusBarHeight) / 2.0));
    
    CGRect frame2 = CGRectMake(0.0,
                               (statusBarHeight + ((tabBarTop - statusBarHeight) / 3.0)),
                               self.view.frame.size.width,
                               ((tabBarTop - statusBarHeight) / 3.0));
    
    CGRect frame3 = CGRectMake(0.0,
                               (statusBarHeight + ((tabBarTop - statusBarHeight) / 1.5)),
                               (self.view.frame.size.width / 2.0),
                               ((tabBarTop - statusBarHeight) / 3.0));
    
    switch (setting)
    {
        case MapViewScreenSettingFullscreen:
        {
            [UIView animateWithDuration:0.25
                             animations:^{
                                 _mapView.layer.borderWidth = 0.0;
                                 
                                 _mapView.frame = _vectorView.frame =
                                 CGRectMake(0.0,
                                            statusBarHeight,
                                            self.view.frame.size.width,
                                            (tabBarTop - statusBarHeight));
                             }];
            
            [UIView animateWithDuration:0.25
                             animations:^{
                                 _firstView.frame = _secondImageView.frame = frame0;
                             }];
            
            _screenSetting = MapViewScreenSettingFullscreen;
        }
            break;
            
        case MapViewScreenSettingSplitScreen:
        {
            [UIView animateWithDuration:0.25
                             animations:^{
                                 _mapView.layer.borderWidth = _splitScreenBorderWidth;
                                 
                                 _mapView.frame = _vectorView.frame =
                                 CGRectMake(0.0,
                                            statusBarHeight,
                                            self.view.frame.size.width,
                                            ((tabBarTop - statusBarHeight) / 2.0));
                             }];
            
            [UIView animateWithDuration:0.25
                             animations:^{
                                 _firstView.frame = _platView.frame = frame1;
                             }];
            
            [UIView animateWithDuration:0.25
                             animations:^{
                                 _secondImageView.frame = frame0;
                             }];
            
            [UIView animateWithDuration:0.25
                             animations:^{
                                 [self platViewPosition:platViewCenter
                                             fromFrame1:frame3
                                               toFrame2:frame1];
                             }];
            
            _screenSetting = MapViewScreenSettingSplitScreen;
        }
            break;
            
        case MapViewScreenSettingTriScreen:
        {
            [UIView animateWithDuration:0.25
                             animations:^{
                                 _mapView.frame = _vectorView.frame =
                                 CGRectMake(0.0,
                                            statusBarHeight,
                                            self.view.frame.size.width,
                                            ((tabBarTop - statusBarHeight) / 3.0));
                             }];
            
            [UIView animateWithDuration:0.25
                             animations:^{
                                 _firstView.frame = frame2;
                             }];
            
            [UIView animateWithDuration:0.25
                             animations:^{
                                 _secondImageView.frame =
                                 CGRectMake(0.0,
                                            (statusBarHeight + ((tabBarTop - statusBarHeight) / 1.5)),
                                            self.view.frame.size.width,
                                            ((tabBarTop - statusBarHeight) / 3.0));
                             }];
            
            [UIView animateWithDuration:0.25
                             animations:^{
                                 [self platViewPosition:platViewCenter
                                             fromFrame1:frame1
                                               toFrame2:frame2];
                             }];
            
            _screenSetting = MapViewScreenSettingTriScreen;
        }
            break;
            
        case MapViewScreenSettingSplitBottomScreen:
        {
            [UIView animateWithDuration:0.25
                             animations:^{
                                 _mapView.frame = _vectorView.frame =
                                 CGRectMake(0.0,
                                            statusBarHeight,
                                            self.view.frame.size.width,
                                            ((tabBarTop - statusBarHeight) / 1.5));
                             }];
            
            [UIView animateWithDuration:0.25
                             animations:^{
                                 _firstView.frame = frame3;
                             }];
            
            [UIView animateWithDuration:0.25
                             animations:^{
                                 _secondImageView.frame =
                                 CGRectMake((self.view.frame.size.width / 2.0),
                                            (statusBarHeight + ((tabBarTop - statusBarHeight) / 1.5)),
                                            (self.view.frame.size.width / 2.0),
                                            ((tabBarTop - statusBarHeight) / 3.0));
                             }];
            
            [UIView animateWithDuration:0.25
                             animations:^{
                                 [self platViewPosition:platViewCenter
                                             fromFrame1:frame2
                                               toFrame2:frame3];
                             }];
            
            _screenSetting = MapViewScreenSettingSplitBottomScreen;
        }
            break;
    }
    
    if (![_firstView.subviews containsObject:_platView])
        [_firstView addSubview:_platView];
}

@end