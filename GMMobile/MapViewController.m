//  MapViewController.m
//  GMMobile

#import "MapViewController.h"
#import "AppDelegate.h"
#import "ConfigurationControl.h"
#import "MapViewENUMS.h"
#import "CCodeLibrary/PolylineCompression.h"
#import "CCodeLibrary/NVTabBarEdit.h"
#import "Destinations.h"
#import "CCodeLibrary/IntersectionsDatabase.h"
#import "NVPageController.h"
#import "CrimeDataOptions.h"
#import "UserLayerDisplay.h"
#import "CCodeLibrary/NVTextVC.h"
#import "CCodeLibrary/NVDigitizerView.h"
#import "CCodeLibrary/NVMarkerInfoButton.h"
#import "CCodeLibrary/NVPhotoController.h"
#import "CCodeLibrary/NVStreetSideController.h"
#import "CCodeLibrary/NVPopoverTableView.h"
#import "ChartsViewController.h"
#import "NVSpreadsheetDelegate.h"
#import "NVCrimeListDelegate.h"
#import "NVMetroSettingsVC.h"
#import "CCodeLibrary/NVPager.h"
#import "CCodeLibrary/NVSendEmail.h"
#import "NVPanoramaVC.h"
#import "CCodeLibrary/SidewalkData.h"
#import "CCodeLibrary/CRAPI.h"
#import "NVGeocoder.h"
#import "CCodeLibrary/shr.h"
#import "ConfigurationVC.h"
#import "CCodeLibrary/shr.h"
#import "FindViewController.h"
#import "BoundaryData.h"
#import "PlanimetricData.h"
#import "PipeTrace.h"
#import "VectorView.h"
#import "PlatImageView.h"
#import "PlatProfileView.h"
#import "LayersViewController.h"
#import "CCodeLibrary/MapToolbar.h"
#import "MarkerInfoWindow.h"
#import "MarkerButton.h"
#import "PropertyList.h"
#import "CrimeList.h"
#import "Destinations.h"
#import "NVDataLoader.h"
#import "CCodeLibrary/NVAlertView.h"
#import "ThemeLegendMapOverlay.h"
#import "CCodeLibrary/FTPDirectoryList.h"
#import "CCodeLibrary/YTPlayerView.h"
#import "CCodeLibrary/RiteHome.h"
#import "CCodeLibrary/NVEmailFileList.h"
#import "HuntingDataDisplay.h"
#import "CompassViewController.h"
#import "CCodeLibrary/NVTextViewAlert.h"
#import "ProximityMapping.h"

#define MAX_VECTORVIEWS 8

@interface MGVPlatData : NSObject

@property (nonatomic, copy) NSString *pdfFile;
@property int page;
@property DPOINT ptUpper, ptLower;
@property CGFloat scaleUpper, scaleLower, rotUpper, rotLower, imageWidth, imageHeight;

@end

@implementation MGVPlatData

@end

@interface MapViewController () <NVDigitizerViewDelegate, NSURLSessionDataDelegate, NSURLSessionTaskDelegate, NVPhotoControllerDelegate, NVPhotoViewDelegate, NVWebViewDelegate, NVPopoverTableViewDelegate, UITabBarControllerDelegate, UIGestureRecognizerDelegate, NVPanoramaVCDelegate, NVGeocoderDelegate, GMSMapViewDelegate, UIGestureRecognizerDelegate, UITableViewDataSource, UITableViewDelegate, NVAlertViewDelegate, MapToolbarDelegate, VectorViewDelegate, CLLocationManagerDelegate, MarkerInfoWindowDelegate, PipeTraceDelegate, MarkerButtonDelegate, PlatImageViewDelegate, GSSiNotesViewDelegate, NVLegendViewDelegate, NVTwoTextAlertDelegate, NVDataLoaderDelegate, NSURLConnectionDataDelegate, ThemeLegendMapOverlayDelegate, CrimeDataDelegate, GSSiPopoverViewDelegate, FTPDirectoryListDelegate, FTPDataPullDelegate, PropertyListDelegate, WeatherDataDelegate,NVTextViewAlertDelegate>

@property (nonatomic) MGVPlatData *mgvData;
@property (nonatomic) CLLocationCoordinate2D target, selectedPIDCoords, currentLocation;
@property (nonatomic, copy) NSArray *options, *linkedList, *files;
@property (nonatomic) NSMutableArray *propertyReport, *markerArray, *pdfsArray, *insetPixArray;
@property PropertyTableViewSetting tableViewSetting;
@property (nonatomic) CGFloat screenSize;
@property (nonatomic) UIColor *tableViewBackgroundColor;
@property BOOL clearWhenDeselected, legendsAreOffMap, showsPanorama, usePlatView;
@property BOOL firstTimeAppear, firstTimeMap, noneSelected, moveDigitizer, routeTraceExists;
@property (nonatomic, copy) NSString *selectedPID, *selectedSanPoint, *selectedSanMain, *selectedPlat, *routeMode;
@property int selectedPlatRefno, nVectorViews;
@property CGFloat vectorViewZoom, mapViewLegendOffset, compassSize;
@property CGFloat currentScreenHeight, splitScreenBorderWidth, tabBarHeight;
@property CGFloat heading, pitch, fov;
@property (nonatomic) VectorView *vectorView;
@property (nonatomic) NSTimer *vectorViewTimer;
@property (nonatomic) UIImageView *targetView, *digitizerTargetView;
@property (nonatomic) UIView *firstView, *secondView;
@property MapViewScreenSetting screenSetting;
@property NSInteger gestureCount, digitizerCount;
@property (nonatomic) MapToolbar *mapToolbar;
@property (nonatomic) CLLocationManager *locationManager;
@property (nonatomic) MarkerInfoWindow *infoWindow;
@property (nonatomic, copy) NSString *selectedSewerPipe, *selectedAlleyWall, *selectedAlleySeg, *selectedCRIntPt, *selectedBA;
@property NSInteger selectedCrime, selectedCensusBoundaryRefno, selectedBARefNo;
@property (nonatomic, copy) NSString *selectedCensusBoundaryType, *currentAddress;
@property int selectedMGVSanMH, selectedMGVSanPipe;
@property NSInteger selectedSewerPipeRefno, selectedAlleyWallRefno, selectedAlleyLineRefno;
@property BOOL waitForVectorViewRefresh, inDigitizationMode, animateToLocation, displayRandomColorAlert;
@property (nonatomic) GMSTileLayer *layer_jpeg;
@property (nonatomic) GMSTileLayer *layer_png;
@property (nonatomic) UIButton *compass;
@property (nonatomic) PlatImageView *platView;
@property (nonatomic) PlatProfileView *profileView;
@property (nonatomic) CGPoint digitizingTargetOffset;
@property (nonatomic) UIImage *blackCrosshairs, *orangeCrosshairs;
@property (nonatomic) UIView *digitizationToolbar;
@property (nonatomic) UIButton *cancelDigitizerButton, *saveDigitizerButton, *legendMinimizeButton;
@property DigitizationMode digitizationMode;
@property AlleyStatusSetting alleyStatusSetting;
@property (nonatomic) NVDataLoader *nvdl;
@property (nonatomic) NVLegendView *legendView;
@property (nonatomic) NSInteger locationCount, headingCount;
@property (nonatomic) GMSPolyline *polyline;
@property (nonatomic) NSMutableSet *polylines;
@property (nonatomic) UIScrollView *legendScrollView;
@property (nonatomic) UIImageView *myLocationMarker;
@property NSUInteger currentLegendTag, pdfCount;
@property NVColorOption currentColorOption;
@property (nonatomic) NVDigitizerView *nvdv;
@property (nonatomic) CrimeData *cd, *cdUpdate;
@property (nonatomic) NSMutableString *dataString;
@property BOOL splitPlatView, keepZoomExtents, grayscaleMode;
@property int splitPlatDirection, vvpass, currentFile;
@property NVMarkerStyle markerStyle;
@property (nonatomic) NVSpreadsheetVC *nvssvc;
@property (nonatomic) UITapGestureRecognizer *zoomExtentsGesture;
@property BOOL continueLoad, fromLegends2X;
@property (nonatomic) GMSCameraPosition *currentPosition;
@property (nonatomic) YTPlayerView *youTubePlayer;
@property (nonatomic) UIButton *ytReturnButton;
@property PropertyList *propertyList;
@property NSString * propYearAndQuarter;
@property CGPoint mapToolbarCenter;
@property LLPOINT llPickedPt;
@property BOOL amAcceptingHeading;
@property int numCurrentRoutePoints;
@property CAShapeLayer *trackLayer;
@property CAShapeLayer *scaleLayer, *scaleLayer2;
@property CAShapeLayer *weatherLayer;
@property BOOL displayTrackingRoute;
@property UILabel *scaleLabel,*scaleLabel2;
@property int  pickedRefno;
@property BOOL hideScaleBar;
@property NSMutableArray * forecastDates;
@property WeatherRecord * currentWeatherData;
@property UIImageView* windImage;
@property UILabel * weatherLabel;
@property NSArray * currentForecast;
@property int needToSetVehicleLocation;
@property NSMutableArray * routeSubLayers;
@property int mapTypeFromConfig;
@end

@implementation MapViewController
{
    VectorView *vectorViews[MAX_VECTORVIEWS];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSLog(@"available storage space:%llu bytes", (unsigned long long)UIDevice.availableStorageSpace);
    UITabBarAppearance *appearance = UITabBarAppearance.new;
    [appearance configureWithOpaqueBackground];
    appearance.backgroundColor = [UIColor whiteColor];
    self.tabBarController.tabBar.backgroundColor = [UIColor whiteColor];
    //self.tabBarController.tabBar.standardAppearance = appearance;
    [NVTabBarEdit tabBarController:self.tabBarController removeViewControllerWithID:@"FieldOptionsVC"];
    [NVTabBarEdit tabBarController:self.tabBarController removeViewControllerWithID:@"DestinationsVC"];
    [NVTabBarEdit tabBarController:self.tabBarController removeViewControllerWithID:@"CurbRampDataOptionsVC"];
    [NVTabBarEdit tabBarController:self.tabBarController removeViewControllerWithID:@"CrimeDataOptionsVC"];
    self.tabBarController.delegate = self;
    _nvssvc = NVSpreadsheetVC.new;
    _nvssvc.restorationIdentifier = @"NVSpreadsheet";
    
    _nvssvc.tabBarItem.image = [UIImage imageWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"spreadsheetIcon"
                                                                                              ofType:@"png"]];
    
    if (![CRAPI.sharedInstance.bundleID isEqualToString:@"com.gssi.newvisionmobile"] &&
        ![CRAPI.sharedInstance.bundleID isEqualToString:@"com.gssi.newvisionaccess"])
    {
        [NVTabBarEdit tabBarController:self.tabBarController removeViewControllerWithID:@"ApplicationsVC"];
        
        if ([CRAPI.sharedInstance.bundleID isEqualToString:@"com.gssi.newvisionaccess"])
            [NVTabBarEdit tabBarController:self.tabBarController setText:@"Projects" forViewControllerWithID:@"ApplicationsVC"];
    }
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(becameActive:)
                                               name:@"didBecomeActive"
                                             object:nil];
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(resignedActive:)
                                               name:@"didResignActive"
                                             object:nil];
    
    CGFloat statusBarHeight = [self statusBarHeight:UIApplication.sharedApplication.statusBarOrientation];
    CGFloat tabBarTop = self.tabBarController.tabBar.frame.origin.y;
    
    _nVectorViews = _currentLegendTag = _pdfCount = 0,
    _animateToLocation = _usePlatView = _keepZoomExtents = YES;
    _routeTraceExists = _fromSpreadsheet = _legendsAreOffMap = _displayRandomColorAlert = NO;
    _showsPanorama = _splitPlatView = _grayscaleMode = NO;
    _routeMode = @"driving";
    _mapViewLegendOffset = (ThemeLegendMapOverlay.width + 4.0);
    
    _legendScrollView = UIScrollView.new;
    _legendScrollView.translatesAutoresizingMaskIntoConstraints = NO;
    _legendScrollView.backgroundColor = UIColor.lightGrayColor;
    _legendScrollView.alpha = 0.0;
    _legendScrollView.clipsToBounds = NO;
    [self.view addSubview:_legendScrollView];
    [_legendScrollView constrainLeadingToAnchor:self.view.trailingAnchor constant:-_mapViewLegendOffset];
    [_legendScrollView constrainTrailingToAnchor:self.view.trailingAnchor];
    [_legendScrollView constrainTopToAnchor:self.view.topAnchor constant:statusBarHeight];
    [_legendScrollView constrainBottomToAnchor:self.view.bottomAnchor];
                         
    _polylines = NSMutableSet.set;
    
    for (int i = 0; i < MAX_VECTORVIEWS; i++)
        vectorViews[i] = nil;
    
    [PipeTrace removeTrace];
    
    _firstTimeAppear = _firstTimeMap = YES;
    CRAPI.sharedInstance.firstTimeZoomToCentract = YES;
    _digitizationMode = DigitizationModeCustom;
    _locationCount = _headingCount = 0;
    MNMXCORD lastBounds;
    float zoom = 12.0;
    if (![CRAPI.sharedInstance getLastBounds:&lastBounds
                                     andZoom:&zoom])
    {
        self.target = CLLocationCoordinate2DMake(44.97, -93.27);
    }
    else
    {
        DPOINT midPt = DBoundsMid(&lastBounds);
        self.target = CLLocationCoordinate2DMake(midPt.y,midPt.x);
    }
    CGRect mapFrame = self.view.frame;
    mapFrame.origin.y = 48;
    int top = self.view.safeAreaInsets.top;
    _mapView = [[GMSMapView alloc] initWithFrame:mapFrame];
    //_mapView = GMSMapView.new;
    _mapView.translatesAutoresizingMaskIntoConstraints = NO;
    _mapView.delegate = self;
    _mapView.mapType = kGMSTypeNormal;
    [self setMapType];
    _mapView.settings.compassButton = NO;
    _mapView.settings.rotateGestures = YES;
    _mapView.settings.tiltGestures = NO;
    _mapView.camera = [GMSCameraPosition cameraWithTarget:_target zoom:zoom];
    [self.view addSubview:_mapView];
    [_mapView constrainToView:self.view leading:0.0 trailing:0.0 top:top bottom:0.0];
    
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
    
    _digitizerTargetView.image = _blackCrosshairs;
    [self.view addSubview:_digitizerTargetView];
    
    _digitizationToolbar = UIView.new;
    _digitizationToolbar.translatesAutoresizingMaskIntoConstraints = NO;
    _digitizationToolbar.backgroundColor = UserDefaults.defaults.appleBlue;
    _digitizationToolbar.layer.borderColor = UIColor.darkGrayColor.CGColor;
    _digitizationToolbar.layer.borderWidth = 1.0;
    _digitizationToolbar.alpha = 0.0;
    [self.view addSubview:_digitizationToolbar];
    
    _cancelDigitizerButton = [UIButton buttonWithType:UIButtonTypeCustom];
    
    [self setupDigitizerToolbarButton:_cancelDigitizerButton
                             selector:@selector(hideDigitizationMode:)
                                title:@"Cancel Move/Add Mode"];
    
    _saveDigitizerButton = [UIButton buttonWithType:UIButtonTypeCustom];
    
    [self setupDigitizerToolbarButton:_saveDigitizerButton
                             selector:@selector(hideDigitizationMode:)
                                title:@"Exit Move/Add Mode"];
    
    _saveDigitizerButton.alpha = 0.0;
/*
    UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                                                   action:@selector(mapViewLongPressed:)];
    longPressGesture.numberOfTouchesRequired = 1;
    longPressGesture.numberOfTapsRequired = 0;
    longPressGesture.minimumPressDuration = 1;
    longPressGesture.delegate = self;
    [_mapView addGestureRecognizer:longPressGesture];
*/
    GMSTileURLConstructor constructor_jpeg = ^(NSUInteger x, NSUInteger y, NSUInteger zoom) {
        NSString *url = [NSString stringWithFormat:@"http://%@/MPLSADA/%lu/%lu/%lu.jp2",[CRAPI.sharedInstance getNVCRISServer],
                         (unsigned long)zoom, (unsigned long)y, (unsigned long)x];
        
        return [NSURL URLWithString:url];
    };
    
    GMSTileURLConstructor constructor_png = ^(NSUInteger x, NSUInteger y, NSUInteger zoom) {
        NSString *url = [NSString stringWithFormat:@"http://%@/MPLSADA/%lu/%lu/%lu.png",[CRAPI.sharedInstance getNVCRISServer],
                         (unsigned long)zoom, (unsigned long)y, (unsigned long)x];
        
        return [NSURL URLWithString:url];
    };
    
    _layer_jpeg = [GMSURLTileLayer tileLayerWithURLConstructor:constructor_jpeg];
    _layer_png = [GMSURLTileLayer tileLayerWithURLConstructor:constructor_png];
    
    _markerArray = NSMutableArray.array;
    _insetPixArray = NSMutableArray.array;
    
    _locationManager = [CRAPI.sharedInstance getLocationManager];
    _locationManager.delegate = self;
    _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    
    if ([_locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)])
        [_locationManager requestWhenInUseAuthorization];
    
    self.view.backgroundColor = UIColor.blackColor;
    
    _popover = [[GSSiPopoverView alloc] initWithView:self.view];
    _popover.hideAtCancel = NO;
    _popover.delegate = self;
    
    _tableViewBackgroundColor = [UIColor colorWithRed:0.0 green:0.0  blue:0.3 alpha:1.0];
    
    _clearWhenDeselected = YES;
    _cityInnerBounds.origin.x = 64631097;
    _cityInnerBounds.origin.y = 96565088;
    _cityInnerBounds.size.width = 83010;
    _cityInnerBounds.size.height = 103220;
    _tabBarHeight = self.tabBarController.tabBar.frame.size.height;
    
    _firstView = [[UIView alloc] init];
    _secondView = [[UIView alloc] init];
    _firstView.clipsToBounds = _secondView.clipsToBounds = YES;
    
    _firstView.frame = _secondView.frame = CGRectMake(0.0, tabBarTop,
                                                      self.view.frame.size.width, 0.0);

    _splitScreenBorderWidth = 2.0;
    
    _firstView.layer.borderColor = _secondView.layer.borderColor = _mapView.layer.borderColor = UIColor.darkGrayColor.CGColor;
    _firstView.backgroundColor = [UIColor colorWithRed:0.8 green:0.9 blue:1.0 alpha:1.0];
    _secondView.backgroundColor = [UIColor colorWithRed:0.9 green:1.0 blue:0.8 alpha:1.0];
    _firstView.layer.borderWidth = _secondView.layer.borderWidth = _splitScreenBorderWidth;
    [self.view addSubview:_firstView];
    [self.view addSubview:_secondView];
    [self setupTableView];
    
    _mapToolbarCenter = CGPointMake((self.view.frame.size.width / 2.0),
                                           (_mapToolbar.frame.size.height / 2.0) + statusBarHeight);
    
    _mapToolbar = [MapToolbar showMapToolbarWithCenter:_mapToolbarCenter
                                                  view:self.view
                                              delegate:self];
    
    _mapToolbar.hidden = YES;
    _mapToolbar.legendOffset = _mapViewLegendOffset;
    CRAPI.sharedInstance.mapToolbar = _mapToolbar;
    [ConfigurationControl setupMapToolbar];
    CRAPI.sharedInstance.mapVC = self;
    
    NSInteger configIndex = [UserDefaults.defaults integerForKey:@"CurrentConfig"];
    
    if (configIndex)
    {
        HardCodedConfigs config = (configIndex - 1);
        _nvdl = [[NVDataLoader alloc] init];
        _nvdl.delegate = self;
        [_nvdl loadNVData:config popover:_popover];
    }
    
    UIImage *compassImage = [UIImage imageWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"compass"
                                                                                           ofType:@"png"]];
    
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
        _compassSize = 44.0;
    
    else
        _compassSize = 52.0;
    
    _compass = [UIButton buttonWithType:UIButtonTypeCustom];
    _compass.frame = CGRectMake(0.0, 0.0, _compassSize, _compassSize);
    _compass.backgroundColor = UIColor.whiteColor;
    _compass.layer.cornerRadius = (_compassSize / 2.0);
    _compass.layer.borderWidth = 1.0;
    _compass.layer.borderColor = UIColor.lightGrayColor.CGColor;
    _compass.alpha = 0.0;
    _compass.hidden = YES;
    [_compass setImage:compassImage forState:UIControlStateNormal];
    
    [_compass addTarget:self
                 action:@selector(compassTapped:)
       forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:_compass];
    
    _myLocationMarker = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, 60.0, 60.0)];
    _myLocationMarker.backgroundColor = UIColor.clearColor;
    _myLocationMarker.hidden = YES;
    
    _myLocationMarker.image = [UIImage imageWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"myLocationMarker"
                                                                                             ofType:@"png"]];
    
    [self.view addSubview:_myLocationMarker];
    _markerStyle = [UserDefaults.defaults integerForKey:@"MarkerStyle"];
    
    _legendMinimizeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _legendMinimizeButton.translatesAutoresizingMaskIntoConstraints = NO;
    _legendMinimizeButton.backgroundColor = _mapToolbar.backgroundColor;
    _legendMinimizeButton.layer.borderColor = _mapToolbar.layer.borderColor;
    _legendMinimizeButton.layer.borderWidth = _mapToolbar.layer.borderWidth;
    _legendMinimizeButton.layer.cornerRadius = 10.0;
    _legendMinimizeButton.titleLabel.font = [UIFont boldSystemFontOfSize:24.0];
    [_legendMinimizeButton setTitle:@"L" forState:UIControlStateNormal];
    [_legendMinimizeButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    [_legendMinimizeButton setTitleColor:UIColor.darkGrayColor forState:UIControlStateHighlighted];
    
    [_legendMinimizeButton addTarget:self
                              action:@selector(expandLegends:)
                    forControlEvents:UIControlEventTouchUpInside];
    top = self.view.safeAreaInsets.top;
    iii = top;
}
- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (void)becameActive:(id)selector
{
    if (CRAPI.sharedInstance.setToAlleyWalls)
    {
        [UserDefaults.defaults saveNSInteger:(HCConfigAlleyWalls + 1) forKey:@"CurrentConfig"];
        [ConfigurationControl.sharedInstance setApp:HCConfigAlleyWalls];
        CRAPI.sharedInstance.setToAlleyWalls = NO;
    }
    [self vectorViewRefresh];
}

- (void)resignedActive:(id)selector
{
    [self clearVectorView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    CGRect r = _mapView.frame;
    r = self.view.frame;
    if ([CRAPI.sharedInstance.bundleID isEqualToString:@"com.gssi.newvisionmetro"])
    {

    }
    
    else if ([CRAPI.sharedInstance.bundleID isEqualToString:@"com.gssi.newvisioncrime"])
    {
        
    }
    
    else if ([CRAPI.sharedInstance.bundleID isEqualToString:@"com.gssi.newvisionsidewalk"])
    {
        if (_firstTimeAppear)
            self.tabBarController.tabBar.hidden = YES;
    }
    
    else if ([CRAPI.sharedInstance.bundleID isEqualToString:@"com.gssi.newvisionmngame"])
    {
        if (_firstTimeAppear)
        {
            self.tabBarController.tabBar.hidden = YES;
            [_mapView constrainToView:self.view leading:0.0 trailing:0.0 top:0.0 bottom:0.0];
        }
    }
    
    else if (!_fromSpreadsheet)
    {
        NSInteger configIndex = [UserDefaults.defaults integerForKey:@"CurrentConfig"];
        
        if (configIndex)
        {
            HardCodedConfigs config = (configIndex - 1);
            [ConfigurationControl.sharedInstance setApp:config];
        }
        
        else
            self.tabBarController.selectedIndex = 3;
    }
    
    if (CRAPI.sharedInstance.appChanged)
    {
        [self themeLegendWasDraggedOffLeftSide];
        [self clearMapItems];
        _mapView.mapType = ConfigurationControl.sharedInstance.mapType;

        for (ThemeLegendMapOverlay *tlmos in self.view.subviews)
        {
            if ([tlmos isKindOfClass:ThemeLegendMapOverlay.class])
                [tlmos removeFromSuperview];
        }
        
        CRAPI.sharedInstance.appChanged = NO;
        CRAPI.sharedInstance.spreadsheetDelegate = nil;
        
        switch (ConfigurationControl.sharedInstance.currentApp)
        {
            case HCConfigMetroProp:
                CRAPI.sharedInstance.spreadsheetDelegate = NVSpreadsheetDelegate.new;
                _nvssvc.delegate = CRAPI.sharedInstance.spreadsheetDelegate;
                _nvssvc.tabBarItem.title = @"Property List";
                break;
            case HCConfigCrimes:
                CRAPI.sharedInstance.spreadsheetDelegate = NVCrimeListDelegate.new;
                _nvssvc.delegate = CRAPI.sharedInstance.spreadsheetDelegate;
                _nvssvc.tabBarItem.title = @"Crime List";
                break;
            default:break;
        }
    }
    
    if (_fromLegends)
    {
        self.view.userInteractionEnabled = NO;
        self.tabBarController.tabBar.userInteractionEnabled = NO;
    }
    
    else
    {
        self.view.userInteractionEnabled = YES;
        self.tabBarController.tabBar.userInteractionEnabled = YES;
    }
    
    if (ConfigurationControl.sharedInstance.currentApp != HCConfigAlleyWallStatus)
    {
        if ([self.view.subviews containsObject:_legendView])
            [_legendView hideLegendView:NO];
    }
    
    for (NVWebView *nvwv in self.view.subviews)
    {
        if ([nvwv isKindOfClass:NVWebView.class])
            [self.view bringSubviewToFront:nvwv];
    }
    
    if (_inDigitizationMode)
        _digitizerTargetView.alpha = 1.0;
    
    else
        _digitizerTargetView.alpha = 0.0;
    
    [self initTableView];
    
    if ([ConfigurationControl.sharedInstance haveUserAerials])
        _mapView.mapType = kGMSTypeNormal;
    
    else
    {
        if (![ConfigurationControl.sharedInstance useMapTypeControl] &&
             [ConfigurationControl.sharedInstance layer:HCLayerAerials
                                          visibleAtZoom:CRAPI.sharedInstance.currentZoom
                                                andPass:-1])
            _mapView.mapType = kGMSTypeHybrid;
    }
    if (ConfigurationControl.sharedInstance.currentApp == HCConfigMinnesotaGame)
    {
        _mapView.settings.scrollGestures = NO;
        _mapView.settings.zoomGestures = NO;
        _mapView.settings.rotateGestures = NO;
    }
    
    else
    {
        _mapView.settings.scrollGestures = YES;
        _mapView.settings.zoomGestures = YES;
        _mapView.settings.rotateGestures = YES;
    }
    
    if (CRAPI.sharedInstance.GMMSetting == GMMSettingPID || CRAPI.sharedInstance.GMMSetting == GMMSettingAddress ||
        CRAPI.sharedInstance.GMMSetting == GMMSettingPropOwner || CRAPI.sharedInstance.GMMSetting == GMMSettingMultipleProps)
    {
        GMSCameraPosition *camera = nil;
        MarkerButton *marker = nil;
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
        
        for (MarkerButton *marker in _markerArray)
        {
            if ([marker.title isEqualToString:_selectedPID])
                [marker removeFromSuperview];
        }
        
        if (CRAPI.sharedInstance.GMMSetting == GMMSettingMultipleProps)
        {
            [self clearMapItems];
            
            for (PropertyRecord *propRec in _propArray)
            {
                marker = [MarkerButton markerWithPosition:propRec.coordinate
                                                     view:self.view
                                                      map:_mapView
                                          statusBarHeight:[self statusBarHeight:UIApplication.sharedApplication.statusBarOrientation]
                                                 delegate:self];
                
                marker.title = propRec.pin;
                marker.snippet = propRec.propOwner;
                marker.type = MarkerInfoWindowTypePID;
                [_markerArray addObject:marker];
            }
            
            if (_propArray.count)
            {
                CLLocationCoordinate2D myLocation = ((MarkerButton *)_markerArray.firstObject).position;
                
                GMSCoordinateBounds *bounds = [[GMSCoordinateBounds alloc] initWithCoordinate:myLocation
                                                                                   coordinate:myLocation];
                
                for (MarkerButton *marker in _markerArray)
                    bounds = [bounds includingCoordinate:marker.position];
                
                [self animateWithCameraUpdate:[GMSCameraUpdate fitBounds:bounds
                                                             withPadding:40.0]];
            }
        }
        
        else
        {
            _selectedPID = CRAPI.sharedInstance.currentPID;
            
            PropertyData *propData = [[PropertyData alloc] init];
            
            _propYearAndQuarter = propData.yearAndQuarter;
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
            
            [self animateToCameraPosition:camera];
            _selectedPIDCoords = pidCoord;
            
            MarkerButton *marker = [MarkerButton markerWithPosition:pidCoord
                                                               view:self.view
                                                                map:_mapView
                                                    statusBarHeight:[self statusBarHeight:UIApplication.sharedApplication.statusBarOrientation]
                                                           delegate:self];
            
            [self removePreviousInfoWindow];
            _infoWindow = MarkerInfoWindow.new;
            _infoWindow.linkedPID = NO;
            
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
            marker.type = MarkerInfoWindowTypePID;
            [_markerArray addObject:marker];
            
            _infoWindow.marker = marker;
            _infoWindow.optionsTitle = marker.title;
            _infoWindow.delegate = self;
            _noneSelected = NO;
            [self.view addSubview:_infoWindow];
            [self updateInfoWindowPosition];
        }
        
        CRAPI.sharedInstance.GMMSetting = GMMSettingDefault;
    }
    
    [self setZoom:_mapView.camera.zoom];
    CGFloat statusBarHeight = [self statusBarHeight:UIApplication.sharedApplication.statusBarOrientation];
    if (_fromSpreadsheet)
    {
        if (!CRAPI.sharedInstance.justZoom)
        {
            [ConfigurationControl.sharedInstance setApp:HCConfigFromSpreadsheet];
            self.tabBarController.tabBar.hidden = YES;
            [_mapView constrainToView:self.view leading:0.0 trailing:0.0 top:statusBarHeight bottom:_tabBarHeight];
            _mapView.userInteractionEnabled = NO;
            _compass.hidden = YES;
            [self hideMarkersAndInfoWindows:NO];
        }
        
        else
        {
            [self zoomToBounds:NVMetroSettings.sharedInstance.savedVisibleBounds];
            [self showMarkersAndInfoWindows:NO];
            CRAPI.sharedInstance.justZoom = NO;
            _mapView.userInteractionEnabled = YES;
            _compass.hidden = NO;
            _fromSpreadsheet = NO;
        }
        
        [self setMapType];
    }
    
    else
    {
        self.tabBarController.tabBar.hidden = NO;

        
        if (_legendsAreOffMap)
            [_mapView constrainToView:self.view leading:0.0 trailing:-_mapViewLegendOffset top:statusBarHeight bottom:0.0];
        
        else
            [_mapView constrainToView:self.view leading:0.0 trailing:0.0 top:statusBarHeight bottom:0.0];
        
        _mapView.userInteractionEnabled = YES;
        
        [self showMarkersAndInfoWindows:NO];
    }
    
    for (NVMarkerInfoButton *nvmibs in self.view.subviews)
    {
        if ([nvmibs isKindOfClass:NVMarkerInfoButton.class])
            [nvmibs removeFromSuperview];
    }
    
    [_digitizationToolbar constrainLeadingToAnchor:_mapView.leadingAnchor];
    [_digitizationToolbar constrainTrailingToAnchor:_mapView.trailingAnchor];
    [_digitizationToolbar constrainTopToAnchor:_mapView.topAnchor];
    [_digitizationToolbar constrainHeightToConstant:80.0];
    [_cancelDigitizerButton constrainToView:_digitizationToolbar leading:0.0 trailing:0.0 top:0.0 bottom:0.0];
    [_saveDigitizerButton constrainToView:_digitizationToolbar leading:0.0 trailing:0.0 top:0.0 bottom:0.0];
    
    CGPoint targetPoint = [_mapView.projection pointForCoordinate:_mapView.camera.target];
    
    _digitizerTargetView.center = CGPointMake(targetPoint.x,
                                              (targetPoint.y + [self statusBarHeight:UIApplication.sharedApplication.statusBarOrientation]));
    
    if (!_tableView.hidden)
        [_tableView reloadData];
    int top = self.view.safeAreaInsets.top;
    iii = top;
    if (CRAPI.sharedInstance.routeBearing)
    {
        double bearing = CRAPI.sharedInstance.routeBearing.doubleValue;
        [_mapView animateToBearing:bearing];
        [self displayScalebar];
    }
    [self createCurrentRouteFromRoutePoints];
}
- (void) setTarget:(CLLocationCoordinate2D)target
{
    _target = target;
    LLPOINT pt;
    pt.lat = target.latitude;
    pt.lon = target.longitude;
    [CRAPI.sharedInstance setCurrentLocation:pt];
}
- (void)setZoom:(float)zoom
{
    CRAPI.sharedInstance.currentZoom = zoom;
    if (CRAPI.sharedInstance.currentApp == HCConfigMetroProp)
    {
        [ConfigurationControl.sharedInstance setZoom:zoom];
    }

}
- (void)updateCompassPosition:(BOOL)animated
{
    if (animated)
    {
        [UIView animateWithDuration:0.25 animations:^{
            [self setCompassPosition];
        }];
    }
    
    else
        [self setCompassPosition];
}

- (void)setCompassPosition
{
    CGFloat halfSize = ((_compassSize / 2.0) + 4.0);
    int top = UIApplication.sharedApplication.windows[0].safeAreaInsets.top;
    _compass.center = CGPointMake(_mapToolbar.center.x, top + halfSize);
    return;
    CGFloat xCenterLeft = (CGRectGetMinX(_mapToolbar.frame) - halfSize);
    CGFloat xCenterRight = (CGRectGetMaxX(_mapToolbar.frame) + halfSize);
    CGFloat yCenterTop = (CGRectGetMinY(_mapToolbar.frame) - halfSize);
    CGFloat yCenterBottom = (CGRectGetMaxY(_mapToolbar.frame) + halfSize);
    
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
    {
        switch (_mapToolbar.orientation)
        {
            case MapToolbarOrientationTop:
                _compass.center = CGPointMake(_mapToolbar.center.x, yCenterBottom);
                break;
            case MapToolbarOrientationBottom:
                _compass.center = CGPointMake(_mapToolbar.center.x, yCenterTop);
                break;
            case MapToolbarOrientationLeft:
                _compass.center = CGPointMake(xCenterRight, _mapToolbar.center.y);
                break;
            case MapToolbarOrientationRight:
                _compass.center = CGPointMake(xCenterLeft, _mapToolbar.center.y);
                break;
            default:break;
        }
    }
    
    else
    {
        switch (_mapToolbar.orientation)
        {
            case MapToolbarOrientationTop:
            case MapToolbarOrientationBottom:
                _compass.center = CGPointMake(xCenterLeft, _mapToolbar.center.y);
                break;
            case MapToolbarOrientationLeft:
            case MapToolbarOrientationRight:
                _compass.center = CGPointMake(_mapToolbar.center.x, yCenterTop);
                break;
            default:break;
        }
    }
}

- (void)setupTempButton:(UIButton *)button
{
    [button setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    [button setTitleColor:UIColor.grayColor forState:UIControlStateHighlighted];
    button.titleLabel.font = [UIFont boldSystemFontOfSize:28.0];
    button.backgroundColor = UIColor.blackColor;
    button.titleLabel.textAlignment = NSTextAlignmentCenter;
    button.layer.cornerRadius = 10.0;
    button.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
}

- (void)mapToolbarDidSelectReturnButton
{
    [ConfigurationControl.sharedInstance setApp:HCConfigMetroProp];
    
    if (_fromSpreadsheet)
    {
        NVMetroSettings.sharedInstance.currentFeature = NVMetroSettings.sharedInstance.currentFeatureSaved;
        [self zoomToBounds:NVMetroSettings.sharedInstance.savedVisibleBounds];
    }
    
    _fromSpreadsheet = NO;
    
    NSUInteger index = [NVTabBarEdit indexOfViewControllerWithID:@"NVSpreadsheet"
                                              inTabBarController:self.tabBarController];
    
    if (index != -1)
    {
        self.tabBarController.selectedIndex = index;
        self.tabBarController.tabBar.hidden = NO;
    }
}

- (void)emailPDF:(BOOL)screenShot
{
    if (screenShot)
    {
        NSMutableArray *viewsArray = NSMutableArray.array;
        
        for (UIView *views in _mapView.subviews)
        {
            if ([views.description containsString:@"GMSUISettingsView"])
                views.hidden = YES;
        }
        
        if ([self.view.subviews containsObject:[self.view viewWithTag:77777]])
            [viewsArray addObject:[self.view viewWithTag:77777]];
        
        else
            [viewsArray addObject:_mapView];
        
        [viewsArray addObject:_vectorView];
        
        UIView *tlov = [[UIView alloc] initWithFrame:self.view.frame];
        tlov.backgroundColor = UIColor.clearColor;
        
        for (ThemeLegendMapOverlay *tlmos in self.view.subviews)
        {
            if ([tlmos isKindOfClass:ThemeLegendMapOverlay.class])
                [tlov addSubview:tlmos];
        }
        
        for (NVPhotoView *nvpvs in self.view.subviews)
        {
            if ([nvpvs isKindOfClass:NVPhotoView.class])
            {
                [viewsArray addObject:nvpvs.overlay];
                
                nvpvs.transform = CGAffineTransformTranslate(nvpvs.transform, 0.0, -20.0);
                nvpvs.deleteButton.hidden = YES;
                [tlov addSubview:nvpvs];
            }
        }
        
        if (tlov.subviews.count)
            [viewsArray addObject:tlov];
        
        NSMutableArray *legends = ConfigurationControl.sharedInstance.legendList;
        UIView *legendsView = [[UIView alloc] initWithFrame:self.view.frame];
        legendsView.hidden = YES;
        legendsView.backgroundColor = UIColor.lightGrayColor;
        [self.view addSubview:legendsView];
        
        CGFloat margin = 10.0, tallestLegend = 0.0;
        CGFloat xPos = margin, yPos = margin;
        
        for (ThemeLegend *tls in legends)
        {
            ThemeLegendMapOverlay *tlmo = [ThemeLegendMapOverlay drawLegend:tls
                                                                    withTag:0
                                                                   delegate:self
                                                                     inView:legendsView
                                                                   atOrigin:CGPointMake(xPos, yPos)
                                                                hideButtons:YES];
            
            tallestLegend = MAX(tallestLegend, tlmo.frame.size.height);
            xPos += (tlmo.frame.size.width + margin);
            
            if (xPos > (legendsView.frame.size.width - tlmo.frame.size.width - margin))
            {
                yPos += (tallestLegend + margin);
                xPos = margin;
                tallestLegend = 0.0;
            }
        }
        
        CGFloat maxWidth = 0.0, maxHeight = 0.0;
        
        for (ThemeLegendMapOverlay *tlmos in legendsView.subviews)
        {
            if ([tlmos isKindOfClass:ThemeLegendMapOverlay.class])
            {
                maxWidth = MAX(maxWidth, CGRectGetMaxX(tlmos.frame));
                maxHeight = MAX(maxHeight, CGRectGetMaxY(tlmos.frame));
            }
        }
        
        legendsView.frame = CGRectMake(0.0, 0.0, (maxWidth + margin), (maxHeight + margin));
        NSArray *dispPoints = NSArray.array;
        NSData *pdf = [NVPDFSnapshotter pdfFromViews:viewsArray legendsView:legendsView pickedItems:dispPoints];
        
        [NVSendEmail sendEmailWithSubject:@"PDF from NVMobile"
                                  message:@"The PDF attached to this email was rendered by NVMobile."
                           attachmentData:pdf
                                 mimeType:@"application/pdf"
                                 fileName:@"testPDF.pdf"
                               controller:self];
        
        for (ThemeLegendMapOverlay *tlmos in tlov.subviews)
        {
            if ([tlmos isKindOfClass:ThemeLegendMapOverlay.class])
                [self.view addSubview:tlmos];
        }
        
        for (NVPhotoView *nvpvs in tlov.subviews)
        {
            if ([nvpvs isKindOfClass:NVPhotoView.class])
            {
                nvpvs.transform = CGAffineTransformTranslate(nvpvs.transform, 0.0, 20.0);
                nvpvs.deleteButton.hidden = NO;
                [self.view addSubview:nvpvs];
            }
        }
    }
    else
    {
        [self allocateVectorView:YES];
        [self vectorViewSetup];
        [_vectorView vectorViewToPDF];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self vectorViewRefresh];
    CGFloat statusBarHeight = [self statusBarHeight:UIApplication.sharedApplication.statusBarOrientation];
    [self setZoom:_mapView.camera.zoom];
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main"
                                                         bundle:NSBundle.mainBundle];
    
    if (ConfigurationControl.sharedInstance.currentApp == HCConfigMetroProp ||
        ConfigurationControl.sharedInstance.currentApp == HCConfigFromSpreadsheet)
    {
        /*if (ConfigurationControl.sharedInstance.currentApp == HCConfigFromSpreadsheet && _legendsAreOffMap)
        {
            [self themeLegendWasDraggedOffLeftSide];
            _legendsAreOffMap = YES;
        }*/
        
        NVMetroSettingsVC *nvmsvc = NVMetroSettingsVC.new;
        nvmsvc.restorationIdentifier = @"NVMetroSettingsVC";
        nvmsvc.tabBarItem.title = @"Settings";
        
        nvmsvc.tabBarItem.image = [UIImage imageWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"settings"
                                                                                                 ofType:@"png"]];
        
        [NVTabBarEdit tabBarController:self.tabBarController removeViewControllerWithID:@"LayersVC"];
        UIViewController *findvc = [storyboard instantiateViewControllerWithIdentifier:@"FindVC"];
        
        [NVTabBarEdit tabBarController:self.tabBarController
           replaceViewControllerWithID:@"FieldOptionsVC"
                    withViewController:findvc];
        
        if ([CRAPI.sharedInstance.bundleID isEqualToString:@"com.gssi.newvisionmetro"])
        {
            [NVTabBarEdit tabBarController:self.tabBarController
               replaceViewControllerWithID:@"DestinationsVC"
                        withViewController:nvmsvc];
        }
        
        else
        {
            UIViewController *avc = [storyboard instantiateViewControllerWithIdentifier:@"ApplicationsVC"];
            
            [NVTabBarEdit tabBarController:self.tabBarController
               replaceViewControllerWithID:@"DestinationsVC"
                        withViewController:avc];
        }
        
        [NVTabBarEdit tabBarController:self.tabBarController
           replaceViewControllerWithID:@"SettingsVC"
                    withViewController:nvmsvc];
        
        NSInteger index = [NVTabBarEdit indexOfViewControllerWithID:@"NVMetroSettingsVC"
                                                 inTabBarController:self.tabBarController];
        
        ConfigurationVC *configVC = ConfigurationVC.new;
        configVC.restorationIdentifier = @"ConfigVC";
        configVC.tabBarItem.title = @"Config";
        
        configVC.tabBarItem.image = [UIImage imageWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"config"
                                                                                                   ofType:@"png"]];
        
        if (![CRAPI.sharedInstance.bundleID isEqualToString:@"com.gssi.newvisionmetro"])
            index--;
        
        [NVTabBarEdit tabBarController:self.tabBarController insertViewController:configVC atIndex:index];
        
        if (ConfigurationControl.sharedInstance.currentApp == HCConfigMetroProp)
        {
            [NVTabBarEdit tabBarController:self.tabBarController
                      insertViewController:_nvssvc
                                   atIndex:1];
            
            CLLocationCoordinate2D coord = {0};
            LLPOINT ll = {0};
            
            if (CRAPI.sharedInstance.mapIndividualDest)
            {
                NSArray *dests = Destinations.new.getIndividualDestinations;
                
                for (Destination *dts in dests)
                {
                    if ([dts isKindOfClass:Destination.class])
                    {
                        ll = dts.latlon;
                        coord.latitude = ll.lat;
                        coord.longitude = ll.lon;
                        
                        NVMarkerInfoButton *nvmib = [NVMarkerInfoButton markerWithPosition:coord
                                                                                     title:dts.destinationName
                                                                                      type:NVMarkerInfoButtonTypeDestinationsIndividual
                                                                                      view:self.view
                                                                                  delegate:self];
                        
                        nvmib.tag = ((dts.destinationID * 100) + 1);
                    }
                }
            }
            
            if (CRAPI.sharedInstance.mapGroupDest)
            {
                NSArray *dests = Destinations.new.getGroupDestinations;
                
                for (Destination *dts in dests)
                {
                    if ([dts isKindOfClass:Destination.class])
                    {
                        ll = dts.latlon;
                        coord.latitude = ll.lat;
                        coord.longitude = ll.lon;
                        
                        NVMarkerInfoButton *nvmib =
                        [NVMarkerInfoButton markerWithPosition:coord
                                                         title:dts.destinationName
                                                          type:NVMarkerInfoButtonTypeDestinationsGroup
                                                          view:self.view
                                                      delegate:self];
                        
                        nvmib.tag = ((dts.destinationID * 100) + 2);
                    }
                }
            }
            
            if ([CRAPI.sharedInstance.mapPropList containsString:@"TAGs"])
            {
                if (!_propertyList)
                {
                    _propertyList = PropertyList.new;
                    BOOL opened = [_propertyList  open:NO];
                    NSArray *props = _propertyList .getPropertyNumbers;
                    
                    for (NSNumber *numbers in props)
                    {
                        if ([numbers isKindOfClass:NSNumber.class])
                        {
                            NSInteger num = numbers.integerValue;
                            ll = [_propertyList  getPropertyLatLon:num];
                            coord.latitude = ll.lat;
                            coord.longitude = ll.lon;
                            
                            NVMarkerInfoButton *nvmib =
                            [NVMarkerInfoButton markerWithPosition:coord
                                                             title:[_propertyList  getFieldValue:num type:PFT_UserID]
                                                              type:NVMarkerInfoButtonTypePropList
                                                              view:self.view
                                                          delegate:self];
                            
                            nvmib.tag = ((num * 100) + 3);
                        }
                    }
                    [_propertyList  close:opened];
                    _propertyList = nil;
                }
            }
        }
    }
    
    else
    {
        [NVTabBarEdit tabBarController:self.tabBarController removeViewControllerWithID:@"NVSpreadsheet"];
        UIViewController *lvc = [storyboard instantiateViewControllerWithIdentifier:@"LayersVC"];
        [NVTabBarEdit tabBarController:self.tabBarController insertViewController:lvc atIndex:1];
        [NVTabBarEdit tabBarController:self.tabBarController removeViewControllerWithID:@"NVWebKitVC"];
        [NVTabBarEdit tabBarController:self.tabBarController removeViewControllerWithID:@"ConfigVC"];
        UIViewController *svc = [storyboard instantiateViewControllerWithIdentifier:@"SettingsVC"];
        
        [NVTabBarEdit tabBarController:self.tabBarController
           replaceViewControllerWithID:@"NVMetroSettingsVC"
                    withViewController:svc];
    }
    
    if (ConfigurationControl.sharedInstance.currentApp == HCConfigHunting)
    {
        NSString *imagePath = [NSBundle.mainBundle pathForResource:@"find" ofType:@"png"];

        FindBoundariesViewController *findBounds = FindBoundariesViewController.new;
        findBounds.restorationIdentifier = @"FindBounds";
        findBounds.delegate = self;
        [NVTabBarEdit tabBarController:self.tabBarController replaceViewControllerWithID:@"FindVC"
                    withViewController:findBounds];
        [NVTabBarEdit tabBarController:self.tabBarController setImage:[UIImage imageWithContentsOfFile:imagePath] forViewControllerWithID:@"FindBounds"];
        [NVTabBarEdit tabBarController:self.tabBarController setText:@"Find" forViewControllerWithID:@"FindBounds"];
        UIViewController *cvc = [storyboard instantiateViewControllerWithIdentifier:@"CompassVC"];
        [NVTabBarEdit tabBarController:self.tabBarController insertViewController:cvc atIndex:4];
 
    }
    
    if (ConfigurationControl.sharedInstance.currentApp == HCConfigCurbRamps)
    {
        UIViewController *cdvc = [storyboard instantiateViewControllerWithIdentifier:@"CurbRampDataOptionsVC"];
        [NVTabBarEdit tabBarController:self.tabBarController insertViewController:cdvc atIndex:5];
    }
    
    else
        [NVTabBarEdit tabBarController:self.tabBarController removeViewControllerWithID:@"CurbRampDataOptionsVC"];
    
    if (ConfigurationControl.sharedInstance.currentApp == HCConfigMapleGrove)
    {
        NSArray *pvaArray = [NSArray arrayWithObjects:[NSNumber numberWithInteger:NVPageViewArrangementFit4Columns2], nil];
        NVPageController *nvpc = [NVPageController pageControllerWithArrangementArray:pvaArray];
        nvpc.restorationIdentifier = @"MGThemesVC";
        nvpc.tabBarItem.title = @"Themes";
        
        nvpc.tabBarItem.image = [UIImage imageWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"fieldOptions"
                                                                                               ofType:@"png"]];
        
        [NVTabBarEdit tabBarController:self.tabBarController insertViewController:nvpc atIndex:1];
    }
    
    else
        [NVTabBarEdit tabBarController:self.tabBarController removeViewControllerWithID:@"MGThemesVC"];
    
    if (ConfigurationControl.sharedInstance.currentApp == HCConfigCrimes)
    {
        NSArray *pvaArray = [NSArray arrayWithObjects:[NSNumber numberWithInteger:NVPageViewArrangementFit2],
                             [NSNumber numberWithInteger:NVPageViewArrangementFit5Columns2], nil];
        
        NVPageController *nvpc = [NVPageController pageControllerWithArrangementArray:pvaArray];
        nvpc.restorationIdentifier = @"NVPageController";
        nvpc.tabBarItem.title = @"Legends";
        
        nvpc.tabBarItem.image = [UIImage imageWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"fieldOptions"
                                                                                               ofType:@"png"]];
        
        [NVTabBarEdit tabBarController:self.tabBarController insertViewController:nvpc atIndex:1];
        UIViewController *crimeOptionsVC = [storyboard instantiateViewControllerWithIdentifier:@"CrimeDataOptionsVC"];
        [NVTabBarEdit tabBarController:self.tabBarController insertViewController:crimeOptionsVC atIndex:1];
        
        if ([CRAPI.sharedInstance.bundleID isEqualToString:@"com.gssi.newvisioncrime"])
            [NVTabBarEdit tabBarController:self.tabBarController removeViewControllerWithID:@"ApplicationsVC"];
        
        _nvssvc.tabBarItem.title = @"Crime Lists";
        [NVTabBarEdit tabBarController:self.tabBarController insertViewController:_nvssvc atIndex:2];
    }
    
    else
    {
        [NVTabBarEdit tabBarController:self.tabBarController removeViewControllerWithID:@"NVPageController"];
        [NVTabBarEdit tabBarController:self.tabBarController removeViewControllerWithID:@"CrimeDataOptionsVC"];
    }
    
    if (ConfigurationControl.sharedInstance.currentApp == HCConfigCrimes ||
        ConfigurationControl.sharedInstance.currentApp == HCConfigCurbRamps ||
        ConfigurationControl.sharedInstance.currentApp == HCConfigMapleGrove ||
        ConfigurationControl.sharedInstance.currentApp == HCConfigMetroProp)
    {
        NSMutableArray *legends = ConfigurationControl.sharedInstance.legendList;
        BOOL legendExistsToDraw = NO, legendsAreAlreadyDrawn = NO;
        
        for (ThemeLegend *tls in legends)
        {
            if (tls.drawOnMap || ConfigurationControl.sharedInstance.currentApp == HCConfigFromSpreadsheet || ConfigurationControl.sharedInstance.currentApp == HCConfigMetroProp)
            {
                legendExistsToDraw = YES;
            }
        }
        
        if (!legendExistsToDraw)
            [self themeLegendWasDraggedOffLeftSide];
        
        if (legendExistsToDraw && !_legendsAreOffMap)
        {
            for (ThemeLegendMapOverlay *tlmos in self.view.subviews)
            {
                if ([tlmos isKindOfClass:ThemeLegendMapOverlay.class])
                    legendsAreAlreadyDrawn = YES;
            }
            
            if (!legendsAreAlreadyDrawn)
            {
                for (ThemeLegendMapOverlay *tlmos in _legendScrollView.subviews)
                {
                    if ([tlmos isKindOfClass:ThemeLegendMapOverlay.class])
                        legendsAreAlreadyDrawn = YES;
                }
                
                if (!legendsAreAlreadyDrawn)
                {
                    [self themeLegendWasDraggedOffRightSide];
                    return;
                }
            }
        }
        
        for (ThemeLegendMapOverlay *tlmos in self.view.subviews)
        {
            if ([tlmos isKindOfClass:ThemeLegendMapOverlay.class])
                [tlmos.tableView reloadData];
        }
        
        for (ThemeLegendMapOverlay *tlmos in _legendScrollView.subviews)
        {
            if ([tlmos isKindOfClass:ThemeLegendMapOverlay.class])
                [tlmos.tableView reloadData];
        }
    }
    
    else
    {
        if (_legendsAreOffMap)
        {
            [_mapView constrainToView:self.view leading:0.0 trailing:0.0 top:statusBarHeight bottom:0.0];
            
            for (ThemeLegendMapOverlay *tlmos in _legendScrollView.subviews)
            {
                if ([tlmos isKindOfClass:ThemeLegendMapOverlay.class])
                    [tlmos removeFromSuperview];
            }
            
            _legendsAreOffMap = _mapToolbar.isOffset = NO;
        }
        
        else for (ThemeLegendMapOverlay *tlmos in self.view.subviews)
        {
            if ([tlmos isKindOfClass:ThemeLegendMapOverlay.class])
                 [tlmos removeFromSuperview];
        }
    }
    
    [_mapToolbar configure:_screenSetting];
    [_mapToolbar didRotateWithTabBarHeight:_tabBarHeight statusBarHeight:statusBarHeight];
    _mapToolbar.hidden = NO;
    [self updateCompassPosition:NO];
    
    _zoomExtentsGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(delayExtentZoom:)];
    _zoomExtentsGesture.delegate = self;
    _zoomExtentsGesture.numberOfTouchesRequired = 2;
    _zoomExtentsGesture.numberOfTapsRequired = 2;
    [self.view addGestureRecognizer:_zoomExtentsGesture];
    
    if (CRAPI.sharedInstance.GMMSetting == GMMSettingBoundaries || _fromSpreadsheet || _firstTimeAppear || _keepZoomExtents)
    {
        [self extentZoom];
        CRAPI.sharedInstance.GMMSetting = GMMSettingDefault;
    }
    
    _firstTimeAppear = NO;
    self.tabBarController.moreNavigationController.navigationBar.hidden = YES;
    self.tabBarController.customizableViewControllers = @[];
    
    if (ConfigurationControl.sharedInstance.currentApp == HCConfigSidewalk)
    {
        if ([CRAPI.sharedInstance.bundleID isEqualToString:@"com.gssi.newvisionsidewalk"])
            [NVTabBarEdit tabBarController:self.tabBarController removeViewControllerWithID:@"ApplicationsVC"];
        
        _mapView.mapType = kGMSTypeHybrid;
        [_locationManager requestLocation];
    }
    [self mapToolbarDidFinishDrag:_mapToolbarCenter
                                    superView:nil];
    if (CRAPI.sharedInstance.locationTrackingEnabled)
    {
        [self startTrackingUserLocation];
        [_mapToolbar selectMyLocationButton:YES];
    }
    if (_amAcceptingHeading)
        [_locationManager startUpdatingHeading];

 }
#pragma mark - EndOfViewDidAppear

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    _currentScreenHeight = self.view.frame.size.height;
    [self stopTrackingUserLocation:NO];
    if (_nvssvc)
        [_nvssvc.delegate closeList];
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

- (void)FTPDirectoryCreateDidCompleteWithStatus:(FTPStatus)status
                                   statusString:(NSString *)statusString
                                      directory:(NSString *)directory
{
    if (status == FTPStatusOK || status == FTPStatusStop)
        NSLog(@"CREATE DIR LIST complete for FTP directory %@", directory);
}

- (void)FTPDirectoryListDidCompleteWithStatus:(FTPStatus)status
                                 statusString:(NSString *)statusString
                                directoryList:(NSData *)directoryList
{
    NSLog(@"FTP Status:%li:%@", (long)status, statusString);
    
    if (status == FTPStatusOK && directoryList)
    {
        NSString *dirListString = [[NSString alloc] initWithData:directoryList
                                                        encoding:NSUTF8StringEncoding];
        
        if (dirListString && dirListString.length)
        {
            NSMutableArray *files = NSMutableArray.array;
            
            if ([dirListString containsString:@"\n"])
                [files addObjectsFromArray:[dirListString componentsSeparatedByString:@"\n"]];
            
            else
                [files addObject:dirListString];
            
            for (int i = 0; i < files.count; i++)
            {
                files[i] = removeOpeningReturn(removeEndingReturn(textAfterLastSpace(files[i])));
                files[i] = [files[i] stringByReplacingOccurrencesOfString:@" " withString:@"_"];
            }
            
            [files removeObject:@""];
            _files = files.copy;
            _currentFile = 0;
            [self getNextFile];
        }
    }
}

- (void)getNextFile
{
    FTPDataPull *pull = FTPDataPull.pull;
    pull.dataType = FTPDataJPG;
    pull.delegate = self;
    pull.popover = _popover;
    _popover.cancelButtonTitle = @"Cancel";
    _popover.title = [NSString stringWithFormat:@"Downloading %@", _files[_currentFile]];
    [_popover show];
    NSString *toDir = [NSString stringWithFormat:@"%@/pdfToJpgPlats", UserDefaults.defaults.sharedFilePath];
    BOOL exists = NO;
    [NSFileManager.defaultManager fileExistsAtPath:toDir isDirectory:&exists];
    pull.createDirectory = !exists;
    
    [pull getFile:_files[_currentFile]
    fromDirectory:[NSString stringWithFormat:@"MapleGrove/As-built/JPG/%@",
                   CRAPI.sharedInstance.selectedPDFID.stringByDeletingPathExtension]
           toFile:_files[_currentFile]
      toDirectory:toDir
    refreshOption:FTPDataPullRefreshOptionUseFileIfExists];
}

- (void)showImage
{
    NSString *path = [NSString stringWithFormat:@"%@/pdfToJpgPlats/%@",
                      UserDefaults.defaults.sharedFilePath, _files[_currentFile]];
    
    NVWebView *webView = [NVWebView showWebViewInView:self.view showFileAtPath:path delegate:self];
    [webView showNextAndPrevious];
}

- (void)webViewDidRequestNextImage:(NVWebView *)webView
{
    if (_currentFile < (_files.count - 1))
        _currentFile++;
        
    else
        _currentFile = 0;
    
    NSString *path = [NSString stringWithFormat:@"%@/pdfToJpgPlats/%@",
                      UserDefaults.defaults.sharedFilePath, _files[_currentFile]];
    
    [webView updateImageViewToImageAtPath:path];
}

- (void)webViewDidRequestPreviousImage:(NVWebView *)webView
{
    if (_currentFile > 0)
        _currentFile--;
    
    else
        _currentFile = (int)(_files.count - 1);
    
    NSString *path = [NSString stringWithFormat:@"%@/pdfToJpgPlats/%@",
                      UserDefaults.defaults.sharedFilePath, _files[_currentFile]];
    
    [webView updateImageViewToImageAtPath:path];
}

- (void)setupDigitizerToolbarButton:(UIButton *)button
                           selector:(SEL)selector
                              title:(NSString *)title
{
    button.translatesAutoresizingMaskIntoConstraints = NO;
    button.backgroundColor = UIColor.clearColor;
    button.titleLabel.font = [UIFont boldSystemFontOfSize:48.0];
    button.titleLabel.textAlignment = NSTextAlignmentCenter;
    button.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    button.titleLabel.layer.shadowColor = UIColor.blackColor.CGColor;
    button.titleLabel.layer.shadowOffset = CGSizeZero;
    button.titleLabel.layer.shadowOpacity = 1.0;
    button.titleLabel.layer.shadowRadius = 4.0;
    
    [button setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    [button setTitleColor:UIColor.redColor forState:UIControlStateHighlighted];
    [button setTitle:title forState:UIControlStateNormal];
    
    [button addTarget:self
               action:selector
     forControlEvents:UIControlEventTouchUpInside];
    
    [_digitizationToolbar addSubview:button];
}

- (CGFloat) getAspectRatioForBounds:(MNMXCORD)bounds
{
    CGFloat ar = 1.0;
    
    CLLocationCoordinate2D ll[2];
    ll[0].latitude = bounds.ymn;
    ll[0].longitude = bounds.xmn;
    ll[1].latitude = bounds.ymx;
    ll[1].longitude = bounds.xmx;
    CGPoint pt[2];
    pt[0] = [_mapView.projection pointForCoordinate:ll[0]];
    pt[1] = [_mapView.projection pointForCoordinate:ll[1]];

    if (fabs(pt[1].y - pt[0].y) > 0)
        ar = fabs((pt[1].x - pt[0].x)/(pt[1].y - pt[0].y));
    
    return ar;
}

- (void)delayExtentZoom:(UITapGestureRecognizer *)gesture
{
    [self performSelector:@selector(extentZoom) withObject:nil afterDelay:0.5];
}

- (void)extentZoom
{

    [self stopTrackingUserLocation:YES];
    CGFloat mapAdj = 0.0;
    MNMXCORD bounds={0};
    int boundaryRefno = 0;
    NSString *boundaryType = CRAPI.sharedInstance.currentOverallBoundaryTable;
    _keepZoomExtents = YES;
    
    if (ConfigurationControl.sharedInstance.currentApp == HCConfigHunting)
    {
        boundaryType = CRAPI.sharedInstance.currentOverallBoundaryType;
    }
    if (ConfigurationControl.sharedInstance.currentApp == HCConfigFromSpreadsheet)
    {
        mapAdj = _tabBarHeight;
        
        if (ConfigurationControl.sharedInstance.MapitBoundaryOpt == MAPIT_CIRCULAR)
        {
            bounds = BoundsFromLLPointAndDist(ConfigurationControl.sharedInstance.MapitTargetCenterPoint,
                                              ConfigurationControl.sharedInstance.MapitCirularBoundaryRadiusInMiles * METERS_PER_MILE);
        }
        
        else
        {
            boundaryRefno = ConfigurationControl.sharedInstance.MapitBoundaryRefno;
            boundaryType = ConfigurationControl.sharedInstance.MapitBoundaryType;
        }
    }
    
    else
        boundaryRefno = CRAPI.sharedInstance.currentOverallBoundaryRefno;
    
    if (boundaryRefno || CRAPI.sharedInstance.selectBoundaryFromMapType)
    {
        BoundaryData *boundData = [[BoundaryData alloc] init];
        
        if (CRAPI.sharedInstance.selectBoundaryFromMapType)
        {
            bounds = [boundData selectBoundaryFromMapInit:
                      CRAPI.sharedInstance.selectBoundaryFromMapType];
        }
        
        else
        {
            bounds = [boundData getBoundaryAreaBounds:boundaryRefno
                                               ofType:boundaryType];

        }
    }
    [self zoomToActualBounds:bounds adjust:mapAdj];
}
- (void)zoomToActualBounds:(MNMXCORD)bounds
                    adjust:(CGFloat)mapAdj
{
    if (BoundsWidth(&bounds) > 0)
    {
        _northeast = CLLocationCoordinate2DMake(bounds.ymx, bounds.xmx);
        _southwest = CLLocationCoordinate2DMake(bounds.ymn, bounds.xmn);
        
        NSMutableArray *subviewsArray = NSMutableArray.array;
        
        for (UIView *subviews in self.view.subviews)
        {
            if ([subviews isKindOfClass:ThemeLegendMapOverlay.class])
            {
                if (!subviews.hidden)
                    [subviewsArray addObject:subviews];
            }
            
            else if ([subviews isKindOfClass:MapToolbar.class])
            {
                MapToolbar * mtv = (MapToolbar *)subviews;
                if (!subviews.hidden && !(mtv.orientation == MapToolbarOrientationMinimized))
                    [subviewsArray addObject:subviews];
            }
            
            else if (subviews == _legendScrollView && _legendsAreOffMap && !_firstTimeAppear)
                [subviewsArray addObject:_legendScrollView];
        }
        
        [[self.view viewWithTag:999] removeFromSuperview];
        
        CGRect *frames = (CGRect *)malloc((sizeof(CGRect) * subviewsArray.count) + 4);
        
        for (int i = 0; i < subviewsArray.count; i++)
            frames[i] = [(UIView *)subviewsArray[i] frame];
        
        CGFloat aspectRatio = [self getAspectRatioForBounds:bounds];
        CGRect targetFrame = largestRect(aspectRatio, 5, _mapView.frame, (int)subviewsArray.count, frames);
        
        free(frames);
        
        [[self.view viewWithTag:999] removeFromSuperview];
        
        GMSCoordinateBounds *coordBounds = [[GMSCoordinateBounds alloc] initWithCoordinate:_northeast
                                                                                coordinate:_southwest];
        
        _inset = UIEdgeInsetsMake((CGRectGetMinY(targetFrame) - CGRectGetMinY(_mapView.frame) + 5.0),
                                              (CGRectGetMinX(targetFrame) - CGRectGetMinX(_mapView.frame) + 5.0),
                                              (CGRectGetMaxY(_mapView.frame) - CGRectGetMaxY(targetFrame)  + 5.0 + mapAdj),
                                              (CGRectGetMaxX(_mapView.frame) - CGRectGetMaxX(targetFrame) + 5.0));
        
        [self moveCamera:[GMSCameraUpdate fitBounds:coordBounds withEdgeInsets:_inset]];
    }
    
    else
        [self animateToCameraPosition:[GMSCameraPosition cameraWithTarget:_target zoom:12.0]];

}

- (void)zoomToPipeTraceBounds:(MNMXCORD)bounds
{
    [self zoomToBounds:bounds];
}

- (void)moveCamera:(GMSCameraUpdate *)update
{
    [_mapView moveCamera:update];
}
- (void)animateToCameraPosition:(GMSCameraPosition *)cameraPosition
{
    [_mapView animateToCameraPosition:cameraPosition];
}
- (void)animateToLocation:(CLLocationCoordinate2D)location
{
    [_mapView animateToLocation:location];
}

- (void)animateWithCameraUpdate:(GMSCameraUpdate *)update
{
    [_mapView animateWithCameraUpdate:update];
}
- (void)zoomToBounds:(MNMXCORD)bounds
{
    if (BoundsWidth(&bounds) > 0)
    {
        CLLocationCoordinate2D northeast = CLLocationCoordinate2DMake(bounds.ymx, bounds.xmx);
        CLLocationCoordinate2D southwest = CLLocationCoordinate2DMake(bounds.ymn, bounds.xmn);
        _keepZoomExtents = NO;
        GMSCoordinateBounds *coordBounds = [[GMSCoordinateBounds alloc] initWithCoordinate:northeast
                                                                                coordinate:southwest];
        
        GMSCameraPosition *camera = [_mapView cameraForBounds:coordBounds
                                                       insets:UIEdgeInsetsMake(20.0, 20.0, 20.0, 20.0)];
        
        [self animateToCameraPosition:camera];
    }
}
-(UserWaypoint*) pickWaypointOfType:(NSString*) type
                       at:(CGPoint)pickedPt
               withRadius:(float)pixels
{
    UserWaypoint *rtn = nil;
    HuntingData *hd = HuntingData.new;
    NSArray *wpArray;
    if ([type isEqual:@"ALL"])
        wpArray = [hd getWaypoints];
    else
        wpArray = [hd getWaypointsOfType:type];
    
    for (UserWaypoint *wp in wpArray)
    {
        CLLocationCoordinate2D llpt;
        llpt.latitude = wp.latlon.lat;
        llpt.longitude = wp.latlon.lon;
        CGPoint pt = [self pointForCoordinate:llpt];
        float dist = LDIST(pt.x,pt.y, pickedPt.x, pickedPt.y);
        if (dist <= pixels)
            rtn = wp;
    }
    return rtn;
}
- (void)mapView:(GMSMapView *)mapView
didLongPressAtCoordinate:(CLLocationCoordinate2D)coordinate
{
    CGPoint pickPt = [self pointForCoordinate:coordinate];
    LLPOINT llpickPt = {0};
    llpickPt.lat = coordinate.latitude;
    llpickPt.lon = coordinate.longitude;
    _llPickedPt = llpickPt;
    HuntingData *hd = HuntingData.new;
    if (_numCurrentRoutePoints)
    {
        LLPOINT llp = {coordinate.longitude,coordinate.latitude};
        _numCurrentRoutePoints++;
        RoutePoint *routePoint = RoutePoint.new;
        routePoint.latlon = llp;
        [CRAPI.sharedInstance.currentRoute addObject:routePoint];
        NSString *name = [NSString stringWithFormat:@"%i",_numCurrentRoutePoints];
        [hd addWaypoint:name type:@"RoutePoint" latlon:llp description:@"" displayOnCompass:YES];
        _numCurrentRoutePoints = 0;
        [self displayCurrentRoute];
        [self vectorViewRefresh];
    }

}
- (void)mapView:(GMSMapView *)mapView
    didTapAtCoordinate:(CLLocationCoordinate2D)coordinate
    {
    CGPoint pickPt = [self pointForCoordinate:coordinate];
    LLPOINT llpickPt = {0};
    llpickPt.lat = coordinate.latitude;
    llpickPt.lon = coordinate.longitude;
    _llPickedPt = llpickPt;
    CRAPI.sharedInstance.lastPickPoint = llpickPt;
    
    NSMutableArray *highlightList = NSMutableArray.array;
    
    if (_inDigitizationMode)
        return;
    
    else if (!_tableView.hidden)
        [self dismissTableView];
    
    else if (CRAPI.sharedInstance.selectBoundaryFromMapType)
    {
        PickedItem *pi = [BoundaryData.new pickBoundaryArea:llpickPt type:CRAPI.sharedInstance.selectBoundaryFromMapType];
        
        if (pi)
        {
            CRAPI.sharedInstance.GMMSetting = GMMSettingBoundaries;
            CRAPI.sharedInstance.currentOverallBoundaryName = pi.identifier;
            CRAPI.sharedInstance.currentOverallBoundaryType = pi.symbolName;
            CRAPI.sharedInstance.currentOverallBoundaryRefno = (int)pi.refno;
            CRAPI.sharedInstance.selectBoundaryFromMapType = nil;
            [self extentZoom];
        }
        
        return;
    }
    
    else switch (ConfigurationControl.sharedInstance.currentApp)
    {
        case HCConfigMetroProp:{
            switch (NVMetroSettings.sharedInstance.currentFeature)
            {
                case CPFLandUse:
                    break;
                case CPFParcels:
                case CPFParcels_IND:
                case CPFParcels_AG:
                case CPFParcels_RES:
                case CPFParcels_COM:{
                    PropertyData *propData = PropertyData.new;
                    _propYearAndQuarter = propData.yearAndQuarter;
                    propData.zoom = _mapView.camera.zoom;
                    [propData pickParcel:&llpickPt highlightList:highlightList];
                    break;}
                case CPFBlocks:
                case CPFBlockGroups:
                case CPFBlockGroups_ACS:
                case CPFTracts:{
                    NSString *cenType = @"PARCEL";
                    
                    switch (NVMetroSettings.sharedInstance.currentFeature)
                    {
                        case CPFBlocks:
                            cenType = @"BLOCK";
                            break;
                        case CPFBlockGroups:
                            cenType = @"BLOCKGROUP";
                            break;
                        case CPFBlockGroups_ACS:
                            cenType = @"BLOCKGROUP_ACS";
                            break;
                        case CPFTracts:
                            cenType = @"TRACT";
                            break;
                        default:break;
                    }
                    
                    PickedItem *pi = [BoundaryData.new pickBoundaryArea:llpickPt type:cenType];
                    
                    if (pi)
                        [highlightList addObject:pi];
                    break;}
                default:break;
            }
            break;}
        case HCConfigCrimes:
            switch (CRAPI.sharedInstance.crimeMode)
            {
                case CHOROPLETH:{
                    PickedItem *pi = [BoundaryData.new pickBoundaryArea:llpickPt type:CRAPI.sharedInstance.crimeTarget];
                    
                    if (pi)
                        [highlightList addObject:pi];
                    break;}
                case PINMAP:
                    if ([ConfigurationControl.sharedInstance layer:HCLayerCrimes
                                                     visibleAtZoom:_vectorViewZoom
                                                           andPass:PickPass])
                    {
                        [DispersePoint.new pickDispersedPoint:&llpickPt highlightList:highlightList];
                    }
                    break;
                default:break;
            }
            break;
        case HCConfigSewers:
            if ([ConfigurationControl.sharedInstance layer:HCLayerSewers
                                             visibleAtZoom:_vectorViewZoom
                                                   andPass:PickPass])
            {
                SewerData *sewerData = SewerData.new;
                sewerData.zoom = _mapView.camera.zoom;
                [sewerData pickSewer:&llpickPt atZoom:_mapView.camera.zoom highlightList:highlightList];
            }
            break;
        case HCConfigCurbRamps:{
            PlanimetricData *planData = PlanimetricData.new;
            planData.zoom = _mapView.camera.zoom;
            [planData pickCurbRampIntersectionPoint:llpickPt highlightList:highlightList];
            break;}
        case HCConfigMapleGrove:{
            UserLayerDisplay *ud = UserLayerDisplay.new;
            ud.processingID = CRAPI.sharedInstance.keepProcessing;
            ud.zoom = _mapView.camera.zoom;
            ud.passID = PickPass;
            [ud pickLayers:&llpickPt highlightList:highlightList];
            break;}
        case HCConfigAlleyWalls:
        case HCConfigAlleyWallStatus:{
            PlanimetricData *planData = PlanimetricData.new;
            planData.zoom = _mapView.camera.zoom;
            [planData pickAlleyWallPoint:llpickPt highlightList:highlightList];
            [planData pickAlleyLine:llpickPt  atZoom:_mapView.camera.zoom highlightList:highlightList];
            break;}
        case HCConfigMinnesotaGame:{
            PropertyData *propData = PropertyData.new;
            propData.zoom = _mapView.camera.zoom;
            [propData pickParcel:&llpickPt highlightList:highlightList];
            break;}
        case HCConfigHunting:
        {
            HuntingData *hd = HuntingData.new;
            if (_numCurrentRoutePoints)
            {
                LLPOINT llp = {coordinate.longitude,coordinate.latitude};
                _numCurrentRoutePoints++;
                RoutePoint *routePoint = RoutePoint.new;
                routePoint.latlon = llp;
                [CRAPI.sharedInstance.currentRoute addObject:routePoint];
                NSString *name = [NSString stringWithFormat:@"%i",_numCurrentRoutePoints];
                [hd addWaypoint:name type:@"RoutePoint" latlon:llp description:@"" displayOnCompass:YES];
                [self displayCurrentRoute];
            }
            else
            {
                NSMutableArray *optionList = NSMutableArray.array;
                
                UserWaypoint *pickedWayPoint = [self pickWaypointOfType:@"ALL" at:pickPt withRadius:25];
                if (pickedWayPoint)
                {
                    _pickedRefno = pickedWayPoint.refno;
                    NSString *txt = @"";
                    if ([pickedWayPoint.type isEqual:@"RoutePoint"])
                    {
                        txt = [NSString stringWithFormat:@"Target this Route Waypoint"];
                    }
                    else if (pickedWayPoint.displayOnCompass)
                    {
                        txt = [NSString stringWithFormat:@"Remove Waypoint from Compass"];
                    }
                    else
                    {
                        txt = [NSString stringWithFormat:@"Add Waypoint to Compass"];
                    }
                   [optionList addObject:txt];
                }
                else
                {
                    [optionList addObject:@"Mark Vehicle Location"];
                    [optionList addObject:@"________________________"];
                    [optionList addObject:@"Add Flushed Waypoint"];
                    [optionList addObject:@"Test Waypoint"];
                    [optionList addObject:@"Add Retrieved Waypoint"];
                    [optionList addObject:@"Add Compass Waypoint"];
                    [optionList addObject:@"________________________"];
                    if (CRAPI.sharedInstance.currentRoute.count)
                    {
                        [optionList addObject:@"Save Route"];
                        [optionList addObject:@"Clear Route"];
                    }
                    else
                        [optionList addObject:@"Start Route"];
                    [optionList addObject:@"________________________"];
                    [optionList addObject:@"Save Configuration"];
                    [optionList addObject:@"List Configurations"];
                    [optionList addObject:@"________________________"];

                    [optionList addObject:@"Proximity Mapping"];
                    if (CRAPI.sharedInstance.currentTrackRoute.count)
                    {
                        [optionList addObject:@"________________________"];
                        [optionList addObject:@"Stop Tracking Location"];
                        if (_displayTrackingRoute)
                            [optionList addObject:@"Hide Tracking Route"];
                        else
                            [optionList addObject:@"Show Tracking Route"];
                        [optionList addObject:@"Save Tracking Route"];
                        [optionList addObject:@"Clear Tracking Route"];
                    }
                    [optionList addObject:@"________________________"];
                    [optionList addObject:@"Delete all Compass Waypoints"];
                    [optionList addObject:@"Delete All Waypoints"];
                    [optionList addObject:@"________________________"];
                    [optionList addObject:@"Display Saved Track Routes"];
                    
                }
                _hideScaleBar = TRUE;
                NVPopoverTableView *nvptv = [NVPopoverTableView showPopoverTableViewInView:self.view
                                                                                  delegate:self
                                                                                     title:@"Waypoint Options"
                                                                                 textArray:optionList
                                                                             includeCancel:YES];
                nvptv.allowsSubtitle = NO;
            }

        }
            break;
        default:break;
    }
    
     [self setZoom:_mapView.camera.zoom];

    if (highlightList.count)
    {
        PickedItem *pi = [PickedItem nearestPickedItem:highlightList];
        CLLocationCoordinate2D pickedPt = {0};
        pickedPt.latitude = pi.pickedPoint.y;
        pickedPt.longitude = pi.pickedPoint.x;
        
        for (MarkerButton *marker in _markerArray)
        {
            if ([marker.title isEqualToString:pi.identifier])
                [marker removeFromSuperview];
        }
        
        [self highlightVectorView:pi displayOption:DISPLAY_DATA_OPTION_HIGHLIGHT];
        
        MarkerButton *marker = [MarkerButton markerWithPosition:pickedPt
                                                           view:self.view
                                                            map:_mapView
                                                statusBarHeight:[self statusBarHeight:UIApplication.sharedApplication.statusBarOrientation]
                                                       delegate:self];
        [self removePreviousInfoWindow];
        _infoWindow = MarkerInfoWindow.new;
        
        switch (pi.itemType)
        {
            case BoundaryArea:
                _selectedBARefNo = pi.refno;
                _selectedBA = pi.identifier;
                marker.title = _selectedBA;
                marker.snippet = pi.symbolName;
                marker.type = MarkerInfoWindowTypeBA;
                break;
            case CrimePoint:{
                _selectedCrime = pi.refno;
                marker.snippet = pi.identifier;
                NSDateFormatter *dateFormatter = NSDateFormatter.new;
                dateFormatter.timeStyle = NSDateFormatterShortStyle;
                dateFormatter.dateStyle = NSDateFormatterShortStyle;
                NSString *dateString = [dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:pi.time]];
                marker.title = dateString;
                marker.type = MarkerInfoWindowTypeCrime;
                break;}
            case AlleyLine:
                _selectedAlleySeg = pi.identifier;
                marker.title = _selectedAlleySeg;
                marker.snippet = pi.symbolName;
                marker.type = MarkerInfoWindowTypeAlleyLine;
                break;
            case AlleyWallPoint:
                _selectedAlleyWall = pi.identifier;
                marker.title = _selectedAlleyWall;
                marker.snippet = pi.symbolName;
                marker.type = MarkerInfoWindowTypeAlleyWall;
                break;
            case StreetIntersection:
                _selectedCRIntPt = pi.identifier;
                marker.title = _selectedCRIntPt;
                marker.snippet = pi.symbolName;
                marker.type = MarkerInfoWindowTypeCRInt;
                break;
            case StormMain:
                _selectedSewerPipe = pi.identifier;
                marker.title = _selectedSewerPipe;
                marker.snippet = pi.symbolName;
                marker.type = MarkerInfoWindowTypeStormSewer;
                break;
            case ParcelBoundary:
                _selectedPID = pi.identifier;
                CRAPI.sharedInstance.selectedPID = _selectedPID;
                marker.title = _selectedPID;
                marker.snippet = [PropertyData.new getOwnerNameForPID:_selectedPID];
                marker.type = MarkerInfoWindowTypePID;
                break;
            case SanitaryManhole:
                _selectedSanPoint = pi.identifier;
                _selectedMGVSanMH = (int)pi.refno;
                marker.title = _selectedSanPoint;
                marker.snippet = pi.symbolName;
                marker.type = MarkerInfoWindowTypeMGVSanPoint;
                break;
            case SanitaryMain:
                _selectedSanMain = pi.data;
                _selectedMGVSanPipe = (int)pi.refno;
                marker.title = _selectedSanMain;
                marker.snippet = pi.symbolName;
                marker.type = MarkerInfoWindowTypeMGVSanMain;
                break;
            case CensusBlockBoundary:
            case CensusTractBoundary:
            case CensusBlockGroupBoundary:
                _selectedCensusBoundaryRefno = pi.refno;
                _selectedCensusBoundaryType = pi.symbolName;
                marker.title = pi.identifier;
                marker.snippet = pi.symbolName;
                marker.type = MarkerInfoWindowTypeCensusBoundary;
                break;
            default:break;
        }
        
        marker.refno = pi.refno;
        marker.symbol = pi.symbol;
        marker.nLinks = pi.nLinks;
        [_markerArray addObject:marker];
        _infoWindow.delegate = self;
        _infoWindow.marker = marker;
        _infoWindow.optionsTitle = marker.title;
        _noneSelected = NO;
        [self.view addSubview:_infoWindow];
        [self updateInfoWindowPosition];
        
        if (_markerStyle != NVMarkerStyleMarkerOnly)
        {
            [self markerInfoWindowDidSelectOptions:marker.title
                                             refno:marker.refno
                                            coords:marker.position
                                              type:marker.type];
            
            if (_markerStyle == NVMarkerStyleOptionsOnly)
            {
                [self removePreviousInfoWindow];
                [marker removeFromSuperview];
            }
        }
    }
    
    [self vectorViewRefresh];
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
        _infoWindow = MarkerInfoWindow.new;
        _selectedPIDCoords = marker.position;
        
        switch (marker.type)
        {
            case MarkerInfoWindowTypeStormSewer:
                _selectedSewerPipe = marker.title;
                break;
            case MarkerInfoWindowTypePID:
                _selectedPID = marker.title;
                break;
            case MarkerInfoWindowTypeAlleyWall:
                _selectedAlleyWall = marker.title;
                break;
            case MarkerInfoWindowTypeCRInt:
                _selectedCRIntPt = marker.title;
                break;
            case MarkerInfoWindowTypeAlleyLine:
                _selectedAlleySeg = marker.title;
                break;
            case MarkerInfoWindowTypeCrime:
                _selectedCrime = marker.refno;
                break;
            case MarkerInfoWindowTypeBA:
                _selectedBA = marker.title;
                break;
            default:break;
        }
        
        [_markerArray addObject:marker];
        
        _infoWindow.delegate = self;
        _infoWindow.marker = marker;
        _infoWindow.optionsTitle = marker.title;
        _noneSelected = NO;
        [self.view addSubview:_infoWindow];
        [self updateInfoWindowPosition];
    }
}

- (void)handleLongPressDigitizingForState:(UILongPressGestureRecognizer *)gesture
{
    if (gesture.state == UIGestureRecognizerStateBegan ||
        gesture.state == UIGestureRecognizerStateChanged)
    {
        [self clearVectorView];
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
        
        CGPoint digitizerCenter = CGPointMake(_digitizerTargetView.center.x, (_digitizerTargetView.center.y -
                                               [self statusBarHeight:UIApplication.sharedApplication.statusBarOrientation]));
        
        CLLocationCoordinate2D position = [_mapView.projection coordinateForPoint:digitizerCenter];
        
        switch (_digitizationMode)
        {
            case DigitizationModeCustom:{
                _digitizerCount++;
                
                MarkerButton *marker = [MarkerButton markerWithPosition:position
                                                                   view:self.view
                                                                    map:_mapView
                                                        statusBarHeight:[self statusBarHeight:UIApplication.sharedApplication.statusBarOrientation]
                                                               delegate:self];
                
                [self removePreviousInfoWindow];
                _infoWindow = MarkerInfoWindow.new;
                [marker setImage:_orangeCrosshairs forState:UIControlStateNormal];
                marker.title = [NSString stringWithFormat:@"Custom Marker %ld", (long)_digitizerCount];
                marker.snippet = [NSString stringWithFormat:@"%f, %f", marker.position.latitude, marker.position.longitude];
                marker.type = MarkerInfoWindowTypeCustom;
                [_markerArray addObject:marker];
                
                _infoWindow.delegate = self;
                _infoWindow.marker = marker;
                _infoWindow.optionsTitle = marker.title;
                _noneSelected = NO;
                [self.view addSubview:_infoWindow];
                [self updateInfoWindowPosition];
            }
                break;
            case DigitizationModeAlleyWallNew:{
                CLLocationCoordinate2D positioncl = position;
                CLLocationCoordinate2D positionpid = position;
                AlleyWallData *awd = [[AlleyWallData alloc] init];
                NSString *nearestAlley = [awd nearestAlleyLine:&positioncl];
                NSString *newWallID = [awd getNextWallForAlley:nearestAlley];
                PropertyData *propData = [[PropertyData alloc] init];
                NSString *houseAndUnit = @"";
                NSString *streetName = @"";
                NSString *nearPID = [propData getNearestPID:&positionpid];
                
                if (nearPID)
                {
                    [propData getAddressForPID:nearPID
                               houseNumAndUnit:&houseAndUnit
                                    streetName:&streetName
                                          city:nil zip:nil ownerName:nil taxpayerName:nil censusBlock:nil associatedCensusBlock:nil useDesc:nil homestead:nil saleDate:nil saleValue:nil yearBuilt:nil
                                        totEMV:nil landEMV:nil bldgEMV:nil totTAX:nil specAss:nil acres:nil];
                    
                    _currentAddress = [NSString stringWithFormat:@"%@ %@", houseAndUnit, streetName];
                    NVGeocoder *geocoder = [NVGeocoder geocoderForCoordinate:position delegate:self];
#pragma unused(geocoder)
                }
                
                if ([newWallID isEqualToString:@""] ||
                    ![awd createNewWall:newWallID
                                atPoint:position
                              withHouse:houseAndUnit
                              andStreet:streetName])
                {
                    NVAlertView *alert = [NVAlertView showLargeAlertViewinView:self.view
                                                                      delegate:CRAPI.sharedInstance
                                                                         title:@"Failed to Create Wall Point"
                                                               buttonTextArray:@[@"OK"]
                                                              destructiveIndex:0];
#pragma unused(alert)
                }
                
                else
                {
                    [self vectorViewRefresh];
                    _noneSelected = NO;
                }
                break;}
            case DigitizationModeAlleyWallMove:{
                if (![AlleyWallData moveAlleyWallPoint:_selectedAlleyWallRefno to:position])
                {
                    NVAlertView *alert = [NVAlertView showLargeAlertViewinView:self.view
                                                                      delegate:CRAPI.sharedInstance
                                                                         title:@"Failed to Move Wall Point"
                                                               buttonTextArray:@[@"OK"]
                                                              destructiveIndex:0];
#pragma unused(alert)
                }
                else
                {
                    MarkerButton *marker = _markerArray.lastObject;
                    marker.position = position;
                    
                    marker.center = CGPointMake(_digitizerTargetView.center.x,
                                                (_digitizerTargetView.center.y - (marker.frame.size.height / 2.0)));
                    
                    [self updateInfoWindowPosition];
                    [self vectorViewRefresh];
                }
                break;}
            case DigitizationModeCurbRamps:{
                LLPOINT intPoint = {0};
                intPoint.lat = position.latitude;
                intPoint.lon = position.longitude;
                IntersectionsDatabase *intDB = [IntersectionsDatabase databaseForGeoid:CRAPI.sharedInstance.currentGeoid];
                [intDB addNewIntersectionAt:intPoint withName:@"Added in NVMobile"];
                [self vectorViewRefresh];
                _noneSelected = NO;
                break;}
            case DigitizationModeProperty:
                break;
            case DigitizationModeSewer:
                break;
             default:break;
        }
        
        [UIView animateWithDuration:0.25
                         animations:^{
                             _cancelDigitizerButton.alpha = 0.0;
                             _saveDigitizerButton.alpha = 1.0;
                         }];
        
        CGPoint targetPoint = [_mapView.projection pointForCoordinate:_mapView.camera.target];
        
        _digitizerTargetView.center =
        CGPointMake(targetPoint.x, (targetPoint.y + [self statusBarHeight:UIApplication.sharedApplication.statusBarOrientation]));
    }
}
-(void) removeScaleBar
{
    if (_scaleLayer)
        [_scaleLayer removeFromSuperlayer];
    if (_scaleLayer2)
        [_scaleLayer2 removeFromSuperlayer];
    if (_scaleLabel)
        [_scaleLabel removeFromSuperview];
    if (_scaleLabel2)
        [_scaleLabel2 removeFromSuperview];

}
-(void) displayScalebar
{
    CGRect mvf = _mapView.frame;
    CGRect sf = self.view.frame;
    [self removeScaleBar];
    _scaleLabel = _scaleLayer = nil;
     if (_hideScaleBar)
        return;
    float lineWidth = 5;
    CGRect tbframe = _mapToolbar.frame;
    CGPoint pt1, pt2, pt3, pt4, pt5, pt6;
//    if (!_compass.isHidden)
//        tbframe = _compass.frame;
    _scaleLayer = CAShapeLayer.layer;
    _scaleLayer2 = CAShapeLayer.layer;
    CAShapeLayer *layer = _scaleLayer;
    _scaleLayer.strokeColor = UIColor.redColor.CGColor;
    _scaleLayer.fillColor = UIColor.redColor.CGColor;
    _scaleLayer.lineWidth = lineWidth;
    if (tbframe.size.width > tbframe.size.height)
    {
        {
            UIBezierPath *path = UIBezierPath.bezierPath;
            pt1.x = _mapView.frame.origin.x;
            pt1.y = tbframe.origin.y - (lineWidth*2);
            [path moveToPoint:pt1];
            pt2.x = _mapView.frame.origin.x + _mapView.frame.size.width;
            pt2.y = pt1.y;
            [path addLineToPoint:pt2];
            [path moveToPoint:pt1];
            pt3.x = pt1.x + lineWidth*2;
            pt3.y = pt1.y - lineWidth*2;
            [path addLineToPoint:pt3];
            pt4.x = pt1.x + lineWidth*2;
            pt4.y = pt1.y + lineWidth*2;
            [path addLineToPoint:pt4];
            [path addLineToPoint:pt1];
            [path moveToPoint:pt2];
            pt5.x = pt2.x - lineWidth*2;
            pt5.y = pt2.y - lineWidth*2;
            [path addLineToPoint:pt5];
            pt6.x = pt2.x - lineWidth*2;
            pt6.y = pt2.y + lineWidth*2;
            [path addLineToPoint:pt6];
            [path addLineToPoint:pt2];
            layer.path = path.CGPath;
            _scaleLayer2.strokeColor = UIColor.whiteColor.CGColor;
            _scaleLayer2.fillColor = UIColor.whiteColor.CGColor;
            path = UIBezierPath.bezierPath;
            lineWidth = 2;
            _scaleLayer2.lineWidth = lineWidth;
            layer = _scaleLayer2;
            [path moveToPoint:pt1];
            [path addLineToPoint:pt2];
            [path moveToPoint:pt1];
            [path addLineToPoint:pt3];
            [path addLineToPoint:pt4];
            [path addLineToPoint:pt1];
            [path moveToPoint:pt2];
            [path addLineToPoint:pt5];
            [path addLineToPoint:pt6];
            [path addLineToPoint:pt2];
            layer.path = path.CGPath;
        }
        CLLocationCoordinate2D ptcl1 = [self coordinateForPoint:pt1];
        CLLocationCoordinate2D ptcl2 = [self coordinateForPoint:pt2];
        LLPOINT ptll1, ptll2;
        ptll1.lon = ptcl1.longitude;
        ptll1.lat = ptcl1.latitude;
        ptll2.lon = ptcl2.longitude;
        ptll2.lat = ptcl2.latitude;
        double dist = ArcDistanceLL(ptll1, ptll2);
        dist /= METERS_PER_MILE;
        CGPoint pt = pt1;
        int width = 250, height=30;
        pt.x += pt2.x/2;
        _scaleLabel = UILabel.new;
        _scaleLabel.backgroundColor = UIColor.clearColor;
        _scaleLabel.frame = CGRectMake(pt.x-width,pt.y-height*2, width,height);
        pt.y-=height/2;
        _scaleLabel.center = pt;
        _scaleLabel.textColor = UIColor.blackColor;
        //_scaleLabel.shadowColor = UIColor.whiteColor;
        //_scaleLabel.shadowOffset = CGSizeMake(3,0);
        _scaleLabel.font = [UIFont monospacedSystemFontOfSize:height-3 weight:UIFontWeightBlack];
        _scaleLabel.text = [NSString stringWithFormat:@"%.1f miles",dist];
        if (*_scaleLabel.text.UTF8String == '0')
        {
            _scaleLabel.text = [NSString stringWithFormat:@"%.2f miles",dist];
        }
        _scaleLabel.textAlignment = NSTextAlignmentCenter;
        _scaleLabel2 = UILabel.new;
        _scaleLabel2.backgroundColor = UIColor.clearColor;
        _scaleLabel2.frame = CGRectMake(pt.x-width,pt.y-height*2, width,height);
     
        _scaleLabel2.center = pt;
        _scaleLabel2.textColor = UIColor.yellowColor;
        //_scaleLabel.shadowColor = UIColor.whiteColor;
        //_scaleLabel.shadowOffset = CGSizeMake(3,0);
        _scaleLabel2.font = [UIFont monospacedSystemFontOfSize:height-3 weight:UIFontWeightUltraLight];
        _scaleLabel2.text = [NSString stringWithFormat:@"%.1f miles",dist];
        if (*_scaleLabel2.text.UTF8String == '0')
        {
            _scaleLabel2.text = [NSString stringWithFormat:@"%.2f miles",dist];
        }
        _scaleLabel2.textAlignment = NSTextAlignmentCenter;

    }
    else
    {
        UIBezierPath *path = UIBezierPath.bezierPath;
        pt1.y = _mapView.frame.origin.y;
        pt1.x = tbframe.origin.x + tbframe.size.width + (lineWidth*2);
        [path moveToPoint:pt1];
        pt2.y = _mapView.frame.size.height + _mapView.frame.origin.y;
        pt2.x = pt1.x;
        [path addLineToPoint:pt2];
        [path moveToPoint:pt1];
        pt3.y = pt1.y + lineWidth*2;
        pt3.x = pt1.x - lineWidth*2;
        [path addLineToPoint:pt3];
        pt3.y = pt1.y + lineWidth*2;
        pt3.x = pt1.x + lineWidth*2;
        [path addLineToPoint:pt3];
        [path addLineToPoint:pt1];
        [path moveToPoint:pt2];
        pt3.y = pt2.y - lineWidth*2;
        pt3.x = pt2.x - lineWidth*2;
        [path addLineToPoint:pt3];
        pt3.y = pt2.y - lineWidth*2;
        pt3.x = pt2.x + lineWidth*2;
        [path addLineToPoint:pt3];
        [path addLineToPoint:pt2];
        _scaleLayer.path = path.CGPath;
        CLLocationCoordinate2D ptcl1 = [self coordinateForPoint:pt1];
        CLLocationCoordinate2D ptcl2 = [self coordinateForPoint:pt2];
        LLPOINT ptll1, ptll2;
        ptll1.lon = ptcl1.longitude;
        ptll1.lat = ptcl1.latitude;
        ptll2.lon = ptcl2.longitude;
        ptll2.lat = ptcl2.latitude;
        double dist = ArcDistanceLL(ptll1, ptll2);
        dist /= METERS_PER_MILE;
        CGPoint pt = pt1;
        int width = 250, height=30;
        pt.y = (pt1.y + pt2.y) /2 - mvf.origin.y / 2;
        _scaleLabel = UILabel.new;
        _scaleLabel.backgroundColor = UIColor.clearColor;
        _scaleLabel.frame = CGRectMake(pt.x+height,pt.y-width*2, width,height);
        pt.x+=height/2;
        _scaleLabel.center = pt;
        _scaleLabel.textColor = UIColor.redColor;
        _scaleLabel.shadowColor = UIColor.whiteColor;
        _scaleLabel.font = [UIFont systemFontOfSize: height -4];
        _scaleLabel.text = [NSString stringWithFormat:@"%.1f miles",dist];
        _scaleLabel.textAlignment = NSTextAlignmentCenter;
        _scaleLabel.transform = CGAffineTransformMakeRotation(HALFPI*3);

    }

    [self.view.layer addSublayer:_scaleLayer];
    [self.view.layer addSublayer:_scaleLayer2];
    [self.view addSubview:_scaleLabel];
    [self.view addSubview:_scaleLabel2];
}

-(void) createCurrentRouteFromRoutePoints
{
    HuntingData *hd = HuntingData.new;
    CRAPI.sharedInstance.currentRoute = NSMutableArray.new;
    NSArray * rt = [hd getWaypointsOfType:@"RoutePoint"];
    
    for (UserWaypoint * wp in rt)
    {
        RoutePoint *routePoint = RoutePoint.new;
        routePoint.refno = wp.refno;
        routePoint.latlon = wp.latlon;
        [CRAPI.sharedInstance.currentRoute addObject:routePoint];
    }
}
-(void) clearCurrentRoute
{
    for (CAShapeLayer *routeLayer in _routeSubLayers)
        [routeLayer removeFromSuperlayer];
    _routeSubLayers = NSMutableArray.new;
}

-(void) displayCurrentRoute
{
    [self clearCurrentRoute];
    HuntingData *hd = HuntingData.new;
    int n = CRAPI.sharedInstance.currentRoute.count;
    if (CRAPI.sharedInstance.currentRoute.count > 1)
    {
        CAShapeLayer *routeLayer = CAShapeLayer.layer;
        if (_numCurrentRoutePoints > 0)
            routeLayer.strokeColor = UIColor.yellowColor.CGColor;
        else
        {
            routeLayer.strokeColor = UIColor.redColor.CGColor;
        }
        routeLayer.fillColor = nil;
        routeLayer.lineWidth = 5;
        UIBezierPath *path = UIBezierPath.bezierPath;
        RoutePoint *rpt = CRAPI.sharedInstance.currentRoute[0];
        int ipt = 0;
        CGPoint pt;
        if (CRAPI.sharedInstance.inRouteMode)
        {
            if (rpt.refno == CRAPI.sharedInstance.currentSelectedWaypoint)
            {
                routeLayer.strokeColor = UIColor.greenColor.CGColor;
                CLLocationCoordinate2D llpt={_currentLocation.latitude,_currentLocation.longitude};
                pt = [_mapView.projection pointForCoordinate:llpt];
                [path moveToPoint:pt];
                llpt.latitude = rpt.latlon.lat;
                llpt.longitude = rpt.latlon.lon;
                pt = [_mapView.projection pointForCoordinate:llpt];
                [path addLineToPoint:pt];
                routeLayer.path = path.CGPath;
                [_mapView.layer addSublayer:routeLayer];
                [_routeSubLayers addObject:routeLayer];
                routeLayer = CAShapeLayer.layer;
                path = UIBezierPath.bezierPath;
                routeLayer.strokeColor = UIColor.redColor.CGColor;
                routeLayer.fillColor = nil;
                routeLayer.lineWidth = 5;
                [_mapView.layer renderInContext:UIGraphicsGetCurrentContext()];
            }
        }
        for (RoutePoint *rpt in CRAPI.sharedInstance.currentRoute)
        {
            CLLocationCoordinate2D llpt={rpt.latlon.lat,rpt.latlon.lon};
            if (CRAPI.sharedInstance.inRouteMode && ipt && rpt.refno == CRAPI.sharedInstance.currentSelectedWaypoint)
            {
                routeLayer.path = path.CGPath;
                [_mapView.layer addSublayer:routeLayer];
                [_routeSubLayers addObject:routeLayer];
                routeLayer = CAShapeLayer.layer;
                routeLayer.fillColor = nil;
                path = UIBezierPath.bezierPath;
                routeLayer.strokeColor = UIColor.greenColor.CGColor;
                _trackLayer.lineWidth = 5;
                [path moveToPoint:pt];
                pt = [_mapView.projection pointForCoordinate:llpt];
                [path addLineToPoint:pt];
                routeLayer.path = path.CGPath;
                [_mapView.layer addSublayer:routeLayer];
                [_routeSubLayers addObject:routeLayer];
                routeLayer = CAShapeLayer.layer;
                path = UIBezierPath.bezierPath;
                routeLayer.fillColor = nil;
                _trackLayer.lineWidth = 5;
                routeLayer.strokeColor = UIColor.redColor.CGColor;
                ipt = 0;
            }
            else
                pt = [_mapView.projection pointForCoordinate:llpt];

            if (!ipt++)
                [path moveToPoint:pt];
            else
                [path addLineToPoint:pt];
        }
        if (ipt)
        {
            routeLayer.path = path.CGPath;
            [_mapView.layer addSublayer:routeLayer];
            [self.view bringSubviewToFront:_myLocationMarker];
            [_routeSubLayers addObject:routeLayer];
        }
    }
}
-(void) displayTrackRoute
{
    [self clearCurrentTrackRoute];
    if (!_displayTrackingRoute)
        return;
    int n = CRAPI.sharedInstance.currentTrackRoute.count;
    if (n > 1)
    {
        _trackLayer = CAShapeLayer.layer;
        _trackLayer.strokeColor = UIColor.greenColor.CGColor;
        _trackLayer.fillColor = nil;
        _trackLayer.lineWidth = 3;
        UIBezierPath *path = UIBezierPath.bezierPath;
        TrackRoutePoint *npt = CRAPI.sharedInstance.currentTrackRoute[0];
        int ipt = 0;
        for (TrackRoutePoint *npt in CRAPI.sharedInstance.currentTrackRoute)
        {
            CLLocationCoordinate2D llpt;
            llpt.latitude = npt.latlon.lat;
            llpt.longitude = npt.latlon.lon;
            CGPoint pt = [_mapView.projection pointForCoordinate:llpt];
            if (!ipt++)
                [path moveToPoint:pt];
            else
                [path addLineToPoint:pt];
        }
        _trackLayer.path = path.CGPath;
        [_mapView.layer addSublayer:_trackLayer];
    }
}
-(void) clearCurrentWeatherData
{
    if (_windImage)
    {
        [_windImage removeFromSuperview];
        [_weatherLabel removeFromSuperview];
        _windImage = nil;
        _weatherLabel = nil;
    }
}

-(void) displayWeatherData
{
    [self clearCurrentWeatherData];
    if (_hideScaleBar)
       return;
    if (!_currentWeatherData)
        return;
    CGFloat windDirDeg = _currentWeatherData.windDir;
    CGFloat windDir = DegreesToRadians (windDirDeg);
    windDir = LTWOPI (windDir - HALFPI);
    CGPoint point  = {CGRectGetMidX(self.view.frame),CGRectGetMidY(self.view.frame)};
    int width = min (self.view.frame.size.width,self.view.frame.size.height);
    width *=  0.9;
    CGRect windRect = CGRectMake (point.x,point.y,width,width);
    CGRect windLabelRect = CGRectMake (point.x,point.y,width/2,width);
    _windImage = [[UIImageView alloc] initWithFrame:windRect];
    _weatherLabel = [[UILabel alloc] initWithFrame:windLabelRect];
    _windImage.backgroundColor = UIColor.clearColor;
    _weatherLabel.backgroundColor = UIColor.clearColor;
    UIColor *blue = [[UIColor alloc] initWithRed:0.0
                                           green:0
                                            blue:1
                                           alpha:.5];
    CGFloat labelRot = windDir-HALFPI;
    if (windDirDeg > 270 || windDirDeg < 90)
        labelRot += PY;

    if (_currentWeatherData.windSpeed < 3)
    {
        _windImage.frame = CGRectMake (point.x,point.y,width/2,width/2);
        _windImage.layer.cornerRadius = _windImage.frame.size.width / 2;
        _windImage.backgroundColor = blue;
        labelRot = 0;
    }
    else
    {
        UIImage *img = [SymbolDictionary imageOfArrow:_windImage.frame
                                            lineWidth:2
                                            lineColor:UIColor.whiteColor
                                            fillColor:blue
                                             withText:nil];
        _windImage.image = img;
    }
    _windImage.center = point;
    _windImage.clipsToBounds = true;
    NSString * dayAndTime = [WeatherData forecastDayandTime:_currentWeatherData.timeStamp];
    NSString * windFrom = [WeatherData compassFromDeg:_currentWeatherData.windDir];
    if (_currentWeatherData.windSpeed <= 0)
    {
        windFrom = @"";
        _weatherLabel.text = [NSString stringWithFormat:@"%@\nTemp:%i deg\nWind:%@ %i mph\n%@",dayAndTime,_currentWeatherData.temp,windFrom,_currentWeatherData.windSpeed,_currentWeatherData.desc];
    }
    else
        _weatherLabel.text = [NSString stringWithFormat:@"%@\nTemp:%i deg\nWind:%@ %i mph\n%@",dayAndTime,_currentWeatherData.temp,windFrom,_currentWeatherData.windSpeed,_currentWeatherData.desc];
    _weatherLabel.numberOfLines = 4;
    _weatherLabel.font =[UIFont boldSystemFontOfSize: 20];
    _weatherLabel.adjustsFontSizeToFitWidth = YES;

    _weatherLabel.textColor = UIColor.whiteColor;
    _weatherLabel.textAlignment = NSTextAlignmentCenter;
    _weatherLabel.center = point;
    _windImage.transform = CGAffineTransformMakeRotation( windDir-HALFPI);
    _weatherLabel.transform = CGAffineTransformMakeRotation(labelRot);
    [self.view addSubview:_windImage];
    [self.view addSubview:_weatherLabel];
    [self.view bringSubviewToFront:_weatherLabel];
}

-(void) clearCurrentTrackRoute
{
    [_trackLayer removeFromSuperlayer];
}

- (void)mapViewLongPressed:(UILongPressGestureRecognizer *)gesture
{
    if (CRAPI.sharedInstance.currentApp ==  HCConfigMetroProp || CRAPI.sharedInstance.currentApp == HCConfigCrimes)
    {
        if (gesture.state == UIGestureRecognizerStateBegan)
            _vectorView.alpha = 0.0;
        
        else if (gesture.state == UIGestureRecognizerStateEnded)
            _vectorView.alpha = 1.0;
        
        return;
    }
    if (CRAPI.sharedInstance.currentApp ==  HCConfigHunting)
    {
        HuntingData *hd = HuntingData.new;
        if (gesture.state == UIGestureRecognizerStateEnded)
        {
            CGPoint gesturePoint  = [gesture locationOfTouch:0 inView:self.view];
            int numTouches = gesture.numberOfTouches;
            CLLocationCoordinate2D gestureLocation = [_mapView.projection coordinateForPoint:gesturePoint];
            LLPOINT llp = {gestureLocation.longitude,gestureLocation.latitude};
            
            if (_numCurrentRoutePoints++)
            {
                RoutePoint *routePoint = RoutePoint.new;
                routePoint.latlon = llp;
                [CRAPI.sharedInstance.currentRoute addObject:routePoint];
                NSString * name = [NSString stringWithFormat:@"%i",_numCurrentRoutePoints];
                [hd addWaypoint:name type:@"RoutePoint" latlon:llp description:@"" displayOnCompass:YES];
                [self displayCurrentRoute];
                [self vectorViewRefresh];
            }
            _numCurrentRoutePoints = 0;

        }
        return;
    }
    if (_inDigitizationMode)
    {
        [self handleLongPressDigitizingForState:gesture];
        return;
    }
    
    if (![ConfigurationControl.sharedInstance layer:HCLayerSewers
                                      visibleAtZoom:_mapView.camera.zoom
                                            andPass:PickPass])
    {
        return;
    }
    
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
            [self vectorViewRefresh];
        }
        
        else if (!_waitForVectorViewRefresh)
        {
            CGPoint gesturePoint = [gesture locationInView:self.view];
            CLLocationCoordinate2D gestureLocation = [_mapView.projection coordinateForPoint:gesturePoint];
            LLPOINT llp = {0};
            llp.lat = gestureLocation.latitude;
            llp.lon = gestureLocation.longitude;
            int platRefno = 0;
            
            if (ConfigurationControl.sharedInstance.currentApp == HCConfigMapleGrove)
            {
                UserLayerDisplay *ud = UserLayerDisplay.new;
                ud.processingID = CRAPI.sharedInstance.keepProcessing;
                CRAPI.sharedInstance.selectedPDFID = [ud pickPDFPlat:&llp platRefno:&platRefno];
            }
            
            else
            {
                SewerData *sewerData = SewerData.new;
                platRefno = [sewerData pickSanPlat:&llp];
            }
            
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
                
                [_platView setPlatID:_selectedPlatRefno andType:PLAT_TYPE_STORM];
                [self vectorViewRefresh];
            }
        }
        
        else if (!_selectedPlatRefno)
        {
            CRAPI.sharedInstance.showPlats = 0;
            [self clearVectorView];
            _waitForVectorViewRefresh = NO;
        }
        
        else if (_platView)
            [_platView setPlatID:_selectedPlatRefno andType:PLAT_TYPE_STORM];
    }
    
    else if (gesture.state == UIGestureRecognizerStateEnded)
    {
        _mapView.settings.scrollGestures = YES;
        CRAPI.sharedInstance.showPlats = 0;
        
        if (_selectedPlatRefno)
        {
            SewerData *sd = SewerData.new;
            _mgvData = nil;
            _splitPlatView = NO;
            
            if (ConfigurationControl.sharedInstance.currentApp == HCConfigMapleGrove)
            {
                NSString *dir = [NSString stringWithFormat:@"MapleGrove/As-built/JPG/%@",
                                 CRAPI.sharedInstance.selectedPDFID.stringByDeletingPathExtension];
                
                [FTPDirectoryList getListingFromFTPDomain:CRAPI.sharedInstance.getNVCRISServer
                                                directory:dir
                                                 username:@"GSSiProfessionalServer"
                                                 password:@"GSSi"
                                                     port:@"21"
                                                 delegate:self];
            }
            
            else
            {
                
                NSString *platID = [sd getPlatIDofType:@"storm" fromRefno:_selectedPlatRefno];
                
                [sd loadPlat:platID
                      ofType:@"storm"
                usingPopover:_popover
                 andDelegate:self];
            }
        }
        
        [self vectorViewRefresh];
    }
}

- (void)FTPdidComplete:(FTPDataType)dataType
            withStatus:(FTPStatus)status
       andStatusString:(NSString *)statusString
              filePath:(NSString *)path
{
    [_popover hide];
    
    NSLog(@"%li:%@", (long)status, statusString);
    
    if (status == FTPStatusOK || status == FTPStatusFileExists)
    {
        switch (dataType)
        {
            case FTPDataJPG:
                _currentFile++;
                
                if (_currentFile < _files.count)
                    [self performSelector:@selector(getNextFile) withObject:nil afterDelay:0.1];
                
                else
                {
                    _currentFile = 0;
                    [self showImage];
                }
                break;
            case FTPDataPlat:{
                CRAPI.sharedInstance.currentPlatImagePath = path;
                CRAPI.sharedInstance.currentPlatType = @"storm";
                [_platView setPlatID:_selectedPlatRefno andType:PLAT_TYPE_STORM];
                
                if (_screenSetting == MapViewScreenSettingFullscreen && _selectedPlatRefno > 0)
                {
                    _usePlatView = YES;
                    [self mapToolbarDidSelectSplitScreenSetting:MapViewScreenSettingSplitScreen];
                    [_mapToolbar splitScreenSelectedSegmentIndex:MapViewScreenSettingSplitScreen];
                }
                break;}
            case FTPDataPDF:{
                [self removeAllPlatPDFs];
                _usePlatView = NO;
                [self hideMarkersAndInfoWindows:NO];
                [ConfigurationControl.sharedInstance setApp:HCConfigMapleGrovePDF];
                [_mapToolbar configure:_screenSetting];
                
                if (_splitPlatView)
                {
                    [self mapToolbarDidSelectSplitScreenSetting:MapViewScreenSettingSplitPlatView];
                    [_mapToolbar splitScreenSelectedSegmentIndex:MapViewScreenSettingSplitScreen];
                }
                
                else
                {
                    [self mapToolbarDidSelectSplitScreenSetting:MapViewScreenSettingPlatView];
                    [_mapToolbar splitScreenSelectedSegmentIndex:MapViewScreenSettingPlatView];
                }
                
                NVWebView *nvwv1 = [NVWebView showWebViewInView:_firstView
                                                 showFileAtPath:path
                                                       delegate:self];
                
                nvwv1.tag = 111;
                [nvwv1 hideReturnButton];
                
                if (_mgvData)
                {
                    [nvwv1 zoomToPoint:_mgvData.ptUpper
                            withinPage:1
                             withScale:_mgvData.scaleUpper
                              rotation:_mgvData.rotUpper];
                }
                
                else
                {
                    DPOINT pt = {0,0};
                    [nvwv1 zoomToPoint:pt
                            withinPage:1
                             withScale:1
                              rotation:0];
                }
                
                if (_splitPlatView)
                {
                    NVWebView *nvwv2 = [NVWebView showWebViewInView:_secondView
                                                     showFileAtPath:path
                                                           delegate:self];
                    
                    nvwv2.tag = 222;
                    [nvwv2 hideReturnButton];
                    
                    [nvwv2 zoomToPoint:_mgvData.ptLower
                            withinPage:1
                             withScale:_mgvData.scaleLower
                              rotation:_mgvData.rotLower];
                }
                break;}
            default:break;
        }
    }
    
    else
    {
        showAlert([NSString stringWithFormat:@"FTP Error:Cannot get %@ (%@)",
                   path.lastPathComponent, statusString]);
    }
}
- (void)webView:(NVWebView *)webView
wasTappedAtPoint:(DPOINT)point
     withinPage:(int)page
{
    switch (webView.tag)
    {
        case 111://top PDF
            NSLog(@"Top PDF tapped on page %i at x:%f,y:%f", page, point.x, point.y);
            break;
        case 222://bottom PDF
            NSLog(@"Bottom PDF tapped on page %i at x:%f,y:%f", page, point.x, point.y);
            break;
    }
}

- (void)removePreviousInfoWindow
{
    if ([self.view.subviews containsObject:_infoWindow])
        [_infoWindow removeFromSuperview];
}

- (void)restorePreviousInfoWindow
{
    if (!_noneSelected)
    {
        MarkerButton *marker = _markerArray.lastObject;
        
        if (marker)
        {
            _infoWindow = MarkerInfoWindow.new;
            _infoWindow.delegate = self;
            _infoWindow.marker = marker;
            _infoWindow.optionsTitle = marker.title;
             _noneSelected = NO;
            [self.view addSubview:_infoWindow];
            [self updateInfoWindowPosition];
        }
    }
}

- (void)mapView:(GMSMapView *)mapView
       willMove:(BOOL)gesture
{
    [self clearCurrentRoute];
    [self clearCurrentTrackRoute];
    if (_screenSetting == MapViewScreenSettingPlatView)
        return;
    
    for (UIView *views in self.view.subviews)
    {
        if (views.tag == 77777)
            [views removeFromSuperview];
    }
    
    [self clearVectorView];
    
    if ([self.view.subviews containsObject:_nvdv])
        [_nvdv clearDigitizerView];
    
    if (_firstView.frame.size.height != 0.0)
        [self.view bringSubviewToFront:_firstView];
    
    if (_secondView.frame.size.height != 0.0)
        [self.view bringSubviewToFront:_secondView];
    
    if (![self legendIsExpanded] && ![self alertVisible] && !_showsPanorama)
    {
        [_mapToolbar bringToFrontOfView];
        [self.view bringSubviewToFront:_compass];
        
        if (_legendsAreOffMap && [self.view.subviews containsObject:_legendScrollView])
            [self.view bringSubviewToFront:_legendScrollView];
    }
    
    if (!_tableView.hidden && ![self alertVisible] && !_showsPanorama)
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
    
    for (NVWebView *nvwv in self.view.subviews)
    {
        if ([nvwv isKindOfClass:NVWebView.class])
            [self.view bringSubviewToFront:nvwv];
    }
    
    [self setMapType];
}

- (void)mapView:(GMSMapView *)mapView
didChangeCameraPosition:(GMSCameraPosition *)position
{
    if (_screenSetting == MapViewScreenSettingPlatView)
        return;
    double bearing = position.bearing;
    if (bearing != 0.0)
    {
        [self showCompass];
        _compass.transform = CGAffineTransformMakeRotation(-bearing * M_PI / 180);
    }
    
    [self updateMarkerPosition];
    _keepZoomExtents = NO;
    
    for (NVPhotoView *nvpvs in _insetPixArray)
        [nvpvs updatePosition];
    LLPOINT pt;
    pt.lat = position.target.latitude;
    pt.lon = position.target.longitude;
    [CRAPI.sharedInstance setCurrentLocation:pt];
    [self setZoom:mapView.camera.zoom];
}

- (void)updateMarkerPosition
{
    CGFloat statusBarHeight = [self statusBarHeight:UIApplication.sharedApplication.statusBarOrientation];
    
    for (MarkerButton *markers in _markerArray)
    {
        CGPoint target = [self pointForCoordinate:markers.position];
        markers.center = CGPointMake(target.x, ((target.y + statusBarHeight) - (markers.frame.size.height / 2.0)));
    }
    
    [self updateInfoWindowPosition];
    
    if (!_myLocationMarker.hidden)
    {
        CGPoint target = [self pointForCoordinate:_currentLocation];
        _myLocationMarker.center = CGPointMake(target.x, (target.y + statusBarHeight));
    }
    
    for (NVMarkerInfoButton *nvmibs in self.view.subviews)
    {
        if ([nvmibs isKindOfClass:NVMarkerInfoButton.class])
        {
            CGPoint target = [self pointForCoordinate:nvmibs.position];
            nvmibs.center = CGPointMake(target.x, ((target.y + statusBarHeight) - (nvmibs.frame.size.height / 2.0)));
        }
    }
}

- (void)updateInfoWindowPosition
{
    MarkerButton *marker = _markerArray.lastObject;
    CGFloat xPos = marker.center.x;
    
    if (CGRectContainsRect(_mapView.frame, marker.frame) || CGRectIntersectsRect(_mapView.frame, marker.frame))
    {
        xPos = MAX(xPos, (_infoWindow.frame.size.width / 2.0));
        xPos = MIN(xPos, (_mapView.frame.size.width - (_infoWindow.frame.size.width / 2.0)));
    }
    
    _infoWindow.center = CGPointMake(xPos, (marker.center.y - 42.0));
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
        [self vectorViewRefresh];
    
    else
        _firstTimeMap = NO;
    
    if (position.bearing == 0.0)
        [self hideCompass];
    else
        iii = 1;
    
    if ([self.view.subviews containsObject:_nvdv])
    {
        _vectorView.mapView = _mapView;
        _vectorView.mvc = self;
        [_nvdv setNeedsDisplay];
    }
    
    [self updateMarkerPosition];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self updateMarkerPosition];
    [self showMarkersAndInfoWindows:NO];
    
    for (NVPhotoView *nvpvs in _insetPixArray)
    {
        [nvpvs updatePosition];
        nvpvs.hidden = NO;
    }
    
    CGFloat statusBarHeight = [self statusBarHeight:UIApplication.sharedApplication.statusBarOrientation];
    NSTimeInterval duration = 0.25;
    CGSize size = self.view.frame.size;
    
    CGFloat margin = 8.0;
    
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
        margin = 4.0;
    
    if ([self.view.subviews containsObject:[self.view viewWithTag:99999]])
    {
        [self.view viewWithTag:99999].frame = CGRectMake((self.view.frame.size.width - _compassSize - margin),
                                                         statusBarHeight + margin, _compassSize, _compassSize);
    }
    
    CGRect frame1 = CGRectMake(0.0, statusBarHeight + ((size.height - statusBarHeight) / 2.0),
                               size.width, ((size.height - statusBarHeight) / 2.0));
    
    CGRect frame2 = CGRectMake(0.0, statusBarHeight + ((size.height - statusBarHeight) / 3.0),
                               size.width, ((size.height - statusBarHeight) / 3.0));
    
    CGRect frame3 = CGRectMake(0.0, statusBarHeight, size.width, (size.height - statusBarHeight));
    
    CGPoint targetPoint = [_mapView.projection pointForCoordinate:_mapView.camera.target];
    _digitizerTargetView.center = CGPointMake(targetPoint.x, (targetPoint.y + [self statusBarHeight:UIApplication.sharedApplication.statusBarOrientation]));
    _digitizerTargetView.hidden = NO;
    
    switch (_screenSetting)
    {
        case MapViewScreenSettingFullscreen:
            break;
        case MapViewScreenSettingSplitScreen:
        {
            [UIView animateWithDuration:duration
                             animations:^{
                                 _mapView.frame = _vectorView.frame =
                                 CGRectMake(0.0, statusBarHeight, size.width,
                                            ((size.height - statusBarHeight) / 2.0));
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
        case MapViewScreenSettingSplitPlatView:
        {
            [UIView animateWithDuration:duration
                             animations:^{
                                 _firstView.frame =
                                 CGRectMake(0.0, statusBarHeight, size.width,
                                            ((size.height - statusBarHeight) / 2.0));
                             }];
            
            [UIView animateWithDuration:duration
                             animations:^{
                                 _secondView.frame = frame1;
                             }];
        }
            break;
        case MapViewScreenSettingTriScreen:
        {
            [UIView animateWithDuration:duration
                             animations:^{
                                 _mapView.frame = _vectorView.frame =
                                 CGRectMake(0.0, statusBarHeight, size.width,
                                            ((size.height - statusBarHeight) / 3.0));
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
                                 CGRectMake(0.0, statusBarHeight + ((size.height - statusBarHeight) / 1.5),
                                            size.width, ((size.height - statusBarHeight) / 3.0));
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
                                 _firstView.frame = frame3;
                             }];
            
            [UIView animateWithDuration:duration
                             animations:^{
                                 _platView.center = CGPointMake((_firstView.frame.size.width / 2.0),
                                                                (_firstView.frame.size.height / 2.0));
                             }];
        }
        default:break;
    }
    
    [_mapToolbar didRotateWithTabBarHeight:_tabBarHeight statusBarHeight:statusBarHeight];
    [self updateCompassPosition:NO];
    
    if (_mapView.camera.bearing != 0.0)
        _compass.alpha = 1.0;
    
    if (![self legendIsExpanded] && ![self alertVisible] &&
        ![self.view.subviews containsObject:_legendMinimizeButton])
    {
        [self updateLegendPositions];
    }
    
    if (!_tableView.hidden)
        [_tableView reloadData];
    
    [self setMapType];
    
    [self performSelector:@selector(resetPlatProfileViewsAfterRotation)
               withObject:nil
               afterDelay:0.1];
    
    if (_keepZoomExtents)
        [self extentZoom];
    
    [self vectorViewRefresh];
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
    _digitizerTargetView.hidden = YES;
    [self clearVectorView];
    [self hideMarkersAndInfoWindows:NO];
    _compass.alpha = 0.0;
    
    for (NVPhotoView *nvpvs in _insetPixArray)
        nvpvs.hidden = YES;
    
    if ([self.view.subviews containsObject:_nvdv])
    {
        [_nvdv clearDigitizerView];
        [_nvdv placeTargetInCenter];
    }
    
    CGFloat statusBarHeight = [self statusBarHeight:toInterfaceOrientation];
    CGSize size = self.view.frame.size;
    
    CGFloat margin = 8.0;
    
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
        margin = 4.0;
    
    if ([self.view.subviews containsObject:[self.view viewWithTag:99999]])
    {
        [UIView animateWithDuration:duration
                         animations:^{
                             [self.view viewWithTag:99999].frame =
                             CGRectMake((self.view.frame.size.height - _compassSize - margin + _tabBarHeight),
                                        statusBarHeight + margin, _compassSize, _compassSize);
                         }];
    }
    
    CGRect frame1 = CGRectMake(0.0, statusBarHeight + ((size.width - _tabBarHeight - statusBarHeight) / 2.0),
                               (size.height + _tabBarHeight), ((size.width - _tabBarHeight - statusBarHeight) / 2.0));
    
    CGRect frame2 = CGRectMake(0.0, statusBarHeight + ((size.width - _tabBarHeight - statusBarHeight) / 3.0),
                               (size.height + _tabBarHeight), ((size.width - _tabBarHeight - statusBarHeight) / 3.0));
    
    CGRect frame3 = CGRectMake(0.0, statusBarHeight, (size.height + _tabBarHeight),
                               (size.width - _tabBarHeight - statusBarHeight));
    
    if (_legendsAreOffMap)
        frame3.size.width -= _mapViewLegendOffset;
    
    if (_fromSpreadsheet)
    {
        [_mapToolbar willRotateWithDuration:duration
                               tabBarHeight:0.0
                            statusBarHeight:statusBarHeight];
    }
    
    else
    {
        [_mapToolbar willRotateWithDuration:duration
                               tabBarHeight:_tabBarHeight
                            statusBarHeight:statusBarHeight];
    }
    
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
    
    switch (_screenSetting)
    {
        case MapViewScreenSettingFullscreen:
            break;
        case MapViewScreenSettingSplitScreen:
        {
            [UIView animateWithDuration:duration
                             animations:^{
                                 _mapView.frame = _vectorView.frame =
                                 CGRectMake(0.0, statusBarHeight, (size.height + _tabBarHeight),
                                            ((size.width - _tabBarHeight - statusBarHeight) / 2.0));
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
        case MapViewScreenSettingSplitPlatView:
        {
            [UIView animateWithDuration:duration
                             animations:^{
                                 _firstView.frame =
                                 CGRectMake(0.0, statusBarHeight, (size.height + _tabBarHeight),
                                            ((size.width - _tabBarHeight - statusBarHeight) / 2.0));
                             }];
            
            [UIView animateWithDuration:duration
                             animations:^{
                                 _secondView.frame = frame1;
                             }];
        }
            break;
        case MapViewScreenSettingTriScreen:
        {
            [UIView animateWithDuration:duration
                             animations:^{
                                 _mapView.frame = _vectorView.frame =
                                 CGRectMake(0.0, statusBarHeight, (size.height + _tabBarHeight),
                                            ((size.width - _tabBarHeight - statusBarHeight) / 3.0));
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
                                 CGRectMake(0.0, statusBarHeight + ((size.width - _tabBarHeight - statusBarHeight) / 1.5),
                                            (size.height + _tabBarHeight), ((size.width - _tabBarHeight - statusBarHeight) / 3.0));
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
                                 _firstView.frame = frame3;
                             }];
            
            [UIView animateWithDuration:duration
                             animations:^{
                                 _platView.center = CGPointMake((_firstView.frame.size.width / 2.0),
                                                                (_firstView.frame.size.height / 2.0));
                             }];
        }
        default:break;
    }
    
    if (ConfigurationControl.sharedInstance.currentApp == HCConfigCrimes ||
        ConfigurationControl.sharedInstance.currentApp == HCConfigCurbRamps ||
        ConfigurationControl.sharedInstance.currentApp == HCConfigMapleGrove ||
        ConfigurationControl.sharedInstance.currentApp == HCConfigFromSpreadsheet ||
        ConfigurationControl.sharedInstance.currentApp == HCConfigMetroProp)
    {
        if (!_legendsAreOffMap)
        {
            for (ThemeLegendMapOverlay *tlmos in self.view.subviews)
            {
                if ([tlmos isKindOfClass:ThemeLegendMapOverlay.class])
                {
                    if (!tlmos.isExpanded)
                    {
                        if (toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft ||
                            toInterfaceOrientation == UIInterfaceOrientationLandscapeRight)
                        {
                            [UIView animateWithDuration:duration
                                             animations:^{
                                                 tlmos.frame = CGRectMake(tlmos.legend.landscapeMapOrigin.x,
                                                                          tlmos.legend.landscapeMapOrigin.y,
                                                                          tlmos.frame.size.width,
                                                                          tlmos.frame.size.height);
                                             }];
                        }
                        
                        else
                        {
                            [UIView animateWithDuration:duration
                                             animations:^{
                                                 tlmos.frame = CGRectMake(tlmos.legend.portraitMapOrigin.x,
                                                                          tlmos.legend.portraitMapOrigin.y,
                                                                          tlmos.frame.size.width,
                                                                          tlmos.frame.size.height);
                                             }];
                        }
                    }
                }
            }
        }
    }
}

- (BOOL)legendIsExpanded
{
    BOOL isExpanded = NO;
    
    if (_legendsAreOffMap)
    {
        for (ThemeLegendMapOverlay *tlmos in _legendScrollView.subviews)
        {
            if ([tlmos isKindOfClass:ThemeLegendMapOverlay.class] && tlmos.isExpanded)
                isExpanded = YES;
        }
    }
    
    else for (ThemeLegendMapOverlay *tlmos in self.view.subviews)
    {
        if ([tlmos isKindOfClass:ThemeLegendMapOverlay.class] && tlmos.isExpanded)
            isExpanded = YES;
    }
    
    return isExpanded;
}

- (BOOL)alertVisible
{
    BOOL alertVisible = NO;
    
    for (NVAlertView *alert in self.view.subviews)
    {
        if ([alert isKindOfClass:NVAlertView.class])
            alertVisible = YES;
    }
    
    return alertVisible;
}

- (void)allocateVectorView:(BOOL)backGround
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
    _vectorView.translatesAutoresizingMaskIntoConstraints = NO;
    vectorViews[ivv] = _vectorView;
    _vectorView.ivv = ivv;
    _vectorView.pass = _vvpass;
    _vectorView.userInteractionEnabled = NO;
    _vectorView.delegate = self;
    if (!backGround)
    {
        [self.view addSubview:_vectorView];
        [_vectorView constrainToView:_mapView leading:0.0 trailing:0.0 top:0.0 bottom:0.0];
    }
}

- (void) CrimeDataUpdateDidComplete:(long)status
{
    _cdUpdate = nil;
    [self startVectorView:nil];
}

- (void)clearVectorView
{
    if (CRAPI.sharedInstance.inDataUpdate)
        return;
    if (!_showsPanorama)
    {
        [_vectorViewTimer invalidate];
        CRAPI.sharedInstance.keepProcessing++;
        NSLog(@"Vector view clear");
        
        if (!_vectorView)
            return;
        
        _vectorView.displayDataOption = DISPLAY_DATA_OPTION_NODISPLAY;
        [_vectorView removeFromSuperview];
        vectorViews[_vectorView.ivv] = nil;
        _vectorView = nil;
        [CRAPI.sharedInstance updateProgress:-1 current:0 range:0 numRanges:1];
        [CRAPI.sharedInstance updateProgress:1 current:0 range:0 numRanges:1];
    }
}

- (void)refreshVectorView:(GMSVisibleRegion)region
                   atZoom:(CGFloat)zoom
{
    if (!_showsPanorama)
    {
        [self clearVectorView];
        _vectorViewZoom = zoom;
        
        _vectorViewTimer = [NSTimer scheduledTimerWithTimeInterval:0.1
                                                            target:self
                                                          selector:@selector(startVectorView:)
                                                          userInfo:nil
                                                           repeats:NO];
    }
}

- (void)startVectorView:(NSTimer *)timer
{
    if (_hideScaleBar)
        return;
    [self clearCurrentRoute];

    if (CRAPI.sharedInstance.becameActive &&
        !CRAPI.sharedInstance.inDataUpdate &&
        ![UserDefaults.defaults boolForKey:@"NoAutoUpdate"] &&
        ConfigurationControl.sharedInstance.currentApp == HCConfigCrimes)
    {        
        if (_cdUpdate)
            return;
        _cdUpdate = [CrimeData new];
        if ([_cdUpdate update:self.view
                         auto:YES
                     delegate:self])
            return;
        else
            _cdUpdate = nil;
    }
    [self allocateVectorView:NO];
    [self vectorViewSetup];
    _vectorView.mapView = _mapView;
    _vectorView.mvc = self;
    [_vectorView setNeedsDisplay];
}

- (void) vectorViewSetup
{
    _vectorView.displayDataOption = DISPLAY_DATA_OPTION_DISPLAY;
    
    [_vectorView setRegion:_mapView.projection.visibleRegion];
    [self setZoom:_vectorViewZoom];

    _vectorView.zoom = _vectorViewZoom;
    
    NSLog(@"Vector view start: zoom = %f", _vectorViewZoom);
    
    if ([ConfigurationControl.sharedInstance haveUserAerials] &&
        [ConfigurationControl.sharedInstance layer:HCLayerAerials
                                     visibleAtZoom:_vectorViewZoom
                                           andPass:AerialPass])
    {
        _layer_jpeg.map = _mapView;
        _layer_png.map = _mapView;
        CRAPI.sharedInstance.GMTilesVisible = YES;
    }
    
    else
    {
        _layer_jpeg.map = nil;
        _layer_png.map = nil;
        CRAPI.sharedInstance.GMTilesVisible = NO;
    }

}
- (void)setMapType
{
    if (_mapTypeFromConfig)
    {
        _mapView.mapType = _mapTypeFromConfig;
        ConfigurationControl.sharedInstance.mapType = _mapTypeFromConfig;

        return;
    }
    if (![ConfigurationControl.sharedInstance haveUserAerials] &&
        ![ConfigurationControl.sharedInstance useMapTypeControl])
    {
        if  ([ConfigurationControl.sharedInstance layer:HCLayerAerials
                                          visibleAtZoom:CRAPI.sharedInstance.currentZoom
                                                andPass:-1])
        {
            _mapView.mapType = kGMSTypeHybrid;
        }
        
        else
            _mapView.mapType = kGMSTypeNormal;
    }
    else
        _mapView.mapType = ConfigurationControl.sharedInstance.mapType;
}

- (void)highlightVectorView:(PickedItem *)pi
              displayOption:(int)option
{
    if (!_vectorView)
        [self allocateVectorView:NO];
    
    _vectorView.displayDataOption = option;
    
    [_vectorView setRegion:_mapView.projection.visibleRegion];
    _vectorView.zoom = _vectorViewZoom;
    _vectorView.pickedItem = pi;
    
    NSLog(@"HighlightVector view start: zoom = %f", _vectorViewZoom);
 
    _vectorView.mapView = _mapView;
    _vectorView.mvc = self;
    [_vectorView setNeedsDisplay];
}

- (void)vectorViewDidComplete:(VectorView *)vectorView
                      pdfData:(NSData *)pdfData
                    reDisplay:(BOOL)reDisplay
{
    //static BOOL first = TRUE;
   _waitForVectorViewRefresh = NO;
    //CRAPI.sharedInstance.mapToolbar.showIndicator = YES;
    if (pdfData)
    {
        [NVSendEmail sendEmailWithSubject:@"PDF from NVMobile"
                                  message:@"The PDF attached to this email was rendered by NVMobile."
                           attachmentData:pdfData
                                 mimeType:@"application/pdf"
                                 fileName:@"testPDF.pdf"
                               controller:self];
        return;
    }
    
    if (vectorView.displayID != CRAPI.sharedInstance.keepProcessing)
        vectorViews[vectorView.ivv] = nil;
    
    else
    {
        if (!reDisplay)
            vectorView.displayID = -1;
        dispatch_async(dispatch_get_main_queue(),
                   ^{
                       if (_fromLegends)
                       {
                           if (_fromLegends2X)
                           {
                               _fromLegends2X = YES;
                               
                               self.tabBarController.selectedIndex = _fromIndex;
                               self.tabBarController.tabBar.userInteractionEnabled = YES;
                               _fromLegends = _fromLegends2X = NO;
                               return;
                           }
                           
                           _fromLegends2X = YES;
                       }
                       
                       //[_vectorView removeFromSuperview];
                       
                       if (_screenSetting != MapViewScreenSettingPlatView)
                       {
                           //[self.view addSubview:_vectorView];
                           [_vectorView constrainToView:_mapView leading:0.0 trailing:0.0 top:0.0 bottom:0.0];
                           
                           if (!_myLocationMarker.hidden)
                               [self.view bringSubviewToFront:_myLocationMarker];
                           
                           if (!CRAPI.sharedInstance.selectBoundaryFromMapType)
                           {
                               for (NVMarkerInfoButton *nvmibs in self.view.subviews)
                               {
                                   if ([nvmibs isKindOfClass:NVMarkerInfoButton.class])
                                       [self.view bringSubviewToFront:nvmibs];
                               }
                               
                               for (NVPhotoView *nvpvs in _insetPixArray)
                               {
                                   [self.view bringSubviewToFront:nvpvs.overlay];
                                   [self.view bringSubviewToFront:nvpvs];
                               }
                            
                               [self bringMarkersAndInfoWindowsToFront];
                           }
                           
                           if (!_compass.hidden)
                               [self.view bringSubviewToFront:_compass];
                           
                           [_mapToolbar bringToFrontOfView];
                           
                           if (_legendsAreOffMap && [self.view.subviews containsObject:_legendScrollView])
                               [self.view bringSubviewToFront:_legendScrollView];
                           
                           for (NVWebView *nvwv in self.view.subviews)
                           {
                               if ([nvwv isKindOfClass:NVWebView.class])
                                   [self.view bringSubviewToFront:nvwv];
                           }
                           
                           if ([self.view.subviews containsObject:_legendMinimizeButton])
                               [self.view bringSubviewToFront:_legendMinimizeButton];
                           
                           else
                               [self updateLegendPositions];
                           
                           for (GSSiDatePicker *datePicker in self.view.subviews)
                           {
                               if ([datePicker isKindOfClass:GSSiDatePicker.class])
                                   [self.view bringSubviewToFront:datePicker];
                           }
                           
                           for (GSSiNotesView *notesView in self.view.subviews)
                           {
                               if ([notesView isKindOfClass:GSSiNotesView.class])
                                   [self.view bringSubviewToFront:notesView];
                           }
                           
                           for (NVPopoverTableView *nvptv in self.view.subviews)
                           {
                               if ([nvptv isKindOfClass:NVPopoverTableView.class])
                               {
                                   [self.view bringSubviewToFront:nvptv.overlayView];
                                   [self.view bringSubviewToFront:nvptv];
                               }
                           }
                           
                           if ([self.view.subviews containsObject:_popover])
                               [self.view bringSubviewToFront:_popover];
                           
                           if ([self.view.subviews containsObject:_digitizerTargetView])
                               [self.view bringSubviewToFront:_digitizerTargetView];
                           
                           if ([self.view.subviews containsObject:_digitizationToolbar])
                               [self.view bringSubviewToFront:_digitizationToolbar];
                           
                           if ([self.view.subviews containsObject:_legendView])
                               [self.view bringSubviewToFront:_legendView];
                           
                           if ([self.view.subviews containsObject:_nvdv])
                               [self.view bringSubviewToFront:_nvdv];
                           
                           if ([self.view.subviews containsObject:[self.view viewWithTag:99999]])
                               [self.view bringSubviewToFront:[self.view viewWithTag:99999]];
                           
                           if ([self.view.subviews containsObject:[self.view viewWithTag:456456]])
                               [self.view bringSubviewToFront:[self.view viewWithTag:456456]];
                           
                           if (_displayRandomColorAlert)
                           {
                               self.tabBarController.tabBar.userInteractionEnabled = NO;
                               ThemeLegendMapOverlay *tlmo = (ThemeLegendMapOverlay *)[self.view viewWithTag:_currentLegendTag];
                               tlmo.currentColorPalette = _currentColorOption;
                               [tlmo displayRandomColorAlertInView:self.view];
                               _displayRandomColorAlert = NO;
                           }
                           
                           if (ConfigurationControl.sharedInstance.mng)
                               [ConfigurationControl.sharedInstance.mng bringViewsToFront:NO];
                       }
                       
                       if (ConfigurationControl.sharedInstance.currentApp == HCConfigCrimes ||
                           ConfigurationControl.sharedInstance.currentApp == HCConfigCurbRamps ||
                           ConfigurationControl.sharedInstance.currentApp == HCConfigMapleGrove ||
                           ConfigurationControl.sharedInstance.currentApp == HCConfigFromSpreadsheet ||
                           ConfigurationControl.sharedInstance.currentApp == HCConfigMetroProp)
                       {
                           if (!_legendsAreOffMap)
                           {
                               for (ThemeLegendMapOverlay *tlmos in self.view.subviews)
                               {
                                   if ([tlmos isKindOfClass:ThemeLegendMapOverlay.class])
                                       [self.view bringSubviewToFront:tlmos];
                               }
                           }
                       }
                       
                       if (!_tableView.hidden)
                           [self.view bringSubviewToFront:_tableView];
                       
                       for (NVAlertView *alert in self.view.subviews)
                       {
                           if ([alert isKindOfClass:NVAlertView.class])
                           {
                               [self.view bringSubviewToFront:alert.overlayView];
                               [self.view bringSubviewToFront:alert];
                           }
                       }
                       
                       if (_grayscaleMode)
                           [self createGrayscale];
                        [self performSelector:@selector(displayCurrentRoute) withObject:nil afterDelay:0.2];

                       //[self displayCurrentRoute];
                       [self displayTrackRoute];
                       [self displayScalebar];
                       [self displayWeatherData];
                       CRAPI.sharedInstance.mapToolbar.showIndicator = NO;
                       if (reDisplay)
                       {
                           UIGraphicsBeginImageContext(self.view.frame.size);
                           _mapToolbar.hidden = YES;
                           [self.view.layer renderInContext:UIGraphicsGetCurrentContext()];
                           _vectorView.backgroundImage = UIGraphicsGetImageFromCurrentImageContext();
                           UIGraphicsEndImageContext();
                           _mapToolbar.hidden = NO;

                           _vvpass = 1;
                           _vectorView.pass = 1;
                           _vectorView.mapView = _mapView;
                           _vectorView.mvc = self;
                           [_vectorView setNeedsDisplay];
                           _vvpass = 0;
                       }
                   });
    }
}

- (void)bringMarkersAndInfoWindowsToFront
{
    for (MarkerButton *markers in _markerArray)
        [self.view bringSubviewToFront:markers];
    
    if ([self.view.subviews containsObject:_infoWindow])
        [self.view bringSubviewToFront:_infoWindow];
}

- (void)updateLegendPositions
{
    if (ConfigurationControl.sharedInstance.currentApp == HCConfigCrimes ||
        ConfigurationControl.sharedInstance.currentApp == HCConfigCurbRamps ||
        ConfigurationControl.sharedInstance.currentApp == HCConfigMapleGrove ||
        ConfigurationControl.sharedInstance.currentApp == HCConfigMetroProp ||
        ConfigurationControl.sharedInstance.currentApp == HCConfigFromSpreadsheet)
    {
        NSMutableArray *legends = ConfigurationControl.sharedInstance.legendList;
        
        if ([self legendIsExpanded])
        {
            if (_legendsAreOffMap)
            {
                for (ThemeLegendMapOverlay *tlmos in _legendScrollView.subviews)
                {
                    if ([tlmos isKindOfClass:ThemeLegendMapOverlay.class])
                    {
                        if (tlmos.isExpanded)
                        {
                            [self.view bringSubviewToFront:_legendScrollView];
                            [_legendScrollView bringSubviewToFront:tlmos];
                            tlmos.legend = legends[(tlmos.tag / 111111) - 1];
                            [tlmos.tableView reloadData];
                        }
                    }
                }
            }
            
            else for (ThemeLegendMapOverlay *tlmos in self.view.subviews)
            {
                if ([tlmos isKindOfClass:ThemeLegendMapOverlay.class])
                {
                    if (tlmos.isExpanded)
                    {
                        [self.view bringSubviewToFront:tlmos];
                        tlmos.legend = legends[(tlmos.tag / 111111) - 1];
                        [tlmos.tableView reloadData];
                    }
                }
            }
            
            if (_displayRandomColorAlert)
            {
                self.tabBarController.tabBar.userInteractionEnabled = NO;
                ThemeLegendMapOverlay *tlmo = [self.view viewWithTag:_currentLegendTag];
                [tlmo displayRandomColorAlertInView:self.view];
                _displayRandomColorAlert = NO;
            }
            
            return;
        }
        
        CGFloat tlmoWidth = (ThemeLegendMapOverlay.width + 2.0);
        CGFloat rowHeight = ThemeLegendMapOverlay.rowHeight;
        
        CGFloat landscapeWidth = MAX(UIScreen.mainScreen.bounds.size.width, UIScreen.mainScreen.bounds.size.height);
        CGFloat portraitWidth = MIN(UIScreen.mainScreen.bounds.size.width, UIScreen.mainScreen.bounds.size.height);
        CGFloat xOriginLandscape = (landscapeWidth - tlmoWidth);
        CGFloat xOriginPortrait = (portraitWidth - tlmoWidth);
        
        CGFloat statusBarHeight = [self statusBarHeight:UIApplication.sharedApplication.statusBarOrientation];
        CGFloat yFactor = 2.0;
        
        CGFloat yOriginPortrait = (statusBarHeight + yFactor);
        CGFloat yOriginLandscape = yOriginPortrait;
        NSUInteger portraitColumnCount = 1, landscapeColumnCount = 1;
        UIView *inView = self.view;
        BOOL legendExistsToDraw = NO, legendsAreAlreadyDrawn = NO;
        
        for (ThemeLegend *tls in legends)
        {
            if (tls.drawOnMap || ConfigurationControl.sharedInstance.currentApp == HCConfigFromSpreadsheet || ConfigurationControl.sharedInstance.currentApp == HCConfigMetroProp)
            {
                legendExistsToDraw = YES;
            }
        }
        
        if (!legendExistsToDraw)
            [self themeLegendWasDraggedOffLeftSide];
        
        if (legendExistsToDraw && !_legendsAreOffMap)
        {
            for (ThemeLegendMapOverlay *tlmos in self.view.subviews)
            {
                if ([tlmos isKindOfClass:ThemeLegendMapOverlay.class])
                    legendsAreAlreadyDrawn = YES;
            }
            
            if (!legendsAreAlreadyDrawn)
            {
                for (ThemeLegendMapOverlay *tlmos in _legendScrollView.subviews)
                {
                    if ([tlmos isKindOfClass:ThemeLegendMapOverlay.class])
                        legendsAreAlreadyDrawn = YES;
                }
                
                if (!legendsAreAlreadyDrawn)
                {
                    [self themeLegendWasDraggedOffRightSide];
                    return;
                }
            }
        }
        
        for (ThemeLegendMapOverlay *tlmos in self.view.subviews)
        {
            if ([tlmos isKindOfClass:ThemeLegendMapOverlay.class])
                [tlmos removeFromSuperview];
        }
        
        for (ThemeLegendMapOverlay *tlmos in _legendScrollView.subviews)
        {
            if ([tlmos isKindOfClass:ThemeLegendMapOverlay.class])
                [tlmos removeFromSuperview];
        }
        
        if (_legendsAreOffMap)
        {
            CGFloat scrollHeight = yOriginPortrait = yOriginLandscape = xOriginPortrait = xOriginLandscape = yFactor;
            inView = _legendScrollView;
            
            for (int i = 0; i < legends.count; i++)
            {
                ThemeLegend *tl = legends[i];
                
                if (tl.drawOnMap)
                {
                    CGFloat legendHeight = (((rowHeight * tl.numCells) + tl.headerHeight) + yFactor);
                    scrollHeight += legendHeight;
                }
            }
            
            _legendScrollView.contentSize = CGSizeMake(_mapViewLegendOffset, scrollHeight);
        }
            
        for (int i = 0; i < legends.count; i++)
        {
            ThemeLegend *tl = legends[i];
            
            if (tl.drawOnMap || (ConfigurationControl.sharedInstance.currentApp == HCConfigFromSpreadsheet ||
                                 ConfigurationControl.sharedInstance.currentApp == HCConfigMetroProp))
            {
                CGFloat legendHeight = ((rowHeight * (tl.numCells + 1)) + yFactor);
                
                if (((yOriginLandscape + legendHeight) > (portraitWidth - 55.0)) && !_legendsAreOffMap)
                {
                    xOriginLandscape = yFactor;
                    
                    if (landscapeColumnCount == 2)
                        xOriginLandscape = _mapViewLegendOffset;
                    
                    yOriginLandscape = (statusBarHeight + yFactor);
                    landscapeColumnCount++;
                }
                
                if (((yOriginPortrait + legendHeight) > (landscapeWidth - 55.0)) && !_legendsAreOffMap)
                {
                    xOriginPortrait = yFactor;
                    
                    if (portraitColumnCount == 2)
                        xOriginPortrait = _mapViewLegendOffset;
                    
                    yOriginPortrait = (statusBarHeight + yFactor);
                    portraitColumnCount++;
                }

                CGPoint mapOrigin = CGPointZero;
                
                if (_legendsAreOffMap)
                {
                    if (UIApplication.sharedApplication.statusBarOrientation == UIDeviceOrientationLandscapeLeft ||
                        UIApplication.sharedApplication.statusBarOrientation == UIDeviceOrientationLandscapeRight)
                    {
                        mapOrigin = CGPointMake(xOriginLandscape, yOriginLandscape);
                        tl.scrollYPosition = yOriginLandscape;
                    }
                    
                    else
                    {
                        mapOrigin = CGPointMake(xOriginPortrait, yOriginPortrait);
                        tl.scrollYPosition = yOriginPortrait;
                    }
                }
                
                else
                {
                    if (!tl.isDraggedLandscape)
                        tl.landscapeMapOrigin = CGPointMake(xOriginLandscape, yOriginLandscape);
                    
                    if (!tl.isDraggedPortrait)
                        tl.portraitMapOrigin = CGPointMake(xOriginPortrait, yOriginPortrait);
                    
                    if (UIApplication.sharedApplication.statusBarOrientation == UIDeviceOrientationLandscapeLeft ||
                        UIApplication.sharedApplication.statusBarOrientation == UIDeviceOrientationLandscapeRight)
                    {
                        mapOrigin = tl.landscapeMapOrigin;
                    }
                    
                    else
                        mapOrigin = tl.portraitMapOrigin;
                    
                    if ((mapOrigin.x < yFactor) || (mapOrigin.y < (yFactor + statusBarHeight)) ||
                        (mapOrigin.x > (inView.frame.size.width - tlmoWidth)) ||
                        (mapOrigin.y > (inView.frame.size.height - legendHeight)))
                        {
                            NSLog(@"Legend (type=%li, origin=%f,%f) was not fully contained in its superview. Its frame was adjusted accordingly.", tl.type, mapOrigin.x, mapOrigin.y);
                            
                            mapOrigin.x = MAX(yFactor, mapOrigin.x);
                            mapOrigin.y = MAX((yFactor + statusBarHeight), mapOrigin.y);
                            
                            mapOrigin.x = MIN((inView.frame.size.width - tlmoWidth),
                                              mapOrigin.x);
                            
                            mapOrigin.y = MIN((inView.frame.size.height - legendHeight),
                                              mapOrigin.y);
                            
                            if (UIApplication.sharedApplication.statusBarOrientation == UIDeviceOrientationLandscapeLeft ||
                                UIApplication.sharedApplication.statusBarOrientation == UIDeviceOrientationLandscapeRight)
                            {
                                tl.landscapeMapOrigin = mapOrigin;
                            }
                            
                            else
                                tl.portraitMapOrigin = mapOrigin;
                        }
                }
                
                ThemeLegendMapOverlay *tlmo = [ThemeLegendMapOverlay drawLegend:tl
                                                                        withTag:((i + 1) * 111111)
                                                                       delegate:self
                                                                         inView:inView
                                                                       atOrigin:mapOrigin
                                                                    hideButtons:NO];
                
                if (tlmo)
                {
                    yOriginPortrait += (tlmo.frame.size.height + yFactor);
                    yOriginLandscape += (tlmo.frame.size.height + yFactor);
                }
            }
        }
    }
}

- (void)themeLegendDidChangeStatus:(BOOL)refreshVectorView
{
    if (refreshVectorView)
        [self vectorViewRefresh];
    
    else
        [self updateLegendPositions];
}

- (void)themeLegendDidWantMinimize
{
    CGFloat statusBarHeight = [self statusBarHeight:UIApplication.sharedApplication.statusBarOrientation];
    CGFloat margin = 8.0;
    
    for (ThemeLegendMapOverlay *tlmos in self.view.subviews)
    {
        if ([tlmos isKindOfClass:ThemeLegendMapOverlay.class])
            tlmos.hidden = YES;
    }
    
    [self.view addSubview:_legendMinimizeButton];
    [_legendMinimizeButton constrainTopToAnchor:self.view.topAnchor constant:(statusBarHeight + margin)];
    [_legendMinimizeButton constrainTrailingToAnchor:self.view.trailingAnchor constant:-margin];
    [_legendMinimizeButton constrainWidthToConstant:_compassSize];
    [_legendMinimizeButton constrainHeightToAnchor:_legendMinimizeButton.widthAnchor];
}

- (void)expandLegends:(UIButton *)button
{
    [_legendMinimizeButton removeFromSuperview];
    
    for (ThemeLegendMapOverlay *tlmos in self.view.subviews)
    {
        if ([tlmos isKindOfClass:ThemeLegendMapOverlay.class])
            tlmos.hidden = NO;
    }
}

- (void)themeLegendWasDraggedOffRightSide
{
    if (!_legendsAreOffMap)
    {
        CGFloat statusBarHeight = [self statusBarHeight:UIApplication.sharedApplication.statusBarOrientation];
        _legendScrollView.alpha = 1.0;
        _vectorView.hidden = _legendsAreOffMap = _mapToolbar.isOffset = YES;
        [self updateLegendPositions];
        [_mapView constrainToView:self.view leading:0.0 trailing:-_mapViewLegendOffset top:statusBarHeight bottom:0.0];
        [_mapToolbar adjustFrameToScrollView];
        [self updateCompassPosition:YES];
        [self vectorViewRefresh];
    }
}

- (void)themeLegendWasDraggedOffLeftSide
{
    if (_legendsAreOffMap)
    {
        CGFloat statusBarHeight = [self statusBarHeight:UIApplication.sharedApplication.statusBarOrientation];
        _vectorView.hidden = YES;
        _legendScrollView.alpha = 0.0;
        _legendsAreOffMap = _mapToolbar.isOffset = NO;
        [self updateLegendPositions];
        [_mapView constrainToView:self.view leading:0.0 trailing:0.0 top:statusBarHeight bottom:0.0];
        [_mapToolbar adjustFrameToScrollView];
        [self updateCompassPosition:YES];
        [self vectorViewRefresh];
    }
}

- (void)updateRightArrowVisibility:(BOOL)hidden
{
    for (ThemeLegendMapOverlay *tlmos in self.view.subviews)
    {
        if ([tlmos isKindOfClass:ThemeLegendMapOverlay.class])
            tlmos.moveRightView.hidden = hidden;
    }
}

- (void)updateLeftArrowVisibility:(BOOL)hidden
{
    for (ThemeLegendMapOverlay *tlmos in _legendScrollView.subviews)
    {
        if ([tlmos isKindOfClass:ThemeLegendMapOverlay.class])
            tlmos.moveLeftView.hidden = hidden;
    }
}

- (void)updateMinimizeVisibility:(BOOL)hidden
{
    for (ThemeLegendMapOverlay *tlmos in self.view.subviews)
    {
        if ([tlmos isKindOfClass:ThemeLegendMapOverlay.class])
            tlmos.minimizeView.hidden = hidden;
    }
}

- (BOOL)themeLegendIsOffMap
{
    return _legendsAreOffMap;
}

- (void)randomColorsSelectedWithOption:(NVColorOption)option
                        forThemeLegend:(ThemeLegendMapOverlay *)legend
{
    _displayRandomColorAlert = YES;
    _currentColorOption = option;
    _currentLegendTag = legend.tag;
    [self themeLegendDidChangeStatus:!legend.isExpanded];
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
        [_tableView deselectRowAtIndexPath:_tableView.indexPathForSelectedRow animated:YES];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (UIView *)tableView:(UITableView *)tableView
viewForHeaderInSection:(NSInteger)section
{
    CGFloat height = [self getHeaderHeight];
    UILabel *headerLabel = UILabel.new;
    headerLabel.frame = CGRectMake(0.0, 0.0, tableView.frame.size.width, height);
    headerLabel.font = [UIFont boldSystemFontOfSize:MAX((_screenSize / 21.0), 21.0)];
    headerLabel.textColor = UIColor.yellowColor;
    headerLabel.backgroundColor = _tableViewBackgroundColor;
    headerLabel.textAlignment = NSTextAlignmentCenter;
    headerLabel.adjustsFontSizeToFitWidth = YES;
    headerLabel.userInteractionEnabled = YES;
    
    switch (_tableViewSetting)
    {
        case PropertyTableViewSettingOptions:
            headerLabel.numberOfLines = 1;
            headerLabel.text = [NSString stringWithFormat:@"Options for %@", _infoWindow.optionsTitle];
            break;
        case PropertyTableViewSettingPropertyReport:{
            headerLabel.numberOfLines = 2;
            headerLabel.text = [NSString stringWithFormat:@"Property Report for\n%@",_propYearAndQuarter];
            
            CGFloat origin = (height * 0.15);
            height *= 0.7;
            TableViewCellButton *clearMarker = [TableViewCellButton buttonWithType:UIButtonTypeCustom];
            clearMarker.frame = CGRectMake(origin, origin, height, height);
            clearMarker.backgroundColor = UIColor.whiteColor;
            clearMarker.imageEdgeInsets = UIEdgeInsetsMake(6.0, 6.0, 6.0, 6.0);
            clearMarker.layer.cornerRadius = 8.0;
            
            [clearMarker setImage:[UIImage imageWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"clearMarkers" ofType:@"png"]]
                         forState:UIControlStateNormal];
            
            [clearMarker addTarget:self
                            action:@selector(prepareToRemoveMarker)
                  forControlEvents:UIControlEventTouchUpInside];
            
            [headerLabel addSubview:clearMarker];
            break;}
        default:break;
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
        default:break;
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
        NSString *textLabelText = textAfterFirstColon(_propertyReport[indexPath.row]);
        
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
            cell.textLabel.text = removeOpeningSpaces(textAfterFirstColon(_propertyReport[indexPath.row]));
            cell.textLabel.textAlignment = NSTextAlignmentLeft;
            cell.indentationWidth = (cell.frame.size.width * 0.3);
            
            UILabel *rowHeader = [[UILabel alloc] initWithFrame:CGRectMake(4.0, 0.0,
                                                                           (cell.indentationWidth - 4.0),
                                                                           cell.frame.size.height)];
            
            rowHeader.text = textBeforeColon(_propertyReport[indexPath.row]);
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
        default:break;
    }
    
    if ([cell.textLabel.text isEqualToString:@""])
    {
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        CGFloat size = min(64.0, cell.contentView.frame.size.height);
        CGFloat margin = (size / 3.0);
        CGFloat xOrigin = margin;
        
        if (indexPath.row == 0)
        {
            TableViewCellButton *clearMarker = [TableViewCellButton buttonWithType:UIButtonTypeCustom];
            clearMarker.frame = CGRectMake(xOrigin, 0.0, size, size);
            clearMarker.center = CGPointMake(clearMarker.center.x, (cell.contentView.frame.size.height / 2.0));
            clearMarker.backgroundColor = UIColor.whiteColor;
            clearMarker.imageEdgeInsets = UIEdgeInsetsMake(4.0, 4.0, 4.0, 4.0);
            clearMarker.layer.cornerRadius = 4.0;
            
            [clearMarker setImage:[UIImage imageWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"clearMarkers" ofType:@"png"]]
                         forState:UIControlStateNormal];
            
            [clearMarker addTarget:self
                            action:@selector(prepareToRemoveMarker)
                  forControlEvents:UIControlEventTouchUpInside];
            
            [cell.contentView addSubview:clearMarker];
            xOrigin += (margin * 4.0);
            NSArray *items = nil;
            
            if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
                items = @[@"Mark", @"Mark+Opt", @"Opt"];
            
            else
                items = @[@"Marker Only", @"Marker+Options", @"Options Only"];
            
            UISegmentedControl *markerOptions = [[UISegmentedControl alloc] initWithItems:items];
            markerOptions.frame = CGRectMake(xOrigin, 0.0, (cell.contentView.frame.size.width - xOrigin - margin), size);
            markerOptions.center = CGPointMake(markerOptions.center.x, (cell.contentView.frame.size.height / 2.0));
            markerOptions.tintColor = UIColor.whiteColor;
            markerOptions.selectedSegmentIndex = _markerStyle;
            UIFont *font = [UIFont boldSystemFontOfSize:14.0];
            NSDictionary *attributes = [NSDictionary dictionaryWithObject:font forKey:NSFontAttributeName];
            [markerOptions setTitleTextAttributes:attributes forState:UIControlStateNormal];
            [markerOptions addTarget:self action:@selector(markerOptionsTapped:) forControlEvents:UIControlEventValueChanged];
            [cell.contentView addSubview:markerOptions];
        }
    }
    
    else
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    
    return cell;
}

- (void)markerOptionsTapped:(UISegmentedControl *)segControl
{
    _markerStyle = segControl.selectedSegmentIndex;
    [UserDefaults.defaults saveNSInteger:_markerStyle forKey:@"MarkerStyle"];
}

- (void)prepareToRemoveMarker
{
    [self dismissTableView];
    [self performSelector:@selector(removeMarker) withObject:nil  afterDelay:0.3];
}

- (NSIndexPath *)tableView:(UITableView *)tableView
  willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if([tableView cellForRowAtIndexPath:indexPath].selectionStyle == UITableViewCellSelectionStyleNone)
        return nil;
    
    return indexPath;
}

- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    _infoWindow.defaultEnabled = YES;
    NSString *text = [tableView cellForRowAtIndexPath:indexPath].textLabel.text;
    
    if ([text isEqualToString:@"Property Report"])
    {
        [UserDefaults.defaults saveNSInteger:PropertyTableViewSettingPropertyReport forKey:@"PIDOption"];
        [self showPropReport];
        return;
    }
    
    else if ([text isEqualToString:@"Property History"])
    {
        [UserDefaults.defaults saveNSInteger:PropertyTableViewSettingPropertyHistory forKey:@"PIDOption"];
        [self showPropHistory];
    }
    
    else if ([text isEqualToString:@"Sales History (Block)"])
    {
        [UserDefaults.defaults saveNSInteger:PropertyTableViewSettingSalesHistoryBlock forKey:@"PIDOption"];
        [self showSalesHistory:@"BLOCK"];
    }
    else if ([text isEqualToString:@"Sales History (Block Group)"])
    {
        [UserDefaults.defaults saveNSInteger:PropertyTableViewSettingSalesHistoryBlockGroup forKey:@"PIDOption"];
        [self showSalesHistory:@"BLOCKGROUP"];
    }

    else if ([text isEqualToString:@"Zillow Property Record"])
    {
        [UserDefaults.defaults saveNSInteger:PropertyTableViewSettingZillow forKey:@"PIDOption"];
        [self showZillow];
    }
    
    else if ([text isEqualToString:@"County Property Record"])
    {
        [UserDefaults.defaults saveNSInteger:PropertyTableViewSettingCountyRecord forKey:@"PIDOption"];
        [self showCountyRecord];
    }
    
    else if ([text isEqualToString:@"Display Google Street View"])
    {
        switch (_infoWindow.marker.type)
        {
            case MarkerInfoWindowTypePID:
                [UserDefaults.defaults saveNSInteger:PropertyTableViewSettingStreetView forKey:@"PIDOption"];
                break;
            case MarkerInfoWindowTypeCrime:
                [UserDefaults.defaults saveNSInteger:CrimePointSettingDisplayStreetView forKey:@"CrimePointOption"];
                break;
            default:break;
        }
        
        [self showStreetView];
    }
    
    else if ([text isEqualToString:@"Display Bing Streetside"])
    {
        switch (_infoWindow.marker.type)
        {
            case MarkerInfoWindowTypePID:
                [UserDefaults.defaults saveNSInteger:PropertyTableViewSettingStreetside forKey:@"PIDOption"];
                break;
            case MarkerInfoWindowTypeCrime:
                [UserDefaults.defaults saveNSInteger:CrimePointSettingDisplayStreetside forKey:@"CrimePointOption"];
                break;
            default:break;
        }
        
        [self showStreetside];
    }
    
    else if ([text isEqualToString:@"Zoom to Census Area"])
    {
        [UserDefaults.defaults saveNSInteger:PropertyTableViewSettingCensusArea forKey:@"PIDOption"];
        [self showCensusArea];
    }
    
    else if ([text isEqualToString:@"Color Parcels"])
    {
        [UserDefaults.defaults saveNSInteger:PropertyTableViewSettingColorParcels forKey:@"PIDOption"];
        [self selectParcelColor];
    }
    
    else if ([text isEqualToString:@"Parcel Text"])
    {
        [UserDefaults.defaults saveNSInteger:PropertyTableViewSettingParcelText forKey:@"PIDOption"];
        [self selectParcelText];
    }
    
    else if ([text isEqualToString:@"Set as Target Parcel"])
    {
        [UserDefaults.defaults saveNSInteger:PropertyTableViewSettingSetTargetParcel forKey:@"PIDOption"];
        [self setTargetParcel];
    }
    
    else if ([text isEqualToString:@"Add to Property List"])
    {
        [UserDefaults.defaults saveNSInteger:PropertyTableViewSettingPropList forKey:@"PIDOption"];
        [self addToProplist];
    }
    
    else if ([text isEqualToString:@"Add to Destinations"])
    {
        [UserDefaults.defaults saveNSInteger:PropertyTableViewSettingDestinations forKey:@"PIDOption"];
        [self addToDestinations];
    }
    
    else if ([text isEqualToString:@"Route From Current Location"])
    {
        [UserDefaults.defaults saveNSInteger:PropertyTableViewSettingRoute forKey:@"PIDOption"];
        [self traceRouteFromCurrentLocation];
    }
    
    else if ([text isEqualToString:@"Trip Time Profile"])
    {
        [self tripTimeProfile];
    }
    
    else if ([text isEqualToString:@"Display Timeline"])
    {
        [UserDefaults.defaults saveNSInteger:BASettingDisplayTimeline forKey:@"BAOption"];
        [self displayTimeline];
    }
    
    else if ([text isEqualToString:@"Show Text"])
    {
        [UserDefaults.defaults saveNSInteger:BASettingShowText forKey:@"BAOption"];
        [self showText];
    }
    
    else if ([text isEqualToString:@"Add to New Crime List"])
    {
        switch (_infoWindow.marker.type)
        {
            case MarkerInfoWindowTypeCrime:
                [UserDefaults.defaults saveNSInteger:CrimePointSettingAddToNewList forKey:@"CrimePointOption"];
                [self addToCrimeList:YES];
                break;
            case MarkerInfoWindowTypeBA:{
                [UserDefaults.defaults saveNSInteger:BASettingAddToNewList forKey:@"BAOption"];
                NSArray *crimes = [PointInAreas.new getAreaPointRefs:_selectedBA];
                [self addToCrimeList:YES fromList:crimes];
                break;}
            default:break;
        }
    }
    
    else if ([text isEqualToString:@"Perform 3D Route Flyover"])
    {
        [SharedDefaults.defaults saveNSInteger:MarkerInfoWindowTypeStormSewer forKey:@"FlyOverType"];
        GMSPath *path = _polyline.path;
        int numPoints = (int)path.count;
        LPDPOINT llpoints = malloc(numPoints * sizeof(DPOINT) + 4);
        
        for (int i = 0; i < numPoints; i++)
        {
            CLLocationCoordinate2D coord = [path coordinateAtIndex:i];
            DPOINT point = {0};
            point.x = coord.longitude;
            point.y = coord.latitude;
            llpoints[i] = point;
        }
        
        if (path.count)
        {
            const char *filePath = [NSString stringWithFormat:@"%@/pipetrace_polydata.bin", UserDefaults.defaults.sharedFilePath].UTF8String;
            FILE *tracePolyFile = fopenGSSi(filePath, "wb");
            
            if (!tracePolyFile)
            {
                NVAlertView *alert = [NVAlertView showLargeAlertViewinView:self.view
                                                                  delegate:self
                                                                     title:@"Polyline Data File Write ERROR"
                                                           buttonTextArray:@[@"OK"]
                                                          destructiveIndex:0];
                
                alert.identifier = @"PolylineDataFileWriteError";
            }
            
            else
            {
                fwrite(&numPoints, sizeof(int), 1, tracePolyFile);
                fwrite(llpoints, sizeof(DPOINT), numPoints, tracePolyFile);
                fcloseGSSi(tracePolyFile);
                [self perform3DFlyAround];
            }
        }
        
        free (llpoints);
    }
    
    else if ([text isEqualToString:@"Perform 3D Fly Around"])
    {
        const char *filePath = [NSString stringWithFormat:@"%@/flyaround_polydata.bin",
                                UserDefaults.defaults.sharedFilePath].UTF8String;
        
        if (_infoWindow.marker.type == MarkerInfoWindowTypeCrime)
        {
            [SharedDefaults.defaults saveNSInteger:MarkerInfoWindowTypeCrime forKey:@"FlyOverType"];
            CLLocationCoordinate2D centerCoord = _selectedPIDCoords;
            int symbol = _infoWindow.marker.symbol;
            FILE *pidPolyFile = fopenGSSi(filePath, "wb");
            
            if (!pidPolyFile)
            {
                NVAlertView *alert = [NVAlertView showLargeAlertViewinView:self.view
                                                                  delegate:self
                                                                     title:@"Crime Point File Write ERROR"
                                                           buttonTextArray:@[@"OK"]
                                                          destructiveIndex:0];
                
                alert.identifier = @"PolygonDataFileWriteError";
            }
            
            else
            {
                fwrite(&centerCoord, sizeof(CLLocationCoordinate2D), 1, pidPolyFile);
                fwrite(&symbol, sizeof(int), 1, pidPolyFile);
                fcloseGSSi(pidPolyFile);
                [self perform3DFlyAround];
            }
        }
        
        else
        {
            [SharedDefaults.defaults saveNSInteger:MarkerInfoWindowTypePID forKey:@"FlyOverType"];
            int numPoints = 0, numLoops = 0, *polyPartLen = 0;
            CLLocationCoordinate2D centerCoord = _selectedPIDCoords;
            MNMXCORD bounds = {0};
            LPDPOINT llpoints = {0};
            
            if (_infoWindow.marker.type == MarkerInfoWindowTypePID)
            {
                PropertyData *propData = [[PropertyData alloc] init];
                _propYearAndQuarter = propData.yearAndQuarter;
                bounds = [propData getBoundsForPID:_selectedPID];
            
                llpoints = [propData getParcelPolygonPointsForPID:_selectedPID
                                                        numPoints:&numPoints
                                                         numLoops:&numLoops
                                                      polyPartLen:&polyPartLen];
            }
            
            else if (_infoWindow.marker.type == MarkerInfoWindowTypeCensusBoundary)
            {
                NSString * areaType=_selectedCensusBoundaryType;
                BoundaryData *boundaryData = [[BoundaryData alloc] init];
                bounds = [boundaryData getBoundsForBoundaryType:areaType
                                                          refno:_selectedCensusBoundaryRefno];
                
                llpoints = [boundaryData getBoundaryPolygonPointsForType:areaType
                                                                   refno:_selectedCensusBoundaryRefno
                                                               numPoints:&numPoints
                                                                numLoops:&numLoops
                                                             polyPartLen:&polyPartLen];
            }
            
            FILE *pidPolyFile = fopenGSSi(filePath, "wb");
            
            if (!pidPolyFile)
            {
                NVAlertView *alert = [NVAlertView showLargeAlertViewinView:self.view
                                                                  delegate:self
                                                                     title:@"Polygon Data File Write ERROR"
                                                           buttonTextArray:@[@"OK"]
                                                          destructiveIndex:0];
                
                alert.identifier = @"PolygonDataFileWriteError";
            }
            
            else
            {
                fwrite(&centerCoord, sizeof(CLLocationCoordinate2D), 1, pidPolyFile);
                fwrite(&numPoints, sizeof(int), 1, pidPolyFile);
                fwrite(&numLoops, sizeof(int), 1, pidPolyFile);
                fwrite(&bounds, sizeof(MNMXCORD), 1, pidPolyFile);
                fwrite(llpoints, sizeof(DPOINT), numPoints, pidPolyFile);
                fcloseGSSi(pidPolyFile);
                [self perform3DFlyAround];
            }
            
            free (llpoints);
        }
    }
    
    else if ([[text substringToIndex:min(text.length,19)] isEqualToString:@"Display Plat"])
    {
        _splitPlatView = NO;
        [self performSelector:@selector(loadPlat) withObject:nil afterDelay:0.3];
    }
    
    else if ([[text substringToIndex:min(text.length,33)] isEqualToString:@"Display Split Screen Profile to 1"])
    {
        _splitPlatView = YES;
        _splitPlatDirection = 0;
        [self performSelector:@selector(loadPlat) withObject:nil afterDelay:0.3];
    }
    
    else if ([[text substringToIndex:min(text.length,33)] isEqualToString:@"Display Split Screen Profile to 2"])
    {
        _splitPlatView = YES;
        _splitPlatDirection = 1;
        [self performSelector:@selector(loadPlat) withObject:nil afterDelay:0.3];
    }
    
    else if ([text isEqualToString:@"Display Pipe Attributes"])
    {
        [UserDefaults.defaults saveNSInteger:SewerPipeSettingAttributes forKey:@"SewerOption"];
        [self showPipeAttributes];
    }
    
    else if ([text isEqualToString:@"Trace Pipe Upstream"])
    {
        [UserDefaults.defaults saveNSInteger:SewerPipeSettingTraceUp forKey:@"SewerOption"];
        [self performSelector:@selector(showPipeTraceUpstream) withObject:nil afterDelay:0.3];
    }
    
    else if ([text isEqualToString:@"Trace Pipe Downstream"])
    {
        [UserDefaults.defaults saveNSInteger:SewerPipeSettingTraceDown forKey:@"SewerOption"];
        [self performSelector:@selector(showPipeTraceDownstream) withObject:nil afterDelay:0.3];
    }
    
    else if ([text isEqualToString:@"Perform Downstream\n3D Fly Over"])
    {
        [SharedDefaults.defaults saveNSInteger:MarkerInfoWindowTypeStormSewer forKey:@"FlyOverType"];
        [self performSelector:@selector(performDownstreamFlyOver) withObject:nil afterDelay:0.3];
    }
    
    else if ([text isEqualToString:@"Remove Pipe Trace"])
    {
        [self performSelector:@selector(removePipeTrace) withObject:nil afterDelay:0.3];
    }
    
    else if ([text isEqualToString:@"Update Cleaning Date"])
    {
        [UserDefaults.defaults saveNSInteger:SewerPipeSettingUpdateCleanDate forKey:@"SewerOption"];
        [self updateCleaningDate];
    }
    
    else if ([text isEqualToString:@"Update Inspection Notes"])
    {
        [UserDefaults.defaults saveNSInteger:SewerPipeSettingUpdateNotes forKey:@"SewerOption"];
        [self updateInspectionNotes];
    }
    
    else if ([text isEqualToString:@"Snap to Node"])
    {
        [UserDefaults.defaults saveNSInteger:CustomSettingSnapToNode forKey:@"CustomOption"];
        [self snapToNode];
    }
    
    else if ([text isEqualToString:@"Snap to Line"])
    {
        [UserDefaults.defaults saveNSInteger:CustomSettingSnapToLine forKey:@"CustomOption"];
        [self snapToLine];
    }
    
    else if ([text isEqualToString:@"Move Wall Point"])
    {
        [UserDefaults.defaults saveNSInteger:AlleyWallSettingMoveWallPoint forKey:@"AlleyWallOption"];
        _digitizationMode = DigitizationModeAlleyWallMove;
        [self performSelector:@selector(movePoint) withObject:nil afterDelay:0.3];
    }
    
    else if ([text isEqualToString:@"Delete Wall Point"])
    {
        [UserDefaults.defaults saveNSInteger:AlleyWallSettingDeleteWallPoint forKey:@"AlleyWallOption"];
        [self deleteWallPoint];
    }
    
    else if ([text isEqualToString:@"Edit Wall Attributes"])
    {
        [UserDefaults.defaults saveNSInteger:AlleyWallSettingEditWallAttributes forKey:@"AlleyWallOption"];
        [self editWallAttributes];
    }
    
    else if ([text isEqualToString:@"View Wall Photos"])
    {
        [UserDefaults.defaults saveNSInteger:AlleyWallSettingViewWallPhotos forKey:@"AlleyWallOption"];
        [self viewWallPhotos];
    }
    
    else if ([text isEqualToString:@"View Inset Wall Photos"])
    {
        [UserDefaults.defaults saveNSInteger:AlleyWallSettingViewInsetWallPhotos forKey:@"AlleyWallOption"];
        [self performSelector:@selector(viewInsetWallPhotos) withObject:nil afterDelay:0.3];
    }
    
    else if ([text isEqualToString:@"Toggle Alley Line\nCompletion Status"])
    {
        [UserDefaults.defaults saveNSInteger:AlleyWallSettingEditWallAttributes forKey:@"AlleyLineOption"];
        [self performSelector:@selector(toggleCompletionStatus) withObject:nil afterDelay:0.3];
    }
    
    else if ([text isEqualToString:@"Alley Centerline Status"])
    {
        _alleyStatusSetting = AlleyStatusSettingCenterline;
        [self performSelector:@selector(alleyStatus) withObject:nil afterDelay:0.3];
    }
    
    else if ([text isEqualToString:@"Alley Wall Status"])
    {
        _alleyStatusSetting = AlleyStatusSettingWall;
        [self performSelector:@selector(alleyStatus) withObject:nil afterDelay:0.3];
    }
    
    else if ([text isEqualToString:@"Edit Intersection Attributes"])
    {
        [self editIntersectionAttributes];
    }
    
    else if ([text isEqualToString:@"Edit Intersection Status"])
    {
        [self editIntersectionStatus];
    }
    
    else if ([text isEqualToString:@"Display Report"])
    {
        [UserDefaults.defaults saveNSInteger:CrimePointSettingDisplayReport forKey:@"CrimePointOption"];
        [self displayCrimeReport];
    }
    
    else if ([text isEqualToString:@"Add to Current Crime List"])
    {
        [UserDefaults.defaults saveNSInteger:CrimePointSettingAddToCurrentList forKey:@"CrimePointOption"];
        [self addToCrimeList:NO];
    }
    
    else if ([text isEqualToString:@"Add All to Current Crime List"])
    {
        [UserDefaults.defaults saveNSInteger:CrimePointSettingAddAllToCurrentList forKey:@"CrimePointOption"];
        [self addToCrimeList:NO fromList:DispersePoint.getDispersedControlNum];
    }
    
    else if ([text isEqualToString:@"Add All to New Crime List"])
    {
        [UserDefaults.defaults saveNSInteger:CrimePointSettingAddAllToNewList forKey:@"CrimePointOption"];
        [self addToCrimeList:YES fromList:DispersePoint.getDispersedControlNum];
    }
    
    else if ([text isEqualToString:@"Delete from Current Crime List"])
    {
        [UserDefaults.defaults saveNSInteger:CrimePointSettingDefault forKey:@"CrimePointOption"];
        _infoWindow.defaultEnabled = NO;
        [self removeIncidentFromCrimeList];
    }
    
    else if ([text isEqualToString:@"Display Census Data Chart"])
    {
        [self displayCensusDataChart];
    }
    
    else if ([text isEqualToString:@"Move Sidewalk Point"])
    {
        _digitizationMode = DigitizationModeSidewalkPointMove;
        [self performSelector:@selector(movePoint) withObject:nil afterDelay:0.3];
    }
    
    [self deselectTableViewRow];
    [self dismissTableView];
}

- (void)showText
{
    AreaText *at = [CRAPI.sharedInstance areaTextForRefno:(int)_selectedBARefNo];
    _popover.progressView.hidden = YES;
    _popover.progressLabel.hidden = YES;
    _popover.delegate = self;
    _popover.hideAtCancel = NO;
    [_popover showAfter:0.5 withTitle:[NSString stringWithFormat:@"%@\n%@",at.areaID,at.text]];
    [self.view bringSubviewToFront:_popover];
}

- (MGVPlatData *)loadMGVData:(NSString *)line
{
    char imageFileName[64];
    
    NSArray * values = [line componentsSeparatedByString:@"\t"];
    if (values.count < 8)
        return 0;
    MGVPlatData *rtn = MGVPlatData.new;
    rtn.imageWidth = [values[6] floatValue];
    rtn.imageHeight = [values[7] floatValue];
    strcpy (imageFileName,[values[1] UTF8String]);
    LPSTR cDash = strrchr (imageFileName,'-');
    *cDash++ = 0;
    NSString * imageFile = [NSString stringWithUTF8String:imageFileName];
    rtn.pdfFile =[imageFile stringByAppendingPathExtension:@"pdf"];
    rtn.page = atoi (cDash);
    DPOINT pt;
    pt.x = [values[2] floatValue]*rtn.imageWidth;
    pt.y = (1.0 - [values[3] floatValue])*rtn.imageHeight;
    rtn.ptUpper = pt;
    pt.x = [values[4] floatValue]*rtn.imageWidth;
    pt.y = (1.0 - [values[5] floatValue])*rtn.imageHeight;
    rtn.ptLower = pt;
    rtn.scaleLower = 2;
    rtn.scaleUpper = 3;
    return rtn;
}

DPOINT PercentPoint (DPOINT p,double w,double h)
{
    DPOINT rtn = p;
    rtn.x /= w;
    rtn.y /= h;
    return rtn;
}

-(MGVPlatData*) getMGVPlatDataByViewport:(int)upperOrLower
                              coordinate:(DPOINT)point
                                    file:(NSString*)file
                                 andPage:(int)page
{
    MGVPlatData *mgvdat = MGVPlatData.new;
    
    return mgvdat;
}

- (NSArray *)getMGVPlatDataByRefno:(int)refno
{
    NSMutableArray *array = NSMutableArray.new;
    NSString *imageFile;
    NSString *manholeID;
    NSString *dataFile = [NSBundle.mainBundle pathForResource:@"SANPTID" ofType:@"txt"];
    NSString *fileData = [NSString stringWithContentsOfFile:dataFile encoding:NSUTF8StringEncoding error:nil];
    NSArray *Lines = [fileData componentsSeparatedByString:@"\r\n"];
    
    for (NSString * line in Lines)
    {
        if (refno && refno == [line integerValue])
        {
            NSArray * values = [line componentsSeparatedByString:@"\t"];
            manholeID = values[1];
            imageFile = values[2];
            break;
        }
    }
    
    dataFile = [NSBundle.mainBundle pathForResource:@"upperlower" ofType:@"txt"];
    fileData = [NSString stringWithContentsOfFile:dataFile encoding:NSUTF8StringEncoding error:nil];
    int index = 0;
    Lines = [fileData componentsSeparatedByString:@"\r\n"];
    
    for (NSString * line in Lines)
    {
        NSArray * values = [line componentsSeparatedByString:@"\t"];
        
        if (values.count == 8)
        {
             if ([values[0] isEqualToString:manholeID] &&
                [values[1] characterAtIndex:imageFile.length] == '-' &&
                [[values[1] substringToIndex:imageFile.length] isEqualToString:imageFile])
            {
                MGVPlatData *curData = [self loadMGVData:Lines[index]];
                //if (_splitPlatView)
                {
                    if (index)
                    {
                        MGVPlatData * prevData = [self loadMGVData:Lines[index-1]];
                        double dist = ldistp(prevData.ptUpper,curData.ptUpper);
                        prevData.scaleUpper = curData.imageWidth /(1.5*dist);
                        prevData.scaleLower = prevData.scaleUpper;
                        if (prevData.ptLower.x > curData.ptLower.x)
                            prevData.rotUpper = 90 - LTWOPI (getazd (prevData.ptUpper,curData.ptUpper)-HALFPI) * RADtoDEG;
                        else
                            prevData.rotUpper = 90 - LTWOPI (getazd (curData.ptUpper,prevData.ptUpper)-HALFPI) * RADtoDEG;
                        prevData.ptUpper = PercentPoint (MidPointD (prevData.ptUpper,curData.ptUpper),curData.imageWidth,curData.imageHeight);
                        prevData.ptLower = PercentPoint (MidPointD (prevData.ptLower,curData.ptLower),curData.imageWidth,curData.imageHeight);
                        [array addObject:prevData];
                    }
                    MGVPlatData * nextData = nil;
                    if (index+1 < Lines.count)
                    {
                        nextData = [self loadMGVData:Lines[index+1]];
                        if (nextData)
                        {
                            double dist = ldistp(nextData.ptUpper,curData.ptUpper);
                            nextData.scaleUpper = curData.imageWidth /(1.5*dist);
                            nextData.scaleLower = nextData.scaleUpper;
                            
                            if (nextData.ptLower.x > curData.ptLower.x)
                                nextData.rotUpper = 90 - LTWOPI (getazd (nextData.ptUpper,curData.ptUpper)-HALFPI) * RADtoDEG;
                            
                            else
                                nextData.rotUpper = 90 - LTWOPI(getazd(curData.ptUpper,nextData.ptUpper)-HALFPI) * RADtoDEG;
                            nextData.ptUpper = PercentPoint(MidPointD(nextData.ptUpper,curData.ptUpper),curData.imageWidth,curData.imageHeight);
                            nextData.ptLower = PercentPoint(MidPointD(nextData.ptLower,curData.ptLower),curData.imageWidth,curData.imageHeight);
                            [array addObject:nextData];
                        }
                    }
                }
            }
        }
        
        index++;
    }
    
    return array;
}

- (void)loadPlat
{
    
    NSArray * array = [self getMGVPlatDataByRefno:_selectedMGVSanMH];
    SewerData *sd = [[SewerData alloc] init];
    
    if (array.count > _splitPlatDirection)
    {
        _mgvData = array[_splitPlatDirection];
        
        if (_mgvData)
        {
            NSString *platFile = [NSString stringWithFormat:@"%@_page_%i.jpg",
                                  _mgvData.pdfFile.stringByDeletingPathExtension, _mgvData.page];
            
            [sd loadPlat:platFile
                  ofType:@"pdfToJpg"
            usingPopover:_popover
             andDelegate:self];
        }
    }
    
    else
       NSLog(@"Error in load plat");
}

- (void)displayCrimeReport
{
    NSString *reportText = [CrimeData reportForControlNumber:_selectedCrime];
    NVTextVC *textVC = [[NVTextVC alloc] initWithText:reportText fontSize:16.0];
    [self presentViewController:textVC animated:YES completion:nil];
}

- (void)addToCrimeList:(BOOL)newList
{
    CrimeList *cl = CrimeList.new;
    
    if (newList)
        [CrimeList createNewCrimeList];
    
    [cl addIncidentToCrimeList:(int)_selectedCrime];
}

- (void)removeIncidentFromCrimeList
{
    if ([CrimeList incidentInCurrentCrimeList:(int)_selectedCrime])
    {
        if ([CrimeList removeIncidentInCurrentCrimeList:(int)_selectedCrime])
            [self vectorViewRefresh];
    }
}

- (void)addToCrimeList:(BOOL)newList
              fromList:(NSArray *)cnumArray
{
    CrimeList *cl = CrimeList.new;
    [_popover showAfter:0 withTitle:@"Adding Crimes to List"];
    _popover.progressView.hidden = NO;
    _popover.delegate = self;
    [self.view bringSubviewToFront:_popover];
    [_popover updateProgress:0];
    _continueLoad = YES;
    
    if (newList)
        [CrimeList createNewCrimeList];
    
    dispatch_queue_t addQueue = dispatch_queue_create("addQueue",NULL);
    
    dispatch_async(addQueue,
                   ^{
                       int count = 1;
                       BOOL opened = [cl open];
                       [cl startTransaction];
                       for (NSNumber * num in cnumArray)
                       {
                           if (!_continueLoad)
                               break;
                           [cl addIncidentToCrimeList:(int)num.integerValue];
                           dispatch_async(dispatch_get_main_queue(),
                                          ^{
                                              [_popover updateProgress:(double)count/cnumArray.count];
                                          });
                           count++;
                           
                       }
                       if (_continueLoad)
                           [cl commitTransaction];
                       [cl close:opened];
                       dispatch_async(dispatch_get_main_queue(),
                                      ^{
                                          [_popover hide];
                                      });
                   });
}

- (void)GSSiPopoverViewdidCancel:(GSSiPopoverView *)popoverView
{
    if (_continueLoad)
        _continueLoad = NO;
    else
        [popoverView hide];
    _hideScaleBar = NO;
    [self displayScalebar];
    [self displayWeatherData];
}

- (void)displayCensusDataChart
{
    ChartsViewController *pieChartVC = [ChartsViewController chartViewWithType:ChartsViewTypeCensusDataPie];
    pieChartVC.areaType = _selectedCensusBoundaryType;
    pieChartVC.geoid = _infoWindow.optionsTitle;
    ChartsViewController *lineChartVC = [ChartsViewController chartViewWithType:ChartsViewTypeCensusDataBar];
    lineChartVC.geoid = _infoWindow.optionsTitle;
    lineChartVC.areaType = _selectedCensusBoundaryType;
    NVPager *pager = [NVPager pagerWithViewControllers:@[(lineChartVC), (pieChartVC)]];
    [self presentViewController:pager animated:YES completion:nil];
}

- (void)showPropReport
{
    PropertyData *pd = PropertyData.new;
    _propertyReport = [pd getReport:PDSettingDefault forPID:_selectedPID];
    _propYearAndQuarter = pd.yearAndQuarter;
    _tableViewSetting = PropertyTableViewSettingPropertyReport;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableView.allowsSelection = NO;
    _tableView.delaysContentTouches = YES;
    [_tableView reloadData];
    [_tableView scrollRectToVisible:CGRectMake(0.0, 0.0, 1.0, 1.0) animated:NO];
}

- (void)showPropHistory
{
    ChartsViewController *chartsVC = [ChartsViewController chartViewWithType:ChartsViewTypePropReport];
    chartsVC.propHistoryArray = [PropertyData.new getParcelHistory:_selectedPID];
    [self presentViewController:chartsVC animated:YES completion:nil];
}

- (void)showSalesHistory:(NSString *)type
{
    NSArray *salesData = [PropertyData.new getSalesHistoryForPropMatching:_selectedPID
                                                               inAreaType:type];
    ChartsViewController *chartsVC = [ChartsViewController chartViewWithType:ChartsViewTypeSalesHistory
                                                                     andData:salesData];
    [self presentViewController:chartsVC animated:YES completion:nil];
}

- (void)showZillow
{
    NSString *houseAndUnit, *streetName, *city, *zipcode, *cenblock, *usedesc;
    double totEMV;
    
    PropertyData *pd = PropertyData.new;
    
    if ([pd getAddressForPID:_selectedPID
             houseNumAndUnit:&houseAndUnit
                  streetName:&streetName
                        city:&city
                         zip:&zipcode
                   ownerName:nil taxpayerName:nil
                 censusBlock:&cenblock
       associatedCensusBlock:nil
                     useDesc:&usedesc
                   homestead:nil
                    saleDate:nil saleValue:nil
                   yearBuilt:nil
                      totEMV:&totEMV
                     landEMV:nil bldgEMV:nil totTAX:nil specAss:nil acres:nil])
    {
        houseAndUnit = [houseAndUnit stringByReplacingOccurrencesOfString:@" " withString:@"-"];
        streetName = [streetName stringByReplacingOccurrencesOfString:@" " withString:@"-"];
        city = [city stringByReplacingOccurrencesOfString:@" " withString:@"-"];
        
        NSString *query = [NSString stringWithFormat:@"www.zillow.com/homes/%@-%@-%@-MN_rb/", houseAndUnit, streetName, city];
        NVWebView *nvwv = [NVWebView showWebViewInView:self.view urlString:query];
        nvwv.delegate = self;
        [self clearVectorView];
    }
}

- (void)showCountyRecord
{
    NSString *query = urlSearchStringForPID(_selectedPID);
    
    if ((query) && ![query isEqualToString:@"NONE"])
    {
        NVWebView *nvwv = [NVWebView showWebViewInView:self.view urlString:query];
        nvwv.delegate = self;
        [self clearVectorView];
    }
}

- (void)webViewDidReturn:(NVWebView *)webView
{
    [webView hide:YES];
    self.tabBarController.tabBar.hidden = NO;
    [self vectorViewRefresh];
}

- (void)showStreetView
{
    CLLocationCoordinate2D pointOnStreet = [PropertyData pointOnStreetForPID:_selectedPID
                                                                       speed:nil];
    
    if ([NVPanoramaVC presentPanoramaInController:self
                                          atCoord:pointOnStreet
                                   lookingAtCoord:_selectedPIDCoords
                                         delegate:self])
    {
        _showsPanorama = YES;
    }
}

- (void)panoramaVC:(NVPanoramaVC *)panoramaVC
didReturnWithCoord:(CLLocationCoordinate2D)coordinate
{
    [panoramaVC dismissViewControllerAnimated:YES completion:nil];
    _showsPanorama = NO;
    
}

- (void)showStreetside
{
    CLLocationCoordinate2D pointOnStreet = [PropertyData pointOnStreetForPID:_selectedPID
                                                                       speed:nil];
    
    
    NVStreetSideController *nvssc = [NVStreetSideController presentStreetSideInController:self
                                                                             atCoordinate:pointOnStreet
                                                                      lookingAtCoordinate:_selectedPIDCoords];
#pragma unused(nvssc)
}

- (void)showCensusArea
{
    NSString *title = [NSString stringWithFormat:@"Zoom to Census Area for Parcel %@", _selectedPID];
    
    NVAlertView *alert = [NVAlertView showLargeAlertViewinView:self.view
                                                      delegate:self
                                                         title:title
                                               buttonTextArray:@[@"Cancel", @"Zoom to Block", @"Zoom to BlockGroup", @"Zoom to Tract"]
                                              destructiveIndex:1];
    
    alert.identifier = @"CensusZoomAlert";
}

- (void)selectParcelText
{
    NSString *title = [NSString stringWithFormat:@"Parcel Text Options %@", _selectedPID];
    
    NVAlertView *alert = [NVAlertView showLargeAlertViewinView:self.view
                                                      delegate:self
                                                         title:title
                                               buttonTextArray:@[@"Cancel|0", @"Owner/Total Tax|1", @"Building Number|2",
                                                                 @"Land EMV|3", @"Land EMV per Acre|4", @"Last Sale|5"]
                                              destructiveIndex:1];
    
    alert.identifier = @"ParcelTextAlert";
}

- (void)selectParcelColor
{
    NSString *title = [NSString stringWithFormat:@"Parcel Color Options %@", _selectedPID];
    
    NVAlertView *alert = [NVAlertView showLargeAlertViewinView:self.view
                                                      delegate:self
                                                         title:title
                                               buttonTextArray:@[@"Cancel|0", @"Total EMV|1", @"Building EMV|2",@"Land EMV|3",
                                                                 @"Land EMV per Acre|4", @"Homestead|5", @"Residential/Commercial|6",
                                                                 @"Special Assessment|7", @"Tax Exempt|8", @"Tax Forfeit|9",@"Last Sale|10"]
                                              destructiveIndex:1];
    
    alert.identifier = @"ParcelColorAlert";
}

- (void)setTargetParcel
{
    CRAPI.sharedInstance.currentPID = _selectedPID;
}

- (void)addToDestinations
{
    Destinations *dests = Destinations.new;
    [dests addParcelToDestinations:_selectedPID];
}

- (void)traceRouteFromCurrentLocation
{
    NVAlertView *alert = [NVAlertView showLargeAlertViewinView:self.view
                                                      delegate:self
                                                         title:@"Select Route Type"
                                               buttonTextArray:@[@"Cancel", @"Driving", @"Transit", @"Biking", @"Walking"]
                                              destructiveIndex:1];
    alert.identifier = @"RouteType";
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data
{
    NSString *dataString = [[NSString alloc] initWithData:data
                                                 encoding:NSUTF8StringEncoding];
    
    [_dataString appendString:dataString];
    
    if ([dataString containsString:@"-->"])
    {
        NSString *data = _dataString.copy;
        data = [data stringByReplacingOccurrencesOfString:@">" withString:@">\n"];
        data = [data stringByReplacingOccurrencesOfString:@"</" withString:@"\n</"];
        data = [data stringByReplacingOccurrencesOfString:@" xsi:" withString:@"\nxsi:"];
        data = [data stringByReplacingOccurrencesOfString:@" https:" withString:@"\nhttps:"];
        data = [data stringByReplacingOccurrencesOfString:@" xmlns:" withString:@"\nxmlns:"];
        
        NVTextVC *textVC = [[NVTextVC alloc] initWithText:data fontSize:16.0];
        textVC.clampTextViewToText = YES;
        textVC.zoomingEnabled = NO;
        [self presentViewController:textVC animated:YES completion:nil];
    }
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error
{
    if (error)
        NSLog(@"URLSession ERROR (PID %@):%@", task.taskDescription, error.localizedDescription);
}

- (void)perform3DFlyAround
{
    NSString *flyOverURL = @"NVFlyover://";
    [SharedDefaults.defaults saveString:@"NVMobile:" forKey:@"FlyoverSourceApplication"];
    
    if ([UIApplication.sharedApplication canOpenURL:[NSURL URLWithString:flyOverURL]])
        [UIApplication.sharedApplication openURL:[NSURL URLWithString:flyOverURL]];
    
    else
    {
        flyOverURL = @"https://itunes.apple.com/us/app/newvision-flyover/id1105410284";
        
        if ([UIApplication.sharedApplication canOpenURL:[NSURL URLWithString:flyOverURL]])
            [UIApplication.sharedApplication openURL:[NSURL URLWithString:flyOverURL]];
        
        else
        {
            NVAlertView *alert = [NVAlertView showLargeAlertViewinView:self.view
                                                              delegate:self
                                                                 title:@"NVMobile cannot launch Flyover App"
                                                       buttonTextArray:@[@"OK"]
                                                      destructiveIndex:0];
            
            alert.identifier = @"CannotLaunchFlyoverApp";
        }
    }
}

- (void)tripTimeProfile
{
    if (hasNetwork())
    {
        ChartsViewController *outboundTrip = [ChartsViewController routingChartFromDestination:_selectedPIDCoords
                                                                                 toDestination:CLLocationCoordinate2DMake(44.97916, -93.26602)
                                                                                     startTime:600
                                                                                       endTime:2000
                                                                                          span:TimeArraySpanNextWorkWeek
                                                                                      interval:60
                                                                                         color:NVColor.dodgerBlueColor];
        
        ChartsViewController *returnTrip = [ChartsViewController routingChartFromDestination:outboundTrip.toDestination
                                                                               toDestination:outboundTrip.fromDestination
                                                                                   startTime:outboundTrip.startTime
                                                                                     endTime:outboundTrip.endTime
                                                                                        span:outboundTrip.span
                                                                                    interval:outboundTrip.interval
                                                                                       color:NVColor.mediumSeaGreenColor];
        
        NVPager *pager = [NVPager pagerWithViewControllers:@[(outboundTrip), (returnTrip)]];
        [self presentViewController:pager animated:YES completion:nil];
    }
    
    else
    {
        NVAlertView *alert = [NVAlertView showLargeAlertViewinView:self.view
                                                          delegate:CRAPI.sharedInstance
                                                             title:@"Network Required for Trip Time Profile"
                                                   buttonTextArray:@[@"OK"]
                                                  destructiveIndex:0];
#pragma unused(alert)
    }
}

- (void)displayTimeline
{
    ChartsViewController *chartsVC = [ChartsViewController chartViewWithType:ChartsViewTypeTimeLine];
    chartsVC.timeLineArray = [PointInAreas.new getAreaTimeline:_selectedBA];
    [self presentViewController:chartsVC animated:YES completion:nil];
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

- (void)performDownstreamFlyOver
{
    PipeTrace *pipeTrace = [[PipeTrace alloc] init];
    
    NSString *path = [NSString stringWithFormat:@"%@/pipetrace_polydata.bin", UserDefaults.defaults.sharedFilePath];
    
    if ([pipeTrace outputPipeTrace:path])
        [self perform3DFlyAround];
}

- (void)removePipeTrace
{
    [PipeTrace removeTrace];
    [self vectorViewRefresh];
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

- (void)movePoint
{
    _inDigitizationMode = YES;
    [self hideMarkersAndInfoWindows:YES];
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
    NVAlertView *alert = [NVAlertView showLargeAlertViewinView:self.view
                                                      delegate:self
                                                         title:@"Do You Wish to Delete This Alley Wall?"
                                               buttonTextArray:@[@"YES", @"NO"]
                                              destructiveIndex:1];
    
    alert.identifier = @"DeleteWallAlert";
}

- (void)editWallAttributes
{
    [SharedDefaults.defaults saveString:_selectedAlleyWall forKey:@"AlleyWallEditAttributes"];
    [self performSelector:@selector(launchAlleyWallApp) withObject:nil afterDelay:0.3];
}

- (void)viewWallPhotos
{
    NSString *title = [NSString stringWithFormat:@"Photos for AlleyWall %@", _selectedAlleyWall];
    NVPhoto *photo1 = [NVPhoto photoWithIdentifier:@"Sample Photo 1" key:@"Key1"];
    NVPhoto *photo2 = [NVPhoto photoWithIdentifier:@"Sample Photo 2" key:@"Key2"];
    
    NVPhotoController *nvpc = [NVPhotoController photoControllerWithNVPhotosArray:@[(photo1), (photo2)]
                                                                         delegate:self
                                                                            title:title];
    
    [self presentViewController:nvpc animated:YES completion:nil];
}

- (NSString *)imageForKey:(NSString *)key
{
    NSString *rtn = @"";
    
    if ([key isEqualToString:@"Key1"])
        rtn = [NSBundle.mainBundle pathForResource:@"SampleCurbRamp1" ofType:@"jpg"];
    
    else if ([key isEqualToString:@"Key2"])
        rtn = [NSBundle.mainBundle pathForResource:@"SampleCurbRamp2" ofType:@"jpg"];
    
    return rtn;
}

- (NSString *)getImagePath:(NVPhotoController *)controller
                    forKey:(NSString *)key
{
    return [self imageForKey:key];
}

- (void)viewInsetWallPhotos
{
    NVPhoto *photo1 = [NVPhoto photoWithIdentifier:@"Sample Photo 1" key:@"Key1"];
    NVPhoto *photo2 = [NVPhoto photoWithIdentifier:@"Sample Photo 2" key:@"Key2"];
    
    NVPhotoView *nvpv = [NVPhotoView showPhotoViewWithNVPhotosArray:@[(photo1), (photo2)]
                                                             inView:self.view
                                                    constrainToView:_mapView
                                                           delegate:self
                                                         coordinate:_selectedPIDCoords];
    
    [_insetPixArray addObject:nvpv];
    _infoWindow.marker.photoView = nvpv;
}

- (void)didAddPhotoView
{
    [self bringMarkersAndInfoWindowsToFront];
}

- (void)didDeletePhotoView:(NVPhotoView *)photoView
{
    [_insetPixArray removeObject:photoView];
}

- (NSString *)getInsetImagePath:(NVPhotoView *)photoView
                         forKey:(NSString *)key
{
    return [self imageForKey:key];
}

- (CGPoint)getPointForCoordinate:(CLLocationCoordinate2D)coordinate
{
    return [_mapView.projection pointForCoordinate:coordinate];
}

- (CGFloat)getVerticalOffset
{
    return (MarkerButton.markerButtonSize + MarkerInfoWindow.markerInfoWindowHeight);
}

- (CGFloat)getStatusBarHeight
{
    return [self statusBarHeight:UIApplication.sharedApplication.statusBarOrientation];
}

- (void)toggleCompletionStatus
{
    AlleyWallData *awd = [[AlleyWallData alloc] init];
    int status = [awd getAlleyLineStatus:_selectedAlleyLineRefno];
    [awd setAlleyLineStatus:_selectedAlleyLineRefno to:!status];
    [self vectorViewRefresh];
}

- (void)editIntersectionAttributes
{
    [SharedDefaults.defaults saveInteger:_selectedCRIntPt.intValue forKey:@"DetailCurrentIntersection"];
    [SharedDefaults.defaults saveString:@"NVMobile" forKey:@"SourceApplication"];
    [self launchNVCRISDetail];
}

- (void)editIntersectionStatus
{
    NVAlertView *alert = [NVAlertView showLargeAlertViewinView:self.view
                                                      delegate:self
                                                         title:@"Edit Intersection Status"
                                               buttonTextArray:@[@"Cancel", @"Never Surveyed", @"Original Survey",
                                                                 @"Scheduled for Rebuild", @"Built", @"Resurveyed"]
                                              destructiveIndex:0];
    
    alert.identifier = @"EditIntersectionStatus";
}

- (void)alleyStatus
{
    [UserDefaults.defaults saveNSInteger:(HCConfigAlleyWallStatus + 1)
                                  forKey:@"CurrentConfig"];
    
    [ConfigurationControl.sharedInstance setApp:HCConfigAlleyWallStatus];
    CGPoint origin = CGPointMake(6.0, ([self statusBarHeight:UIApplication.sharedApplication.statusBarOrientation] + 6.0));
    
    if ([self.view.subviews containsObject:_legendView])
        [_legendView reloadView];
    
    else
    {
        _legendView = [NVLegendView showLegendViewAtOrigin:origin
                                                    inView:self.view
                                            containerFrame:_mapView.frame
                                                  delegate:self
                                                selectable:NO
                                                  animated:YES];
    }
}

- (void)huntingLegend
{
    if (_legendView)
    {
        [_legendView hideLegendView:YES];
        _legendView = nil;
    }
    else
    {
        CGPoint origin = CGPointMake(6.0, ([self statusBarHeight:UIApplication.sharedApplication.statusBarOrientation] + 6.0));
        
        if ([self.view.subviews containsObject:_legendView])
            [_legendView reloadView];
        
        else
        {
            _legendView = [NVLegendView showLegendViewAtOrigin:origin
                                                        inView:self.view
                                                containerFrame:_mapView.frame
                                                      delegate:self
                                                    selectable:NO
                                                      animated:YES];
        }
    }
}

- (void)hideDigitizationMode:(UIButton *)button
{
    _inDigitizationMode = NO;
    [self hideDigitizer];
    [self showMarkersAndInfoWindows:YES];
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

- (void)hideMarkersAndInfoWindows:(BOOL)animated
{
    if (animated)
    {
        [UIView animateWithDuration:0.25
                         animations:^{
                             for (MarkerButton *markers in _markerArray)
                                 markers.alpha = 0.0;
                             
                             _infoWindow.alpha = 0.0;
                         }];
    }
    
    else
    {
        for (MarkerButton *markers in _markerArray)
            markers.alpha = 0.0;
        
        _infoWindow.alpha = 0.0;
    }
}

- (void)showMarkersAndInfoWindows:(BOOL)animated
{
    if (animated)
    {
        [UIView animateWithDuration:0.25
                         animations:^{
                             for (MarkerButton *markers in _markerArray)
                                 markers.alpha = 1.0;
                             
                             _infoWindow.alpha = 1.0;
                         }];
    }
    
    else
    {
        for (MarkerButton *markers in _markerArray)
            markers.alpha = 1.0;
        
        _infoWindow.alpha = 1.0;
    }
}

- (void)showDigitizer:(BOOL)moveMarker;
{
    if (moveMarker)
    {
        MarkerButton *marker = _markerArray.lastObject;
        CGPoint markerPosition = [_mapView.projection pointForCoordinate:marker.position];
        _digitizerTargetView.center = CGPointMake(markerPosition.x,
        (markerPosition.y + [self statusBarHeight:UIApplication.sharedApplication.statusBarOrientation]));
    }
    
    [UIView animateWithDuration:0.25
                     animations:^{
                         _digitizerTargetView.alpha = 1.0;
                         _digitizationToolbar.alpha = 1.0;
                     }];
}

- (void)hideDigitizer
{
    [UIView animateWithDuration:0.25
                     animations:^{
                         _digitizerTargetView.alpha = 0.0;
                         _digitizationToolbar.alpha = 0.0;
                     } completion:^(BOOL finished) {
                         _saveDigitizerButton.alpha = 0.0;
                         _cancelDigitizerButton.alpha = 1.0;
                     }];
}

- (void)alertView:(NVAlertView *)alertView
didTapButtonAtIndex:(NSInteger)buttonIndex
{
    [alertView hideLargeAlertView:YES];
    
    if ([alertView.identifier isEqualToString:@"DeleteWallAlert"])
    {
        if (buttonIndex == 0)
        {
            AlleyWallData *awd = [[AlleyWallData alloc] init];
            [awd deleteAlleyWallPoint:_selectedAlleyWallRefno];
            [self removePreviousInfoWindow];
            [self removeMarker];
            [self vectorViewRefresh];
        }
    }
    
    else if ([alertView.identifier isEqualToString:@"CensusZoomAlert"])
    {
        switch (buttonIndex)
        {
            case CensusZoomSettingCancel:
                break;
            case CensusZoomSettingBlock:
                //implement zoom to block here
                break;
            case CensusZoomSettingBlockGroup:
                //implement zoom to block group here
                break;
            case CensusZoomSettingTract:
                //implement zoom to tract here
                break;
            default:break;
        }
    }
    
    else if ([alertView.identifier isEqualToString:@"ParcelTextAlert"])
    {
        switch (buttonIndex)
        {
            case ParcelTextSettingCancel:
                break;
            case ParcelTextSettingOwnerTax:
            case ParcelTextSettingBuildingNum:
            case ParcelTextSettingEMVLand:
            case ParcelTextSettingEMVLandPerAcre:
            case ParcelTextSettingLastSale:
                CRAPI.sharedInstance.parcelTextOption = (int)buttonIndex;
                [self vectorViewRefresh];
            default:break;
        }
    }
    
    else if ([alertView.identifier isEqualToString:@"ParcelColorAlert"])
    {
        switch (buttonIndex)
        {
            case ParcelColorSettingCancel:
                CRAPI.sharedInstance.parcelColorOption = 0;
                CRAPI.sharedInstance.parcelShadingOption = 0;
                break;
            case ParcelColorSettingTotEMV:
            case ParcelColorSettingLandEMV:
            case ParcelColorSettingLandEMVPerAcre:
            case ParcelColorSettingBuildingEMV:
                CRAPI.sharedInstance.parcelShadingOption = 0;
                CRAPI.sharedInstance.parcelColorOption = (int)buttonIndex;
                [self vectorViewRefresh];
                break;
            case ParcelColorSettingHomestead:
            case ParcelColorSettingResCom:
            case ParcelColorSettingSpecialAssessment:
            case ParcelColorSettingTaxExempt:
            case ParcelColorSettingTaxForfeit:
            case ParcelColorSettingLastSale:
                CRAPI.sharedInstance.parcelShadingOption = ((int)buttonIndex - 4);
                [self vectorViewRefresh];
                break;
            default:break;
        }
    }
    
    else if ([alertView.identifier isEqualToString:@"EditIntersectionStatus"])
    {
        if (buttonIndex > 0)
        {
            IntersectionsDatabase *intDb = [IntersectionsDatabase databaseForGeoid:CRAPI.sharedInstance.currentGeoid];
            [intDb startTransaction];
            
            [intDb setIntersectionStatusTo:(int)buttonIndex
                           forIntersection:_selectedCRIntPt.intValue];
            
            [intDb commitTransaction];
            [self removePreviousInfoWindow];
            [self removeMarker];
            [self vectorViewRefresh];
        }
    }
    
    else if ([alertView.identifier isEqualToString:@"RouteType"])
    {
        switch (buttonIndex)
        {
            case 0://cancel
                return;
            case 1:
                _routeMode = @"driving";
                break;
            case 2:
                _routeMode = @"transit";
                break;
            case 3:
                _routeMode = @"bicycling";
                break;
            case 4:
                _routeMode = @"walking";
                break;
            default:break;
        }
        
        _animateToLocation = NO;
        [self startTrackingUserLocation];
    }
}

- (void)dismissTableView
{
    if (!_tableView.hidden)
    {
        CGRect frame = _tableView.frame;
        
        [UIView animateWithDuration:0.25
                         animations:^{
                             _tableView.frame = CGRectMake(self.view.center.x, self.view.center.y, 0.0, 0.0);
                             _mapToolbar.alpha = 1.0;
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
    int top = UIApplication.sharedApplication.windows[0].safeAreaInsets.top;
    return top;
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
    if (pBearing != 0)
        iii = 1;
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithTarget:pTarget
                                                               zoom:pZoom
                                                            bearing:pBearing
                                                       viewingAngle:0.0];
    
    [self animateToCameraPosition:camera];
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

- (void)mapToolbarDidSelectZoomExtent
{
    if (ConfigurationControl.sharedInstance.currentApp == HCConfigMapleGrovePDF)
    {
        for (NVWebView *nvwvs in _firstView.subviews)
        {
            if ([nvwvs isKindOfClass:NVWebView.class])
            {
                [nvwvs gotoOriginalPosition];
                break;
            }
        }
        
        for (NVWebView *nvwvs in _secondView.subviews)
        {
            if ([nvwvs isKindOfClass:NVWebView.class])
            {
                [nvwvs gotoOriginalPosition];
                break;
            }
        }
    }

    else
        [self extentZoom];
}

- (void)mapToolbarDidSelectUserLocation:(BOOL)enabled
{
    if (ConfigurationControl.sharedInstance.currentApp == HCConfigMapleGrovePDF)
        [self stopTrackingUserLocation:YES];
    
    else
    {
        if (enabled)
        {
            [self startTrackingUserLocation];
        }
        else
        {
            [self stopTrackingUserLocation:YES];
        }
    }
}

- (void)startTrackingUserLocation
{
    if (CLLocationManager.locationServicesEnabled)
    {
        [_locationManager startUpdatingLocation];
        CRAPI.sharedInstance.locationTrackingEnabled = YES;
        [self.view bringSubviewToFront:_myLocationMarker];
    }
}

- (void)stopTrackingUserLocation:(BOOL)setEnabled
{
    [_locationManager stopUpdatingLocation];
    [_mapToolbar deselectMyLocationButton];
    _myLocationMarker.hidden = YES;
    _locationCount = 0;
    if (setEnabled)
        CRAPI.sharedInstance.locationTrackingEnabled = NO;
}

-(BOOL) Point:(CGPoint)target InView:(UIView*)view
{
    BOOL rtn = TRUE;
    
    return rtn;
}

- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray *)locations
{
    if (!CRAPI.sharedInstance.locationTrackingEnabled)
        return;
    _currentLocation = [locations.firstObject coordinate];
    LLPOINT llpt;
    llpt.lat = _currentLocation.latitude;
    llpt.lon = _currentLocation.longitude;
    CRAPI.sharedInstance.currentLocation = llpt;
    
    if (_needToSetVehicleLocation)
    {
        if (_needToSetVehicleLocation-- == 1)
        {
            HuntingData *hd = HuntingData.new;
            CRAPI.sharedInstance.currentTrackRoute = NSMutableArray.new;
            CRAPI.sharedInstance.amTrackingRoute = TRUE;
            [hd deleteWaypointsOfType:@"Vehicle"];
            [hd addWaypoint:@"V" type:@"Vehicle" latlon:llpt description:@"" displayOnCompass:YES];
            [_mapToolbar selectMyLocationButton:YES];
            CRAPI.sharedInstance.currentVehicleLocation = llpt;
            [self vectorViewRefresh];
        }
    }
    int st = [CRAPI.sharedInstance addPointToTrackRoute: _currentLocation];
    if (st > 0)
    {
        [self displayTrackRoute];
        if (st == 2)
        {
            HuntingData *hd = HuntingData.new;
            [hd saveTrackRoute:CRAPI.sharedInstance.currentTrackRoute];
            CRAPI.sharedInstance.currentTrackRoute = NSMutableArray.new;
            CRAPI.sharedInstance.amTrackingRoute = FALSE;
        }       
    }
    
    _locationCount++;
    
    if (ConfigurationControl.sharedInstance.currentApp == HCConfigSidewalk)
    {
        GMSCameraPosition *camera = [GMSCameraPosition cameraWithTarget:_currentLocation zoom:20];
        GMSCameraUpdate *update = [GMSCameraUpdate setCamera:camera];
        [self moveCamera:update];
    }
    else if (CRAPI.sharedInstance.firstTimeZoomToCentract)
    {
        LLPOINT llpickPt;
        llpickPt.lat = _currentLocation.latitude;
        llpickPt.lon = _currentLocation.longitude;
        PickedItem *pi = nil;
        if (ConfigurationControl.sharedInstance.currentApp != HCConfigHunting)
            pi = [BoundaryData.new pickBoundaryArea:llpickPt type:@"BLOCK"];
        CRAPI.sharedInstance.firstTimeZoomToCentract = NO;

        if (pi)
        {
            CRAPI.sharedInstance.GMMSetting = GMMSettingBoundaries;
            CRAPI.sharedInstance.currentOverallBoundaryName = pi.identifier;
            CRAPI.sharedInstance.currentOverallBoundaryType = pi.symbolName;
            CRAPI.sharedInstance.currentOverallBoundaryRefno = (int)pi.refno;
            CRAPI.sharedInstance.selectBoundaryFromMapType = nil;
            [self zoomToActualBounds:pi.llbounds
                              adjust:0];
        }
        else
        {
            MNMXCORD lastBounds;
            if (![CRAPI.sharedInstance getLastBounds:&lastBounds])
            {
                HuntingData *hd = HuntingData.new;
                lastBounds = hd.NWIBounds;
            }
            [self zoomToActualBounds:lastBounds
                              adjust:0];
        }

    }
    else if (_animateToLocation)
    {
        CGPoint target = [_mapView.projection pointForCoordinate:_currentLocation];
        if (_locationCount < 2 || !PointInView(target,_mapView))
        {
            double bearing = _mapView.camera.bearing;
            if (CRAPI.sharedInstance.routeBearing)
                bearing = CRAPI.sharedInstance.routeBearing.doubleValue;
            GMSCameraPosition *camera = [GMSCameraPosition cameraWithTarget:_currentLocation
                                                                       zoom:_mapView.camera.zoom
                                                                    bearing:bearing
                                                               viewingAngle:_mapView.camera.viewingAngle];
            GMSCameraUpdate *update = [GMSCameraUpdate setCamera:camera];
            [self moveCamera:update];
            
            if (_mapToolbar.applyRotation && CLLocationManager.headingAvailable)
            {
                _amAcceptingHeading = TRUE;
                [_locationManager startUpdatingHeading];
            }
        }
        _myLocationMarker.center = CGPointMake(target.x, target.y + ([self statusBarHeight:UIApplication.sharedApplication.statusBarOrientation]));
        _myLocationMarker.hidden = NO;
    }
    
    else if (_locationCount > 2)
    {
        [self stopTrackingUserLocation:YES];
        [self beginLocationRouteTrace];
    }
}

- (void)beginLocationRouteTrace
{
    NSString *urlString =
    [NSString stringWithFormat:@"https://maps.google.com/maps/api/directions/json?origin=%f,%f&destination=%f,%f&sensor=true&mode=%@",
     _currentLocation.latitude, _currentLocation.longitude, _selectedPIDCoords.latitude, _selectedPIDCoords.longitude, _routeMode];
    
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    urlRequest.timeoutInterval = 15;
    
    NSData *urlData = nil;
    NSURLResponse *response = nil;
    NSError *error = nil;
    
    urlData = [NSURLConnection sendSynchronousRequest:urlRequest
                                    returningResponse:&response
                                                error:&error];
    
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:urlData
                                                         options:NSJSONReadingMutableContainers
                                                           error:&error];
    
    NSString *status = json[@"status"];
    NSString *message = @"";
    
    if (error)
        message = [NSString stringWithFormat:@"JSON error:%@", error.localizedDescription];
    
    else if (![status isEqualToString:@"OK"])
        message = [NSString stringWithFormat:@"JSON error:%@", status];
    
    if (message.length)
    {
        NVAlertView *alert = [NVAlertView showLargeAlertViewinView:self.view
                                                          delegate:CRAPI.sharedInstance
                                                             title:message
                                                   buttonTextArray:@[@"OK"]
                                                  destructiveIndex:0];
#pragma unused(alert)
    }
    
    else
    {
        GMSPath *overviewPath = [GMSPath pathFromEncodedPath:json[@"routes"][0][@"overview_polyline"][@"points"]];
        
        for (GMSPolyline *polylines in _polylines)
            polylines.map = nil;
        
        [_polylines removeAllObjects];
        
        if ([_routeMode isEqualToString:@"transit"])
        {
            NSDictionary *legs = json[@"routes"][0][@"legs"][0];
            NSArray *steps = legs[@"steps"];
            
            for (int i = 0; i < steps.count; i++)
            {
                NSString *travelMode = steps[i][@"travel_mode"];
                GMSPath *path = [GMSPath pathFromEncodedPath:steps[i][@"polyline"][@"points"]];
                GMSPolyline *polyline = [GMSPolyline polylineWithPath:path];
                [_polylines addObject:polyline];
                polyline.strokeWidth = 10.0;
                
                if ([travelMode isEqualToString:@"TRANSIT"])
                    polyline.strokeColor = UserDefaults.defaults.appleBlue;
                
                else if ([travelMode isEqualToString:@"WALKING"])
                    polyline.strokeColor = UIColor.orangeColor;
                
                else if ([travelMode isEqualToString:@"BICYCLING"])
                    polyline.strokeColor = UIColor.brownColor;
                
                else
                    polyline.strokeColor = UserDefaults.defaults.darkGreen;
                
                polyline.map = _mapView;
            }
        }
        
        else
        {
            GMSPolyline *polyline = [GMSPolyline polylineWithPath:overviewPath];
            [_polylines addObject:polyline];
            polyline.strokeWidth = 10.0;
            
            if ([_routeMode isEqualToString:@"walking"])
                polyline.strokeColor = UIColor.orangeColor;
            
            else if ([_routeMode isEqualToString:@"bicycling"])
                polyline.strokeColor = UIColor.brownColor;
            
            else
                polyline.strokeColor = UserDefaults.defaults.darkGreen;
            
            polyline.map = _mapView;
        }
        
        GMSCoordinateBounds *bounds = [[GMSCoordinateBounds alloc] initWithPath:overviewPath];
        [self moveCamera:[GMSCameraUpdate fitBounds:bounds withPadding:40.0]];
        [self updateMarkerPosition];
    }
    
    _animateToLocation = YES;
}

- (void)locationManager:(CLLocationManager *)manager
       didUpdateHeading:(CLHeading *)newHeading
{
    if (!_amAcceptingHeading)
        return;
    if (newHeading.trueHeading != 0)
        iii = 1;
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithTarget:_mapView.camera.target
                                                               zoom:_mapView.camera.zoom
                                                            bearing:newHeading.trueHeading
                                                       viewingAngle:_mapView.camera.viewingAngle];
    
    GMSCameraUpdate *update = [GMSCameraUpdate setCamera:camera];
    [self moveCamera:update];
    [_locationManager performSelector:@selector(stopUpdatingHeading) withObject:nil afterDelay:0.5];
}

- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error
{
    NSLog(@"CLLocationManager ERROR:%@", error.localizedDescription);
}

- (void)mapToolbarDidSelectClearMarkers
{
    [self performSelector:@selector(clearMapItems) withObject:nil afterDelay:0.3];
}
- (void) mapToolbarDidSelectWeatherButton:(BOOL)longPressed
{
    if (_currentWeatherData)
    {
        _currentWeatherData = nil;
        [self performSelectorOnMainThread:@selector(vectorViewRefresh)
                               withObject:nil
                            waitUntilDone:NO];

    }
    else
    {
        WeatherData *weatherData = WeatherData.new;
        LLPOINT llp;
        _currentPosition = [GMSCameraPosition cameraWithTarget:_mapView.camera.target
                                                          zoom:_mapView.camera.zoom];
        
        llp.lat = _currentPosition.target.latitude;
        llp.lon = _currentPosition.target.longitude;
        if (longPressed)
        {
            [weatherData getWeatherforecast:llp
                                   forTime:0
                                  delegate:self];
        }
        else
        {
            [weatherData getCurrentWeather:llp delegate:self];
        }
    }
}
- (void)weatherDataDidReturnData:(WeatherRecord*)data
{
    _currentWeatherData = data;
    [self performSelectorOnMainThread:@selector(vectorViewRefresh)
                           withObject:nil
                        waitUntilDone:NO];
}
- (void) weatherDataDidReturnError:(NSString *)message
{
    NSLog (message);
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
    [self removeScaleBar];
    _hideScaleBar = YES;
    [self clearCurrentWeatherData];
    NVPopoverTableView *nvptv =
    [NVPopoverTableView showPopoverTableViewInView:self.view
                                          delegate:self
                                             title:@"Select a Date and Time"
                                         textArray:_forecastDates
                                     includeCancel:YES];
    nvptv.identifier = @"forecast";
    nvptv.parseTextToButtons = NO;
    
}
- (void)clearMapItems
{
    for (MarkerButton *markers in _markerArray)
        [markers removeFromSuperview];
    
    [self removePreviousInfoWindow];
    
    for (GMSPolyline *polylines in _polylines)
        polylines.map = nil;
    
    [_markerArray removeAllObjects];
    [_polylines removeAllObjects];
}

- (void)mapToolbarDidSelectGrayscale
{
    _grayscaleMode = !_grayscaleMode;
    
    if (_grayscaleMode)
        [self createGrayscale];
    
    else for (UIView *views in self.view.subviews)
    {
        if (views.tag == 77777)
            [views removeFromSuperview];
    }
}

- (void)createGrayscale
{
    if (![self.view.subviews containsObject:[self.view viewWithTag:77777]])
    {
        UIView *grayscaleMapView = [[UIView alloc] initWithFrame:_mapView.frame];
        grayscaleMapView.backgroundColor = UIColor.whiteColor;
        grayscaleMapView.tag = 77777;
        grayscaleMapView.userInteractionEnabled = NO;
        UIGraphicsBeginImageContext(_mapView.frame.size);
        [_mapView.layer renderInContext:UIGraphicsGetCurrentContext()];
        UIImage *mapImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        UIImageView *grayscaleView = [[UIImageView alloc] initWithFrame:grayscaleMapView.bounds];
        grayscaleView.alpha = 0.6;
        grayscaleView.image = grayscaleImage(mapImage);
        [grayscaleMapView addSubview:grayscaleView];
        [self.view addSubview:grayscaleMapView];
        
        if ([self.view.subviews containsObject:_vectorView])
            [self.view bringSubviewToFront:_vectorView];
        
        if ([self.view.subviews containsObject:_mapToolbar])
            [_mapToolbar bringToFrontOfView];
        
        if ([self.view.subviews containsObject:_compass])
            [self.view bringSubviewToFront:_compass];
        
        for (ThemeLegendMapOverlay *tlmos in self.view.subviews)
        {
            if ([tlmos isKindOfClass:ThemeLegendMapOverlay.class])
                [self.view bringSubviewToFront:tlmos];
        }
        
        [self bringMarkersAndInfoWindowsToFront];
    }
}

- (void)mapToolbarDidSelectEmailPDF
{
    [NVEmailFileList sendFileList:self];
    //[self emailPDF:YES];
}

- (void)mapToolbarDidSelectHelpButton
{
    NSMutableString *helpList = NSMutableString.string;
    NSString *appName = @"";
    [helpList appendString:@"List"];
    
    switch (ConfigurationControl.sharedInstance.currentApp)
    {
        case HCConfigCrimes:
            appName = @"NVCrime";
            break;
        default:break;
    }
    
    [helpList insertString:appName atIndex:0];
    
    if (helpList && ![helpList isEqualToString:@"List"])
    {
        NSString *filePath = [NSBundle.mainBundle pathForResource:helpList.copy
                                                           ofType:@"txt"];
        
        NSURL *url = [NSURL fileURLWithPath:filePath];
        NSError *error = nil;
        
        NSString *helpText = [NSString stringWithContentsOfURL:url
                                                      encoding:NSUTF8StringEncoding
                                                         error:&error];
        
        if (helpText)
        {
            NSArray *helpTopics = [helpText componentsSeparatedByString:@"\n"];
            
            NVPopoverTableView *nvptv =
            [NVPopoverTableView showPopoverTableViewInView:self.view
                                                  delegate:self
                                                     title:[NSString stringWithFormat:@"Help Topics for %@", appName]
                                                 textArray:helpTopics
                                             includeCancel:YES];
            
            nvptv.parseTextToButtons = YES;
        }
        
        else
            NSLog(@"Help List ERROR: %@", error.localizedDescription);
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
            [self hideMarkersAndInfoWindows:YES];
            [_mapToolbar hide];
            
            _nvdv = [NVDigitizerView showDigitizerInView:self.view
                                       constrainedToView:_mapView
                                                delegate:self];
            return;
        case HCConfigSewers:
            _digitizationMode = DigitizationModeSewer;
            break;
        case HCConfigCurbRamps:
            _digitizationMode = DigitizationModeCurbRamps;
            break;
        case HCConfigSidewalk:
            _digitizationMode = DigitizationModeSidewalkPointNew;
            break;
        default:break;
    }
    
    _inDigitizationMode = YES;
    [self hideMarkersAndInfoWindows:YES];
    [_mapToolbar hide];
    [self showDigitizer:NO];
}

- (void)mapToolbarDidSelectLegends
{
    _options = @[];
    switch (ConfigurationControl.sharedInstance.currentApp)
    {
        case HCConfigHunting:
            [self performSelector:@selector(huntingLegend) withObject:nil afterDelay:0.3];

            break;
        case HCConfigMetroProp:
            CRAPI.sharedInstance.spreadsheetDelegate = NVSpreadsheetDelegate.new;
            _nvssvc.delegate = CRAPI.sharedInstance.spreadsheetDelegate;
            _nvssvc.tabBarItem.title = @"Property List";
            break;
        case HCConfigCrimes:
            CRAPI.sharedInstance.spreadsheetDelegate = NVCrimeListDelegate.new;
            _nvssvc.delegate = CRAPI.sharedInstance.spreadsheetDelegate;
            _nvssvc.tabBarItem.title = @"Crime List";
            break;
        case HCConfigAlleyWalls:
            _options = @[@"Alley Centerline Status", @"Alley Wall Status", @"Cancel"];
            break;
        default:break;
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
        default:break;
    }
    ConfigurationControl.sharedInstance.mapType = _mapView.mapType;
}

- (void)mapToolbarDidToggleMapType
{
    _mapTypeFromConfig = 0;
    GMSMapViewType mapType = ConfigurationControl.sharedInstance.mapType;
    switch (mapType)
    {
        case kGMSTypeNormal:
            mapType = kGMSTypeHybrid;
            break;
        case kGMSTypeHybrid:
            mapType = kGMSTypeNone;
            break;
        default:
            mapType = kGMSTypeNormal;
            break;
    }
    ConfigurationControl.sharedInstance.mapType = mapType;
    _mapView.mapType = mapType;
    [self clearVectorView];
    dispatch_async(dispatch_get_main_queue(),
                   ^{
                       [NSTimer scheduledTimerWithTimeInterval:0.1
                                                        target:self
                                                      selector:@selector(startVectorView:)
                                                      userInfo:nil
                                                       repeats:NO];
                   });


}

- (void)mapToolbarDidSelectSplitScreenSetting:(NSInteger)setting
{
    if (ConfigurationControl.sharedInstance.currentApp == HCConfigMapleGrovePDF)
    {
        if (setting == MapViewScreenSettingSplitScreen)
            setting = MapViewScreenSettingSplitPlatView;
        
        else if (setting == MapViewScreenSettingTriScreen)
            return;
    }
    
    CGFloat statusBarHeight = [self statusBarHeight:UIApplication.sharedApplication.statusBarOrientation];
    CGFloat tabBarTop = self.tabBarController.tabBar.frame.origin.y;
    [_mapView removeAllConstraints];
    _mapView.translatesAutoresizingMaskIntoConstraints = YES;
    CGFloat width = self.view.frame.size.width;
    
    //frame with no height for hidden views
    CGRect frame0 = CGRectMake(0.0, tabBarTop, width, 0.0);
    
    //bottom half of split screen
    CGRect frame1 = CGRectMake(0.0, (statusBarHeight + ((tabBarTop - statusBarHeight) / 2.0)),
                               width, ((tabBarTop - statusBarHeight) / 2.0));
    
    //upper third of tri screen
    CGRect frame2 = CGRectMake(0.0, (statusBarHeight + ((tabBarTop - statusBarHeight) / 3.0)),
                               width, ((tabBarTop - statusBarHeight) / 3.0));
    
    //bottom third of tri screen
    CGRect frame4 = CGRectMake(0.0, (statusBarHeight + ((tabBarTop - statusBarHeight) / 1.5)),
                               width, ((tabBarTop - statusBarHeight) / 3.0));
    
    //fullscreen (except not status bar)
    CGRect frame6 = CGRectMake(0.0, statusBarHeight, width, (tabBarTop - statusBarHeight));
    
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
    
    if (ConfigurationControl.sharedInstance.currentApp == HCConfigMapleGrovePDF)
        [self hideCompass];
    
    else if (setting == MapViewScreenSettingPlatView)
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
    
    NSTimeInterval duration = 0.25;
    
    if (!_usePlatView)
        duration = 0.0;
    
    switch (setting)
    {
        case MapViewScreenSettingFullscreen:
        {
            [self removeAllPlatPDFs];
            [self showMarkersAndInfoWindows:NO];
            
            if (ConfigurationControl.sharedInstance.currentApp == HCConfigMapleGrovePDF)
            {
                [ConfigurationControl.sharedInstance setApp:HCConfigMapleGrove];
                [_mapToolbar configure:setting];
            }
            
            [UIView animateWithDuration:duration
                             animations:^{
                                 _mapView.layer.borderWidth = 0.0;
                                 _mapView.translatesAutoresizingMaskIntoConstraints = NO;
                                 [_mapView constrainToView:self.view leading:0.0 trailing:0.0 top:statusBarHeight bottom:0.0];
                                 [self updateMarkerPosition];
                             }
                             completion:^(BOOL finished) {
                                 [self vectorViewRefresh];
                                 
                                 if (_mapView.camera.bearing != 0.0)
                                 {
                                     [self showCompass];
                                     _compass.transform = CGAffineTransformMakeRotation(-_mapView.camera.bearing * M_PI / 180);
                                 }
                             }];
            
            [UIView animateWithDuration:duration
                             animations:^{
                                 _firstView.frame = _secondView.frame = frame0;
                             }];
            
            _screenSetting = MapViewScreenSettingFullscreen;
        }
            break;
        case MapViewScreenSettingSplitScreen:
        {
            [UIView animateWithDuration:duration
                             animations:^{
                                 _mapView.layer.borderWidth = _splitScreenBorderWidth;
                                 
                                 _mapView.frame = CGRectMake(0.0, statusBarHeight,
                                            width, ((tabBarTop - statusBarHeight) / 2.0));
                                 
                                 [self updateMarkerPosition];
                             }
                             completion:^(BOOL finished) {
                                 [self vectorViewRefresh];
                             }];
            
            [UIView animateWithDuration:duration
                             animations:^{
                                 _firstView.frame = frame1;
                             }];
            
            [UIView animateWithDuration:duration
                             animations:^{
                                 _secondView.frame = frame0;
                             }];
            
            _screenSetting = MapViewScreenSettingSplitScreen;
        }
            break;
        case MapViewScreenSettingSplitPlatView:
        {
            [UIView animateWithDuration:duration
                             animations:^{
                                 _mapView.layer.borderWidth = _splitScreenBorderWidth;
                                 _mapView.frame = frame0;
                             }];
            
            [UIView animateWithDuration:duration
                             animations:^{
                                 _firstView.frame = CGRectMake(0.0, statusBarHeight,
                                                               width, ((tabBarTop - statusBarHeight) / 2.0));
                             }];
            
            [UIView animateWithDuration:duration
                             animations:^{
                                 _secondView.frame = frame1;
                             }];
            
            _screenSetting = MapViewScreenSettingSplitPlatView;
            CGRectMake(0.0, statusBarHeight, width, ((tabBarTop - statusBarHeight) / 2.0));
        }
            break;
        case MapViewScreenSettingTriScreen:
        {
            [UIView animateWithDuration:duration
                             animations:^{
                                 _mapView.layer.borderWidth = _splitScreenBorderWidth;
                                 
                                 _mapView.frame = CGRectMake(0.0, statusBarHeight,
                                            width, ((tabBarTop - statusBarHeight) / 3.0));
                                 
                                 [self updateMarkerPosition];
                             }
                             completion:^(BOOL finished) {
                                 [self vectorViewRefresh];
                             }];
            
            [UIView animateWithDuration:duration
                             animations:^{
                                 _firstView.frame = frame2;
                             }];
            
            [UIView animateWithDuration:duration
                             animations:^{
                                 _secondView.frame =
                                 CGRectMake(0.0, (statusBarHeight + ((tabBarTop - statusBarHeight) / 1.5)),
                                            width, ((tabBarTop - statusBarHeight) / 3.0));
                             }];
            
            _screenSetting = MapViewScreenSettingTriScreen;
        }
            break;
        case MapViewScreenSettingPlatView:
        {
            [UIView animateWithDuration:duration
                             animations:^{
                                 _firstView.frame = CGRectMake(0.0, statusBarHeight,
                                            width, (tabBarTop - statusBarHeight));
                             }];
            
            [UIView animateWithDuration:duration
                             animations:^{
                                 _secondView.frame = frame0;
                             }];
            
            _screenSetting = MapViewScreenSettingPlatView;
        }
    }
    
    if (setting != MapViewScreenSettingFullscreen && _usePlatView)
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
            default:break;
        }
        
        _platView = [PlatImageView platImageViewWithDelegate:self andFrame:frame];
        
        if (_selectedPlatRefno > 0)
            [_platView setPlatID:_selectedPlatRefno andType:PLAT_TYPE_STORM];
        
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

- (void)removeAllPlatPDFs
{
    for (NVWebView *nvwvs in _firstView.subviews)
    {
        if ([nvwvs isKindOfClass:NVWebView.class])
            [nvwvs removeFromSuperview];
    }
    
    for (NVWebView *nvwvs in _secondView.subviews)
    {
        if ([nvwvs isKindOfClass:NVWebView.class])
            [nvwvs removeFromSuperview];
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
    CGFloat pBearing = 0.0;
    CLLocationCoordinate2D pTarget = {0};
    DPOINT minYpt = {0}, maxYpt = {0};
    
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
    
    [self animateToCameraPosition:camera];
}

- (void)mapToolbarDidFinishDrag:(CGPoint)locationInSuperview
                      superView:(UIView *)view;
{
    CGFloat statusBarHeight = [self statusBarHeight:UIApplication.sharedApplication.statusBarOrientation];
    CGFloat margin = 8.0;
    NSTimeInterval duration = 0.25;
    int windowWidth = 0;
    int windowHeight = 0;
    
    if (_mapToolbar.orientation == MapToolbarOrientationMinimized)
        return;
    if (view)
    {
        windowWidth= view.frame.size.width;
        windowHeight = view.frame.size.height;
    }
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
        margin = 4.0;
    
    if (locationInSuperview.x < (_compassSize + (margin * 2.0)) &&
        locationInSuperview.y < (_compassSize + statusBarHeight + (margin * 2.0)))
    {
        _mapToolbar.previousOrientation = _mapToolbar.orientation;
        _mapToolbar.orientation = MapToolbarOrientationMinimized;
        
        [UIView animateWithDuration:duration animations:^{
            _mapToolbar.frame = CGRectMake(margin, (statusBarHeight + margin), _compassSize, _compassSize);
            _mapToolbar.layer.cornerRadius = 10.0;
            _compass.center = CGPointMake((_compassSize + (margin * 2.0) + (_compassSize / 2.0)), (statusBarHeight + margin) + (_compassSize / 2.0));
            
            for (UIView *subviews in _mapToolbar.subviews)
            {
                subviews.alpha = 0.0;
                subviews.userInteractionEnabled = NO;
            }
        } completion:^(BOOL finished) {
            [_mapToolbar addExpandButton];
        }];
    }
    else if (locationInSuperview.x < (_compassSize + (margin * 2.0)) &&
        locationInSuperview.y > (windowHeight - _compassSize - (margin * 2.0)))
    {
        _mapToolbar.previousOrientation = _mapToolbar.orientation;
        _mapToolbar.orientation = MapToolbarOrientationMinimized;
        
        [UIView animateWithDuration:duration animations:^{
            _mapToolbar.frame = CGRectMake(margin, (windowHeight - _compassSize - margin), _compassSize, _compassSize);
            _mapToolbar.layer.cornerRadius = 10.0;
            _compass.center = CGPointMake((_compassSize + (margin * 2.0) + (_compassSize / 2.0)), (statusBarHeight + margin) + (_compassSize / 2.0));
            
            for (UIView *subviews in _mapToolbar.subviews)
            {
                subviews.alpha = 0.0;
                subviews.userInteractionEnabled = NO;
            }
        } completion:^(BOOL finished) {
            [_mapToolbar addExpandButton];
        }];
    }

    else if (_mapToolbar.center.y < (self.view.frame.size.height * 0.25))
    {
        goto Bottom;
        [UIView animateWithDuration:0.25
                         animations:^{
                             [_mapToolbar animateToHorizontalOrientation];
                             
                             _mapToolbar.center = CGPointMake((_mapView.frame.size.width / 2.0),
                                                              (_mapToolbar.frame.size.height / 2.0) +
                                                              [self statusBarHeight:UIApplication.sharedApplication.statusBarOrientation]);
                         }];
        
        _mapToolbar.orientation = MapToolbarOrientationTop;
    }
    
    else if (_mapToolbar.center.y > (self.view.frame.size.height * 0.75))
    {
    Bottom:[UIView animateWithDuration:0.25
                         animations:^{
                             [_mapToolbar animateToHorizontalOrientation];
                             
                             _mapToolbar.center = CGPointMake((_mapView.frame.size.width / 2.0),
                                                              (self.view.frame.size.height -
                                                               (_mapToolbar.frame.size.height / 2.0)));
                         }];
        
        _mapToolbar.orientation = MapToolbarOrientationBottom;
    }
    
    else if (_mapToolbar.center.x < (_mapView.frame.size.width / 2.0))
    {
        [UIView animateWithDuration:0.25
                         animations:^{
                             [_mapToolbar animateToVerticalOrientation];
                             
                             _mapToolbar.center = CGPointMake((_mapToolbar.frame.size.width / 2.0),
                                                              (self.view.frame.size.height / 2.0));
                         }];
        
        _mapToolbar.orientation = MapToolbarOrientationLeft;
    }
    
    else if (_mapToolbar.center.x > (_mapView.frame.size.width / 2.0))
    {
        [UIView animateWithDuration:0.25
                         animations:^{
                             [_mapToolbar animateToVerticalOrientation];
                             
                             _mapToolbar.center = CGPointMake(_mapView.frame.size.width -
                                                              (_mapToolbar.frame.size.width / 2.0),
                                                              (self.view.frame.size.height / 2.0));
                         }];
        
        _mapToolbar.orientation = MapToolbarOrientationRight;
    }
    
    [_mapToolbar bringToFrontOfView];
    
    if (_mapToolbar.orientation != MapToolbarOrientationMinimized)
        [self updateCompassPosition:YES];
    
    if (_legendsAreOffMap && [self.view.subviews containsObject:_legendScrollView])
        [self.view bringSubviewToFront:_legendScrollView];
    [self displayScalebar];
}

- (void)mapToolbarDidWantExpand
{
    _mapToolbar.frame = _mapToolbar.previousFrame;
    _mapToolbar.layer.cornerRadius = 0.0;
    _mapToolbar.orientation = _mapToolbar.previousOrientation;
    
    for (UIView *subviews in _mapToolbar.subviews)
    {
        subviews.alpha = 1.0;
        subviews.userInteractionEnabled = YES;
    }
    
    [self restoreMapToolbarPosition];
    [self updateCompassPosition:YES];
    [self displayScalebar];
}

- (void)restoreMapToolbarPosition
{
    switch (_mapToolbar.orientation)
    {
        case MapToolbarOrientationTop:{
            [UIView animateWithDuration:0.25
                             animations:^{
                                 [_mapToolbar animateToHorizontalOrientation];
                                 
                                 _mapToolbar.center = CGPointMake((_mapView.frame.size.width / 2.0),
                                                                  (_mapToolbar.frame.size.height / 2.0) +
                                                                  [self statusBarHeight:UIApplication.sharedApplication.statusBarOrientation]);
                             }];
            break;}
        case MapToolbarOrientationBottom:{
            [UIView animateWithDuration:0.25
                             animations:^{
                                 [_mapToolbar animateToHorizontalOrientation];
                                 
                                 _mapToolbar.center = CGPointMake((_mapView.frame.size.width / 2.0),
                                                                  (self.view.frame.size.height -
                                                                   (_mapToolbar.frame.size.height / 2.0)));
                             }];
            break;}
        case MapToolbarOrientationLeft:{
            [UIView animateWithDuration:0.25
                             animations:^{
                                 [_mapToolbar animateToVerticalOrientation];
                                 
                                 _mapToolbar.center = CGPointMake((_mapToolbar.frame.size.width / 2.0),
                                                                  (self.view.frame.size.height / 2.0));
                             }];
            break;}
        case MapToolbarOrientationRight:{
            [UIView animateWithDuration:0.25
                             animations:^{
                                 [_mapToolbar animateToVerticalOrientation];
                                 
                                 _mapToolbar.center = CGPointMake(_mapView.frame.size.width -
                                                                  (_mapToolbar.frame.size.width / 2.0),
                                                                  (self.view.frame.size.height / 2.0));
                             }];
            break;}
       default:break;
    }
}

- (void)popoverTableViewDidCancel:(NVPopoverTableView *)popoverTableView
{
    [popoverTableView hide:YES];
    _hideScaleBar = NO;
    [self displayScalebar];
    [self displayWeatherData];
    [self vectorViewRefresh];
}

- (void)popoverTableView:(NVPopoverTableView *)popoverTableView
didSelectYTButtonWithText:(NSString *)text
                 atIndex:(NSInteger)index
{
    self.tabBarController.tabBar.hidden = YES;
    [self clearVectorView];
    
    for (UIView *subviews in self.view.subviews)
        subviews.hidden = YES;
    
    _youTubePlayer = YTPlayerView.new;
    _youTubePlayer.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_youTubePlayer];
    [_youTubePlayer constrainToView:self.view leading:0.0 trailing:0.0 top:0.0 bottom:0.0];
    
    CGFloat statusBarHeight = [self statusBarHeight:UIApplication.sharedApplication.statusBarOrientation];
    _ytReturnButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _ytReturnButton.translatesAutoresizingMaskIntoConstraints = NO;
    _ytReturnButton.backgroundColor = UIColor.clearColor;
    [_ytReturnButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    [_ytReturnButton setTitleColor:UIColor.lightGrayColor forState:UIControlStateHighlighted];
    [_ytReturnButton setTitle:@"< Return" forState:UIControlStateNormal];
    _ytReturnButton.titleLabel.font = [UIFont boldSystemFontOfSize:32.0];
    
    [_ytReturnButton addTarget:self
                        action:@selector(returnFromYTPlayer:)
              forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:_ytReturnButton];
    [_ytReturnButton constrainTopToAnchor:self.view.topAnchor constant:statusBarHeight];
    [_ytReturnButton constrainCenterXToAnchor:self.view.centerXAnchor];
    
    if (![_youTubePlayer loadWithVideoId:text])
    {
        NSLog(@"YTPlayerView Load ERROR");
        [self returnFromYTPlayer:nil];
    }
    
    [popoverTableView hide:YES];
}

- (void)popoverTableView:(NVPopoverTableView *)popoverTableView
didSelectPDFButtonWithText:(NSString *)text
                 atIndex:(NSInteger)index
{
    NSMutableString *fileName = NSMutableString.string;
    NSString *appName = @"";
    [fileName appendString:text];
    
    switch (ConfigurationControl.sharedInstance.currentApp)
    {
        case HCConfigCrimes:
            appName = @"NVCrime";
            break;
        default:break;
    }
    
    [fileName insertString:appName atIndex:0];
    
    NSString *filePath = [NSBundle.mainBundle pathForResource:fileName.copy
                                                       ofType:@"pdf"];
    
    NVWebView *nvwv = [NVWebView showWebViewInView:self.view
                                    showFileAtPath:filePath
                                          delegate:self];
#pragma unused(nvwv)
    
    self.tabBarController.tabBar.hidden = YES;
    [popoverTableView hide:YES];
}

- (void)popoverTableView:(NVPopoverTableView *)popoverTableView
    didSelectRowWithText:(NSString *)text
                 atIndex:(NSInteger)index
{
    if ([popoverTableView.identifier isEqual:@"Select Config"])
    {
        HuntingData *hd = HuntingData.new;
        int mapType;
        LLPOINT latlon;
        double zoom;
        if ([hd getConfiguration:text type:&mapType target:&latlon zoom:&zoom])
        {
            _mapTypeFromConfig = mapType;
            [self setMapType];
            _mapView.settings.compassButton = NO;
            _mapView.settings.rotateGestures = YES;
            _mapView.settings.tiltGestures = NO;
            _target.latitude = latlon.lat;
            _target.longitude = latlon.lon;
            _mapView.camera = [GMSCameraPosition cameraWithTarget:_target zoom:zoom];
            GMSCameraUpdate *update = [GMSCameraUpdate setCamera:_mapView.camera];
            [self moveCamera:update];
            [popoverTableView hide:YES];
            _hideScaleBar = NO;

            [self vectorViewRefresh];
        }
        return;
    }
    if ([popoverTableView.identifier isEqual:@"forecast"])
    {
        NSString *time = textAfter(text,@"|");
        if (time)
        {
            time_t itime = time.integerValue;
            _currentWeatherData = [WeatherData getRecordFromForecast:_currentForecast atTime:itime];
            [self performSelectorOnMainThread:@selector(vectorViewRefresh)
                                   withObject:nil
                                waitUntilDone:NO];

        }
    }
    else if ([popoverTableView.title isEqual:@"Saved Track Routes"])
    {
        HuntingData *hd = HuntingData.new;
        NSString *tmp = textAfter (text,@"Route:");
        int routeNumber = tmp.intValue;
        if ([hd getSavedTrack:routeNumber])
        {
            _displayTrackingRoute = TRUE;
            MNMXCORD trackBounds = [hd getTrackBounds:CRAPI.sharedInstance.currentTrackRoute];
            [self zoomToActualBounds:trackBounds
                              adjust:0];
        }
    }
    else if (ConfigurationControl.sharedInstance.currentApp == HCConfigHunting)
    {
        if ([text isEqualToString:@"Mark Vehicle Location"])
        {
            _needToSetVehicleLocation = 3;
            [self startTrackingUserLocation];
        }
        else if ([text isEqualToString:@"Stop Tracking Location"])
        {
            CRAPI.sharedInstance.amTrackingRoute = FALSE;
        }
        else if ([text isEqualToString:@"Show Tracking Route"])
        {
            _displayTrackingRoute = TRUE;
            [self displayTrackRoute];
        }
        else if ([text isEqualToString:@"Hide Tracking Route"])
        {
            _displayTrackingRoute = FALSE;
        }
        else if ([text isEqualToString:@"Save Tracking Route"])
        {
            HuntingData *hd = HuntingData.new;
            [hd saveTrackRoute:CRAPI.sharedInstance.currentTrackRoute];
            CRAPI.sharedInstance.currentTrackRoute = NSMutableArray.new;
            CRAPI.sharedInstance.amTrackingRoute = FALSE;
        }
        else if ([text isEqualToString:@"Clear Tracking Route"])
        {
            CRAPI.sharedInstance.currentTrackRoute = NSMutableArray.new;
            [self displayTrackRoute];
            [self vectorViewRefresh];
            
        }
        else if ([text isEqualToString:@"Save Route"])
        {
            
            
            [NVTextViewAlert showTextViewAlertinView:self.view
                                                        delegate:self
                                                           title:@"Enter Route Name"
                                                            text:@"Name"
                                                            idText:text];
        }
        else if ([text isEqualToString:@"Save Configuration"])
        {
            
            
            [NVTextViewAlert showTextViewAlertinView:self.view
                                            delegate:self
                                               title:@"Enter Configuration Name"
                                                text:@"Name"
                                              idText:text];
        }

        else if ([text isEqualToString:@"List Configurations"])
        {
            [popoverTableView hide:YES];
            [self removeScaleBar];
            _hideScaleBar = YES;
            [self clearCurrentWeatherData];
            HuntingData *hd = HuntingData.new;
            NSArray *list = [hd getConfiguratonList];
            NVPopoverTableView *nvptv = [NVPopoverTableView showPopoverTableViewInView:self.view
                                                                              delegate:self
                                                                                 title:@"Saved Configurations"
                                                                             textArray:list
                                                                         includeCancel:YES];
            nvptv.allowsSubtitle = NO;
            nvptv.identifier = @"Select Config";
            return;
        }
        else if ([text isEqualToString:@"Proximity Mapping"])
        {
            ProximityMapping * pm = ProximityMapping.new;
            [pm CreateSurface];
        }
        else if ([text isEqualToString:@"Start Route"])
        {
            CRAPI.sharedInstance.currentRoute = NSMutableArray.new;
            _numCurrentRoutePoints++;
            RoutePoint *routePoint = RoutePoint.new;
            routePoint.latlon = _llPickedPt;
            [CRAPI.sharedInstance.currentRoute addObject:routePoint];
            
            HuntingData *hd = HuntingData.new;
            [hd deleteWaypointsOfType:@"RoutePoint"];
            [hd addWaypoint:@"1" type:@"RoutePoint" latlon:_llPickedPt description:@"" displayOnCompass:YES];
            _numCurrentRoutePoints = 1;
            [self vectorViewRefresh];
            
        }
        else if ([text isEqualToString:@"Clear Route"])
        {
            CRAPI.sharedInstance.currentRoute = NSMutableArray.new;
            HuntingData *hd = HuntingData.new;
            [hd deleteWaypointsOfType:@"RoutePoint"];
            CRAPI.sharedInstance.currentSelectedWaypoint = -1;
            [self vectorViewRefresh];
            
        }
        else if ([text isEqualToString:@"Delete all Compass Waypoints"])
        {
            HuntingData *hd = HuntingData.new;
            [hd deleteWaypointsOfType:@"CompassPoint"];
            [self vectorViewRefresh];
            
        }
        else if ([text isEqualToString:@"Delete All Waypoints"])
        {
            HuntingData *hd = HuntingData.new;
            [hd deleteAllWaypoints];
            [self vectorViewRefresh];
        }
        else if ([text isEqualToString:@"Target this Route Waypoint"])
        {
            HuntingData *hd = HuntingData.new;
            NSArray *routePoints = [hd getWaypointsOfType:@"RoutePoint"];
            for (UserWaypoint *wp in routePoints)
            {
                if (wp.refno < _pickedRefno)
                    [hd deleteWaypointWithRefno:wp.refno];
            }
            CRAPI.sharedInstance.currentSelectedWaypoint = _pickedRefno;
            [self vectorViewRefresh];
        }
        else if ([text isEqualToString:@"Remove Waypoint from Compass"])
        {
            HuntingData *hd = HuntingData.new;
            [hd setWaypointCompassStatus:_pickedRefno
                        displayOnCompass:NO];
            [self vectorViewRefresh];
        }
        else if ([text isEqualToString:@"Add Waypoint to Compass"])
        {
            HuntingData *hd = HuntingData.new;
            [hd setWaypointCompassStatus:_pickedRefno
                        displayOnCompass:YES];
            [self vectorViewRefresh];
        }
        else if ([text isEqualToString:@"Add Compass Waypoint"])
        {
            HuntingData *hd = HuntingData.new;
            [hd addWaypoint:@"C.id" type:@"CompassPoint" latlon:_llPickedPt description:@"" displayOnCompass:YES];
            [self vectorViewRefresh];
        }
        else if ([text isEqualToString:@"Add Flushed Waypoint"])
        {
            HuntingData *hd = HuntingData.new;
            [hd addWaypoint:@"F1" type:@"FlushPoint" latlon:_llPickedPt description:@"" displayOnCompass:NO];
            [self vectorViewRefresh];
        }
        else if ([text isEqualToString:@"Test Waypoint"])
        {
            CompassViewController *cvc = CompassViewController.new;
            [cvc checkIfOffRouteTest:_llPickedPt];
        }
        else if ([text isEqualToString:@"Add Retrieved Waypoint"])
        {
            HuntingData *hd = HuntingData.new;
            [hd addWaypoint:@"R1" type:@"RetrievePoint" latlon:_llPickedPt description:@"" displayOnCompass:NO];
            [self vectorViewRefresh];
        }
        else if ([text isEqualToString:@"Display Saved Track Routes"])
        {
            [popoverTableView hide:YES];
            [self removeScaleBar];
            _hideScaleBar = YES;
            [self clearCurrentWeatherData];
            HuntingData *hd = HuntingData.new;
            NSArray * trArray = [hd getTrackRoutes];
            NSMutableArray *optionList = NSMutableArray.array;
            for (NSNumber * n in trArray)
            {
                NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                dateFormatter.timeStyle = NSDateFormatterShortStyle;
                dateFormatter.dateStyle = NSDateFormatterShortStyle;
                [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm"];
                NSString *when = [dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSinceReferenceDate:n.integerValue]];
                NSString *info = [hd getTrackInfo:n.integerValue];
                when = [when stringByAppendingString:[NSString stringWithFormat:@"\n%@||Route:%i",info,n.integerValue]];
                [optionList addObject:when];
            }
            NVPopoverTableView *nvptv = [NVPopoverTableView showPopoverTableViewInView:self.view
                                                                              delegate:self
                                                                                 title:@"Saved Track Routes"
                                                                             textArray:optionList
                                                                         includeCancel:YES];
            nvptv.allowsSubtitle = NO;
            return;

        }
        else if ([text containsString:@"Route:"])
        {
            [popoverTableView hide:YES];
            _hideScaleBar = YES;
            [self clearCurrentWeatherData];
            NSMutableArray *optionList = NSMutableArray.array;
            [optionList addObject:@"Display Saved Route"];
            [optionList addObject:@"Delete Saved Route"];

            NVPopoverTableView *nvptv = [NVPopoverTableView showPopoverTableViewInView:self.view
                                                                              delegate:self
                                                                                 title:@"Track Route Options"
                                                                             textArray:optionList
                                                                         includeCancel:YES];
            nvptv.allowsSubtitle = NO;
            return;
        }

        else
            return;
    }
    else
    {
        if ([text isEqualToString:@"View Overall Property Report"])
        {
            
        }
        
        else if ([text isEqualToString:@"Add All Units to Property List"])
        {
            PropertyData *pd = PropertyData.new;
            _linkedList = [pd getLinkedParcels:_selectedPID];
            
            if (_linkedList.count)
            {
                NSMutableArray * PIDList = NSMutableArray.new;
                for (PropertyDataExtract *ped in _linkedList)
                {
                    [PIDList addObject:ped.PIN];
                }
                _propertyList = PropertyList.new;
                _propertyList.delegate = self;
                [_propertyList addParcelsToPropertyList:PIDList
                                                popover:_popover
                                               delegate:self
                                       computeAllValues:YES];
            }
            
        }
        
        else
        {
            PropertyDataExtract *ped = (PropertyDataExtract *)_linkedList[index - 2];
            _infoWindow.linkedPID = YES;
            _infoWindow.optionsTitle = ped.PIN;
            
            [self markerInfoWindowDidSelectOptions:ped.PIN
                                             refno:0
                                            coords:_selectedPIDCoords
                                              type:MarkerInfoWindowTypePID];
        }
    }
    _hideScaleBar = FALSE;
    [popoverTableView hide:YES];
    [self displayScalebar];
}
- (void)textViewAlertDidCancel:(NVTextViewAlert *)textViewAlert
{
    [textViewAlert hideTextViewAlert:YES];
}

- (void)textViewAlert:(NVTextViewAlert *)textViewAlert
didReturnText:(NSString *)text
{
    if (text)
    {
        if ([textViewAlert.idText isEqual:@"Save Configuration"])
        {
            [self saveConfiguration:text];
        }
        else if ([textViewAlert.idText isEqual:@"List Configurations"])
        {
            [self saveConfiguration:text];
        }
    }
    
    [textViewAlert hideTextViewAlert:YES];
}


- (void)returnFromYTPlayer:(UIButton *)button
{
    [_ytReturnButton removeFromSuperview];
    [_youTubePlayer stopVideo];
    [_youTubePlayer removeFromSuperview];
    self.tabBarController.tabBar.hidden = NO;
    
    for (UIView *subviews in self.view.subviews)
    {
        if (![subviews isKindOfClass:GSSiPopoverView.class] && subviews != _tableView && subviews != _myLocationMarker)
            subviews.hidden = NO;
    }

    [self vectorViewRefresh];
}

- (void)markerInfoWindowDidSelectOptions:(NSString *)title
                                   refno:(NSInteger)refno
                                  coords:(CLLocationCoordinate2D)coords
                                    type:(NSInteger)type
{
    CRAPI.sharedInstance.keepProcessing++;
    _selectedPIDCoords = coords;

    switch (type)
    {
        case MarkerInfoWindowTypePID:
        {
            _selectedPID = title;
            if (_infoWindow.marker.nLinks && !_infoWindow.linkedPID)
            {
                PropertyData *pd = PropertyData.new;
                _linkedList = [pd getLinkedParcels:title];
                
                if (_linkedList.count)
                {
                    NSMutableArray *unitList = NSMutableArray.array;
                    [unitList addObject:@"View Overall Property Report"];
                    [unitList addObject:@"Add All Units to Property List"];
                    
                    for (PropertyDataExtract *ped in _linkedList)
                    {
                        NSString *unitName = ped.unit;
                        
                        if ([unitName isEqualToString:@""] || [unitName isEqualToString:@" "])
                        {
                            NSUInteger index = ([_linkedList indexOfObject:ped] + 1);
                            unitName = [NSString stringWithFormat:@"Select Unit %lu\n%@: %@", (unsigned long)index,ped.unitType,[CRAPI.sharedInstance.dollarFmt stringFromNumber:[NSNumber numberWithDouble:ped.emvTotal]]];
                        }
                        
                        else
                            unitName = [NSString stringWithFormat:@"Select Unit %@\n%@: %@", unitName,ped.unitType,[CRAPI.sharedInstance.dollarFmt stringFromNumber:[NSNumber numberWithDouble:ped.emvTotal]]];
                        
                        [unitList addObject:unitName];
                    }
                    
                    NVPopoverTableView *nvptv = [NVPopoverTableView showPopoverTableViewInView:self.view
                                                                                      delegate:self
                                                                                         title:@"Multi-Unit Property Options"
                                                                                     textArray:unitList
                                                                                 includeCancel:YES];
                    nvptv.allowsSubtitle = YES;
#pragma unused(nvptv)
                    return;
                }
            }
            
             
            _options = @[@"", @"Property Report", @"Property History", @"Sales History (Block)", @"Sales History (Block Group)", @"Zillow Property Record",
                         @"Display Google Street View", @"Display Bing Streetside",
                         @"Set as Target Parcel", @"Perform 3D Fly Around",
                         @"Add to Property List", @"Add to Destinations", @"Route From Current Location", @"Trip Time Profile"];
            
            NSMutableArray *newArray = [NSMutableArray arrayWithArray:_options];
            
            if (_routeTraceExists)
            {
                [newArray insertObject:@"Perform 3D Route Flyover" atIndex:8];
                _options = newArray.copy;
            }
            
            if (countySupportsLookupForPID(_selectedPID))
            {
                [newArray insertObject:@"County Property Record" atIndex:3];
                _options = newArray.copy;
            }
        }
            break;
        case MarkerInfoWindowTypeStormSewer:
        {
            _selectedSewerPipe = title;
            
            _options = @[@"", @"Display Pipe Attributes", @"Trace Pipe Upstream", @"Trace Pipe Downstream",
                         @"Remove Pipe Trace", @"Update Cleaning Date", @"Update Inspection Notes"];
           
            PipeTrace *pipeTrace = PipeTrace.new;
            
            if (pipeTrace.havePipeTrace)
            {
                NSMutableArray *newArray = [NSMutableArray arrayWithArray:_options];
                [newArray insertObject:@"Perform Downstream\n3D Fly Over" atIndex:3];
                _options = newArray.copy;
            }
        }
            break;
        case MarkerInfoWindowTypeAlleyWall:
            _selectedAlleyWall = title;
            _selectedAlleyWallRefno = refno;
            
            _options = @[@"", @"Move Wall Point", @"Delete Wall Point", @"Edit Wall Attributes",
                         @"Display Google Street View", @"Display Bing Streetside"];
            
            BOOL hasInsetWallPhoto = NO;
            
            for (NVPhotoView *nvpvs in _insetPixArray)
            {
                if (CLLocationCoordinateEqual(_infoWindow.marker.position, nvpvs.coordinate))
                    hasInsetWallPhoto = YES;
            }
            
            if (!hasInsetWallPhoto)
            {
                NSMutableArray *newArray = [NSMutableArray arrayWithArray:_options];
                [newArray addObject:@"View Inset Wall Photos"];
                _options = newArray.copy;
            }
            
            break;
        case MarkerInfoWindowTypeAlleyLine:
            _selectedAlleySeg = title;
            _selectedAlleyLineRefno = refno;
            _options = @[@"", @"Toggle Alley Line\nCompletion Status"];
            break;
        case MarkerInfoWindowTypeCRInt:
            _selectedCRIntPt = title;
            _options = @[@"", @"Edit Intersection Attributes", @"Edit Intersection Status"];
            break;
        case MarkerInfoWindowTypeCustom:
            _options = @[@"", @"Snap to Node", @"Snap to Line"];
            break;
        case MarkerInfoWindowTypeCrime:
            _selectedCrime = refno;
            
            _options = @[@"", @"Display Report", @"Add to Current Crime List", @"Add to New Crime List",
                         @"Add All to Current Crime List", @"Add All to New Crime List", @"Delete from Current Crime List",
                         @"Perform 3D Fly Around", @"Display Google Street View", @"Display Bing Streetside"];
            break;
        case MarkerInfoWindowTypeMGVSanPoint:{
            _options = @[@""];
            NSMutableArray *newArray = [NSMutableArray arrayWithArray:_options];
            BOOL splitPlatViewSave = _splitPlatView;
            _splitPlatView = YES;
            NSArray *array = [self getMGVPlatDataByRefno:_selectedMGVSanMH];
            _splitPlatView = splitPlatViewSave;
            
            if (array.count)
            {
                [newArray addObject:@"Display Plat"];
                [newArray addObject:@"Display Split Screen Profile to 1"];
                
                if (array.count > 1)
                    [newArray addObject:@"Display Split Screen Profile to 2"];
                
                _options = newArray.copy;
            }
            break;}
        case MarkerInfoWindowTypeMGVSanMain:{
            _options = @[@""];
            NSMutableArray *newArray = [NSMutableArray arrayWithArray:_options];
            BOOL splitPlatViewSave = _splitPlatView;
            _splitPlatView = YES;
            NSArray *array = [self getMGVPlatDataByRefno:_selectedMGVSanPipe];
            _splitPlatView = splitPlatViewSave;
            
            if (array.count)
            {
                [newArray addObject:@"Display Plat"];
                [newArray addObject:@"Display Split Screen Profile Along Pipe"];
                _options = newArray;
            }
            break;}
        case MarkerInfoWindowTypeCensusBoundary:
            _selectedCensusBoundaryRefno = refno;
            
            _options = @[@"", @"Display Census Data Chart", @"Perform 3D Fly Around", @"Display Google Street View",
                         @"Trip Time Profile"];
            break;
        case MarkerInfoWindowTypeBA:
            _selectedBARefNo = refno;
            _options = @[@"", @"Display Timeline", @"Add to New Crime List"];
            if ([CRAPI.sharedInstance refnoInAreaText:(int)_selectedBARefNo])
                _options = @[@"", @"Display Timeline", @"Add to New Crime List", @"Show Text"];
            break;
        default:break;
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
    _selectedPIDCoords = coords;
    
    switch (type)
    {
        case MarkerInfoWindowTypePID:
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
                case PropertyTableViewSettingPropertyHistory:
                    [self showPropHistory];
                    break;
                case PropertyTableViewSettingCountyRecord:
                    [self showCountyRecord];
                    break;
                case PropertyTableViewSettingZillow:
                    [self showZillow];
                    break;
                case PropertyTableViewSettingStreetView:
                    [self showStreetView];
                    break;
                case PropertyTableViewSettingStreetside:
                    [self showStreetside];
                    break;
                case PropertyTableViewSettingCensusArea:
                    [self showCensusArea];
                    break;
                case PropertyTableViewSettingParcelText:
                    [self selectParcelText];
                    break;
                case PropertyTableViewSettingColorParcels:
                    [self selectParcelColor];
                    break;
                case PropertyTableViewSettingFlyover:
                    break;
                case PropertyTableViewSettingPropList:
                    [self addToProplist];
                    break;
                case PropertyTableViewSettingDestinations:
                    [self addToDestinations];
                    break;
                case PropertyTableViewSettingRoute:
                    [self traceRouteFromCurrentLocation];
                    break;
                default:break;
            }
            break;
        case MarkerInfoWindowTypeStormSewer:
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
                default:break;
            }
            break;
        case MarkerInfoWindowTypeAlleyWall:
            option = [UserDefaults.defaults integerForKey:@"AlleyWallOption"];
            
            if (option == AlleyWallSettingDefault)
                option = AlleyWallSettingEditWallAttributes;
            
            switch (option)
            {
                case AlleyWallSettingMoveWallPoint:
                    _digitizationMode = DigitizationModeAlleyWallMove;
                    [self movePoint];
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
                default:break;
            }
            break;
        case MarkerInfoWindowTypeAlleyLine:
            option = [UserDefaults.defaults integerForKey:@"AlleyLineOption"];
            
            if (option == AlleyLineSettingDefault)
                option = AlleyLineSettingToggleCompletionStatus;
            
            switch (option)
            {
                case AlleyLineSettingToggleCompletionStatus:
                    [self toggleCompletionStatus];
                    [self vectorViewRefresh];
                    break;
                default:break;
            }
            break;
        case MarkerInfoWindowTypeCustom:
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
                default:break;
            }
            break;
        case MarkerInfoWindowTypeCrime:
            option = [UserDefaults.defaults integerForKey:@"CrimePointOption"];
            
            switch (option)
            {
                case CrimePointSettingDisplayReport:
                    [self displayCrimeReport];
                    break;
                case CrimePointSettingAddToCurrentList:
                    [self addToCrimeList:NO];
                    break;
                case CrimePointSettingAddToNewList:
                    [self addToCrimeList:YES];
                    break;
                case CrimePointSettingAddAllToCurrentList:
                    [self addToCrimeList:NO fromList:DispersePoint.getDispersedControlNum];
                    break;
                case CrimePointSettingAddAllToNewList:
                    [self addToCrimeList:YES fromList:DispersePoint.getDispersedControlNum];
                    break;
                case CrimePointSettingDisplayStreetView:
                    [self showStreetView];
                    break;
                case CrimePointSettingDisplayStreetside:
                    [self showStreetside];
                    break;
                default:break;
            }
            break;
        case MarkerInfoWindowTypeBA:
            option = [UserDefaults.defaults integerForKey:@"BAOption"];
            
            switch (option)
            {
                case BASettingDisplayTimeline:
                    [self displayTimeline];
                    break;
                case BASettingAddToNewList:
                    [self addToCrimeList:NO];
                    break;
                case BASettingShowText:
                    if ([CRAPI.sharedInstance refnoInAreaText:(int)_selectedBARefNo])
                        [self showText];
                default:break;
            }
            break;
        default:break;
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
                             _mapToolbar.alpha = 0.0;
                         }];
    }
}

- (void)compassTapped:(UIButton *)button
{
    CRAPI.sharedInstance.routeBearing = nil;
    [_mapView animateToBearing:0.0];

    [self hideCompass];
    [self displayScalebar];
}

- (void)hideCompass
{
    if (!_compass.hidden)
    {
        _compass.hidden = YES;
        [UIView animateWithDuration:0.25
                         animations:^{
                             _compass.alpha = 0.0;
                         } completion:^(BOOL finished) {
                         }];
    }
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
            SewerData *sewerData = SewerData.new;
            [sewerData processDate:datePicker.dateString forPipe:_selectedSewerPipe];
            [datePicker hideDatePicker:YES];
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
}

- (void)notesViewDidCancel:(GSSiNotesView *)notesView
{
    [notesView hideNotesView:YES];
}

- (void)notesView:(GSSiNotesView *)notesView
didFindMatchBetweenNote:(NSString *)note
    andItemInList:(NSString *)itemInList;
{
    NSString *text1 = [NSString stringWithFormat:@"Replace %@ with %@", itemInList, note];
    NSString *text2 = [NSString stringWithFormat:@"Add %@ to list", note];
    
    NVAlertView *alert = [NVAlertView showLargeAlertViewinView:self.view
                                                      delegate:notesView
                                                         title:[NSString stringWithFormat:@"List already contains %@", itemInList]
                                               buttonTextArray:@[@"Cancel", text1, text2]
                                              destructiveIndex:0];
#pragma unused(alert)
}

- (NSArray *)arrayOfPickableNotesItemsForNotesView:(GSSiNotesView *)notesView
{
    return nil;
}

- (void)launchAlleyWallApp
{
    NSString *AlleyWallURL = @"NVAlleyWalls://";
    [SharedDefaults.defaults saveString:@"NVMobile" forKey:@"SourceApplication"];
    
    if ([UIApplication.sharedApplication canOpenURL:[NSURL URLWithString:AlleyWallURL]])
        [UIApplication.sharedApplication openURL:[NSURL URLWithString:AlleyWallURL]];
    
    else
    {
        NVAlertView *alert = [NVAlertView showLargeAlertViewinView:self.view
                                                          delegate:self
                                                             title:@"NVMobile cannot launch Alley Wall Inventory"
                                                   buttonTextArray:@[@"OK"]
                                                  destructiveIndex:0];
#pragma unused(alert)
    }
}

- (void)launchNVCRISDetail
{
    NSString *CRISDetailURL = @"CRISDetail://";
    
    if ([UIApplication.sharedApplication canOpenURL:[NSURL URLWithString:CRISDetailURL]])
        [UIApplication.sharedApplication openURL:[NSURL URLWithString:CRISDetailURL]];
    
    else
    {
        NVAlertView *alert = [NVAlertView showLargeAlertViewinView:self.view
                                                          delegate:self
                                                             title:@"NVMobile cannot launch NVCRIS Detail"
                                                   buttonTextArray:@[@"OK"]
                                                  destructiveIndex:0];
        
        alert.identifier = @"CannotLaunchCRISDetail";
    }
}

BOOL CLLocationCoordinateEqual(CLLocationCoordinate2D coordinate1, CLLocationCoordinate2D coordinate2)
{
    return (fabs(coordinate1.latitude - coordinate2.latitude) < 0.00001) &&
           (fabs(coordinate1.longitude - coordinate2.longitude) < 0.00001);
}

- (NSUInteger)numberOfRowsInLegendView
{
    switch (ConfigurationControl.sharedInstance.currentApp)
    {
        case HCConfigHunting:
            return 5;
            break;
        case HCConfigMetroProp:
            break;
        case HCConfigAlleyWalls:
            break;
        default:break;
    }
    return 3;
}

- (NSString *)nameForRowInLegendViewAtIndex:(NSUInteger)index
{
    NSArray *names;
    switch (ConfigurationControl.sharedInstance.currentApp)
    {
        case HCConfigHunting:
            names = @[@"Wildlife Management Area",@"Waterfowl Production Area",@"Wildlife Refuge",@"CRP Area",@"Walk-in Area"];
            break;
        case HCConfigMetroProp:
            break;
        case HCConfigAlleyWalls:
            break;
        default:break;
    }
    return [names objectAtIndex:index];
}

- (UIColor *)colorForRowInLegendViewAtIndex:(NSUInteger)index
{
    UIColor * rtn;
    NSArray *colors = @[UserDefaults.defaults.appleBlue, UserDefaults.defaults.darkGreen, UIColor.redColor, UIColor.orangeColor];
    switch (ConfigurationControl.sharedInstance.currentApp)
    {
        case HCConfigHunting:
            rtn = [NVColor boldColors][index*6];
            return rtn;
            break;
        case HCConfigMetroProp:
            break;
        case HCConfigAlleyWalls:
            break;
        default:break;
    }

    return [colors objectAtIndex:index];
}

- (NSUInteger)countForRowInLegendViewAtIndex:(NSUInteger)index
{
    switch (ConfigurationControl.sharedInstance.currentApp)
    {
        case HCConfigHunting:
            return -1;
            break;
        case HCConfigMetroProp:
            break;
        case HCConfigAlleyWalls:
            break;
        default:break;
    }
    NSUInteger array[3] = {123, 456, 789};
    return array[index];
}

- (NSString *)titleForLegendView
{
    NSString *title = @"";
    switch (ConfigurationControl.sharedInstance.currentApp)
    {
        case HCConfigHunting:
            title = @"Area Type";
            break;
        case HCConfigMetroProp:
            break;
        case HCConfigAlleyWalls:
            switch(_alleyStatusSetting)
            {
                case AlleyStatusSettingWall:
                    title = @"Wall Status";
                    break;
                case AlleyStatusSettingCenterline:
                    title = @"Centerline\nStatus";
                    break;
                default:break;
            }
            break;
        default:break;
    }

    
    return title;
}

- (void)twoTextAlert:(NVTwoTextAlert *)twoTextAlert
    didReturnTopText:(NSString *)topText
          bottomText:(NSString *)bottomText
{
    [SharedDefaults.defaults saveString:topText forKey:@"OrganizationName"];
    [SharedDefaults.defaults saveString:bottomText forKey:@"DeviceNumber"];
    CRAPI.sharedInstance.organizationName = topText;
    CRAPI.sharedInstance.deviceNumber = (int)bottomText.integerValue;
    [twoTextAlert hideTwoTextAlert:YES];
}

- (void)NVDataLoaderFailed:(int)status
{
    _nvdl.popover = nil; _nvdl.delegate = nil; _nvdl = nil;
}

- (void)NVDataLoaderSuccess
{
    _nvdl.popover = nil; _nvdl.delegate = nil; _nvdl = nil;
}

- (CLLocationCoordinate2D)coordinateForPoint:(CGPoint)point
{
    return [_mapView.projection coordinateForPoint:point];
}

- (CGPoint)pointForCoordinate:(CLLocationCoordinate2D)coordinate
{
    return [_mapView.projection pointForCoordinate:coordinate];
}

- (void)digitizerViewDidComplete:(NVDigitizerView *)digitizerView
{
    [digitizerView removeFromSuperview];
    [self showMarkersAndInfoWindows:YES];
    [_mapToolbar show];
}

- (void)zoomMapToNearLeft:(CLLocationCoordinate2D)nearLeft
                 farRight:(CLLocationCoordinate2D)farRight
{
    GMSCoordinateBounds *bounds = [[GMSCoordinateBounds alloc] initWithCoordinate:farRight
                                                                       coordinate:nearLeft];
    
    [self animateWithCameraUpdate:[GMSCameraUpdate fitBounds:bounds withPadding:20.0]];
}

- (NVWebView *)webViewWithTag:(NSInteger)tag
{
    if ([[self.view viewWithTag:tag] isKindOfClass:NVWebView.class])
        return [self.view viewWithTag:tag];
    
    else
        return nil;
}

- (void)tabBarController:(UITabBarController *)tabBarController
 didSelectViewController:(UIViewController *)viewController
{
    if (viewController == self && ConfigurationControl.sharedInstance.currentApp == HCConfigMapleGrovePDF)
        [self mapToolbarDidSelectSplitScreenSetting:MapViewScreenSettingFullscreen];
}

- (void)vectorViewRefresh
{
    if (![self.view.subviews containsObject:_youTubePlayer])
    {
        [self refreshVectorView:_mapView.projection.visibleRegion
                         atZoom:_mapView.camera.zoom];
    }
}

- (void)geocoderDidReturnAddresses:(NSArray<GMSAddress *> *)addresses
                             error:(NSError *)error
{
    NSLog(@"Database Address: %@", _currentAddress);
    NSLog(@"NVGeocoder Address: %@", addresses.firstObject.thoroughfare);
}

- (void)themeLegendWillExpand
{
    _currentPosition = [GMSCameraPosition cameraWithTarget:_mapView.camera.target
                                                      zoom:_mapView.camera.zoom];
}

- (void)themeLegendDidShrink
{
    [self moveCamera:[GMSCameraUpdate setCamera:_currentPosition]];
}

- (void)themeLegendDidWantResetPositions
{
    [ConfigurationControl.sharedInstance resetLegendPositions];
    [self updateLegendPositions];
}

- (void)addToProplist
{
    _propertyList = PropertyList.new;
    _propertyList.delegate = self;
    [_propertyList addParcelToPropertyList:_selectedPID
                                   popover:_popover
                                  delegate:self
                          computeAllValues:YES];
}

- (void)ParcelAddedToPropertyList:(int)status
{
    dispatch_async(dispatch_get_main_queue(),
                   ^{
                       [NSTimer scheduledTimerWithTimeInterval:0.1
                                                        target:self
                                                      selector:@selector(endProplist:)
                                                      userInfo:nil
                                                       repeats:NO];
                   });
}

- (void)endProplist:(NSTimer *)timer
{
    _propertyList = nil;
}

- (void)findBoundsViewController:(FindBoundariesViewController *)findBounds
                 didSelectBounds:(NSString *)bounds
                            type:(NSString *)type
                           refno:(int)refno
{
    if (bounds && ![bounds isEqualToString:@""])
    {
        CRAPI.sharedInstance.currentOverallBoundaryRefno = refno;
        [UserDefaults.defaults saveInteger:refno forKey:@"CurrentOverallBoundaryRefno"];
        CRAPI.sharedInstance.currentOverallBoundaryName = bounds;
        [UserDefaults.defaults saveString:bounds forKey:@"CurrentOverallBoundaryName"];
        CRAPI.sharedInstance.currentOverallBoundaryType = type;
        [UserDefaults.defaults saveString:type forKey:@"CurrentOverallBoundaryType"];
    }
    self.tabBarController.selectedIndex = 0;
    [findBounds dismissViewControllerAnimated:YES completion:nil];
}

-(BOOL) saveConfiguration:(NSString*)name
{
    HuntingData *hd = HuntingData.new;
    
    [hd saveConfiguration:name
                     type:_mapView.mapType
                   target:CRAPI.sharedInstance.currentLocation
                     zoom:CRAPI.sharedInstance.currentZoom];
}
@end
