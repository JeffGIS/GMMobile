//  MapViewController.m
//  GMMobile

extern int keepProcessing;

#import "MapViewController.h"
#import "WebKitViewController.h"
#import "PickedItem.h"

@interface MapViewController ()

@property (nonatomic) CLLocationCoordinate2D target, selectedPIDCoords;
@property (nonatomic) NSArray *options;
@property (nonatomic) NSMutableArray *propertyReport, *markerArray;
@property (nonatomic) NSInteger tableViewSetting;
@property (nonatomic) CGFloat screenSize;
@property (nonatomic) UIColor *tableViewBackgroundColor;
@property (nonatomic) BOOL clearAnnotations, clearWhenDeselected, initialZoom, rotateZoom;
@property (nonatomic) BOOL firstTimeAppear, firstTimeMap, allowRefresh, noneSelected;
@property (nonatomic, copy) NSString *selectedPID;
@property (nonatomic, copy) NSString *selectedPlat;
@property (nonatomic) int selectedPlatRefno;
@property (nonatomic) CGFloat currentScreenHeight, splitScreenBorderWidth, tabBarHeight;
@property (nonatomic) CGFloat heading, pitch, fov;
@property (nonatomic) VectorView *vectorView;
@property (nonatomic) UIImageView *streetView;
@property (nonatomic) UIView *firstView, *secondView;
@property (nonatomic) NSInteger screenSetting;
@property (nonatomic) GSSiAlertController *gssiAlert;
@property (nonatomic) MapToolbar *mapToolbar;
@property (nonatomic) GMSMapView *mapView;
@property (nonatomic) CLLocationManager *locationManager;
@property (nonatomic) MarkerInfoWindow *infoWindow;
@property (nonatomic) GSSiPopoverView *popover;
@property (nonatomic) NSString *selectedSewerPipe;
@property (atomic) BOOL waitForVectorViewRefresh;
@property (nonatomic) GMSTileLayer *layer;
@property (nonatomic) UIButton *compass;
@property (nonatomic) PlatImageView *platView;
@property (nonatomic) UIImageView *profileView;

@end

#define MAX_VECTORVIEWS 8
@implementation MapViewController
{
    VectorView * vectorViews[MAX_VECTORVIEWS];
    int nVectorViews;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    nVectorViews = 0;
    for (int i=0;i<MAX_VECTORVIEWS;i++)
        vectorViews[i] = nil;
    
    [PipeTrace removeTrace];
    
    _profileView = [[UIImageView alloc] init];
    _profileView.contentMode = UIViewContentModeScaleAspectFit;
    
    _firstTimeAppear = _firstTimeMap = _allowRefresh = YES;
    
    CGFloat statusBarHeight = [self statusBarHeight:self.interfaceOrientation];
    CGFloat tabBarTop = self.tabBarController.tabBar.frame.origin.y;
    
    CGRect mapViewFrame = CGRectMake(0.0, statusBarHeight,
                                     self.view.frame.size.width,
                                     (tabBarTop - statusBarHeight));
    
    _target = CLLocationCoordinate2DMake(44.97, -93.27);
    
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithTarget:_target
                                                               zoom:12.0];
    
    _mapView = [GMSMapView mapWithFrame:mapViewFrame
                                 camera:camera];
    
    _mapView.delegate = self;
    _mapView.mapType = kGMSTypeNormal;
    _mapView.settings.compassButton = NO;
    _mapView.settings.rotateGestures = YES;
    _mapView.settings.tiltGestures = NO;
    [self.view addSubview:_mapView];
    
    UIImage *compassImage = [UIImage imageWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"compass"
                                                                                           ofType:@"png"]];
    
    CGFloat compassSize = 48.0, compassMargin = 6.0;
    
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
        compassSize = 36.0, compassMargin = 4.0;
    
    _compass = [[UIButton alloc] initWithFrame:CGRectMake((self.view.frame.size.width - compassSize - compassMargin),
                                                          (statusBarHeight + compassMargin), compassSize, compassSize)];
    
    [_compass setImage:compassImage
              forState:UIControlStateNormal];
    
    _compass.backgroundColor = UIColor.whiteColor;
    _compass.layer.cornerRadius = (compassSize / 2.0);
    _compass.layer.borderWidth = 1.0;
    _compass.layer.borderColor = UIColor.lightGrayColor.CGColor;
    _compass.imageEdgeInsets = UIEdgeInsetsMake(2.0, 2.0, 2.0, 2.0);
    _compass.alpha = 0.0;
    _compass.hidden = YES;
    
    [_compass addTarget:self
                 action:@selector(compassTapped:)
       forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:_compass];
    
    UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                                                   action:@selector(mapViewLongPressed:)];
    
    longPressGesture.delegate = self;
    [_mapView addGestureRecognizer:longPressGesture];
    
    GMSTileURLConstructor constructor = ^(NSUInteger x, NSUInteger y, NSUInteger zoom) {
        NSString *url = [NSString stringWithFormat:@"http://www.gssidata.com/MPLS/%lu/%lu/%lu.png",
                         (unsigned long)zoom, (unsigned long)y, (unsigned long)x];
        
        return [NSURL URLWithString:url];
    };
    
    _layer = [GMSURLTileLayer tileLayerWithURLConstructor:constructor];
    
    if (CRAPI.sharedInstance.GMTilesVisible)
        _layer.map = _mapView;
    
    _markerArray = [[NSMutableArray alloc] init];
    
    _locationManager = [[CLLocationManager alloc] init];
    _locationManager.delegate = self;
    
    if ([_locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)])
        [_locationManager requestWhenInUseAuthorization];
    
    self.view.backgroundColor = UIColor.whiteColor;
    
    _gssiAlert = [[GSSiAlertController alloc] initWithViewController:self];
    _gssiAlert.delegate = self;
    _popover = [[GSSiPopoverView alloc] initWithView:self.view];
    
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
    
    _firstView = [[UIView alloc] init];
    _secondView = [[UIView alloc] init];
    _firstView.clipsToBounds = _secondView.clipsToBounds = YES;
    
    _firstView.frame = _secondView.frame = CGRectMake(0.0, tabBarTop,
                                                      self.view.frame.size.width, 0.0);

    _splitScreenBorderWidth = 2.0;
    
    _firstView.layer.borderColor = _secondView.layer.borderColor =
    _mapView.layer.borderColor = UIColor.darkGrayColor.CGColor;
    
    _firstView.backgroundColor = [UIColor colorWithRed:0.8
                                                 green:0.9
                                                  blue:1.0
                                                 alpha:1.0];
    
    _secondView.backgroundColor = [UIColor colorWithRed:0.9
                                                  green:1.0
                                                   blue:0.8
                                                  alpha:1.0];
    
    _firstView.layer.borderWidth = _secondView.layer.borderWidth = _splitScreenBorderWidth;
    
    [self.view addSubview:_firstView];
    [self.view addSubview:_secondView];
    [self.view addSubview:_streetView];
    
    [self setupTableView];
    
    _mapToolbar = [[MapToolbar alloc] init];
    _mapToolbar.delegate = self;
    
    _mapToolbar.center = CGPointMake((self.view.frame.size.width / 2.0),
                                     (_mapToolbar.frame.size.height / 2.0) + statusBarHeight);
    
    _mapToolbar.orientation = MapToolbarOrientationTop;
    
    [self.view addSubview:_mapToolbar];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (!_firstTimeAppear)
    {
        [self initTableView];
        
        if (CRAPI.sharedInstance.GMTilesVisible)
            _layer.map = _mapView;
        
        else
            _layer.map = nil;
    }
    
    if (CRAPI.sharedInstance.GMMSetting == GMMSettingPID ||
        CRAPI.sharedInstance.GMMSetting == GMMSettingAddress ||
        CRAPI.sharedInstance.GMMSetting == GMMSettingPropOwner)
    {
        GMSCameraPosition *camera;
        
        _tableView.hidden = YES;
        _selectedPID = CRAPI.sharedInstance.currentPID;
        
        PropertyData *propData = [[PropertyData alloc] init];
        
        LLPOINT pidPoint = [propData getPointForPID:_selectedPID];
        MNMXCORD bounds = [propData getBoundsForPID:_selectedPID];
        
        CLLocationCoordinate2D pidCoord = CLLocationCoordinate2DMake(pidPoint.lat, pidPoint.lon);
        CLLocationCoordinate2D northeast = CLLocationCoordinate2DMake(bounds.ymx, bounds.xmx);
        CLLocationCoordinate2D southwest = CLLocationCoordinate2DMake(bounds.ymn, bounds.xmn);
        
        if (northeast.latitude == 0.0 || northeast.longitude == 0.0 ||
            southwest.latitude == 0.0 || southwest.longitude == 0.0)
        {
            camera = [GMSCameraPosition cameraWithTarget:pidCoord
                                                    zoom:21.0];
        }
        
        else
        {
            GMSCoordinateBounds *coordBounds = [[GMSCoordinateBounds alloc] initWithCoordinate:northeast
                                                                                    coordinate:southwest];
            
            camera = [_mapView cameraForBounds:coordBounds
                                        insets:UIEdgeInsetsMake(20.0, 20.0, 20.0, 20.0)];
        }
        
        [_mapView animateToCameraPosition:camera];
        
        if (_clearAnnotations)
        {
            for (MarkerButton *markers in _markerArray)
                [markers removeFromSuperview];
            
            [_markerArray removeAllObjects];
        }
        
        _selectedPIDCoords = pidCoord;
        
        for (MarkerButton *marker in _markerArray)
        {
            if ([marker.title isEqualToString:_selectedPID])
                [marker removeFromSuperview];
        }
        
        MarkerButton *marker = [MarkerButton markerWithPosition:pidCoord
                                                           view:self.view
                                                            map:_mapView
                                                       delegate:self];
        
        [self removePreviousInfoWindow];
        _infoWindow = [[MarkerInfoWindow alloc] init];
        
        switch (CRAPI.sharedInstance.GMMSetting)
        {
            case GMMSettingPID:
                marker.snippet = CRAPI.sharedInstance.currentPropOwner;
                break;
                
            case GMMSettingAddress:
                marker.snippet = CRAPI.sharedInstance.currentAddress;
                break;
                
            case GMMSettingPropOwner:
                marker.snippet = CRAPI.sharedInstance.currentPropOwner;
                break;
        }
        
        marker.title = _selectedPID;
        [_markerArray addObject:marker];
        
        _infoWindow.type = marker.type = MarkerInfoWindowTypePID;
        _infoWindow.center = CGPointMake(marker.center.x, (marker.center.y - 42.0));
        _infoWindow.delegate = self;
        _infoWindow.title = marker.title;
        _infoWindow.snippet = marker.snippet;
        _infoWindow.position = marker.position;
        
        NSLog(@"%@", marker.title);
        NSLog(@"%@", _infoWindow.title);
        
        [self.view addSubview:_infoWindow];
        _noneSelected = NO;
        
        CRAPI.sharedInstance.GMMSetting = GMMSettingDefault;
    }
    
    else if (CRAPI.sharedInstance.GMMSetting == GMMSettingBoundaries)
    {
        [self extentZoom];
        CRAPI.sharedInstance.GMMSetting = GMMSettingDefault;
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (!_firstTimeAppear)
    {
        [self refreshVectorView:_mapView.projection.visibleRegion
                         atZoom:_mapView.camera.zoom];
    }
    
    else
        _firstTimeAppear = NO;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    _currentScreenHeight = self.view.frame.size.height;
    
    [self stopTrackingUserLocation:YES];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    [self clearVectorView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)extentZoom
{
    [self stopTrackingUserLocation:NO];
    GMSCameraPosition *camera;
    
    if (CRAPI.sharedInstance.currentOverallBoundaryRefno)
    {
        PropertyData *propData = [[PropertyData alloc] init];
        
        MNMXCORD bounds = [propData getBoundaryAreaBounds:
                           CRAPI.sharedInstance.currentOverallBoundaryRefno];
        
        CLLocationCoordinate2D northeast = CLLocationCoordinate2DMake(bounds.ymx, bounds.xmx);
        CLLocationCoordinate2D southwest = CLLocationCoordinate2DMake(bounds.ymn, bounds.xmn);
        
        GMSCoordinateBounds *coordBounds = [[GMSCoordinateBounds alloc] initWithCoordinate:northeast
                                                                                coordinate:southwest];
        
        camera = [_mapView cameraForBounds:coordBounds
                                    insets:UIEdgeInsetsMake(20.0, 20.0, 20.0, 20.0)];
    }
    
    else
    {
        camera = [GMSCameraPosition cameraWithTarget:_target
                                                zoom:12.0];
    }
    
    [_mapView animateToCameraPosition:camera];
}

- (void)zoomToPipeTraceBounds:(MNMXCORD)bounds
{
    CLLocationCoordinate2D northeast = CLLocationCoordinate2DMake(bounds.ymx, bounds.xmx);
    CLLocationCoordinate2D southwest = CLLocationCoordinate2DMake(bounds.ymn, bounds.xmn);
    
    GMSCoordinateBounds *coordBounds = [[GMSCoordinateBounds alloc] initWithCoordinate:northeast
                                                                            coordinate:southwest];
    
    GMSCameraPosition *camera = [_mapView cameraForBounds:coordBounds
                                                   insets:UIEdgeInsetsMake(20.0, 20.0, 20.0, 20.0)];
    
    [_mapView animateToCameraPosition:camera];
    
}

- (void)mapView:(GMSMapView *)mapView
didTapAtCoordinate:(CLLocationCoordinate2D)coordinate
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
    
    else
    {
        LLPOINT llpickPt, llSewerPt, llPropPt;
        //CGFloat dist;
        llpickPt.lat = coordinate.latitude;
        llpickPt.lon = coordinate.longitude;
        llPropPt = llpickPt;
        llSewerPt = llpickPt;
        NSMutableArray *highlightList = [[NSMutableArray alloc] init];
        PropertyData *propData = [[PropertyData alloc] init];
        SewerData *sewerData = [[SewerData alloc] init];
        
        sewerData.zoom = _mapView.camera.zoom;
        propData.zoom = _mapView.camera.zoom;
        
        [propData pickPID:&llPropPt
            highlightList:highlightList];
        
        [sewerData pickSewer:&llSewerPt
               highlightList:highlightList];
        
        if (highlightList.count)
        {
            if (_clearAnnotations)
            {
                for (MarkerButton *markers in _markerArray)
                    [markers removeFromSuperview];
                
                [_markerArray removeAllObjects];
            }
            
            PickedItem *pi = [PickedItem nearestPickedItem:highlightList];
            CLLocationCoordinate2D pickedPt;
            pickedPt.latitude = pi.pickedPoint.y;
            pickedPt.longitude = pi.pickedPoint.x;
            
            for (MarkerButton *marker in _markerArray)
            {
                if ([marker.title isEqualToString:pi.identifier])
                    [marker removeFromSuperview];
            }
            
            MarkerButton *marker = [MarkerButton markerWithPosition:pickedPt
                                                               view:self.view
                                                                map:_mapView
                                                           delegate:self];
            
            [self removePreviousInfoWindow];
            _infoWindow = [[MarkerInfoWindow alloc] init];
            
            switch (pi.itemType)
            {
                case PTStormSewerLine:
                    _selectedSewerPipe = pi.identifier;
                    marker.title = _selectedSewerPipe;
                    marker.snippet = pi.symbolName;
                    _infoWindow.type = marker.type = MarkerInfoWindowTypeStormSewer;
                    break;
                    
                case PTPid:
                    _selectedPID = pi.identifier;
                    marker.title = _selectedPID;
                    marker.snippet = [propData getOwnerNameForPID:_selectedPID];
                    _infoWindow.type = marker.type = MarkerInfoWindowTypePID;
                    break;
            }
            
            [_markerArray addObject:marker];
            
            _infoWindow.center = CGPointMake(marker.center.x, (marker.center.y - 42.0));
            _infoWindow.delegate = self;
            _infoWindow.title = marker.title;
            _infoWindow.snippet = marker.snippet;
            _infoWindow.position = marker.position;
            [self.view addSubview:_infoWindow];
            _noneSelected = NO;
        }
    }
}

- (void)markerButtonWasTapped:(MarkerButton *)marker
{
    [self removePreviousInfoWindow];
    
    if ([marker.title isEqualToString:[_markerArray.lastObject title]] && _noneSelected == NO)
    {
        _selectedPID = _selectedSewerPipe = nil;
        _noneSelected = YES;
    }
    
    else
    {
        [_markerArray removeObject:marker];
        _infoWindow = [[MarkerInfoWindow alloc] init];
        
        switch (marker.type)
        {
            case MarkerInfoWindowTypeStormSewer:
                _selectedSewerPipe = _infoWindow.title = marker.title;
                break;
                
            case MarkerInfoWindowTypePID:
                _selectedPID = _infoWindow.title = marker.title;
                _selectedPIDCoords = marker.position;
                break;
        }
        
        _infoWindow.type = marker.type;
        
        [_markerArray addObject:marker];
        CGPoint target = [_mapView.projection pointForCoordinate:marker.position];
        
        _infoWindow.center = CGPointMake(target.x, (target.y - 42.0));
        _infoWindow.delegate = self;
        _selectedPID = _infoWindow.title = marker.title;
        _infoWindow.snippet = marker.snippet;
        _infoWindow.position = marker.position;
        [self.view addSubview:_infoWindow];
        _noneSelected = NO;
    }
}

- (void)mapViewLongPressed:(UILongPressGestureRecognizer *)gesture
{
    if (gesture.state == UIGestureRecognizerStateBegan ||
        gesture.state == UIGestureRecognizerStateChanged)
    {
        if (gesture.state == UIGestureRecognizerStateBegan)
        {
            _mapView.settings.scrollGestures = NO;
            CRAPI.sharedInstance.showPlats = -1;
            [self clearVectorView];
            _selectedPlatRefno = 0;
            _waitForVectorViewRefresh = YES;
            
            [self refreshVectorView:_mapView.projection.visibleRegion
                             atZoom:_mapView.camera.zoom];
        }
        
        else if (!_waitForVectorViewRefresh)
        {
            CGPoint gesturePoint = [gesture locationInView:self.view];
            CLLocationCoordinate2D gestureLocation = [_mapView.projection coordinateForPoint:gesturePoint];
            SewerData *sewerData = [[SewerData alloc] init];
            LLPOINT llp;
            llp.lat = gestureLocation.latitude;
            llp.lon = gestureLocation.longitude;
            int platRefno = [sewerData pickSanPlat:&llp];
            
            if (platRefno != _selectedPlatRefno)
            {
                _selectedPlatRefno = platRefno;
                _waitForVectorViewRefresh = YES;
                CRAPI.sharedInstance.showPlats = platRefno;
                
               [self refreshVectorView:_mapView.projection.visibleRegion
                                 atZoom:_mapView.camera.zoom];
            }
        }
        
        else if (!_selectedPlatRefno)
        {
            CRAPI.sharedInstance.showPlats = 0;
            [self clearVectorView];
            _waitForVectorViewRefresh = NO;
        }
    }
    
    else if (gesture.state == UIGestureRecognizerStateEnded)
    {
        _mapView.settings.scrollGestures = YES;
        CRAPI.sharedInstance.showPlats = 0;
        [self clearVectorView];
        
        [self refreshVectorView:_mapView.projection.visibleRegion
                         atZoom:_mapView.camera.zoom];
    }
}

- (void)removePreviousInfoWindow
{
    for (UIView *views in self.view.subviews)
    {
        if ([views isKindOfClass:MarkerInfoWindow.class])
            [views removeFromSuperview];
    }
}

- (void)restorePreviousInfoWindow
{
    if (!_noneSelected)
    {
        MarkerButton *marker = _markerArray.lastObject;
        
        if (marker)
        {
            CGPoint target = [_mapView.projection pointForCoordinate:marker.position];
            
            _infoWindow = [[MarkerInfoWindow alloc] init];
            _infoWindow.center = CGPointMake(target.x, (target.y - 42.0));
            _infoWindow.delegate = self;
            _infoWindow.title = marker.title;
            _infoWindow.snippet = marker.snippet;
            _infoWindow.position = marker.position;
            [self.view addSubview:_infoWindow];
            _noneSelected = NO;
        }
    }
}

- (void)mapView:(GMSMapView *)mapView
       willMove:(BOOL)gesture
{
    [self clearVectorView];
    [self.view bringSubviewToFront:_mapToolbar];
    [self.view bringSubviewToFront:_compass];
    
    if (!_tableView.hidden)
        [self.view bringSubviewToFront:_tableView];
    
    if (_firstView.frame.size.height != 0.0)
        [self.view bringSubviewToFront:_firstView];
    
    if (_secondView.frame.size.height != 0.0)
        [self.view bringSubviewToFront:_secondView];
}

- (void)mapView:(GMSMapView *)mapView
didChangeCameraPosition:(GMSCameraPosition *)position
{
    if (position.bearing != 0.0)
    {
        if (_compass.hidden)
        {
            _compass.hidden = NO;
            
            [UIView animateWithDuration:0.25
                             animations:^{
                                 _compass.alpha = 1.0;
                             }];
            
            [self.view bringSubviewToFront:_compass];
        }
        
        _compass.transform = CGAffineTransformMakeRotation(-position.bearing * M_PI / 180);
    }
    
    [self updateMarkerPosition];
}

- (void)updateMarkerPosition
{
    for (MarkerButton *markers in _markerArray)
    {
        CGPoint target = [_mapView.projection pointForCoordinate:markers.position];
        markers.center = target;
    }
    
    MarkerButton *marker = _markerArray.lastObject;
    _infoWindow.center = CGPointMake(marker.center.x, (marker.center.y - 42.0));
}

- (void)mapView:(GMSMapView *)mapView
idleAtCameraPosition:(GMSCameraPosition *)position
{
    if (!_firstTimeMap)
    {
       // if (_allowRefresh && !_mapView.myLocationEnabled)
            if (!_mapView.myLocationEnabled)
        {
            [self refreshVectorView:_mapView.projection.visibleRegion
                             atZoom:position.zoom];
        }
    }
    
    else
        _firstTimeMap = NO;
    
    if (position.bearing == 0.0 && !_compass.hidden)
        [self hideCompass];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    if (!_tableView.hidden)
        [_tableView reloadData];
    
    if (_rotateZoom)
        [_mapView moveCamera:[GMSCameraUpdate zoomBy:0.000001]];
    
    else
        [_mapView moveCamera:[GMSCameraUpdate zoomBy:-0.000001]];
   
    _rotateZoom = !_rotateZoom;
    
    [UIView animateWithDuration:0.25
                     animations:^{
                         _platView.center = CGPointMake((_firstView.frame.size.width / 2.0),
                                                        (_firstView.frame.size.height / 2.0));
                     }];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
                                duration:(NSTimeInterval)duration
{
    [self clearVectorView];
    
    CGFloat statusBarHeight = [self statusBarHeight:toInterfaceOrientation];
    CGFloat compassSize = 48.0, compassMargin = 6.0;
    
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
        compassSize = 36.0, compassMargin = 4.0;
    
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
    
    [UIView animateWithDuration:duration
                     animations:^{
                         _mapToolbar.center = CGPointMake(((self.view.frame.size.height / 2.0) + statusBarHeight),
                                                          (_mapToolbar.frame.size.height / 2.0) + statusBarHeight);
                     }];
    
    if (!_compass.hidden)
        _compass.transform = CGAffineTransformMakeRotation(0.0);
    
    [UIView animateWithDuration:duration
                     animations:^{
                         _compass.frame = CGRectMake((self.view.frame.size.height - compassSize - compassMargin + _tabBarHeight),
                                                     (statusBarHeight + compassMargin), compassSize, compassSize);
                         
                         _compass.alpha = 0.0;
                     } completion:^(BOOL finished) {
                         _compass.transform = CGAffineTransformMakeRotation(_mapView.camera.bearing * M_PI / 180);
                         
                         if (!_compass.hidden)
                             _compass.alpha = 1.0;
                     }];
    
    switch (_screenSetting)
    {
        case MapViewScreenSettingFullscreen:
        {
            [UIView animateWithDuration:duration
                             animations:^{
                                 _mapView.frame = _vectorView.frame =
                                 CGRectMake(0.0, statusBarHeight,
                                            (self.view.frame.size.height + _tabBarHeight),
                                            (self.view.frame.size.width - _tabBarHeight - statusBarHeight));
                                 
                                 [self updateMarkerPosition];
                             }];
        }
            break;
            
        case MapViewScreenSettingSplitScreen:
        {
            [UIView animateWithDuration:duration
                             animations:^{
                                 _mapView.frame = _vectorView.frame =
                                 CGRectMake(0.0, statusBarHeight,
                                            (self.view.frame.size.height + _tabBarHeight),
                                            ((self.view.frame.size.width - _tabBarHeight - statusBarHeight) / 2.0));
                                 
                                 [self updateMarkerPosition];
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
                                 
                                 [self updateMarkerPosition];
                             }];
            
            [UIView animateWithDuration:duration
                             animations:^{
                                 _firstView.frame = frame2;
                             }];
            
            [UIView animateWithDuration:duration
                             animations:^{
                                 _secondView.frame =
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
                                 
                                 [self updateMarkerPosition];
                             }];
            
            [UIView animateWithDuration:duration
                             animations:^{
                                 _firstView.frame = frame3;
                             }];
            
            [UIView animateWithDuration:duration
                             animations:^{
                                 _secondView.frame =
                                 CGRectMake(((self.view.frame.size.height + _tabBarHeight) / 2.0),
                                            statusBarHeight + ((self.view.frame.size.width - _tabBarHeight - statusBarHeight) / 1.5),
                                            ((self.view.frame.size.height + _tabBarHeight) / 2.0),
                                            ((self.view.frame.size.width - _tabBarHeight - statusBarHeight) / 3.0));
                             }];
        }
            break;
    }
}

-(void)allocateVectorView
{
    int ivv;
    for (int i=0;i<MAX_VECTORVIEWS;i++)
    {
        if (!vectorViews[i])
        {
            ivv = i;
            goto haveVV;
        }
    }
    return;
haveVV:
    _vectorView = [[VectorView alloc] init];
    vectorViews[ivv] = _vectorView;
    _vectorView.ivv = ivv;
    _vectorView.frame = _mapView.frame;
    _vectorView.userInteractionEnabled = NO;
    _vectorView.delegate = self;
    [self.view addSubview:_vectorView];

}
- (void)clearVectorView
{
    keepProcessing++;
    if (!_vectorView)
        return;
    _vectorView.displayData = 0;
    [_vectorView removeFromSuperview];
    vectorViews[_vectorView.ivv] = nil;
    _vectorView = nil;
}

- (void)refreshVectorView:(GMSVisibleRegion)region
                   atZoom:(int)zoom
{
    [self clearVectorView];
    [self allocateVectorView];
    _vectorView.displayData = 1;
    
    [_vectorView setRegion:region];
    _vectorView.zoom = zoom;
    
    NSLog(@"Vector view start: zoom = %i", zoom);
    
    [_vectorView setNeedsDisplay];
}

- (void)vectorViewDidComplete:(VectorView*)vectorView
{
    _waitForVectorViewRefresh = NO;
    
    if (vectorView.displayID != keepProcessing)
        vectorViews[vectorView.ivv] = nil;
    else dispatch_async(dispatch_get_main_queue(),
                   ^{
                       [_vectorView removeFromSuperview];
                       [self.view addSubview:_vectorView];
                       [self.view bringSubviewToFront:_vectorView];

                       for (MarkerButton *markers in _markerArray)
                           [self.view bringSubviewToFront:markers];
                       
                       if (_infoWindow)
                           [self.view bringSubviewToFront:_infoWindow];
                       
                       [self.view bringSubviewToFront:_mapToolbar];
                       
                       if (!_tableView.hidden)
                           [self.view bringSubviewToFront:_tableView];
                       
                       if (!_compass.hidden)
                           [self.view bringSubviewToFront:_compass];
                   });
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
        [self showPropReport];
        
        [UserDefaults.defaults saveInteger:PropertyTableViewSettingPropertyReport
                                    forKey:@"PIDOption"];
    }
    
    else if ([[tableView cellForRowAtIndexPath:indexPath].textLabel.text
              isEqualToString:@"Hennepin County Website"])
    {
        [self showHCWebsite];
        
        [UserDefaults.defaults saveInteger:PropertyTableViewSettingHCWebsite
                                    forKey:@"PIDOption"];
    }
    
    else if ([[tableView cellForRowAtIndexPath:indexPath].textLabel.text
              isEqualToString:@"Display Street View"])
    {
        [self showStreetView];
        
        [UserDefaults.defaults saveInteger:PropertyTableViewSettingStreetView
                                    forKey:@"PIDOption"];
    }
    
    else if ([[tableView cellForRowAtIndexPath:indexPath].textLabel.text
              isEqualToString:@"Zoom to Census Area"])
    {
        [self showCensusArea];
        
        [UserDefaults.defaults saveInteger:PropertyTableViewSettingCensusArea
                                    forKey:@"PIDOption"];
    }
    
    else if ([[tableView cellForRowAtIndexPath:indexPath].textLabel.text
              isEqualToString:@"Display Pipe Attributes"])
    {
        [self showPipeAttributes];
        
        [UserDefaults.defaults saveInteger:SewerPipeSettingAttributes
                                    forKey:@"SewerOption"];
    }
    
    else if ([[tableView cellForRowAtIndexPath:indexPath].textLabel.text
              isEqualToString:@"Trace Pipe Upstream"])
    {
        [self dismissTableView];
        
        [self performSelector:@selector(showPipeTraceUpstream)
                   withObject:nil
                   afterDelay:0.3];
        
        [UserDefaults.defaults saveInteger:SewerPipeSettingTraceUp
                                    forKey:@"SewerOption"];
    }
    
    else if ([[tableView cellForRowAtIndexPath:indexPath].textLabel.text
              isEqualToString:@"Trace Pipe Downstream"])
    {
        [self dismissTableView];
        
        [self performSelector:@selector(showPipeTraceDownstream)
                   withObject:nil
                   afterDelay:0.3];
        
        [UserDefaults.defaults saveInteger:SewerPipeSettingTraceDown
                                    forKey:@"SewerOption"];
    }
    
    else if ([[tableView cellForRowAtIndexPath:indexPath].textLabel.text
              isEqualToString:@"Remove Pipe Trace"])
    {
        [self dismissTableView];
        
        [self performSelector:@selector(removePipeTrace)
                   withObject:nil
                   afterDelay:0.3];
    }
    
    else if ([[tableView cellForRowAtIndexPath:indexPath].textLabel.text
              isEqualToString:@"Remove Property Marker"] ||
             [[tableView cellForRowAtIndexPath:indexPath].textLabel.text
              isEqualToString:@"Remove Pipe Marker"])
    {
        [self dismissTableView];
        
        [self performSelector:@selector(removeMarker)
                   withObject:nil
                   afterDelay:0.3];
    }
}

- (void)showPropReport
{
    _tableViewSetting = PropertyTableViewSettingPropertyReport;
    
    PropertyData *propData = [[PropertyData alloc] init];
    
    _propertyReport = [propData getReport:PDSettingDefault
                                   forPID:_selectedPID];
    
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableView.allowsSelection = NO;
    _tableView.delaysContentTouches = YES;
    
    [_tableView reloadData];
    
    [_tableView scrollRectToVisible:CGRectMake(0.0, 0.0, 1.0, 1.0)
                           animated:NO];
}

- (void)showHCWebsite
{
    WebKitViewController *wkvc = [[WebKitViewController alloc] initWithPID:
                                  [UserDefaults.defaults removePIDPrefix:_selectedPID]];
    
    [self presentViewController:wkvc
                       animated:YES
                     completion:nil];
}

- (void)showStreetView
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

- (void)showCensusArea
{
    [_gssiAlert showAlertWithTitle:@"Zoom to Census Area"
                           message:[NSString stringWithFormat:@"Parcel %@", _selectedPID]
                 cancelButtonTitle:@"Cancel"
                 otherButtonTitles:@[@"Zoom to Block", @"Zoom to BlockGroup", @"Zoom to Tract"]
         destructiveButtonPosition:0];
}

- (void)showPipeAttributes
{
    [self dismissTableView];//this is temporary
    
    //implement pipe attributes here (then reload tableView)
}

- (void)showPipeTraceUpstream
{
    [_popover showAfter:0.0
              withTitle:@"Trace Pipe Upstream"];
    
    dispatch_async(dispatch_queue_create("pipeTraceQueue", NULL),
                   ^{
                       PipeTrace *pipeTrace = [[PipeTrace alloc] init];
                       pipeTrace.delegate = self;
                       pipeTrace.popover = _popover;
                       [pipeTrace tracePipeUpstream:_selectedSewerPipe];
                   });
}

- (void)showPipeTraceDownstream
{
    [_popover showAfter:0.0
              withTitle:@"Trace Pipe Downstream"];
    
    dispatch_async(dispatch_queue_create("pipeTraceQueue", NULL),
                   ^{
                       PipeTrace *pipeTrace = [[PipeTrace alloc] init];
                       pipeTrace.delegate = self;
                       pipeTrace.popover = _popover;
                       [pipeTrace tracePipeDownstream:_selectedSewerPipe];
                   });
}

- (void)removePipeTrace
{
    [PipeTrace removeTrace];
    
    [self refreshVectorView:_mapView.projection.visibleRegion
                     atZoom:_mapView.camera.zoom];

}

- (void)removeMarker
{
    MarkerButton *marker = _markerArray.lastObject;
    CGFloat alpha = _infoWindow.alpha;
    
    [UIView animateWithDuration:0.25
                     animations:^{
                         marker.alpha = 0.0;
                         _infoWindow.alpha = 0.0;
                     }
                     completion:^(BOOL finished){
                         [marker removeFromSuperview];
                         [self removePreviousInfoWindow];
                         _infoWindow.alpha = alpha;
                     }];
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
                         
                         if(!_tableView.hidden)
                             [self.view bringSubviewToFront:_tableView];
                         
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

- (BOOL)isHennepinCountyPID:(NSString *)PID
{
    if (!([PID rangeOfString:@"053-"].location == NSNotFound))
        return YES;
    
    else
        return NO;
}

- (void)platViewDidZoom:(CGFloat)pZoom
            withBearing:(CGFloat)pBearing
                 target:(CLLocationCoordinate2D)pTarget
                 minYpt:(DPOINT)minYpt
                 maxYpt:(DPOINT)maxYpt
{
    [self clearVectorView];
    
     NSLog(@"minY = %f, maxY = %f", minYpt.y, maxYpt.y);
    
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithTarget:pTarget
                                                               zoom:pZoom
                                                            bearing:pBearing
                                                       viewingAngle:0.0];
    
    [_mapView animateToCameraPosition:camera];
}

- (void)platViewDidBeginTrans
{
    [self clearVectorView];

    _allowRefresh = NO;
}

- (void)platViewDidEndTrans
{
    _allowRefresh = YES;
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
    [self extentZoom];
}

- (void)mapToolbarDidSelectUserLocation:(BOOL)enabled
{
    if (enabled)
        [self startTrackingUserLocation];
    
    else
        [self stopTrackingUserLocation:YES];
}

- (void)startTrackingUserLocation
{
    if (CLLocationManager.locationServicesEnabled)
        [_locationManager startUpdatingHeading];
    
    if (CLLocationManager.headingAvailable)
        [_locationManager startUpdatingLocation];
    
    _mapView.myLocationEnabled = YES;
    _mapView.settings.rotateGestures = NO;
    _initialZoom = YES;
}

- (void)stopTrackingUserLocation:(BOOL)refresh
{
    [_locationManager stopUpdatingLocation];
    [_locationManager stopUpdatingHeading];
    _mapView.myLocationEnabled = NO;
    _mapView.settings.rotateGestures = YES;
    [_mapToolbar deselectMyLocationButton];
    
    if (refresh)
    {
        [self refreshVectorView:_mapView.projection.visibleRegion
                         atZoom:_mapView.camera.zoom];
    }
}

- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray *)locations
{
    [_mapView animateToLocation:[locations.firstObject coordinate]];
    
    if (_initialZoom)
    {
        [_mapView animateToZoom:20.0];
        _initialZoom = NO;
    }
}

- (void)locationManager:(CLLocationManager *)manager
       didUpdateHeading:(CLHeading *)newHeading
{
    [_mapView animateToBearing:newHeading.trueHeading];
}

- (void)mapToolbarDidSelectAnnotationOption:(BOOL)option
{
    if (option)
        _clearAnnotations = NO;
    
    else
    {
        for (MarkerButton *markers in _markerArray)
            [markers removeFromSuperview];
        
        [_markerArray removeAllObjects];
        [self removePreviousInfoWindow];
        _clearAnnotations = YES;
    }
}

- (void)mapToolbarDidSelectMapType:(NSInteger)mapType
{
    switch (mapType)
    {
        case MapTypeSettingStandard:
            _mapView.mapType = kGMSTypeNormal;
            break;
            
        case MapTypeSettingHybrid:
            _mapView.mapType = kGMSTypeHybrid;
            break;
    }
}

- (void)mapToolbarDidSelectSplitScreenSetting:(NSInteger)setting
{
    _allowRefresh = NO;
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
    
    CGRect frame4 = CGRectMake(0.0,
                               (statusBarHeight + ((tabBarTop - statusBarHeight) / 1.5)),
                               self.view.frame.size.width,
                               ((tabBarTop - statusBarHeight) / 3.0));
    
    //this is the frame for the bottom right of the split bottom
    /*CGRect frame5 = CGRectMake((self.view.frame.size.width / 2.0),
                               (statusBarHeight + ((tabBarTop - statusBarHeight) / 1.5)),
                               (self.view.frame.size.width / 2.0),
                               ((tabBarTop - statusBarHeight) / 3.0));*/
    
    if (![_firstView.subviews containsObject:_platView])
    {
        if (setting != MapViewScreenSettingFullscreen)
            _platView = [PlatImageView platImageViewWithDelegate:self];
        
        switch (setting)
        {
            case MapViewScreenSettingSplitScreen:
                _platView.frame = CGRectMake(0.0, 0.0, frame1.size.width, frame1.size.height);
                break;
                
            case MapViewScreenSettingTriScreen:
                _platView.frame = CGRectMake(0.0, 0.0, frame2.size.width, frame2.size.height);
                break;
                
            case MapViewScreenSettingSplitBottomScreen:
                _platView.frame = CGRectMake(0.0, 0.0, frame3.size.width, frame3.size.height);
                break;
        }
    }
    
    if (setting == MapViewScreenSettingTriScreen)
            _profileView.frame = CGRectMake(0.0, 0.0, frame4.size.width, frame4.size.height);
        
        else
        {
            [_profileView removeFromSuperview];
            _profileView.image = nil;
        }
    
    [self clearVectorView];
    
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
                                 
                                 [self updateMarkerPosition];
                             }
                             completion:^(BOOL finished) {
                                 [self refreshVectorView:_mapView.projection.visibleRegion
                                                  atZoom:_mapView.camera.zoom];
                             }];
            
            [UIView animateWithDuration:0.25
                             animations:^{
                                 _firstView.frame = _secondView.frame = frame0;
                             }
                             completion:^(BOOL finished) {
                                 [_platView removeFromSuperview];
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
                                 
                                 [self updateMarkerPosition];
                             }
                             completion:^(BOOL finished) {
                                 [self refreshVectorView:_mapView.projection.visibleRegion
                                                  atZoom:_mapView.camera.zoom];
                             }];
            
            [UIView animateWithDuration:0.25
                             animations:^{
                                 _firstView.frame = frame1;
                             }];
            
            [UIView animateWithDuration:0.25
                             animations:^{
                                 _secondView.frame = frame0;
                             }];
            
            switch (_screenSetting)
            {
                case MapViewScreenSettingFullscreen:
                    [self performSelector:@selector(addPlatView)
                               withObject:nil
                               afterDelay:0.3];
                    break;
                    
                case MapViewScreenSettingTriScreen:
                {
                    [UIView animateWithDuration:0.25
                                     animations:^{
                                         [self platViewPosition:platViewCenter
                                                     fromFrame1:frame2
                                                       toFrame2:frame1];
                                     }];
                }
                    break;
                    
                case MapViewScreenSettingSplitBottomScreen:
                {
                    [UIView animateWithDuration:0.25
                                     animations:^{
                                         [self platViewPosition:platViewCenter
                                                     fromFrame1:frame3
                                                       toFrame2:frame1];
                                     }];
                }
                    break;
            }
            
            _screenSetting = MapViewScreenSettingSplitScreen;
        }
            break;
            
        case MapViewScreenSettingTriScreen:
        {
            [UIView animateWithDuration:0.25
                             animations:^{
                                 _mapView.layer.borderWidth = _splitScreenBorderWidth;
                                 
                                 _mapView.frame = _vectorView.frame =
                                 CGRectMake(0.0,
                                            statusBarHeight,
                                            self.view.frame.size.width,
                                            ((tabBarTop - statusBarHeight) / 3.0));
                                 
                                 [self updateMarkerPosition];
                             }
                             completion:^(BOOL finished) {
                                 [self refreshVectorView:_mapView.projection.visibleRegion
                                                  atZoom:_mapView.camera.zoom];
                             }];
            
            [UIView animateWithDuration:0.25
                             animations:^{
                                 _firstView.frame = frame2;
                             }];
            
            [UIView animateWithDuration:0.25
                             animations:^{
                                 _secondView.frame =
                                 CGRectMake(0.0,
                                            (statusBarHeight + ((tabBarTop - statusBarHeight) / 1.5)),
                                            self.view.frame.size.width,
                                            ((tabBarTop - statusBarHeight) / 3.0));
                             }];
            
            switch (_screenSetting)
            {
                case MapViewScreenSettingFullscreen:
                    [self performSelector:@selector(addPlatView)
                               withObject:nil
                               afterDelay:0.3];
                    break;
                    
                case MapViewScreenSettingSplitScreen:
                {
                    [UIView animateWithDuration:0.25
                                     animations:^{
                                         [self platViewPosition:platViewCenter
                                                     fromFrame1:frame1
                                                       toFrame2:frame2];
                                     }];
                }
                    break;
                    
                case MapViewScreenSettingSplitBottomScreen:
                {
                    [UIView animateWithDuration:0.25
                                     animations:^{
                                         [self platViewPosition:platViewCenter
                                                     fromFrame1:frame3
                                                       toFrame2:frame2];
                                     }];
                }
                    break;
            }
            
            _screenSetting = MapViewScreenSettingTriScreen;
        }
            break;
            
        case MapViewScreenSettingSplitBottomScreen:
        {
            [UIView animateWithDuration:0.25
                             animations:^{
                                 _mapView.layer.borderWidth = _splitScreenBorderWidth;
                                 
                                 _mapView.frame = _vectorView.frame =
                                 CGRectMake(0.0,
                                            statusBarHeight,
                                            self.view.frame.size.width,
                                            ((tabBarTop - statusBarHeight) / 1.5));
                                 
                                 [self updateMarkerPosition];
                             }
                             completion:^(BOOL finished) {
                                 [self refreshVectorView:_mapView.projection.visibleRegion
                                                  atZoom:_mapView.camera.zoom];
                             }];
            
            [UIView animateWithDuration:0.25
                             animations:^{
                                 _firstView.frame = frame3;
                             }];
            
            [UIView animateWithDuration:0.25
                             animations:^{
                                 _secondView.frame =
                                 CGRectMake((self.view.frame.size.width / 2.0),
                                            (statusBarHeight + ((tabBarTop - statusBarHeight) / 1.5)),
                                            (self.view.frame.size.width / 2.0),
                                            ((tabBarTop - statusBarHeight) / 3.0));
                             }];
            
            switch (_screenSetting)
            {
                case MapViewScreenSettingFullscreen:
                    [self performSelector:@selector(addPlatView)
                               withObject:nil
                               afterDelay:0.3];
                    break;
                    
                case MapViewScreenSettingTriScreen:
                {
                    [UIView animateWithDuration:0.25
                                     animations:^{
                                         [self platViewPosition:platViewCenter
                                                     fromFrame1:frame2
                                                       toFrame2:frame3];
                                     }];
                }
                    break;
                    
                case MapViewScreenSettingSplitScreen:
                {
                    [UIView animateWithDuration:0.25
                                     animations:^{
                                         [self platViewPosition:platViewCenter
                                                     fromFrame1:frame1
                                                       toFrame2:frame3];
                                     }];
                }
                    break;
            }
            
            _screenSetting = MapViewScreenSettingSplitBottomScreen;
        }
            break;
    }
}

- (void)addPlatView
{
    [_firstView addSubview:_platView];
    _platView.originalSize = _firstView.frame.size;
    
    if (_screenSetting == MapViewScreenSettingTriScreen)
        [self addProfileView];
    
    [self syncPlatView];
}

- (void)addProfileView
{
    _profileView.image = _platView.image;
    [_secondView addSubview:_profileView];
}

- (void)platViewPosition:(CGPoint)center
              fromFrame1:(CGRect)frame1
                toFrame2:(CGRect)frame2
{
    _platView.center = CGPointMake(center.x - ((frame1.size.width - frame2.size.width) / 2.0),
                                   center.y - ((frame1.size.height - frame2.size.height) / 2.0));
    
    if (_screenSetting == MapViewScreenSettingTriScreen)
        [self addProfileView];
    
    [self syncPlatView];
}

- (void)syncPlatView
{
    CGFloat pBearing;
    CLLocationCoordinate2D pTarget;
    DPOINT minYpt, maxYpt;
    
    CGFloat pZoom = [_platView zoomForMapBounds:_platView.frame
                                        bearing:&pBearing
                                         target:&pTarget
                                    mapViewSize:_mapView.frame.size
                                         minYpt:&minYpt
                                         maxYpt:&maxYpt];
    
    NSLog(@"minY = %f, maxY = %f", minYpt.y, maxYpt.y);
    
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithTarget:pTarget
                                                               zoom:pZoom
                                                            bearing:pBearing
                                                       viewingAngle:0.0];
    
    [_mapView animateToCameraPosition:camera];
    _allowRefresh = YES;
}

- (void)mapToolbarDidFinishDrag
{
    if (_mapToolbar.center.y < (self.view.frame.size.height * 0.25))
    {
        [UIView animateWithDuration:0.25
                         animations:^{
                             [_mapToolbar animateToHorizontalOrientation];
                             
                             _mapToolbar.center = CGPointMake((self.view.frame.size.width / 2.0),
                                                              (_mapToolbar.frame.size.height / 2.0) +
                                                              [self statusBarHeight:self.interfaceOrientation]);
                         }];
        
        _mapToolbar.orientation = MapToolbarOrientationTop;
    }
    
    else if (_mapToolbar.center.y > (self.view.frame.size.height * 0.75))
    {
        [UIView animateWithDuration:0.25
                         animations:^{
                             [_mapToolbar animateToHorizontalOrientation];
                             
                             _mapToolbar.center = CGPointMake((self.view.frame.size.width / 2.0),
                                                              (self.view.frame.size.height -
                                                               (_mapToolbar.frame.size.height / 2.0)));
                         }];
        
        _mapToolbar.orientation = MapToolbarOrientationBottom;
    }
    
    else if (_mapToolbar.center.x < (self.view.frame.size.width / 2.0))
    {
        [UIView animateWithDuration:0.25
                         animations:^{
                             [_mapToolbar animateToVerticalOrientation];
                             
                             _mapToolbar.center = CGPointMake((_mapToolbar.frame.size.width / 2.0),
                                                              (self.view.frame.size.height / 2.0));
                         }];
        
        _mapToolbar.orientation = MapToolbarOrientationLeft;
    }
    
    else if (_mapToolbar.center.x > (self.view.frame.size.width / 2.0))
    {
        [UIView animateWithDuration:0.25
                         animations:^{
                             [_mapToolbar animateToVerticalOrientation];
                             
                             _mapToolbar.center = CGPointMake(self.view.frame.size.width -
                                                              (_mapToolbar.frame.size.width / 2.0),
                                                              (self.view.frame.size.height / 2.0));
                         }];
        
        _mapToolbar.orientation = MapToolbarOrientationRight;
    }
    
    [self.view bringSubviewToFront:_mapToolbar];
}

- (void)markerInfoWindowDidSelectOptions:(NSString *)title
                                  coords:(CLLocationCoordinate2D)coords
                                    type:(NSInteger)type
{
    switch (type)
    {
        case MarkerInfoWindowTypePID:
            _selectedPID = title;
            _selectedPIDCoords = coords;
            
            if ([self isHennepinCountyPID:_selectedPID])
            {
                _options = @[@"Property Report", @"Hennepin County Website", @"Rankings",
                             @"Computed Values", @"Display Street View", @"Zoom to Census Area", @"Remove Property Marker"];
            }
            
            else
            {
                _options = @[@"Property Report", @"Rankings", @"Computed Values",
                             @"Display Street View", @"Zoom to Census Area", @"Remove Property Marker"];
            }
            
            break;
            
        case MarkerInfoWindowTypeStormSewer:
            _selectedSewerPipe = title;
            
            _options = @[@"Display Pipe Attributes", @"Trace Pipe Upstream",
                         @"Trace Pipe Downstream", @"Remove Pipe Trace", @"Remove Pipe Marker"];
            
            break;
    }
    
    _tableViewSetting = PropertyTableViewSettingOptions;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    _tableView.allowsSelection = YES;
    _tableView.delaysContentTouches = NO;
    [_tableView reloadData];
    [self presentTableView];
}

- (void)markerInfoWindowDidSelectPropReport:(NSString *)title
                                     coords:(CLLocationCoordinate2D)coords
                                       type:(NSInteger)type
{
    NSInteger option;
    
    switch (type)
    {
        case MarkerInfoWindowTypePID:
        {
            _selectedPID = title;
            option = [UserDefaults.defaults integerForKey:@"PIDOption"];
            
            if (option == PropertyTableViewSettingDefault)
                option = PropertyTableViewSettingPropertyReport;
            
            switch (option)
            {
                case PropertyTableViewSettingPropertyReport:
                    [self presentTableView];
                    [self showPropReport];
                    break;
                    
                case PropertyTableViewSettingHCWebsite:
                    [self showHCWebsite];
                    break;
                    
                case PropertyTableViewSettingStreetView:
                    _selectedPIDCoords = coords;
                    [self showStreetView];
                    break;
                    
                case PropertyTableViewSettingCensusArea:
                    [self showCensusArea];
                    break;
            }
        }
            break;
            
        case MarkerInfoWindowTypeStormSewer:
        {
            _selectedSewerPipe = title;
            option = [UserDefaults.defaults integerForKey:@"SewerOption"];
            
            if (option == PropertyTableViewSettingDefault)
                option = SewerPipeSettingTraceDown;
            
            switch (option)
            {
                case SewerPipeSettingAttributes:
                    [self showPipeAttributes];
                    break;
                    
                case SewerPipeSettingTraceUp:
                    [self showPipeTraceUpstream];
                    break;
                    
                case SewerPipeSettingTraceDown:
                    [self showPipeTraceDownstream];
                    break;
            }
        }
            break;
    }
}

- (void)markerInfoWindowWasSwiped
{
    [self removePreviousInfoWindow];
    _noneSelected = YES;
}

- (void)presentTableView
{
    if (_tableView.hidden)
    {
        CGRect frame = _tableView.frame;
        _tableView.frame = CGRectMake(self.view.center.x, self.view.center.y, 0.0, 0.0);
        _tableView.hidden = NO;
        [self.view bringSubviewToFront:_tableView];
        
        [UIView animateWithDuration:0.25
                         animations:^{
                             _tableView.frame = frame;
                         }];
    }
}

- (void)compassTapped:(UIButton *)button
{
    if (_mapView.myLocationEnabled)
        [self stopTrackingUserLocation:NO];
    
    [_mapView animateToBearing:0.0];
}

- (void)hideCompass
{
    [UIView animateWithDuration:0.25
                     animations:^{
                         _compass.alpha = 0.0;
                     } completion:^(BOOL finished) {
                         _compass.hidden = YES;
                     }];
}

@end