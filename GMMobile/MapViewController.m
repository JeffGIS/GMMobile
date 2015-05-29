//  MapViewController.m
//  GMMobile

extern int keepProcessing;

#import "MapViewController.h"
#import "WebKitViewController.h"
#import "AppDelegate.h"
#import "ConfigurationControl.h"

#define MAX_VECTORVIEWS 8

typedef NS_ENUM(NSInteger, PropertyTableViewSetting)
{
    PropertyTableViewSettingDefault,
    PropertyTableViewSettingOptions,
    PropertyTableViewSettingPropertyReport,
    PropertyTableViewSettingHCWebsite,
    PropertyTableViewSettingStreetView,
    PropertyTableViewSettingCensusArea,
    PropertyTableViewSettingPropList,
    PropertyTableViewSettingDestinations,
};

typedef NS_ENUM(NSInteger, CensusZoomSetting)
{
    CensusZoomSettingCancel,
    CensusZoomSettingBlock,
    CensusZoomSettingBlockGroup,
    CensusZoomSettingTract,
};

typedef NS_ENUM(NSInteger, SewerPipeSetting)
{
    SewerPipeSettingDefault,
    SewerPipeSettingAttributes,
    SewerPipeSettingTraceUp,
    SewerPipeSettingTraceDown,
    SewerPipeSettingRemoveTrace,
    SewerPipeSettingUpdateCleanDate,
    SewerPipeSettingUpdateNotes,
};

typedef NS_ENUM(NSInteger, CustomSetting)
{
    CustomSettingDefault,
    CustomSettingSnapToNode,
    CustomSettingSnapToLine,
};

typedef NS_ENUM(NSInteger, AlleyWallSetting)
{
    AlleyWallSettingDefault,
    AlleyWallSettingMoveWallPoint,
    AlleyWallSettingDeleteWallPoint,
    AlleyWallSettingEditWallAttributes,
    AlleyWallSettingViewWallPhotos,
};

typedef NS_ENUM(NSInteger, AlleyLineSetting)
{
    AlleyLineSettingDefault,
    AlleyLineSettingToggleCompletionStatus,
};

typedef NS_ENUM(NSInteger, MapTypeSetting)
{
    MapTypeSettingStandard,
    MapTypeSettingHybrid,
};

typedef NS_ENUM(NSInteger, DigitizationMode)
{
    DigitizationModeCustom,
    DigitizationModeAlleyWallNew,
    DigitizationModeAlleyWallMove,
    DigitizationModeSewer,
    DigitizationModeProperty,
    DigitizationModeCurbRamps,
};

typedef NS_ENUM(NSInteger, AlleyStatusSetting)
{
    AlleyStatusSettingDefault,
    AlleyStatusSettingCenterline,
    AlleyStatusSettingWall,
};


@interface MapViewController ()

@property (nonatomic) CLLocationCoordinate2D target, selectedPIDCoords;
@property (nonatomic) NSArray *options;
@property (nonatomic) NSMutableArray *propertyReport, *markerArray;
@property PropertyTableViewSetting tableViewSetting;
@property (nonatomic) CGFloat screenSize;
@property (nonatomic) UIColor *tableViewBackgroundColor;
@property BOOL clearMarkers, clearWhenDeselected, initialZoom, rotateZoom;
@property BOOL firstTimeAppear, firstTimeMap, noneSelected, moveDigitizer;
@property (nonatomic, copy) NSString *selectedPID;
@property (nonatomic, copy) NSString *selectedPlat;
@property (nonatomic) int selectedPlatRefno, nVectorViews;
@property (nonatomic) CGFloat vectorViewZoom;
@property (nonatomic) CGFloat currentScreenHeight, splitScreenBorderWidth, tabBarHeight;
@property (nonatomic) CGFloat heading, pitch, fov;
@property (nonatomic) VectorView *vectorView;
@property (nonatomic) NSTimer *vectorViewTimer;
@property (nonatomic) UIImageView *streetView, *targetView, *digitizerTargetView;
@property (nonatomic) UIView *firstView, *secondView;
@property MapViewScreenSetting screenSetting;
@property (nonatomic) NSInteger gestureCount, digitizerCount;
@property (nonatomic) GSSiAlertController *gssiAlert;
@property (nonatomic) MapToolbar *mapToolbar;
@property (nonatomic) GMSMapView *mapView;
@property (nonatomic) CLLocationManager *locationManager;
@property (nonatomic) MarkerInfoWindow *infoWindow;
@property (nonatomic) GSSiPopoverView *popover;
@property (nonatomic, copy) NSString *selectedSewerPipe, *selectedAlleyWall, *selectedAlleySeg;
@property (nonatomic) NSInteger selectedSewerPipeRefno, selectedAlleyWallRefno, selectedAlleyLineRefno;
@property BOOL waitForVectorViewRefresh, inDigitizationMode, helpButtonMoved;
@property (nonatomic) GMSTileLayer *layer_jpeg;
@property (nonatomic) GMSTileLayer *layer_png;
@property (nonatomic) UIButton *compass;
@property (nonatomic) PlatImageView *platView;
@property (nonatomic) PlatProfileView *profileView;
@property (nonatomic) CGPoint digitizingTargetOffset;
@property (nonatomic) UIImage *blackCrosshairs, *orangeCrosshairs;
@property (nonatomic) UIView *digitizationToolbar;
@property (nonatomic) UIButton *cancelDigitizerButton, *saveDigitizerButton, *undoDigitizerButton;
@property DigitizationMode digitizationMode;
@property AlleyStatusSetting alleyStatusSetting;


@end

@implementation MapViewController
{
    VectorView *vectorViews[MAX_VECTORVIEWS];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(becameActive:)
                                               name:@"didBecomeActive"
                                             object:nil];
    
    _nVectorViews = 0;
    
    for (int i = 0; i < MAX_VECTORVIEWS; i++)
        vectorViews[i] = nil;
    
    [PipeTrace removeTrace];
    
    _firstTimeAppear = _firstTimeMap = YES;
    _digitizationMode = DigitizationModeCustom;
    
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
    
    _targetView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, 60.0, 60.0)];
    
    _targetView.image = [UIImage imageWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"redTarget"
                                                                                       ofType:@"png"]];
    
    _targetView.hidden = YES;
    [_mapView addSubview:_targetView];
    
    _blackCrosshairs = [UIImage imageWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"blackCrosshairs"
                                                                                      ofType:@"png"]];
    
    _orangeCrosshairs = [UIImage imageWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"blackOrangeCrosshairs"
                                                                                       ofType:@"png"]];
    
    _digitizerTargetView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, 120.0, 120.0)];
    
    CGPoint targetPoint = [_mapView.projection pointForCoordinate:_mapView.camera.target];
    
    _digitizerTargetView.center = CGPointMake(targetPoint.x,
                                              (targetPoint.y + [self statusBarHeight:self.interfaceOrientation]));
    
    _digitizerTargetView.image = _blackCrosshairs;
    [self.view addSubview:_digitizerTargetView];
    
    _digitizationToolbar = [[UIView alloc] initWithFrame:CGRectMake(_mapView.frame.origin.x,
                                                                    _mapView.frame.origin.y,
                                                                    _mapView.frame.size.width, 80.0)];
    
    _digitizationToolbar.backgroundColor = UserDefaults.defaults.appleBlue;
    _digitizationToolbar.layer.borderColor = UIColor.darkGrayColor.CGColor;
    _digitizationToolbar.layer.borderWidth = 1.0;
    _digitizationToolbar.alpha = 0.0;
    _digitizationToolbar.hidden = YES;
    [self.view addSubview:_digitizationToolbar];
    
    _cancelDigitizerButton = [[UIButton alloc] initWithFrame:CGRectMake((_digitizationToolbar.frame.size.width * 0.1), 0.0,
                                                                        (_digitizationToolbar.frame.size.width * 0.8),
                                                                        _digitizationToolbar.frame.size.height)];
    
    [self setupDigitizerToolbarButton:_cancelDigitizerButton
                             selector:@selector(cancelDigitizationMode:)
                                title:@"Cancel Move/Add Mode"];
    
    //save button on left side
    /*_saveDigitizerButton = [[UIButton alloc] initWithFrame:CGRectMake((_digitizationToolbar.frame.size.width * 0.05), 0.0,
                                                                      (_digitizationToolbar.frame.size.width * 0.35),
                                                                      _digitizationToolbar.frame.size.height)];*/
    
    //save button in middle
    _saveDigitizerButton = [[UIButton alloc] initWithFrame:CGRectMake((_digitizationToolbar.frame.size.width * 0.1), 0.0,
                                                                      (_digitizationToolbar.frame.size.width * 0.8),
                                                                      _digitizationToolbar.frame.size.height)];
    
    //"Save Digitization" title
    /*[self setupDigitizerToolbarButton:_saveDigitizerButton
                             selector:@selector(saveDigitizationMode:)
                                title:@"Save Digitization"];*/
    
    
    [self setupDigitizerToolbarButton:_saveDigitizerButton
                             selector:@selector(saveDigitizationMode:)
                                title:@"Exit Move/Add Mode"];
    
    //undo button on right side
    /*_undoDigitizerButton = [[UIButton alloc] initWithFrame:CGRectMake((_digitizationToolbar.frame.size.width * 0.6), 0.0,
                                                                      (_digitizationToolbar.frame.size.width * 0.35),
                                                                      _digitizationToolbar.frame.size.height)];

    [self setupDigitizerToolbarButton:_undoDigitizerButton
                             selector:@selector(undoDigitizationMode:)
                                title:@"Undo Digitization"];*/
    
    _saveDigitizerButton.alpha = /*_undoDigitizerButton.alpha =*/ 0.0;
    
    UIImage *compassImage = [UIImage imageWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"compass"
                                                                                           ofType:@"png"]];
    
    CGFloat compassSize = 48.0, compassMargin = 6.0;
    CGFloat helpButtonSize = 56.0, helpButtonMargin = 8.0;
    
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
    {
        compassSize = 36.0, compassMargin = 4.0;
        helpButtonSize = 40.0, helpButtonMargin = 4.0;
    }
    
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
    
    GMSTileURLConstructor constructor_jpeg = ^(NSUInteger x, NSUInteger y, NSUInteger zoom) {
        NSString *url = [NSString stringWithFormat:@"http://gssidata.com/MPLSADA/%lu/%lu/%lu.jp2",
                         (unsigned long)zoom, (unsigned long)y, (unsigned long)x];
        
        return [NSURL URLWithString:url];
    };
    
    GMSTileURLConstructor constructor_png = ^(NSUInteger x, NSUInteger y, NSUInteger zoom) {
        NSString *url = [NSString stringWithFormat:@"http://gssidata.com/MPLSADA/%lu/%lu/%lu.png",
                         (unsigned long)zoom, (unsigned long)y, (unsigned long)x];
        
        return [NSURL URLWithString:url];
    };
    
    _layer_jpeg = [GMSURLTileLayer tileLayerWithURLConstructor:constructor_jpeg];
    //[_layer_jpeg clearTileCache];
    
    _layer_png = [GMSURLTileLayer tileLayerWithURLConstructor:constructor_png];
    //[_layer_png clearTileCache];
    
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
    
    CGPoint mapToolbarCenter = CGPointMake((self.view.frame.size.width / 2.0),
                                           (_mapToolbar.frame.size.height / 2.0) + statusBarHeight);
    
    _mapToolbar = [MapToolbar showMapToolbarWithCenter:mapToolbarCenter
                                                  view:self.view
                                              delegate:self];
    
    AppDelegate *sharedAppDelegate = UIApplication.sharedApplication.delegate;
    sharedAppDelegate.mapToolbar = _mapToolbar;
    
    
    NSInteger config = [UserDefaults.defaults integerForKey:@"CurrentConfig"];
    [ConfigurationControl.sharedInstance setApp:config];

    HelpButton *helpButton = [HelpButton showHelpButtonWithOrigin:
                              CGPointMake(helpButtonMargin, (helpButtonMargin +
                                           [self statusBarHeight:self.interfaceOrientation]))
                                                             size:helpButtonSize
                                                             view:self.view
                                                              tag:HelpButtonPresenterMapVC
                                                           tabBar:self.tabBarController.tabBar];
#pragma unused(helpButton)
    
    
}

- (void)becameActive:(id)selector
{
    if (CRAPI.sharedInstance.setToAlleyWalls)
    {
        [UserDefaults.defaults saveNSInteger:HCConfigAlleyWalls
                                      forKey:@"CurrentConfig"];
        
        [ConfigurationControl.sharedInstance setApp:HCConfigAlleyWalls];
        CRAPI.sharedInstance.setToAlleyWalls = NO;
        
        [self refreshVectorView:_mapView.projection.visibleRegion
                         atZoom:_mapView.camera.zoom];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (ConfigurationControl.sharedInstance.currentApp != HCConfigAlleyWallStatus)
    {
        for (NVLegendView *legendView in self.view.subviews)
        {
            if ([legendView isKindOfClass:NVLegendView.class])
            {
                [legendView hideLegendView:NO];
                
                if (_helpButtonMoved)
                {
                    for (HelpButton *helpButton in self.view.subviews)
                    {
                        if ([helpButton isKindOfClass:HelpButton.class])
                        {
                            helpButton.center =
                            CGPointMake(helpButton.center.x, helpButton.center.y -
                                        legendView.frame.size.height);
                            
                            _helpButtonMoved = NO;
                        }
                    }
                }
            }
        }
    }
    
    for (HelpWebView *helpWebView in self.view.subviews)
    {
        if ([helpWebView isKindOfClass:HelpWebView.class])
            [self.view bringSubviewToFront:helpWebView];
    }
    
    if (_inDigitizationMode)
    {
        _digitizerTargetView.hidden = NO;
        _digitizerTargetView.alpha = 1.0;
    }
    
    else
    {
        _digitizerTargetView.hidden = YES;
        _digitizerTargetView.alpha = 0.0;
    }
    
    if (!_firstTimeAppear)
        [self initTableView];
    
    if (CRAPI.sharedInstance.GMMSetting == GMMSettingPID ||
        CRAPI.sharedInstance.GMMSetting == GMMSettingAddress ||
        CRAPI.sharedInstance.GMMSetting == GMMSettingPropOwner)
    {
        GMSCameraPosition *camera;
        
        _tableView.hidden = YES;
        
        for (GSSiDatePicker *datePicker in self.view.subviews)
        {
            if ([datePicker isKindOfClass:GSSiDatePicker.class])
                [datePicker hideDatePicker:NO];
        }
        
        for (GSSiNotesView *notesView in self.view.subviews)
        {
            if ([notesView isKindOfClass:GSSiNotesView.class])
                [notesView hideNotesView:NO];
        }
        
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
        
        if (_clearMarkers)
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
                                                statusBarHeight:[self statusBarHeight:self.interfaceOrientation]
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
        
        [self.view addSubview:_infoWindow];
        _noneSelected = NO;
        
        CRAPI.sharedInstance.GMMSetting = GMMSettingDefault;
    }
    
    else if (CRAPI.sharedInstance.GMMSetting == GMMSettingBoundaries)
    {
        [self extentZoom];
        CRAPI.sharedInstance.GMMSetting = GMMSettingDefault;
    }
    
    CRAPI.sharedInstance.currentZoom = _mapView.camera.zoom;

    [_mapToolbar configure:_screenSetting];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (_firstTimeAppear)
    {
        CGFloat statusBarHeight = [self statusBarHeight:self.interfaceOrientation];
        CGFloat tabBarTop = self.tabBarController.tabBar.frame.origin.y;
        
        _mapView.frame = CGRectMake(0.0, statusBarHeight,
                                    self.view.frame.size.width,
                                    (tabBarTop - statusBarHeight));
        
        _mapToolbar.center = CGPointMake((self.view.frame.size.width / 2.0),
                                         (_mapToolbar.frame.size.height / 2.0) + statusBarHeight);
        
        _firstTimeAppear = NO;
    }
    
    else
    {
        [self refreshVectorView:_mapView.projection.visibleRegion
                         atZoom:_mapView.camera.zoom];
    }
    
    CRAPI.sharedInstance.currentZoom = _mapView.camera.zoom;
    
    NSString *organizationName = [SharedDefaults.defaults stringForKey:@"OrganizationName"];
    NSString *deviceNumber = [SharedDefaults.defaults stringForKey:@"DeviceNumber"];
    
    if (!organizationName || !deviceNumber ||
        [organizationName isEqualToString:@""] ||
        [deviceNumber isEqualToString:@""])
    {
        NVTwoTextAlert *textAlert = [NVTwoTextAlert showTwoTextAlertInView:self.view
                                                                  delegate:self
                                                                     title:@"Please set your Organization Name and Device Number"
                                                            topPlaceholder:@"Organization Name"
                                                         bottomPlaceholder:@"Device Number"];
#pragma unused(textAlert)
    }
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

- (void)setupDigitizerToolbarButton:(UIButton *)button
                           selector:(SEL)selector
                              title:(NSString *)title
{
    button.backgroundColor = UIColor.clearColor;
    button.titleLabel.font = [UIFont boldSystemFontOfSize:48.0];
    button.titleLabel.textAlignment = NSTextAlignmentCenter;
    button.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    button.titleLabel.layer.shadowColor = UIColor.blackColor.CGColor;
    button.titleLabel.layer.shadowOffset = CGSizeZero;
    button.titleLabel.layer.shadowOpacity = 1.0;
    button.titleLabel.layer.shadowRadius = 4.0;
    
    [button setTitleColor:UIColor.whiteColor
                 forState:UIControlStateNormal];
    
    [button setTitleColor:UIColor.redColor
                 forState:UIControlStateHighlighted];
    
    [button setTitle:title
            forState:UIControlStateNormal];
    
    [button addTarget:self
               action:selector
     forControlEvents:UIControlEventTouchUpInside];
    
    [_digitizationToolbar addSubview:button];
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
    if (_inDigitizationMode)
        return;
    
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
        CRAPI.sharedInstance.currentZoom = _mapView.camera.zoom;
        
        NSMutableArray *highlightList = [[NSMutableArray alloc] init];
        PropertyData *propData = [[PropertyData alloc] init];
        SewerData *sewerData = [[SewerData alloc] init];
        PlanimetricData *planData = [[PlanimetricData alloc] init];
        
        sewerData.zoom = _mapView.camera.zoom;
        propData.zoom = _mapView.camera.zoom;
        planData.zoom = _mapView.camera.zoom;
        
        [propData pickPID:&llPropPt
            highlightList:highlightList];
        
        [sewerData pickSewer:&llSewerPt
                      atZoom:_mapView.camera.zoom
               highlightList:highlightList];
        
        [planData pickAlleyWallPoint:llpickPt
                       highlightList:highlightList];
        
        [planData pickAlleyLine:llpickPt
                         atZoom:_mapView.camera.zoom
                  highlightList:highlightList];
        
        if (highlightList.count)
        {
            if (_clearMarkers)
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
            
            [self highlightVectorView:pi
                        displayOption:DISPLAY_DATA_OPTION_HIGHLIGHT];
            
            MarkerButton *marker = [MarkerButton markerWithPosition:pickedPt
                                                               view:self.view
                                                                map:_mapView
                                                    statusBarHeight:[self statusBarHeight:self.interfaceOrientation]
                                                           delegate:self];
            
            [self removePreviousInfoWindow];
            _infoWindow = [[MarkerInfoWindow alloc] init];
            
            switch (pi.itemType)
            {
                case PTAlleyLine:
                    _selectedAlleySeg = pi.identifier;
                    marker.title = _selectedAlleySeg;
                    marker.snippet = pi.symbolName;
                    _infoWindow.type = marker.type = MarkerInfoWindowTypeAlleyLine;
                    break;
                    
                case PTAlleyWallPt:
                    _selectedAlleyWall = pi.identifier;
                    marker.title = _selectedAlleyWall;
                    marker.snippet = pi.symbolName;
                    _infoWindow.type = marker.type = MarkerInfoWindowTypeAlleyWall;
                    break;
                    
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
            marker.refno = pi.refno;
            
            [_markerArray addObject:marker];
            
            _infoWindow.center = CGPointMake(marker.center.x, (marker.center.y - 42.0));
            _infoWindow.delegate = self;
            _infoWindow.title = marker.title;
            _infoWindow.snippet = marker.snippet;
            _infoWindow.position = marker.position;
            _infoWindow.refno = marker.refno;
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
                
            case MarkerInfoWindowTypeAlleyWall:
                _selectedAlleyWall = _infoWindow.title = marker.title;
                break;
                
            case MarkerInfoWindowTypeAlleyLine:
                _selectedAlleySeg = _infoWindow.title = marker.title;
                break;
                
            default:
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

- (void)handleLongPressDigitizingForState:(UILongPressGestureRecognizer *)gesture
{
    if (gesture.state == UIGestureRecognizerStateBegan ||
        gesture.state == UIGestureRecognizerStateChanged)
    {
        CGPoint gesturePoint = [gesture locationInView:self.view];
        
        if (gesture.state == UIGestureRecognizerStateBegan)
        {
            _mapView.settings.scrollGestures = NO;
            _digitizerTargetView.image = _orangeCrosshairs;
            
            _digitizingTargetOffset = CGPointMake(gesturePoint.x - _digitizerTargetView.center.x,
                                                  gesturePoint.y - _digitizerTargetView.center.y);
        }
        
        _digitizerTargetView.center = CGPointMake(gesturePoint.x - _digitizingTargetOffset.x,
                                                  gesturePoint.y - _digitizingTargetOffset.y);
    }
    
    else if (gesture.state == UIGestureRecognizerStateEnded)
    {
        _mapView.settings.scrollGestures = YES;
        _digitizerTargetView.image = _blackCrosshairs;
        
        CGPoint digitizerCenter = CGPointMake(_digitizerTargetView.center.x,
                                              (_digitizerTargetView.center.y -
                                               [self statusBarHeight:self.interfaceOrientation]));
        
        CLLocationCoordinate2D position = [_mapView.projection coordinateForPoint:digitizerCenter];
        
        switch (_digitizationMode)
        {
            case DigitizationModeCustom:
            {
                _digitizerCount++;
                
                MarkerButton *marker = [MarkerButton markerWithPosition:position
                                                                   view:self.view
                                                                    map:_mapView
                                                        statusBarHeight:[self statusBarHeight:self.interfaceOrientation]
                                                               delegate:self];
                
                [self removePreviousInfoWindow];
                _infoWindow = [[MarkerInfoWindow alloc] init];
                
                [marker setImage:_orangeCrosshairs
                        forState:UIControlStateNormal];
                
                marker.title = [NSString stringWithFormat:@"Custom Marker %ld", (long)_digitizerCount];
                marker.snippet = [NSString stringWithFormat:@"%f, %f", marker.position.latitude, marker.position.longitude];
                [_markerArray addObject:marker];
                
                _infoWindow.center = CGPointMake(marker.center.x, (marker.center.y - 42.0));
                _infoWindow.delegate = self;
                _infoWindow.title = marker.title;
                _infoWindow.snippet = marker.snippet;
                _infoWindow.position = marker.position;
                _infoWindow.type = MarkerInfoWindowTypeCustom;
                [self.view addSubview:_infoWindow];
                _noneSelected = NO;
            }
                break;
                
            case DigitizationModeAlleyWallMove:
            {
                AlleyWallData *awd = [[AlleyWallData alloc] init];
                
                [awd moveAlleyWallPoint:_selectedAlleyWallRefno
                                    to:position];
                
                MarkerButton *marker = _markerArray.lastObject;
                marker.position = _infoWindow.position = position;
                
                marker.center = CGPointMake(_digitizerTargetView.center.x,
                                            (_digitizerTargetView.center.y -
                                             (marker.frame.size.height / 2.0)));
                
                _infoWindow.center = CGPointMake(marker.center.x, (marker.center.y - 42.0));
                
                [UIView animateWithDuration:0.25
                                 animations:^{
                                     _cancelDigitizerButton.alpha = 0.0;
                                     _saveDigitizerButton.alpha = 1.0;
                                     //_undoDigitizerButton.alpha = 1.0;
                                 }];
                
                [_vectorView setNeedsDisplay];
            }
                break;
                
            case DigitizationModeAlleyWallNew:
            {
                _digitizerCount++;
                CGPoint digitizerCenter = CGPointMake(_digitizerTargetView.center.x,
                                                      (_digitizerTargetView.center.y -
                                                       [self statusBarHeight:self.interfaceOrientation]));
                
                CLLocationCoordinate2D position = [_mapView.projection coordinateForPoint:digitizerCenter];
                CLLocationCoordinate2D positioncl = position;
                CLLocationCoordinate2D positionpid = position;
                AlleyWallData *awd = [[AlleyWallData alloc] init];
                NSString *nearestAlley = [awd nearestAlleyLine:&positioncl];
                NSString *newWallID = [awd getNextWallForAlley:nearestAlley];
                PropertyData *propData = [[PropertyData alloc] init];
                NSString* houseAndUnit = @"";
                NSString* streetName = @"";
                NSString * nearPID = [propData getNearestPID:&positionpid];
                if (nearPID)
                {
                    [propData getAddressForPID:nearPID houseNumAndUnit:&houseAndUnit streetName:&streetName];
                }
                [awd createNewWall:newWallID atPoint:position withHouse:houseAndUnit andStreet:streetName];
                [self refreshVectorView:_mapView.projection.visibleRegion
                                 atZoom:_mapView.camera.zoom];
                
/*                MarkerButton *marker = [MarkerButton markerWithPosition:position
                                                                   view:self.view
                                                                    map:_mapView
                                                        statusBarHeight:[self statusBarHeight:self.interfaceOrientation]
                                                               delegate:self];
                
                marker.center = CGPointMake(_digitizerTargetView.center.x,
                                            (_digitizerTargetView.center.y -
                                             (marker.frame.size.height / 2.0)));
                
                [self removePreviousInfoWindow];
                _infoWindow = [[MarkerInfoWindow alloc] init];
                
                marker.title = [NSString stringWithFormat:@"New Alley Wall %ld", (long)_digitizerCount];
                marker.snippet = [NSString stringWithFormat:@"%f, %f", marker.position.latitude, marker.position.longitude];
                [_markerArray addObject:marker];
                
                _infoWindow.center = CGPointMake(marker.center.x, (marker.center.y - 42.0));
                _infoWindow.delegate = self;
                _infoWindow.title = marker.title;
                _infoWindow.snippet = marker.snippet;
                _infoWindow.position = marker.position;
                _infoWindow.type = MarkerInfoWindowTypeCustom;
                [self.view addSubview:_infoWindow];*/
                _noneSelected = NO;
                
                [UIView animateWithDuration:0.25
                                 animations:^{
                                     _cancelDigitizerButton.alpha = 0.0;
                                     _saveDigitizerButton.alpha = 1.0;
                                     //_undoDigitizerButton.alpha = 1.0;
                                 }];
            }
                
            case DigitizationModeProperty:
                break;
                
            case DigitizationModeSewer:
                break;
                
            default:
                break;
        }
        
        CGPoint targetPoint = [_mapView.projection pointForCoordinate:_mapView.camera.target];
        
        _digitizerTargetView.center = CGPointMake(targetPoint.x,
                                                  (targetPoint.y + [self statusBarHeight:self.interfaceOrientation]));
    }
}

- (void)mapViewLongPressed:(UILongPressGestureRecognizer *)gesture
{
    if (_inDigitizationMode)
    {
        [self handleLongPressDigitizingForState:gesture];
        return;
    }
    
    if (![ConfigurationControl.sharedInstance layer:HCLayerSewers
                                     visibleAtZoom:_mapView.camera.zoom])
        return;
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
                
                if (!platRefno)
                {
                    _waitForVectorViewRefresh = NO;
                    CRAPI.sharedInstance.showPlats = -1;
                }
                
                else
                {
                    _waitForVectorViewRefresh = YES;
                    CRAPI.sharedInstance.showPlats = platRefno;
                }
                
                [_platView setPlatID:_selectedPlatRefno
                             andType:PLAT_TYPE_STORM];
                
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
        
        else if (_platView)
        {
            [_platView setPlatID:_selectedPlatRefno
                         andType:PLAT_TYPE_STORM];
        }
    }
    
    else if (gesture.state == UIGestureRecognizerStateEnded)
    {
        _mapView.settings.scrollGestures = YES;
        CRAPI.sharedInstance.showPlats = 0;
        
        if (_selectedPlatRefno)
        {
            SewerData *sd = [[SewerData alloc] init];
            
            NSString *platID = [sd getPlatIDofType:@"storm"
                                         fromRefno:_selectedPlatRefno];
            
            [sd loadPlat:platID
                  ofType:@"storm"
            usingPopover:_popover
             andDelegate:self];
        }
        
        [self refreshVectorView:_mapView.projection.visibleRegion
                         atZoom:_mapView.camera.zoom];
    }
}
- (void)FTPdidComplete:(int)option
            withStatus:(int)status
       andStatusString:(NSString*)statusString
              filePath:(NSString *)path
{
    if (status == FTPStatusOK || status == FTPStatusFileExists)
    {
        [_popover hide];
        
        switch (option)
        {
            case GET_STORMPLAT:
            {
                CRAPI.sharedInstance.currentPlatImagePath = path;
                CRAPI.sharedInstance.currentPlatType = @"storm";
                
                [_platView setPlatID:_selectedPlatRefno
                             andType:PLAT_TYPE_STORM];
                
                if (_screenSetting == MapViewScreenSettingFullscreen && _selectedPlatRefno > 0)
                {
                    [self mapToolbarDidSelectSplitScreenSetting:MapViewScreenSettingSplitScreen];
                    [_mapToolbar splitScreenSelectedSegmentIndex:MapViewScreenSettingSplitScreen];
                }
            }
        }
    }
    
    else
    {
        [_popover hide];
        
        [_gssiAlert showAlertWithTitle:@"Error getting plat file"
                               message:statusString
                     cancelButtonTitle:@"Continue"
                     otherButtonTitles:nil
             destructiveButtonPosition:0];
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
    if (_screenSetting == MapViewScreenSettingPlatView)
        return;
    
    [self clearVectorView];
    
    if (_firstView.frame.size.height != 0.0)
        [self.view bringSubviewToFront:_firstView];
    
    if (_secondView.frame.size.height != 0.0)
        [self.view bringSubviewToFront:_secondView];
    
    [self.view bringSubviewToFront:_mapToolbar];
    [self.view bringSubviewToFront:_compass];
    
    if (!_tableView.hidden)
        [self.view bringSubviewToFront:_tableView];
    
    for (GSSiDatePicker *datePicker in self.view.subviews)
    {
        if ([datePicker isKindOfClass:GSSiDatePicker.class])
        {
            [datePicker bringToFrontOfView:self.view];
            [self initTableView];
        }
    }
    
    for (GSSiNotesView *notesView in self.view.subviews)
    {
        if ([notesView isKindOfClass:GSSiNotesView.class])
        {
            [notesView bringToFrontOfView:self.view];
            [self initTableView];
        }
    }
    
    for (HelpWebView *helpWebView in self.view.subviews)
    {
        if ([helpWebView isKindOfClass:HelpWebView.class])
            [self.view bringSubviewToFront:helpWebView];
    }
}

- (void)mapView:(GMSMapView *)mapView
didChangeCameraPosition:(GMSCameraPosition *)position
{
    if (_screenSetting == MapViewScreenSettingPlatView)
        return;
    
    if (position.bearing != 0.0)
    {
        if (_compass.hidden)
            [self showCompass];
        
        _compass.transform = CGAffineTransformMakeRotation(-position.bearing * M_PI / 180);
    }
    
    [self updateMarkerPosition];
}

- (void)updateMarkerPosition
{
    for (MarkerButton *markers in _markerArray)
    {
        CGPoint target = [_mapView.projection pointForCoordinate:markers.position];
        
        markers.center = CGPointMake(target.x,
                                     ((target.y + [self statusBarHeight:self.interfaceOrientation]) -
                                      (markers.frame.size.height / 2.0)));
    }
    
    MarkerButton *marker = _markerArray.lastObject;
    _infoWindow.center = CGPointMake(marker.center.x, (marker.center.y - 42.0));
}

- (void)mapView:(GMSMapView *)mapView
idleAtCameraPosition:(GMSCameraPosition *)position
{
    if (_moveDigitizer)
    {
        _moveDigitizer = NO;
        [self showDigitizer:YES];
    }
    
    if (!_firstTimeMap)
    {
        [self refreshVectorView:_mapView.projection.visibleRegion
                         atZoom:position.zoom];
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
    
    [self performSelector:@selector(resetPlatProfileViewsAfterRotation)
               withObject:nil
               afterDelay:0.1];
}

- (void)resetPlatProfileViewsAfterRotation
{
    if (_screenSetting != MapViewScreenSettingPlatView)
    {
        CGFloat pBearing;
        CLLocationCoordinate2D pTarget;
        DPOINT minYpt, maxYpt;
        
        [_platView zoomForMapBounds:_platView.frame
                            bearing:&pBearing
                             target:&pTarget
                        mapViewSize:_mapView.frame.size
                             minYpt:&minYpt
                             maxYpt:&maxYpt];
        
        if (_screenSetting == MapViewScreenSettingTriScreen)
        {
            [_profileView zoomImage:_platView.image
                                atX:minYpt.x
                           fromMinY:minYpt.y
                             toMaxY:maxYpt.y];
        }
    }
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
    
    /*CGRect frame3 = CGRectMake(0.0, statusBarHeight +
                               ((self.view.frame.size.width - _tabBarHeight - statusBarHeight) / 1.5),
                               ((self.view.frame.size.height + _tabBarHeight) / 2.0),
                               ((self.view.frame.size.width - _tabBarHeight - statusBarHeight) / 3.0));*/
    
    CGRect frame4 = CGRectMake(0.0, statusBarHeight,
                               (self.view.frame.size.height + _tabBarHeight),
                               (self.view.frame.size.width - _tabBarHeight - statusBarHeight));
    
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

    [_mapToolbar willRotateWithDuration:duration
                           tabBarHeight:_tabBarHeight
                        statusBarHeight:statusBarHeight];
    
    for (GSSiDatePicker *datePicker in self.view.subviews)
    {
        if ([datePicker isKindOfClass:GSSiDatePicker.class])
        {
            [datePicker willRotateWithDuration:duration
                                  tabBarHeight:_tabBarHeight];
        }
        
    }
    
    for (GSSiNotesView *notesView in self.view.subviews)
    {
        if ([notesView isKindOfClass:GSSiNotesView.class])
        {
            [notesView willRotateWithDuration:duration
                       toInterfaceOrientation:toInterfaceOrientation
                                 tabBarHeight:_tabBarHeight];
        }
    }
    
    for (HelpWebView *helpWebView in self.view.subviews)
    {
        if ([helpWebView isKindOfClass:HelpWebView.class])
        {
            [helpWebView willRotateWithDuration:duration
                         toInterfaceOrientation:toInterfaceOrientation
                                   tabBarHeight:_tabBarHeight];
        }
    }
    
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
                                 _mapView.frame = _vectorView.frame = frame4;
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
            
            [UIView animateWithDuration:duration
                             animations:^{
                                 _platView.center = CGPointMake((_firstView.frame.size.width / 2.0),
                                                                (_firstView.frame.size.height / 2.0));
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
                                 _platView.center = CGPointMake((_firstView.frame.size.width / 2.0),
                                                                (_firstView.frame.size.height / 2.0));
                             }];
            
            [UIView animateWithDuration:duration
                             animations:^{
                                 _secondView.frame =
                                 CGRectMake(0.0, statusBarHeight +
                                            ((self.view.frame.size.width - _tabBarHeight - statusBarHeight) / 1.5),
                                            (self.view.frame.size.height + _tabBarHeight),
                                            ((self.view.frame.size.width - _tabBarHeight - statusBarHeight) / 3.0));
                             }];
            
            [UIView animateWithDuration:duration
                             animations:^{
                                 _profileView.frame = CGRectMake(0.0, 0.0, _secondView.frame.size.width,
                                                                 (_secondView.frame.size.height));
                             }];
        }
            break;
            
        case MapViewScreenSettingPlatView:
        {
            [UIView animateWithDuration:duration
                             animations:^{
                                 _firstView.frame = frame4;
                             }];
            
            [UIView animateWithDuration:duration
                             animations:^{
                                 _platView.center = CGPointMake((_firstView.frame.size.width / 2.0),
                                                                (_firstView.frame.size.height / 2.0));
                             }];
        }
            
            /*
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
                                 _platView.center = CGPointMake((_firstView.frame.size.width / 2.0),
                                                                (_firstView.frame.size.height / 2.0));
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
         */
            
        default:
            break;
    }
}

- (void)allocateVectorView
{
    int ivv;
    
    for (int i = 0; i < MAX_VECTORVIEWS; i++)
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
    [_vectorViewTimer invalidate];
    keepProcessing++;
    
    if (!_vectorView)
        return;
    
    _vectorView.displayDataOption = DISPLAY_DATA_OPTION_NODISPLAY;
    [_vectorView removeFromSuperview];
    vectorViews[_vectorView.ivv] = nil;
    _vectorView = nil;
}

- (void)refreshVectorView:(GMSVisibleRegion)region
                   atZoom:(CGFloat)zoom
{
    [self clearVectorView];
    _vectorViewZoom = zoom;
    
    _vectorViewTimer = [NSTimer scheduledTimerWithTimeInterval:0.1
                                                        target:self
                                                      selector:@selector(startVectorView:)
                                                      userInfo:nil
                                                       repeats:NO];
}

- (void)startVectorView:(NSTimer *)timer
{
    [self allocateVectorView];
    _vectorView.displayDataOption = DISPLAY_DATA_OPTION_DISPLAY;
    
    [_vectorView setRegion:_mapView.projection.visibleRegion];
    CRAPI.sharedInstance.currentZoom = _vectorViewZoom;
    _vectorView.zoom = _vectorViewZoom;
    
    NSLog(@"Vector view start: zoom = %f", _vectorViewZoom);
    
    if ([ConfigurationControl.sharedInstance layer:HCLayerAerials
                                     visibleAtZoom:_vectorViewZoom])
    {
        _layer_jpeg.map = _mapView;
        _layer_png.map = _mapView;
        ConfigurationControl.sharedInstance.GMTilesVisible = YES;
    }
    
    else
    {
        _layer_jpeg.map = nil;
        _layer_png.map = nil;
        ConfigurationControl.sharedInstance.GMTilesVisible = NO;
    }
    
    [_vectorView setNeedsDisplay];
}

- (void)highlightVectorView:(PickedItem *)pi
              displayOption:(int)option
{
    if (!_vectorView)
        [self allocateVectorView];
    
    _vectorView.displayDataOption = option;
    
    [_vectorView setRegion:_mapView.projection.visibleRegion];
    _vectorView.zoom = _vectorViewZoom;
    _vectorView.pickedItem = pi;
    
    NSLog(@"HighlightVector view start: zoom = %f", _vectorViewZoom);
    
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
                       
                       if (_screenSetting != MapViewScreenSettingPlatView)
                       {
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
                           
                           for (GSSiDatePicker *datePicker in self.view.subviews)
                           {
                               if ([datePicker isKindOfClass:GSSiDatePicker.class])
                                   [datePicker bringToFrontOfView:self.view];
                           }
                           
                           for (GSSiNotesView *notesView in self.view.subviews)
                           {
                               if ([notesView isKindOfClass:GSSiNotesView.class])
                                   [notesView bringToFrontOfView:self.view];
                           }
                           
                           if ([self.view.subviews containsObject:_popover])
                               [self.view bringSubviewToFront:_popover];
                           
                           if ([self.view.subviews containsObject:_digitizerTargetView])
                               [self.view bringSubviewToFront:_digitizerTargetView];
                           
                           if ([self.view.subviews containsObject:_digitizationToolbar])
                               [self.view bringSubviewToFront:_digitizationToolbar];
                           
                           for (HelpButton *helpButton in self.view.subviews)
                           {
                               if ([helpButton isKindOfClass:HelpButton.class])
                                   [self.view bringSubviewToFront:helpButton];
                           }
                           
                           for (HelpWebView *helpWebView in self.view.subviews)
                           {
                               if ([helpWebView isKindOfClass:HelpWebView.class])
                                   [self.view bringSubviewToFront:helpWebView];
                           }
                           
                           for (NVLegendView *legendView in self.view.subviews)
                           {
                               if ([legendView isKindOfClass:NVLegendView.class])
                                   [self.view bringSubviewToFront:legendView];
                           }
                       }
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
        
        [self deselectTableViewRow];
        
        NSIndexPath *indexPath;
        
        for (GSSiDatePicker *datePicker in self.view.subviews)
        {
            if ([datePicker isKindOfClass:GSSiDatePicker.class])
            {
                indexPath = [NSIndexPath indexPathForRow:(SewerPipeSettingUpdateCleanDate - 1)
                                               inSection:0];
                
                [_tableView selectRowAtIndexPath:indexPath
                                        animated:NO
                                  scrollPosition:UITableViewScrollPositionNone];
            }
        }
        
        for (GSSiNotesView *notesView in self.view.subviews)
        {
            if ([notesView isKindOfClass:GSSiNotesView.class])
            {
                indexPath = [NSIndexPath indexPathForRow:(SewerPipeSettingUpdateNotes - 1)
                                               inSection:0];
                
                [_tableView selectRowAtIndexPath:indexPath
                                        animated:NO
                                  scrollPosition:UITableViewScrollPositionNone];
            }
        }
    }
}

- (void)deselectTableViewRow
{
    if (_tableView.indexPathForSelectedRow)
    {
        [_tableView deselectRowAtIndexPath:_tableView.indexPathForSelectedRow
                                  animated:YES];
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
            
        default:
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
            
        default:
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
        {
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
            
        default:
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
        
        [UserDefaults.defaults saveNSInteger:PropertyTableViewSettingPropertyReport
                                    forKey:@"PIDOption"];
    }
    
    else if ([[tableView cellForRowAtIndexPath:indexPath].textLabel.text
              isEqualToString:@"Hennepin County Website"])
    {
        [self showHCWebsite];
        
        [UserDefaults.defaults saveNSInteger:PropertyTableViewSettingHCWebsite
                                      forKey:@"PIDOption"];
    }
    
    else if ([[tableView cellForRowAtIndexPath:indexPath].textLabel.text
              isEqualToString:@"Display Street View"])
    {
        [self showStreetView];
        
        [UserDefaults.defaults saveNSInteger:PropertyTableViewSettingStreetView
                                      forKey:@"PIDOption"];
    }
    
    else if ([[tableView cellForRowAtIndexPath:indexPath].textLabel.text
              isEqualToString:@"Zoom to Census Area"])
    {
        [self showCensusArea];
        
        [UserDefaults.defaults saveNSInteger:PropertyTableViewSettingCensusArea
                                      forKey:@"PIDOption"];
    }
    
    else if ([[tableView cellForRowAtIndexPath:indexPath].textLabel.text
              isEqualToString:@"Add to Property List"])
    {
        [self addToPropList];
        
        [UserDefaults.defaults saveNSInteger:PropertyTableViewSettingPropList
                                      forKey:@"PIDOption"];
    }
    
    else if ([[tableView cellForRowAtIndexPath:indexPath].textLabel.text
              isEqualToString:@"Add to Destinations"])
    {
        [self addToDestinations];
        
        [UserDefaults.defaults saveNSInteger:PropertyTableViewSettingDestinations
                                      forKey:@"PIDOption"];
    }
    
    else if ([[tableView cellForRowAtIndexPath:indexPath].textLabel.text
              isEqualToString:@"Display Pipe Attributes"])
    {
        [self showPipeAttributes];
        
        [UserDefaults.defaults saveNSInteger:SewerPipeSettingAttributes
                                      forKey:@"SewerOption"];
    }
    
    else if ([[tableView cellForRowAtIndexPath:indexPath].textLabel.text
              isEqualToString:@"Trace Pipe Upstream"])
    {
        [self dismissTableView];
        
        [self performSelector:@selector(showPipeTraceUpstream)
                   withObject:nil
                   afterDelay:0.3];
        
        [UserDefaults.defaults saveNSInteger:SewerPipeSettingTraceUp
                                      forKey:@"SewerOption"];
    }
    
    else if ([[tableView cellForRowAtIndexPath:indexPath].textLabel.text
              isEqualToString:@"Trace Pipe Downstream"])
    {
        [self dismissTableView];
        
        [self performSelector:@selector(showPipeTraceDownstream)
                   withObject:nil
                   afterDelay:0.3];
        
        [UserDefaults.defaults saveNSInteger:SewerPipeSettingTraceDown
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
              isEqualToString:@"Update Cleaning Date"])
    {
        [self updateCleaningDate];
        
        [UserDefaults.defaults saveNSInteger:SewerPipeSettingUpdateCleanDate
                                      forKey:@"SewerOption"];
    }
    
    else if ([[tableView cellForRowAtIndexPath:indexPath].textLabel.text
              isEqualToString:@"Update Inspection Notes"])
    {
        [self updateInspectionNotes];
        
        [UserDefaults.defaults saveNSInteger:SewerPipeSettingUpdateNotes
                                      forKey:@"SewerOption"];
    }
    
    else if ([[tableView cellForRowAtIndexPath:indexPath].textLabel.text
              isEqualToString:@"Snap to Node"])
    {
        [self snapToNode];
        
        [UserDefaults.defaults saveNSInteger:CustomSettingSnapToNode
                                      forKey:@"CustomOption"];
    }
    
    else if ([[tableView cellForRowAtIndexPath:indexPath].textLabel.text
              isEqualToString:@"Snap to Line"])
    {
        [self snapToLine];
        
        [UserDefaults.defaults saveNSInteger:CustomSettingSnapToLine
                                      forKey:@"CustomOption"];
    }
    
    else if ([[tableView cellForRowAtIndexPath:indexPath].textLabel.text
              isEqualToString:@"Move Wall Point"])
    {
        [self dismissTableView];
        
        [self performSelector:@selector(moveWallPoint)
                   withObject:nil
                   afterDelay:0.3];
        
        [UserDefaults.defaults saveNSInteger:AlleyWallSettingMoveWallPoint
                                      forKey:@"AlleyWallOption"];
    }
    
    else if ([[tableView cellForRowAtIndexPath:indexPath].textLabel.text
              isEqualToString:@"Delete Wall Point"])
    {
        [self deleteWallPoint];
        
        [UserDefaults.defaults saveNSInteger:AlleyWallSettingDeleteWallPoint
                                      forKey:@"AlleyWallOption"];
    }
    
    else if ([[tableView cellForRowAtIndexPath:indexPath].textLabel.text
              isEqualToString:@"Edit Wall Attributes"])
    {
        [self editWallAttributes];
        
        [UserDefaults.defaults saveNSInteger:AlleyWallSettingEditWallAttributes
                                      forKey:@"AlleyWallOption"];
    }
    
    else if ([[tableView cellForRowAtIndexPath:indexPath].textLabel.text
              isEqualToString:@"View Wall Photos"])
    {
        [self viewWallPhotos];
        
        [UserDefaults.defaults saveNSInteger:AlleyWallSettingViewWallPhotos
                                      forKey:@"AlleyWallOption"];
    }
    
    else if ([[tableView cellForRowAtIndexPath:indexPath].textLabel.text
              isEqualToString:@"Toggle Alley Line\nCompletion Status"])
    {
        [self dismissTableView];
        
        [self performSelector:@selector(toggleCompletionStatus)
                   withObject:nil
                   afterDelay:0.3];
        
        [UserDefaults.defaults saveNSInteger:AlleyWallSettingEditWallAttributes
                                      forKey:@"AlleyLineOption"];
    }
    
    else if ([[tableView cellForRowAtIndexPath:indexPath].textLabel.text
              isEqualToString:@"Alley Centerline Status"])
    {
        [self dismissTableView];
        _alleyStatusSetting = AlleyStatusSettingCenterline;
        
        [self performSelector:@selector(alleyStatus)
                   withObject:nil
                   afterDelay:0.3];
    }
    
    else if ([[tableView cellForRowAtIndexPath:indexPath].textLabel.text
              isEqualToString:@"Alley Wall Status"])
    {
        [self dismissTableView];
        _alleyStatusSetting = AlleyStatusSettingWall;
        
        [self performSelector:@selector(alleyStatus)
                   withObject:nil
                   afterDelay:0.3];
    }
    
    else if ([[tableView cellForRowAtIndexPath:indexPath].textLabel.text
              isEqualToString:@"Remove Property Marker"] ||
             [[tableView cellForRowAtIndexPath:indexPath].textLabel.text
              isEqualToString:@"Remove Pipe Marker"] ||
             [[tableView cellForRowAtIndexPath:indexPath].textLabel.text
              isEqualToString:@"Remove Alley Wall Marker"] ||
             [[tableView cellForRowAtIndexPath:indexPath].textLabel.text
              isEqualToString:@"Remove Custom Marker"] ||
             [[tableView cellForRowAtIndexPath:indexPath].textLabel.text
              isEqualToString:@"Remove Alley Line Marker"])
        
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
                     } completion:^(BOOL finished) {
                         self.tabBarController.tabBar.hidden = YES;
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

- (void)addToPropList
{
    PropertyList *pl = [[PropertyList alloc] init];
    
    [pl addParcel:_selectedPID];
}

- (void)addToDestinations
{
    //implement add to destinations here
}

- (void)showPipeAttributes
{
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

- (void)updateCleaningDate
{
    GSSiDatePicker *datePicker = [GSSiDatePicker showDatePickerWithView:self.view];
#pragma unused(datePicker)
}

- (void)updateInspectionNotes
{
    GSSiNotesView *notesView = [GSSiNotesView showNotesViewWithView:self.view
                                                           delegate:self
                                                              title:[NSString stringWithFormat:@"Notes for %@", _selectedSewerPipe]
                                                       currentValue:nil
                                                   allowAutoCorrect:YES];
#pragma unused(notesView)
}

- (void)snapToNode
{
    //implement snap to node here
}

- (void)snapToLine
{
    //implement snap to line here
}

- (void)moveWallPoint
{
    _inDigitizationMode = YES;
    _digitizationMode = DigitizationModeAlleyWallMove;
    [self hideMarkersAndInfoWindows];
    [_mapToolbar hide];
    
    MarkerButton *marker = _markerArray.lastObject;
    
    if (CLLocationCoordinateEqual(_mapView.camera.target, marker.position))
        [self showDigitizer:YES];
    else
    {
        _moveDigitizer = YES;
        [_mapView animateToLocation:marker.position];
    }
}

- (void)deleteWallPoint
{
    NVLargeAlertView *alert = [NVLargeAlertView showLargeAlertViewinView:self.view
                                                                delegate:self
                                                                   title:@"Do You Wish to Delete This Alley Wall?"
                                                           topButtonText:@"YES"
                                                        bottomButtonText:@"NO"
                                                        destructiveIndex:NVLargeAlertIndexTopButton];
#pragma unused(alert)
    
    [self deselectTableViewRow];
}

- (void)editWallAttributes
{
    [SharedDefaults.defaults saveString:_selectedAlleyWall
                                 forKey:@"AlleyWallEditAttributes"];
    
    [self launchAlleyWallApp];
    [self dismissTableView];
}

- (void)viewWallPhotos
{
    NVPhotoViewController *photoViewer = [NVPhotoViewController viewerWithPhotosFromDirectory:CRAPI.sharedInstance.sharedOutputDirectory
                                                                               withIdentifier:_selectedAlleyWall];
    
    [self presentViewController:photoViewer
                       animated:YES
                     completion:nil];
}

- (void)toggleCompletionStatus
{
    AlleyWallData *awd = [[AlleyWallData alloc] init];
    int status = [awd getAlleyLineStatus:_selectedAlleyLineRefno];
    
    [awd setAlleyLineStatus:_selectedAlleyLineRefno
                         to:!status];
    
    [self refreshVectorView:_mapView.projection.visibleRegion
                     atZoom:_mapView.camera.zoom];
}

- (void)alleyStatus
{
    [UserDefaults.defaults saveNSInteger:HCConfigAlleyWallStatus
                                  forKey:@"CurrentConfig"];
    
    ConfigurationControl.sharedInstance.currentApp = HCConfigAlleyWallStatus;
    
    CGPoint origin = CGPointMake(6.0, ([self statusBarHeight:self.interfaceOrientation] + 6.0));
    
    for (NVLegendView *views in self.view.subviews)
    {
        if ([views isKindOfClass:NVLegendView.class])
            [views reloadView];
    }
    
    NVLegendView *legendView = [NVLegendView showLegendViewAtOrigin:origin
                                                             inView:self.view
                                                     containerFrame:_mapView.frame
                                                           delegate:self
                                                         selectable:NO
                                                           animated:YES];
    
    if (!_helpButtonMoved)
    {
        [UIView animateWithDuration:0.25
                         animations:^{
                             for (HelpButton *helpButton in self.view.subviews)
                             {
                                 if ([helpButton isKindOfClass:HelpButton.class])
                                 {
                                     helpButton.center =
                                     CGPointMake(helpButton.center.x, helpButton.center.y +
                                                 legendView.frame.size.height);
                                 }
                             }
                         } completion:^(BOOL finished) {
                             _helpButtonMoved = YES;
                         }];
    }
}

- (void)cancelDigitizationMode:(UIButton *)button
{
    [self hideDigitizationMode];
}

- (void)saveDigitizationMode:(UIButton *)button
{
    PlanimetricData *pd = [[PlanimetricData alloc] init];
    
    if (_digitizationMode == DigitizationModeAlleyWallMove)
        [pd userSavedAlleyWallPointMove:YES];
    
    [self hideDigitizationMode];
}

- (void)undoDigitizationMode:(UIButton *)button
{
    PlanimetricData *pd = [[PlanimetricData alloc] init];
    [pd userSavedAlleyWallPointMove:NO];
    
    [_vectorView setNeedsDisplay];
    
    [UIView animateWithDuration:0.25
                     animations:^{
                         _saveDigitizerButton.alpha = 0.0;
                         //_undoDigitizerButton.alpha = 0.0;
                         _cancelDigitizerButton.alpha = 1.0;
                     }];
}

- (void)hideDigitizationMode
{
    _inDigitizationMode = NO;
    
    [self hideDigitizer];
    [self showMarkersAndInfoWindows];
    [_mapToolbar show];
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

- (void)hideMarkersAndInfoWindows
{
    [UIView animateWithDuration:0.25
                     animations:^{
                         for (MarkerButton *markers in self.view.subviews)
                         {
                             if ([markers isKindOfClass:MarkerButton.class])
                                 markers.alpha = 0.0;
                         }
                         
                         _infoWindow.alpha = 0.0;
                     }];
}

- (void)showMarkersAndInfoWindows
{
    [UIView animateWithDuration:0.25
                     animations:^{
                         for (MarkerButton *markers in self.view.subviews)
                         {
                             if ([markers isKindOfClass:MarkerButton.class])
                                 markers.alpha = 1.0;
                         }
                         
                         _infoWindow.alpha = 1.0;
                     }];
}

- (void)showDigitizer:(BOOL)moveMarker;
{
    if (moveMarker)
    {
        MarkerButton *marker = _markerArray.lastObject;
        
        CGPoint markerPosition = [_mapView.projection pointForCoordinate:marker.position];
        
        _digitizerTargetView.center = CGPointMake(markerPosition.x,
                                                  (markerPosition.y + [self statusBarHeight:self.interfaceOrientation]));
    }
    
    _digitizerTargetView.hidden = NO;
    _digitizationToolbar.hidden = NO;
    
    [UIView animateWithDuration:0.25
                     animations:^{
                         _digitizerTargetView.alpha = 1.0;
                         _digitizationToolbar.alpha = 1.0;
                         
                         for (HelpButton *helpButton in self.view.subviews)
                         {
                             if ([helpButton isKindOfClass:HelpButton.class])
                             {
                                 helpButton.center =
                                 CGPointMake(helpButton.center.x, helpButton.center.y +
                                             _digitizationToolbar.frame.size.height);
                             }
                         }
                     }];
}

- (void)hideDigitizer
{
    [UIView animateWithDuration:0.25
                     animations:^{
                         _digitizerTargetView.alpha = 0.0;
                         _digitizationToolbar.alpha = 0.0;
                         
                         for (HelpButton *helpButton in self.view.subviews)
                         {
                             if ([helpButton isKindOfClass:HelpButton.class])
                             {
                                 helpButton.center =
                                 CGPointMake(helpButton.center.x, helpButton.center.y -
                                             _digitizationToolbar.frame.size.height);
                             }
                         }
                     } completion:^(BOOL finished) {
                         _digitizerTargetView.hidden = YES;
                         _digitizationToolbar.hidden = YES;
                         _saveDigitizerButton.alpha = /*_undoDigitizerButton.alpha =*/ 0.0;
                         _cancelDigitizerButton.alpha = 1.0;
                     }];
}

- (void)gssiAlert:(GSSiAlertController *)gssiAlert
clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (buttonIndex)
    {
        case CensusZoomSettingCancel:
            [self deselectTableViewRow];
            
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
    self.tabBarController.tabBar.hidden = NO;
    
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
                         
                         [self deselectTableViewRow];
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
           gestureState:(UIGestureRecognizerState)gestureState
{
    if (_screenSetting == MapViewScreenSettingPlatView)
        return;
    
    if (gestureState == UIGestureRecognizerStateBegan)
    {
        [self clearVectorView];
        _gestureCount++;
    }
    
    if (gestureState == UIGestureRecognizerStateEnded)
        _gestureCount--;
    
    if (_gestureCount == 0)
    {
        [_profileView zoomImage:_platView.image
                            atX:minYpt.x
                       fromMinY:minYpt.y
                         toMaxY:maxYpt.y];
    }
    
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithTarget:pTarget
                                                               zoom:pZoom
                                                            bearing:pBearing
                                                       viewingAngle:0.0];
    
    [_mapView animateToCameraPosition:camera];
}

- (void)platViewDidLongPressAtFrameXPosition:(CGFloat)xFrame
                           andSuperviewPoint:(CGPoint)superpoint
                           andImageXPosition:(CGFloat)xImage
                                gestureState:(UIGestureRecognizerState)gestureState;
{
    if (_screenSetting == MapViewScreenSettingTriScreen)
    {
        CGFloat currentPlatScale = [[_platView.layer valueForKeyPath:@"transform.scale"] floatValue];
        
        if (gestureState == UIGestureRecognizerStateBegan)
        {
            UIView *platIndicatorView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, (5.0 / currentPlatScale), 1024.0)];
            platIndicatorView.backgroundColor = UIColor.redColor;
            [_platView addSubview:platIndicatorView];
            
            CGFloat currentProfileScale = [[_profileView.layer valueForKeyPath:@"transform.scale"] floatValue];
            
            UIView *profileIndicatorView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, (5.0 / currentProfileScale), 1024.0)];
            profileIndicatorView.backgroundColor = UIColor.redColor;
            [_profileView addSubview:profileIndicatorView];
            
            _targetView.hidden = NO;
        }
        
        else if (gestureState == UIGestureRecognizerStateEnded)
        {
            for (UIView *subviews in _platView.subviews)
                [subviews removeFromSuperview];
            
            for (UIView *subviews in _profileView.subviews)
                [subviews removeFromSuperview];
            
            _targetView.hidden = YES;
            
            return;
        }
        
        for (UIView *subviews in _platView.subviews)
            subviews.center = CGPointMake(xFrame, (_platView.center.y));
        
        for (UIView *subviews in _profileView.subviews)
        {
            CGFloat minY, maxY;
            CGFloat xPosition = [_profileView referenceLineAtX:xImage];
            if (xPosition < 0 || xPosition > _profileView.frame.size.width)
            {
                if ([_platView getYValueRangeForProfileAtX:xImage
                                                    minY:&minY
                                                    maxY:&maxY])
                {
                    [_profileView zoomImage:_platView.image
                                        atX:xImage
                                   fromMinY:minY
                                     toMaxY:maxY];
                }
            }
            else
                subviews.center = CGPointMake(xPosition, _profileView.center.y);
        }
        
        _targetView.center = superpoint;
    }
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

- (void)mapToolbarDidSelectMarkerSwitch:(BOOL)option
{
    if (option)
        _clearMarkers = NO;
    
    else
    {
        for (MarkerButton *markers in _markerArray)
            [markers removeFromSuperview];
        
        [_markerArray removeAllObjects];
        [self removePreviousInfoWindow];
        _clearMarkers = YES;
    }
}

- (void)mapToolbarDidSelectDigitize
{
    switch (ConfigurationControl.sharedInstance.currentApp)
    {
        case HCConfigAlleyWalls:
            _digitizationMode = DigitizationModeAlleyWallNew;
            break;
            
        case HCConfigMetroProp:
            _digitizationMode = DigitizationModeProperty;
            break;
        
        case HCConfigSewers:
            _digitizationMode = DigitizationModeSewer;
            break;
            
        case HCConfigCurbRamps:
            _digitizationMode = DigitizationModeCurbRamps;
            break;
            
        default:
            break;
    }
    
    _inDigitizationMode = YES;
    [self hideMarkersAndInfoWindows];
    [_mapToolbar hide];
    [self showDigitizer:NO];
}

- (void)mapToolbarDidSelectLegends
{
    _options = @[@"Alley Centerline Status", @"Alley Wall Status"];
    
    if (_options.count > 0)
    {
        _tableViewSetting = PropertyTableViewSettingOptions;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        _tableView.allowsSelection = YES;
        _tableView.delaysContentTouches = NO;
        [_tableView reloadData];
        [self presentTableView];
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
    CGFloat statusBarHeight = [self statusBarHeight:self.interfaceOrientation];
    CGFloat tabBarTop = self.tabBarController.tabBar.frame.origin.y;
    
    //frame with no height for hidden views
    CGRect frame0 = CGRectMake(0.0,
                               tabBarTop,
                               self.view.frame.size.width, 0.0);
    
    //bottom half of split screen
    CGRect frame1 = CGRectMake(0.0,
                               (statusBarHeight + ((tabBarTop - statusBarHeight) / 2.0)),
                               self.view.frame.size.width,
                               ((tabBarTop - statusBarHeight) / 2.0));
    
    //upper third of tri screen
    CGRect frame2 = CGRectMake(0.0,
                               (statusBarHeight + ((tabBarTop - statusBarHeight) / 3.0)),
                               self.view.frame.size.width,
                               ((tabBarTop - statusBarHeight) / 3.0));
    
    //middle third of tri screen
    /*CGRect frame3 = CGRectMake(0.0,
                               (statusBarHeight + ((tabBarTop - statusBarHeight) / 1.5)),
                               (self.view.frame.size.width / 2.0),
                               ((tabBarTop - statusBarHeight) / 3.0));*/
    
    //bottom third of tri screen
    CGRect frame4 = CGRectMake(0.0,
                               (statusBarHeight + ((tabBarTop - statusBarHeight) / 1.5)),
                               self.view.frame.size.width,
                               ((tabBarTop - statusBarHeight) / 3.0));
    
    //bottom right of split bottom
    /*CGRect frame5 = CGRectMake((self.view.frame.size.width / 2.0),
                               (statusBarHeight + ((tabBarTop - statusBarHeight) / 1.5)),
                               (self.view.frame.size.width / 2.0),
                               ((tabBarTop - statusBarHeight) / 3.0));*/
    
    //fullscreen (except not status bar)
    CGRect frame6 = CGRectMake(0.0, statusBarHeight,
                               self.view.frame.size.width,
                               (tabBarTop - statusBarHeight));
    
    [self clearVectorView];
    
    if ([_firstView.subviews containsObject:_platView])
        [_platView removeFromSuperview];
    
    if (_screenSetting == MapViewScreenSettingTriScreen &&
        setting != MapViewScreenSettingTriScreen)
    {
        if ([_firstView.subviews containsObject:_profileView])
            [_profileView removeFromSuperview];
        
        if (_profileView.image)
            _profileView.image = nil;
       
        if (_profileView)
            _profileView = nil;
    }
    
    if (setting == MapViewScreenSettingPlatView)
    {
        [self hideCompass];
        [_mapToolbar platViewMode:setting];
    }
    
    else
    {
        [self showCompass];
        
        if (_screenSetting == MapViewScreenSettingPlatView)
            [_mapToolbar normalMode:setting];
    }
    
    switch (setting)
    {
        case MapViewScreenSettingFullscreen:
        {
            [UIView animateWithDuration:0.25
                             animations:^{
                                 _mapView.layer.borderWidth = 0.0;
                                 _mapView.frame = _vectorView.frame = frame6;
                                 [self updateMarkerPosition];
                             }
                             completion:^(BOOL finished) {
                                 [self refreshVectorView:_mapView.projection.visibleRegion
                                                  atZoom:_mapView.camera.zoom];
                             }];
            
            [UIView animateWithDuration:0.25
                             animations:^{
                                 _firstView.frame = _secondView.frame = frame0;
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
            
            _screenSetting = MapViewScreenSettingTriScreen;
        }
            break;
            
        case MapViewScreenSettingPlatView:
        {
            [UIView animateWithDuration:0.25
                             animations:^{
                                 _firstView.frame =
                                 CGRectMake(0.0, statusBarHeight,
                                            self.view.frame.size.width,
                                            (tabBarTop - statusBarHeight));
                             }];
            
            [UIView animateWithDuration:0.25
                             animations:^{
                                 _secondView.frame = frame0;
                             }];
            
            _screenSetting = MapViewScreenSettingPlatView;
        }
            
            /*
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
            
            _screenSetting = MapViewScreenSettingSplitBottomScreen;
        }
            break;
             */
    }
    
            
    if (setting != MapViewScreenSettingFullscreen)
    {
        CGRect frame = CGRectZero;
        
        switch (setting)
        {
            case MapViewScreenSettingSplitScreen:
                frame = CGRectMake(0.0, 0.0, frame1.size.width, frame1.size.height);
                break;
                
            case MapViewScreenSettingTriScreen:
                frame = CGRectMake(0.0, 0.0, frame2.size.width, frame2.size.height);
                break;
                
            case MapViewScreenSettingPlatView:
                frame = CGRectMake(0.0, 0.0, frame6.size.width, frame6.size.height);
        }
        
        _platView = [PlatImageView platImageViewWithDelegate:self
                                                    andFrame:frame];
        
        if (_selectedPlatRefno > 0)
        {
            [_platView setPlatID:_selectedPlatRefno
                         andType:PLAT_TYPE_STORM];
        }
        
        [self performSelector:@selector(addPlatView)
                   withObject:nil
                   afterDelay:0.3];
        
        if (setting == MapViewScreenSettingTriScreen)
        {
            _profileView = [[PlatProfileView alloc] init];
            _profileView.contentMode = UIViewContentModeScaleAspectFit;
            _profileView.frame = CGRectMake(0.0, 0.0, frame4.size.width, frame4.size.height);
            [self addProfileView];
        }
    }
}

- (void)addPlatView
{
    [_firstView addSubview:_platView];
    _platView.originalSize = _firstView.frame.size;
    
    if (_screenSetting != MapViewScreenSettingPlatView)
        [self syncPlatView];
}

- (void)addProfileView
{
    _profileView.image = _platView.image;
    [_secondView addSubview:_profileView];
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
    
    if (_screenSetting == MapViewScreenSettingTriScreen)
    {
        [_profileView zoomImage:_platView.image
                            atX:minYpt.x
                       fromMinY:minYpt.y
                         toMaxY:maxYpt.y];
    }
    
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithTarget:pTarget
                                                               zoom:pZoom
                                                            bearing:pBearing
                                                       viewingAngle:0.0];
    
    [_mapView animateToCameraPosition:camera];
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
                                   refno:(NSInteger)refno
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
                _options = @[@"Property Report", @"Hennepin County Website", @"Display Street View", @"Zoom to Census Area",
                             @"Add to Property List", @"Add to Desinations", @"Remove Property Marker"];
            }
            
            else
            {
                _options = @[@"Property Report", @"Display Street View", @"Zoom to Census Area",
                             @"Add to Property List", @"Add to Desinations", @"Remove Property Marker"];
            }
            
            break;
            
        case MarkerInfoWindowTypeStormSewer:
            _selectedSewerPipe = title;
            
            _options = @[@"Display Pipe Attributes", @"Trace Pipe Upstream",
                         @"Trace Pipe Downstream", @"Remove Pipe Trace", @"Update Cleaning Date",
                         @"Update Inspection Notes", @"Remove Pipe Marker"];
            
            break;
            
        case MarkerInfoWindowTypeAlleyWall:
            _selectedAlleyWall = title;
            _selectedAlleyWallRefno= refno;
            
            _options = @[@"Move Wall Point", @"Delete Wall Point", @"Edit Wall Attributes",
                         @"View Wall Photos", @"Remove Alley Wall Marker"];
            
            break;
            
        case MarkerInfoWindowTypeAlleyLine:
            _selectedAlleySeg = title;
            _selectedAlleyLineRefno = refno;
            _options = @[@"Toggle Alley Line\nCompletion Status", @"Remove Alley Line Marker"];
            break;
            
        case MarkerInfoWindowTypeCustom:
            _options = @[@"Snap to Node", @"Snap to Line", @"Remove Custom Marker"];
            break;
    }
    
    if (_options.count > 0)
    {
        _tableViewSetting = PropertyTableViewSettingOptions;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        _tableView.allowsSelection = YES;
        _tableView.delaysContentTouches = NO;
        [_tableView reloadData];
        [self presentTableView];
    }
}

- (void)markerInfoWindowDidSelectPropReport:(NSString *)title
                                     coords:(CLLocationCoordinate2D)coords
                                       type:(NSInteger)type
{
    NSInteger option = 0;
    
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
                    
                default:
                    break;
            }
        }
            break;
            
        case MarkerInfoWindowTypeStormSewer:
        {
            _selectedSewerPipe = title;
            option = [UserDefaults.defaults integerForKey:@"SewerOption"];
            
            if (option == SewerPipeSettingDefault)
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
                    
                case SewerPipeSettingUpdateCleanDate:
                    [self updateCleaningDate];
                    break;
                    
                case SewerPipeSettingUpdateNotes:
                    [self updateInspectionNotes];
                    break;
                    
                default:
                    break;
            }
        }
            break;
            
        case MarkerInfoWindowTypeAlleyWall:
        {
            option = [UserDefaults.defaults integerForKey:@"AlleyWallOption"];
            
            if (option == AlleyWallSettingDefault)
                option = AlleyWallSettingEditWallAttributes;
            
            switch (option)
            {
                case AlleyWallSettingMoveWallPoint:
                    [self moveWallPoint];
                    break;
                    
                case AlleyWallSettingDeleteWallPoint:
                    [self deleteWallPoint];
                    break;
                    
                case AlleyWallSettingEditWallAttributes:
                    [self editWallAttributes];
                    break;
                    
                case AlleyWallSettingViewWallPhotos:
                    [self viewWallPhotos];
                    break;
                    
                default:
                    break;
            }
        }
            
        case MarkerInfoWindowTypeAlleyLine:
        {
            option = [UserDefaults.defaults integerForKey:@"AlleyLineOption"];
            
            if (option == AlleyLineSettingDefault)
                option = AlleyLineSettingToggleCompletionStatus;
            
            switch (option)
            {
                case AlleyLineSettingToggleCompletionStatus:
                    [self toggleCompletionStatus];
                    [self refreshVectorView:_mapView.projection.visibleRegion
                                     atZoom:_mapView.camera.zoom];
                    break;
                    
                default:
                    break;
            }
        }
            
        case MarkerInfoWindowTypeCustom:
        {
            option = [UserDefaults.defaults integerForKey:@"CustomOption"];
            
            if (option == CustomSettingDefault)
                option = CustomSettingSnapToLine;
            
            switch (option)
            {
                case CustomSettingSnapToLine:
                    [self snapToLine];
                    break;
                    
                case CustomSettingSnapToNode:
                    [self snapToNode];
                    break;
                    
                default:
                    break;
            }
        }
            
        default:
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

- (void)showCompass
{
    if (_compass.hidden && _mapView.camera.bearing != 0.0)
    {
        _compass.hidden = NO;
        
        [UIView animateWithDuration:0.25
                         animations:^{
                             _compass.alpha = 1.0;
                         }];
        
        [self.view bringSubviewToFront:_compass];
    }
}

- (void)touchesBegan:(NSSet *)touches
           withEvent:(UIEvent *)event
{
    for (GSSiDatePicker *datePicker in self.view.subviews)
    {
        if ([datePicker isKindOfClass:GSSiDatePicker.class])
        {
            SewerData *sewerData = [[SewerData alloc] init];
            
            [sewerData processDate:datePicker.dateString
                           forPipe:_selectedSewerPipe];
            
            [datePicker hideDatePicker:YES];
            [self deselectTableViewRow];
        }
    }
}

- (void)notesView:(GSSiNotesView *)notesView
     didSaveNotes:(NSString *)notes
             list:(NSArray *)list
{
    SewerData *sewerData = [[SewerData alloc] init];
    
    [sewerData processNotes:notes
                  notesList:list
                    forPipe:_selectedSewerPipe];
    
    [notesView hideNotesView:YES];
    [self deselectTableViewRow];
}

- (void)notesViewDidCancel:(GSSiNotesView *)notesView
{
    [notesView hideNotesView:YES];
    [self deselectTableViewRow];
}

- (void)notesView:(GSSiNotesView *)notesView
didFindMatchBetweenNote:(NSString *)note
    andItemInList:(NSString *)itemInList;
{
    GSSiAlertController *alert = [[GSSiAlertController alloc] initWithViewController:self];
    alert.delegate = notesView;
    
    [alert showAlertWithTitle:[NSString stringWithFormat:@"List already contains %@", itemInList]
                      message:nil
            cancelButtonTitle:@"Cancel"
            otherButtonTitles:@[[NSString stringWithFormat:@"Replace %@ with %@", itemInList, note],
                                [NSString stringWithFormat:@"Add %@ to list", note]]
    destructiveButtonPosition:0];
}

- (NSArray *)arrayOfPickableNotesItemsForNotesView:(GSSiNotesView *)notesView
{
    return nil;
}

- (void)launchAlleyWallApp
{
    NSString *AlleyWallURL = @"AlleyWallInventory://";
    
    [SharedDefaults.defaults saveString:@"GMMobile"
                                 forKey:@"SourceApplication"];
    
    if ([UIApplication.sharedApplication canOpenURL:[NSURL URLWithString:AlleyWallURL]])
        [UIApplication.sharedApplication openURL:[NSURL URLWithString:AlleyWallURL]];
    
    else
    {
        [_gssiAlert showAlertWithTitle:@"GMMobile cannot launch Alley Wall Inventory"
                               message:nil
                     cancelButtonTitle:@"OK"
                     otherButtonTitles:nil
             destructiveButtonPosition:0];
    }
}

BOOL CLLocationCoordinateEqual(CLLocationCoordinate2D coordinate1, CLLocationCoordinate2D coordinate2)
{
    return (fabs(coordinate1.latitude - coordinate2.latitude) < 0.00001) &&
           (fabs(coordinate1.longitude - coordinate2.longitude) < 0.00001);
}

- (void)largeAlertView:(NVLargeAlertView *)largeAlertView
   didTapButtonAtIndex:(NVLargeAlertIndex)buttonIndex
{
    if (buttonIndex == NVLargeAlertIndexTopButton)
    {
        AlleyWallData *awd = [[AlleyWallData alloc] init];
        
        [awd deleteAlleyWallPoint:_selectedAlleyWallRefno];
        
        [self dismissTableView];
        [self removePreviousInfoWindow];
        [self removeMarker];
        
        [self refreshVectorView:_mapView.projection.visibleRegion
                         atZoom:_mapView.camera.zoom];
    }
    
    [largeAlertView hideLargeAlertView:YES];
}

- (NSUInteger)numberOfRowsInLegendView
{
    return 3;
}

- (NSString *)nameForRowInLegendViewAtIndex:(NSUInteger)index
{
    NSArray *names = @[@"Completed", @"To Be Done", @"Other"];
    return [names objectAtIndex:index];
}

- (UIColor *)colorForRowInLegendViewAtIndex:(NSUInteger)index
{
    NSArray *colors = @[UserDefaults.defaults.appleBlue, UserDefaults.defaults.darkGreen, UIColor.redColor];
    return [colors objectAtIndex:index];
}

- (NSUInteger)countForRowInLegendViewAtIndex:(NSUInteger)index
{
    NSUInteger array[3] = {123, 456, 789};
    return array[index];
}

- (NSString *)titleForLegendView
{
    NSString *title = @"";
    
    switch(_alleyStatusSetting)
    {
        case AlleyStatusSettingWall:
            title = @"Wall Status";
            break;
            
        case AlleyStatusSettingCenterline:
            title = @"Centerline\nStatus";
            break;
            
        default:
            break;
    }
    
    return title;
}

- (void)twoTextAlert:(NVTwoTextAlert *)twoTextAlert
    didReturnTopText:(NSString *)topText
          bottomText:(NSString *)bottomText
{
    [SharedDefaults.defaults saveString:topText
                                 forKey:@"OrganizationName"];
    
    [SharedDefaults.defaults saveString:bottomText
                                 forKey:@"DeviceNumber"];
    
    [twoTextAlert hideTwoTextAlert:YES];
}

@end