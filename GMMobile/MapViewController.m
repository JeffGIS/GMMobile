//  MapViewController.m
//  GMMobile

#import "MapViewController.h"
#import "AppDelegate.h"
#import "ConfigurationControl.h"
#import "MapViewENUMS.h"
#import <MapKit/MapKit.h>
#import "CCodeLibrary/PolylineCompression.h"
#import "CCodeLibrary/NVTabBarEdit.h"
#import "Destinations.h"
#import "CCodeLibrary/IntersectionsDatabase.h"
#import "NVPageController.h"
#import "CrimeDataOptions.h"
#import "UserLayerDisplay.h"
#import "ReaderViewController.h"
#import "CCodeLibrary/NVTextVC.h"
#import "CCodeLibrary/NVDigitizerView.h"
#import "CCodeLibrary/NVMarkerInfoButton.h"
#import "CCodeLibrary/NVPhotoController.h"
#import "CCodeLibrary/NVStreetSideController.h"
#import "CCodeLibrary/NVPopoverTableView.h"
#import "ChartsViewController.h"
#import "NVSpreadsheetDelegate.h"
#import "NVMetroSettingsVC.h"

#define MAX_VECTORVIEWS 8

@interface MGVPlatData : NSObject
@property NSString * pdfFile;
@property int page;
@property DPOINT ptUpper, ptLower;
@property CGFloat scaleUpper, scaleLower;
@property CGFloat rotUpper, rotLower;
@property CGFloat imageWidth, imageHeight;
@end
@implementation MGVPlatData
@end

@interface MapViewController () <GMSPanoramaViewDelegate,ReaderViewControllerDelegate,NVDigitizerViewDelegate,NSURLSessionDataDelegate,NSURLSessionTaskDelegate,NVPhotoControllerDelegate,NVPhotoViewDelegate,NVWebViewDelegate,NVPopoverTableViewDelegate,UITabBarControllerDelegate,UIGestureRecognizerDelegate>

@property MGVPlatData *mgvData;
@property (nonatomic) CLLocationCoordinate2D target, selectedPIDCoords, currentLocation;
@property (nonatomic, copy) NSArray *options, *linkedList;
@property (nonatomic) NSMutableArray *propertyReport, *markerArray, *pdfsArray, *insetPixArray;
@property PropertyTableViewSetting tableViewSetting;
@property (nonatomic) CGFloat screenSize;
@property (nonatomic) UIColor *tableViewBackgroundColor;
@property BOOL clearWhenDeselected, rotateZoom, legendsAreOffMap, showsPanorama, usePlatView;
@property BOOL firstTimeAppear, firstTimeMap, noneSelected, moveDigitizer, routeTraceExists;
@property (nonatomic, copy) NSString *selectedPID, *selectedSanPoint, *selectedSanMain, *selectedPlat;
@property (nonatomic) int selectedPlatRefno, nVectorViews;
@property (nonatomic) CGFloat vectorViewZoom, mapViewLegendOffset, compassSize;
@property (nonatomic) CGFloat currentScreenHeight, splitScreenBorderWidth, tabBarHeight;
@property (nonatomic) CGFloat heading, pitch, fov;
@property (nonatomic) VectorView *vectorView;
@property (nonatomic) NSTimer *vectorViewTimer;
@property (nonatomic) UIImageView *targetView, *digitizerTargetView;
@property (nonatomic) UIView *firstView, *secondView;
@property MapViewScreenSetting screenSetting;
@property (nonatomic) NSInteger gestureCount, digitizerCount;
@property (nonatomic) MapToolbar *mapToolbar;
@property (nonatomic) CLLocationManager *locationManager;
@property (nonatomic) MarkerInfoWindow *infoWindow;
@property (nonatomic) GSSiPopoverView *popover;
@property (nonatomic, copy) NSString *selectedSewerPipe, *selectedAlleyWall, *selectedAlleySeg, *selectedCRIntPt;
@property NSInteger selectedCrime;
@property int selectedMGVSanMH, selectedMGVSanPipe;
@property (nonatomic) NSInteger selectedSewerPipeRefno, selectedAlleyWallRefno, selectedAlleyLineRefno;
@property BOOL waitForVectorViewRefresh, inDigitizationMode, animateToLocation, displayRandomColorAlert;
@property (nonatomic) GMSTileLayer *layer_jpeg;
@property (nonatomic) GMSTileLayer *layer_png;
@property (nonatomic) UIButton *compass;
@property (nonatomic) PlatImageView *platView;
@property (nonatomic) PlatProfileView *profileView;
@property (nonatomic) CGPoint digitizingTargetOffset;
@property (nonatomic) UIImage *blackCrosshairs, *orangeCrosshairs;
@property (nonatomic) UIView *digitizationToolbar;
@property (nonatomic) UIButton *cancelDigitizerButton, *saveDigitizerButton;
@property DigitizationMode digitizationMode;
@property AlleyStatusSetting alleyStatusSetting;
@property (nonatomic) NVDataLoader *nvdl;
@property (nonatomic) NVLegendView *legendView;
@property (nonatomic) NSInteger locationCount;
@property (nonatomic) GMSPolyline *polyline;
@property (nonatomic) NSMutableSet *polylines;
@property (nonatomic) UIScrollView *legendScrollView;
@property (nonatomic) UIImageView *myLocationMarker;
@property NSUInteger currentLegendTag, pdfCount;
@property NVColorOption currentColorOption;
@property (nonatomic) ReaderViewController *readerVC;
@property (nonatomic) NVDigitizerView *nvdv;
@property (nonatomic) CrimeData *cd;
@property (nonatomic) NSMutableString *dataString;
@property BOOL splitPlatView, legendMinimized;
@property int splitPlatDirection;
@property NVMarkerStyle markerStyle;
@property (nonatomic) GMSPanoramaView *panView;
@property (nonatomic) NVSpreadsheetDelegate *ssDelegate;
@property (nonatomic) NVSpreadsheetVC *nvssvc;
@property (nonatomic) UITapGestureRecognizer *zoomExtentsGesture;

@end

@implementation MapViewController
{
    VectorView *vectorViews[MAX_VECTORVIEWS];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSLog(@"available storage space:%llu bytes", (unsigned long long)UIDevice.availableStorageSpace);
    _firstMove = TRUE;
    [NVTabBarEdit tabBarController:self.tabBarController removeViewControllerWithID:@"FieldOptionsVC"];
    [NVTabBarEdit tabBarController:self.tabBarController removeViewControllerWithID:@"DestinationsVC"];
    [NVTabBarEdit tabBarController:self.tabBarController removeViewControllerWithID:@"CurbRampDataOptionsVC"];
    [NVTabBarEdit tabBarController:self.tabBarController removeViewControllerWithID:@"MGThemesVC"];
    [NVTabBarEdit tabBarController:self.tabBarController removeViewControllerWithID:@"CrimeDataOptionsVC"];
    
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
    _animateToLocation = _usePlatView = YES;
    _routeTraceExists = _fromSpreadsheet = _legendsAreOffMap = _displayRandomColorAlert = NO;
    _showsPanorama = _splitPlatView = _legendMinimized = NO;
    self.tabBarController.delegate = self;
    
    _nvssvc = NVSpreadsheetVC.new;
    _ssDelegate = NVSpreadsheetDelegate.new;
    _nvssvc.delegate = _ssDelegate;
    _nvssvc.restorationIdentifier = @"NVSpreadsheet";
    _nvssvc.tabBarItem.title = @"Spreadsheet";
    
    _nvssvc.tabBarItem.image = [UIImage imageWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"spreadsheetIcon"
                                                                                              ofType:@"png"]];

    _mapViewLegendOffset = (ThemeLegendMapOverlay.width + 4.0);
    
    _legendScrollView = UIScrollView.new;
    _legendScrollView.translatesAutoresizingMaskIntoConstraints = NO;
    _legendScrollView.backgroundColor = UIColor.lightGrayColor;
    _legendScrollView.alpha = 0.0;
    
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
    _digitizationMode = DigitizationModeCustom;
    _locationCount = 0;
    _target = CLLocationCoordinate2DMake(44.97, -93.27);
    
    _mapView = GMSMapView.new;
    _mapView.translatesAutoresizingMaskIntoConstraints = NO;
    _mapView.delegate = self;
    _mapView.mapType = kGMSTypeNormal;
    _mapView.settings.compassButton = NO;
    _mapView.settings.rotateGestures = YES;
    _mapView.settings.tiltGestures = NO;
    
    _mapView.camera = [GMSCameraPosition cameraWithTarget:_target
                                                     zoom:12.0];
    
    [self.view addSubview:_mapView];
    
    [_mapView constrainToView:self.view leading:0.0 trailing:0.0 top:statusBarHeight bottom:0.0];
    
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
    
    UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                                                   action:@selector(mapViewLongPressed:)];
    
    longPressGesture.delegate = self;
    [_mapView addGestureRecognizer:longPressGesture];
    
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
    
    _locationManager = [[CLLocationManager alloc] init];
    _locationManager.delegate = self;
    
    if ([_locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)])
        [_locationManager requestWhenInUseAuthorization];
    
    self.view.backgroundColor = UIColor.whiteColor;
    
    _popover = [[GSSiPopoverView alloc] initWithView:self.view];
    
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
    
    CGPoint mapToolbarCenter = CGPointMake((self.view.frame.size.width / 2.0),
                                           (_mapToolbar.frame.size.height / 2.0) + statusBarHeight);
    
    _mapToolbar = [MapToolbar showMapToolbarWithCenter:mapToolbarCenter
                                                  view:self.view
                                              delegate:self];
    
    _mapToolbar.hidden = YES;
    _mapToolbar.legendOffset = _mapViewLegendOffset;
    CRAPI.sharedInstance.mapToolbar = _mapToolbar;
    CRAPI.sharedInstance.mapVC = self;
    
    HardCodedConfigs config = [UserDefaults.defaults integerForKey:@"CurrentConfig"];
    
    if (config)
    {
        _nvdl = [[NVDataLoader alloc] init];
        _nvdl.delegate = self;
        
        [_nvdl loadNVData:(config - 1)
                  popover:_popover];
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
    
    [_compass setImage:compassImage
              forState:UIControlStateNormal];
    
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
}

- (void)becameActive:(id)selector
{
    if (CRAPI.sharedInstance.setToAlleyWalls)
    {
        [UserDefaults.defaults saveNSInteger:(HCConfigAlleyWalls + 1)
                                      forKey:@"CurrentConfig"];
        
        [ConfigurationControl.sharedInstance setApp:HCConfigAlleyWalls];
        CRAPI.sharedInstance.setToAlleyWalls = NO;
    }
    
    [self refreshVectorView:_mapView.projection.visibleRegion
                     atZoom:_mapView.camera.zoom];
    
    if (_tableView)
        [self deselectTableViewRow];
}

- (void)resignedActive:(id)selector
{
    [self clearVectorView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (CRAPI.sharedInstance.appChanged)
    {
        [self themeLegendWasDraggedOffLeftSide];
        
        for (ThemeLegendMapOverlay *tlmos in self.view.subviews)
        {
            if ([tlmos isKindOfClass:ThemeLegendMapOverlay.class])
                [tlmos removeFromSuperview];
        }
        
        CRAPI.sharedInstance.appChanged = NO;
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
    _mapView.mapType = kGMSTypeNormal;
    
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
            
            CLLocationCoordinate2D myLocation = ((MarkerButton *)_markerArray.firstObject).position;
            
            GMSCoordinateBounds *bounds = [[GMSCoordinateBounds alloc] initWithCoordinate:myLocation
                                                                               coordinate:myLocation];
            
            for (MarkerButton *marker in _markerArray)
                bounds = [bounds includingCoordinate:marker.position];
            
            [_mapView animateWithCameraUpdate:[GMSCameraUpdate fitBounds:bounds
                                                             withPadding:40.0]];
        }
        
        else
        {
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
            
            [self animateToCamPos:camera];
            
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
            _infoWindow.center = CGPointMake(marker.center.x, (marker.center.y - 42.0));
            _infoWindow.delegate = self;
            _noneSelected = NO;
            [self.view addSubview:_infoWindow];
        }
        
        CRAPI.sharedInstance.GMMSetting = GMMSettingDefault;
    }
    
    else if (CRAPI.sharedInstance.GMMSetting == GMMSettingBoundaries)
    {
        [self extentZoom];
        CRAPI.sharedInstance.GMMSetting = GMMSettingDefault;
    }
    
    CRAPI.sharedInstance.currentZoom = _mapView.camera.zoom;
    
    CGFloat statusBarHeight = [self statusBarHeight:UIApplication.sharedApplication.statusBarOrientation];
    
    if (_fromSpreadsheet)
    {
        [ConfigurationControl.sharedInstance setApp:HCConfigFromSpreadsheet];
        
        self.tabBarController.tabBar.hidden = YES;
        [_mapView constrainToView:self.view leading:0.0 trailing:0.0 top:statusBarHeight bottom:_tabBarHeight];
        _mapView.userInteractionEnabled = NO;

        [self extentZoom];
        [self setMapType];
        _compass.hidden = YES;
        
        [self hideMarkersAndInfoWindows:NO];
    }
    
    else
    {
        self.tabBarController.tabBar.hidden = NO;
        
        if (_legendsAreOffMap)
            [_mapView constrainToView:self.view leading:0.0 trailing:-_mapViewLegendOffset top:statusBarHeight bottom:0.0];
        
        else
            [_mapView constrainToView:self.view leading:0.0 trailing:0.0 top:statusBarHeight bottom:0.0];
        
        _mapView.userInteractionEnabled = YES;
        _compass.hidden = NO;
        
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
                
            default:
                break;
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
                
            default:
                break;
        }
    }
}

- (void)setupTempButton:(UIButton *)button
{
    [button setTitleColor:UIColor.whiteColor
                       forState:UIControlStateNormal];
    
    [button setTitleColor:UIColor.grayColor
                       forState:UIControlStateHighlighted];
    
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
    _fromSpreadsheet = NO;
    
    NSUInteger index = [NVTabBarEdit indexOfViewControllerWithID:@"NVSpreadsheet"
                                              inTabBarController:self.tabBarController];
    
    if (index != -1)
    {
        self.tabBarController.selectedIndex = index;
        self.tabBarController.tabBar.hidden = NO;
    }
}

- (void)emailPDF
{
    NSMutableArray *viewsArray = NSMutableArray.array;
    
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
                                                               delegate:nil
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
    
    NSData *pdf = [NVPDFSnapshotter pdfFromViews:viewsArray
                                     legendsView:legendsView
                                     pickedItems:DispersePoint.getDispersedPoints];
    
    if (MFMailComposeViewController.canSendMail)
    {
        MFMailComposeViewController *composer = [[MFMailComposeViewController alloc] init];
        composer.mailComposeDelegate = self;
        composer.subject = @"PDF from NVMobile";
        
        [composer setMessageBody:@"The PDF attached to this email was rendered by NVMobile."
                          isHTML:NO];
        
        [composer setToRecipients:[NSArray arrayWithObjects:@"jeffgis@aol.com", @"wildbillmunson@gmail.com", nil]];
        
        [composer addAttachmentData:pdf
                           mimeType:@"application/pdf"
                           fileName:@"testPDF.pdf"];
        
        [self presentViewController:composer
                           animated:YES
                         completion:nil];
    }
    
    else
    {
        NVAlertView *alert = [NVAlertView showLargeAlertViewinView:self.view
                                                          delegate:self
                                                             title:@"ERROR: No mail account setup on device."
                                                   buttonTextArray:@[@"OK"]
                                                  destructiveIndex:0];
#pragma unused(alert)
    }
    
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

- (void)mailComposeController:(MFMailComposeViewController *)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError *)error
{
    switch (result)
    {
        case MFMailComposeResultCancelled:
            NSLog(@"Mail cancelled");
            break;
            
        case MFMailComposeResultSaved:
            NSLog(@"Mail saved");
            break;
            
        case MFMailComposeResultSent:
            NSLog(@"Mail sent");
            break;
            
        case MFMailComposeResultFailed:
            NSLog(@"Mail sent failure:%@", error.localizedDescription);
            break;
            
        default:
            break;
    }
    
    [self dismissViewControllerAnimated:YES
                             completion:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (!_fromSpreadsheet)
    {
        HardCodedConfigs config = [UserDefaults.defaults integerForKey:@"CurrentConfig"];
        
        if (config)
            [ConfigurationControl.sharedInstance setApp:(config - 1)];
        
        else
            self.tabBarController.selectedIndex = 3;
        
        if (_firstTimeAppear)
        {
            [self extentZoom];
            _firstTimeAppear = NO;
        }
    }
    
    [self refreshVectorView:_mapView.projection.visibleRegion
                     atZoom:_mapView.camera.zoom];
    
    CGFloat statusBarHeight = [self statusBarHeight:UIApplication.sharedApplication.statusBarOrientation];
    CRAPI.sharedInstance.currentZoom = _mapView.camera.zoom;
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main"
                                                         bundle:NSBundle.mainBundle];
    
    if (ConfigurationControl.sharedInstance.currentApp == HCConfigMetroProp ||
        ConfigurationControl.sharedInstance.currentApp == HCConfigFromSpreadsheet)
    {
        if (_legendsAreOffMap)
        {
            [self themeLegendWasDraggedOffLeftSide];
            _legendsAreOffMap = YES;
        }
        
        [NVTabBarEdit tabBarController:self.tabBarController removeViewControllerWithID:@"LayersVC"];
        
        UIViewController *findvc = [storyboard instantiateViewControllerWithIdentifier:@"FindVC"];
        
        [NVTabBarEdit tabBarController:self.tabBarController
           replaceViewControllerWithID:@"FieldOptionsVC"
                    withViewController:findvc];
        
        UIViewController *avc = [storyboard instantiateViewControllerWithIdentifier:@"ApplicationsVC"];
        
        [NVTabBarEdit tabBarController:self.tabBarController
           replaceViewControllerWithID:@"DestinationsVC"
                    withViewController:avc];
        
        NVMetroSettingsVC *nvmsvc = NVMetroSettingsVC.new;
        nvmsvc.restorationIdentifier = @"NVMetroSettingsVC";
        nvmsvc.tabBarItem.title = @"Settings";
        
        nvmsvc.tabBarItem.image = [UIImage imageWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"settings"
                                                                                                 ofType:@"png"]];
        
        [NVTabBarEdit tabBarController:self.tabBarController
           replaceViewControllerWithID:@"SettingsVC"
                    withViewController:nvmsvc];
        
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
            
            if (CRAPI.sharedInstance.mapPropList)
            {
                PropertyList *pl = PropertyList.new;
                NSArray *props = pl.getPropertyNumbers;
                
                for (NSNumber *numbers in props)
                {
                    if ([numbers isKindOfClass:NSNumber.class])
                    {
                        NSInteger num = numbers.integerValue;
                        ll = [pl getPropertyLatLon:num];
                        coord.latitude = ll.lat;
                        coord.longitude = ll.lon;
                        
                        NVMarkerInfoButton *nvmib =
                        [NVMarkerInfoButton markerWithPosition:coord
                                                         title:[pl getFieldValue:num type:PFT_UserID]
                                                          type:NVMarkerInfoButtonTypePropList
                                                          view:self.view
                                                      delegate:self];
                        
                        nvmib.tag = ((num * 100) + 3);
                    }
                }
            }
        }
    }
    
    else
    {
        [NVTabBarEdit tabBarController:self.tabBarController
            removeViewControllerWithID:@"NVSpreadsheet"];
        
        UIViewController *lvc = [storyboard instantiateViewControllerWithIdentifier:@"LayersVC"];
        
        [NVTabBarEdit tabBarController:self.tabBarController
                  insertViewController:lvc
                               atIndex:1];
        
        [NVTabBarEdit tabBarController:self.tabBarController
            removeViewControllerWithID:@"NVWebKitVC"];
        
        UIViewController *svc = [storyboard instantiateViewControllerWithIdentifier:@"SettingsVC"];
        
        [NVTabBarEdit tabBarController:self.tabBarController
           replaceViewControllerWithID:@"NVMetroSettingsVC"
                    withViewController:svc];
    }
    
    if (ConfigurationControl.sharedInstance.currentApp == HCConfigCurbRamps)
    {
        UIViewController *cdvc = [storyboard instantiateViewControllerWithIdentifier:@"CurbRampDataOptionsVC"];
        
        [NVTabBarEdit tabBarController:self.tabBarController
                  insertViewController:cdvc
                               atIndex:1];
    }
    
    else
    {
        [NVTabBarEdit tabBarController:self.tabBarController
            removeViewControllerWithID:@"CurbRampDataOptionsVC"];
    }
    
    if (ConfigurationControl.sharedInstance.currentApp == HCConfigMapleGrove)
    {
        UIViewController *mgtvc = [storyboard instantiateViewControllerWithIdentifier:@"MGThemesVC"];
        
        [NVTabBarEdit tabBarController:self.tabBarController
                  insertViewController:mgtvc
                               atIndex:1];
    }
    
    else
    {
        [NVTabBarEdit tabBarController:self.tabBarController
            removeViewControllerWithID:@"MGThemesVC"];
    }
    
    if (ConfigurationControl.sharedInstance.currentApp == HCConfigCrimes)
    {
        NSArray *pvaArray = [NSArray arrayWithObjects:[NSNumber numberWithInteger:NVPageViewArrangementFit2],
                             [NSNumber numberWithInteger:NVPageViewArrangementFit5Columns2], nil];
        
        NVPageController *nvpc = [NVPageController pageControllerWithArrangementArray:pvaArray];
        nvpc.restorationIdentifier = @"NVPageController";
        nvpc.tabBarItem.title = @"Legends";
        
        nvpc.tabBarItem.image = [UIImage imageWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"fieldOptions"
                                                                                               ofType:@"png"]];
        
        [NVTabBarEdit tabBarController:self.tabBarController
                  insertViewController:nvpc
                               atIndex:1];
        
        UIViewController *crimeOptionsVC = [storyboard instantiateViewControllerWithIdentifier:@"CrimeDataOptionsVC"];
        
        [NVTabBarEdit tabBarController:self.tabBarController
                  insertViewController:crimeOptionsVC
                               atIndex:2];
    }
    
    else
    {
        [NVTabBarEdit tabBarController:self.tabBarController
            removeViewControllerWithID:@"NVPageController"];
        
        [NVTabBarEdit tabBarController:self.tabBarController
            removeViewControllerWithID:@"CrimeDataOptionsVC"];
    }
    
    if (ConfigurationControl.sharedInstance.currentApp == HCConfigCrimes ||
        ConfigurationControl.sharedInstance.currentApp == HCConfigCurbRamps ||
        ConfigurationControl.sharedInstance.currentApp == HCConfigMapleGrove)
    {
        NSMutableArray *legends = ConfigurationControl.sharedInstance.legendList;
        BOOL legendExistsToDraw = NO, legendsAreAlreadyDrawn = NO;
        
        for (ThemeLegend *tls in legends)
        {
            if (tls.drawOnMap)
                legendExistsToDraw = YES;
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
                
                if (!legendsAreAlreadyDrawn &&
                    ConfigurationControl.sharedInstance.currentApp == HCConfigCrimes)
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
    
    [_mapToolbar didRotateWithTabBarHeight:_tabBarHeight
                           statusBarHeight:statusBarHeight];
    
    _mapToolbar.hidden = NO;
    [self updateCompassPosition:NO];
    
    _zoomExtentsGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(extentZoom)];
    _zoomExtentsGesture.delegate = self;
    _zoomExtentsGesture.numberOfTouchesRequired = 2;
    _zoomExtentsGesture.numberOfTapsRequired = 2;
    [self.view addGestureRecognizer:_zoomExtentsGesture];
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
    if (status == FTPStatusOK && directoryList)
    {
        NSString *dirListString = [[NSString alloc] initWithData:directoryList
                                                        encoding:NSUTF8StringEncoding];
        
        NSLog(@"%@", dirListString);
    }
    
    NSLog(@"FTP Status:%li:%@", (long)status, statusString);
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    _currentScreenHeight = self.view.frame.size.height;
    [self stopTrackingUserLocation];
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
    button.translatesAutoresizingMaskIntoConstraints = NO;
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

- (void)extentZoom
{
    [self stopTrackingUserLocation];
    MNMXCORD bounds={0};
    int boundaryRefno = 0;
    NSString *boundaryType = @"BOUNDARY";
    CGFloat mapAdj = 0.0;
    
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
    
    if (BoundsWidth(&bounds) > 0)
    {
        CLLocationCoordinate2D northeast = CLLocationCoordinate2DMake(bounds.ymx, bounds.xmx);
        CLLocationCoordinate2D southwest = CLLocationCoordinate2DMake(bounds.ymn, bounds.xmn);
        
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
                if (!subviews.hidden)
                    [subviewsArray addObject:subviews];
            }
        }
        
        [[self.view viewWithTag:999] removeFromSuperview];
        
        CGRect *frames = (CGRect *)malloc((sizeof(CGRect) * subviewsArray.count) + 4);
        
        for (int i = 0; i < subviewsArray.count; i++)
            frames[i] = [(UIView *)subviewsArray[i] frame];
        
        CGFloat aspectRatio = [self getAspectRatioForBounds:bounds];
        CGRect targetFrame = largestRect(aspectRatio, 5, _mapView.frame, (int)subviewsArray.count, frames);
        
        free(frames);
        
        [[self.view viewWithTag:999] removeFromSuperview];
        
        GMSCoordinateBounds *coordBounds = [[GMSCoordinateBounds alloc] initWithCoordinate:northeast
                                                                                coordinate:southwest];
        
        UIEdgeInsets inset = UIEdgeInsetsMake((CGRectGetMinY(targetFrame) - CGRectGetMinY(_mapView.frame) + 5.0),
                                              (CGRectGetMinX(targetFrame) - CGRectGetMinX(_mapView.frame) + 5.0),
                                              (CGRectGetMaxY(_mapView.frame) - CGRectGetMaxY(targetFrame)  + 5.0 + mapAdj),
                                              (CGRectGetMaxX(_mapView.frame) - CGRectGetMaxX(targetFrame) + 5.0));
        
        [self moveCam:[GMSCameraUpdate fitBounds:coordBounds withEdgeInsets:inset]];
    }
    
    else
    {
        GMSCameraPosition *camera = [GMSCameraPosition cameraWithTarget:_target
                                                                   zoom:12.0];
        
        [self animateToCamPos:camera];
    }
}

- (void)zoomToPipeTraceBounds:(MNMXCORD)bounds
{
    [self zoomToBounds:bounds];
}
- (void)zoomToBounds:(MNMXCORD)bounds
{
    CLLocationCoordinate2D northeast = CLLocationCoordinate2DMake(bounds.ymx, bounds.xmx);
    CLLocationCoordinate2D southwest = CLLocationCoordinate2DMake(bounds.ymn, bounds.xmn);
    
    GMSCoordinateBounds *coordBounds = [[GMSCoordinateBounds alloc] initWithCoordinate:northeast
                                                                            coordinate:southwest];
    
    GMSCameraPosition *camera = [_mapView cameraForBounds:coordBounds
                                                   insets:UIEdgeInsetsMake(20.0, 20.0, 20.0, 20.0)];
    
    [self animateToCamPos:camera];
}

- (void)mapView:(GMSMapView *)mapView
didTapAtCoordinate:(CLLocationCoordinate2D)coordinate
{
    if (_inDigitizationMode)
        return;
    
    if (!_tableView.hidden)
        [self dismissTableView];
    
    else if (CRAPI.sharedInstance.selectBoundaryFromMapType)
    {
        LLPOINT llpickPt = {0};
        llpickPt.lat = coordinate.latitude;
        llpickPt.lon = coordinate.longitude;
        BoundaryData *bd = [[BoundaryData alloc]init];
        
        if ([bd pickBoundaryArea:llpickPt] == 1)
            [self extentZoom];
    }
    
    else
    {
        LLPOINT llpickPt = {0}, llSewerPt = {0}, llPropPt = {0}, llCrimePt = {0};
        llpickPt.lat = coordinate.latitude;
        llpickPt.lon = coordinate.longitude;
        llPropPt = llpickPt;
        llSewerPt = llpickPt;
        llCrimePt = llpickPt;
        CRAPI.sharedInstance.currentZoom = _mapView.camera.zoom;

        NSMutableArray *highlightList = [[NSMutableArray alloc] init];
        PropertyData *propData = [[PropertyData alloc] init];
        SewerData *sewerData = [[SewerData alloc] init];
        PlanimetricData *planData = [[PlanimetricData alloc] init];
        DispersePoint *dp = [[DispersePoint alloc]init];
        sewerData.zoom = _mapView.camera.zoom;
        propData.zoom = _mapView.camera.zoom;
        planData.zoom = _mapView.camera.zoom;
        
        [propData pickParcel:&llPropPt
               highlightList:highlightList];
        
        if ([ConfigurationControl.sharedInstance layer:HCLayerCrimes
                                         visibleAtZoom:_vectorViewZoom
                                               andPass:PickPass])
        {
            [dp pickDispersedPoint:&llCrimePt
                   highlightList:highlightList];
        }
        
        if ([ConfigurationControl.sharedInstance layer:HCLayerSewers
                                         visibleAtZoom:_vectorViewZoom
                                               andPass:PickPass])
        {
            [sewerData pickSewer:&llSewerPt
                          atZoom:_mapView.camera.zoom
                   highlightList:highlightList];
        }
        if (ConfigurationControl.sharedInstance.currentApp == HCConfigMapleGrove)
        {
            UserLayerDisplay *ud = [[UserLayerDisplay alloc] init];
            ud.processingID = CRAPI.sharedInstance.keepProcessing;
            ud.zoom = _mapView.camera.zoom;
            ud.passID = PickPass;
            [ud pickLayers:&llpickPt
             highlightList:highlightList];
        }
        
        /*UserLayerDisplay *ud = [[UserLayerDisplay alloc] init];
        ud.processingID = CRAPI.sharedInstance.keepProcessing;
        ud.zoom = _zoom;
        ud.passID = passID;
        if (CRAPI.sharedInstance.keepProcessing == self.displayID)
        {
            [ud displayLayers:_context
       displayCharacteristics:dc
                    llCorners:&_latlonCornerPoints
                     LLBounds:&_latlonBounds
                   viewBounds:&_viewBounds
                       themes:themes
                  pointInArea:_pia];
        }*/
        
        [planData pickAlleyWallPoint:llpickPt
                       highlightList:highlightList];
        
        [planData pickAlleyLine:llpickPt
                         atZoom:_mapView.camera.zoom
                  highlightList:highlightList];
        
        [planData pickCurbRampIntersectionPoint:llpickPt
                                  highlightList:highlightList];
        
        if (highlightList.count)
        {
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
                                                    statusBarHeight:[self statusBarHeight:UIApplication.sharedApplication.statusBarOrientation]
                                                           delegate:self];
            [self removePreviousInfoWindow];
            _infoWindow = MarkerInfoWindow.new;
            
            switch (pi.itemType)
            {
                case CrimePoint:
                {
                    _selectedCrime = pi.refno;
                    marker.snippet = pi.identifier;
                    NSDateFormatter *dateFormatter = NSDateFormatter.new;
                    dateFormatter.timeStyle = NSDateFormatterShortStyle;
                    dateFormatter.dateStyle = NSDateFormatterShortStyle;
                    NSString *dateString = [dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:pi.time]];
                    marker.title = dateString;
                    marker.type = MarkerInfoWindowTypeCrime;
                }
                    break;
                    
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
                    marker.snippet = [propData getOwnerNameForPID:_selectedPID];
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
                    
                default:
                    break;
            }
            
            marker.refno = pi.refno;
            marker.symbol = pi.symbol;
            marker.nLinks = pi.nLinks;
            
            [_markerArray addObject:marker];
            
            _infoWindow.center = CGPointMake(marker.center.x, (marker.center.y - 42.0));
            _infoWindow.delegate = self;
            _infoWindow.marker = marker;
            _infoWindow.optionsTitle = marker.title;
            _noneSelected = NO;
            
            [self.view addSubview:_infoWindow];
            
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
                
            default:
                break;
        }
        
        [_markerArray addObject:marker];
        
        CGPoint target = [_mapView.projection pointForCoordinate:marker.position];
        
        _infoWindow.center = CGPointMake(target.x, (target.y - 42.0));
        _infoWindow.delegate = self;
        _infoWindow.marker = marker;
        _infoWindow.optionsTitle = marker.title;
        _noneSelected = NO;
        
        [self.view addSubview:_infoWindow];
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
        
        CGPoint digitizerCenter = CGPointMake(_digitizerTargetView.center.x, (_digitizerTargetView.center.y -
                                               [self statusBarHeight:UIApplication.sharedApplication.statusBarOrientation]));
        
        CLLocationCoordinate2D position = [_mapView.projection coordinateForPoint:digitizerCenter];
        
        switch (_digitizationMode)
        {
            case DigitizationModeCustom:
            {
                _digitizerCount++;
                
                MarkerButton *marker = [MarkerButton markerWithPosition:position
                                                                   view:self.view
                                                                    map:_mapView
                                                        statusBarHeight:[self statusBarHeight:UIApplication.sharedApplication.statusBarOrientation]
                                                               delegate:self];
                
                [self removePreviousInfoWindow];
                _infoWindow = MarkerInfoWindow.new;
                
                [marker setImage:_orangeCrosshairs
                        forState:UIControlStateNormal];
                
                marker.title = [NSString stringWithFormat:@"Custom Marker %ld", (long)_digitizerCount];
                marker.snippet = [NSString stringWithFormat:@"%f, %f", marker.position.latitude, marker.position.longitude];
                marker.type = MarkerInfoWindowTypeCustom;
                
                [_markerArray addObject:marker];
                
                _infoWindow.center = CGPointMake(marker.center.x, (marker.center.y - 42.0));
                _infoWindow.delegate = self;
                _infoWindow.marker = marker;
                _infoWindow.optionsTitle = marker.title;
                _noneSelected = NO;
                
                [self.view addSubview:_infoWindow];
            }
                break;
                
            case DigitizationModeAlleyWallMove:
            {
                
                [AlleyWallData moveAlleyWallPoint:_selectedAlleyWallRefno
                                               to:position];
                
                MarkerButton *marker = _markerArray.lastObject;
                marker.position = position;
                
                marker.center = CGPointMake(_digitizerTargetView.center.x,
                                            (_digitizerTargetView.center.y -
                                             (marker.frame.size.height / 2.0)));
                
                _infoWindow.center = CGPointMake(marker.center.x, (marker.center.y - 42.0));
                
                [UIView animateWithDuration:0.25
                                 animations:^{
                                     _cancelDigitizerButton.alpha = 0.0;
                                     _saveDigitizerButton.alpha = 1.0;
                                 }];
                
                [_vectorView setNeedsDisplay];
            }
                break;
                
            case DigitizationModeAlleyWallNew:
            {
                _digitizerCount++;
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
                                          city:nil
                                   censusBlock:nil
                                       useDesc:nil
                                        totEMV:nil];
                }
                
                [awd createNewWall:newWallID
                           atPoint:position
                         withHouse:houseAndUnit
                         andStreet:streetName];
                
                [self refreshVectorView:_mapView.projection.visibleRegion
                                 atZoom:_mapView.camera.zoom];
                
                _noneSelected = NO;
                
                [UIView animateWithDuration:0.25
                                 animations:^{
                                     _cancelDigitizerButton.alpha = 0.0;
                                     _saveDigitizerButton.alpha = 1.0;
                                 }];
            }
                break;
                
            case DigitizationModeCurbRamps:
            {
                LLPOINT intPoint = {0};
                intPoint.lat = position.latitude;
                intPoint.lon = position.longitude;
                
                IntersectionsDatabase *intDB = [IntersectionsDatabase databaseForGeoid:CRAPI.sharedInstance.currentGeoid];
                
                [intDB addNewIntersectionAt:intPoint
                                   withName:@"Added in NVMobile"];
                
                [self refreshVectorView:_mapView.projection.visibleRegion
                                 atZoom:_mapView.camera.zoom];
                
                _noneSelected = NO;
                
                [UIView animateWithDuration:0.25
                                 animations:^{
                                     _cancelDigitizerButton.alpha = 0.0;
                                     _saveDigitizerButton.alpha = 1.0;
                                 }];
            }
                break;
                
            case DigitizationModeProperty:
                break;
                
            case DigitizationModeSewer:
                break;
                
            default:
                break;
        }
        
        CGPoint targetPoint = [_mapView.projection pointForCoordinate:_mapView.camera.target];
        
        _digitizerTargetView.center = CGPointMake(targetPoint.x,
                                                  (targetPoint.y + [self statusBarHeight:UIApplication.sharedApplication.statusBarOrientation]));
    }
}

- (void)mapViewLongPressed:(UILongPressGestureRecognizer *)gesture
{
    if (CRAPI.sharedInstance.currentApp ==  HCConfigMetroProp)
    {
        if (gesture.state == UIGestureRecognizerStateBegan)
            _vectorView.alpha = 0.0;
        
        else if (gesture.state == UIGestureRecognizerStateEnded)
            _vectorView.alpha = 1.0;
        
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
            LLPOINT llp;
            llp.lat = gestureLocation.latitude;
            llp.lon = gestureLocation.longitude;
            int platRefno = 0;
            
            if (ConfigurationControl.sharedInstance.currentApp == HCConfigMapleGrove)
            {
                UserLayerDisplay *ud = [[UserLayerDisplay alloc] init];
                ud.processingID = CRAPI.sharedInstance.keepProcessing;
                
                CRAPI.sharedInstance.selectedPDFID = [ud pickPDFPlat:&llp
                                                           platRefno:&platRefno];
           }
            
            else
            {
                SewerData *sewerData = [[SewerData alloc] init];
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
            _mgvData = nil;
            _splitPlatView = NO;
            if (ConfigurationControl.sharedInstance.currentApp == HCConfigMapleGrove)
            {
                
                [sd loadPlat:CRAPI.sharedInstance.selectedPDFID
                      ofType:@"pdf"
                usingPopover:_popover
                 andDelegate:self];
            }
            else
            {
                
                NSString *platID = [sd getPlatIDofType:@"storm"
                                             fromRefno:_selectedPlatRefno];
                [sd loadPlat:platID
                      ofType:@"storm"
                usingPopover:_popover
                 andDelegate:self];
            }
        }
        
        [self refreshVectorView:_mapView.projection.visibleRegion
                         atZoom:_mapView.camera.zoom];
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
            case FTPDataPlat:
            {
                CRAPI.sharedInstance.currentPlatImagePath = path;
                CRAPI.sharedInstance.currentPlatType = @"storm";
                
                [_platView setPlatID:_selectedPlatRefno
                             andType:PLAT_TYPE_STORM];
                
                if (_screenSetting == MapViewScreenSettingFullscreen && _selectedPlatRefno > 0)
                {
                    _usePlatView = YES;
                    [self mapToolbarDidSelectSplitScreenSetting:MapViewScreenSettingSplitScreen];
                    [_mapToolbar splitScreenSelectedSegmentIndex:MapViewScreenSettingSplitScreen];
                }
            }
                break;
            case FTPDataPDF:
            {
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
                                                 showFileAtPath:path];
                
                nvwv1.delegate = self;
                nvwv1.tag = 111;
                [nvwv1 hideReturnButton];
                
                if (_mgvData)
                {
                    [nvwv1 zoomToPoint:_mgvData.ptUpper
                            withinPage:_mgvData.page
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
                                                     showFileAtPath:path];
                    
                    nvwv2.delegate = self;
                    nvwv2.tag = 222;
                    [nvwv2 hideReturnButton];
                    
                    [nvwv2 zoomToPoint:_mgvData.ptLower
                            withinPage:_mgvData.page
                             withScale:_mgvData.scaleLower
                              rotation:_mgvData.rotLower];
                }
            }
                break;
                
            default:
                break;
        }
    }
    
    else
    {
        NVAlertView *alert = [NVAlertView showLargeAlertViewinView:self.view
                                                          delegate:self
                                                             title:[NSString stringWithFormat:@"FTP Error:Cannot get %@ (%@)",
                                                                    path.lastPathComponent, statusString]
                                                   buttonTextArray:@[@"OK"]
                                                  destructiveIndex:0];
#pragma unused(alert)
    }
}
- (void)webView:(NVWebView *)webView
wasTappedAtPoint:(DPOINT)point
     withinPage:(int)page
{
    switch (webView.tag)
    {
        case 111://top PDF
        {
            NSLog(@"Top PDF tapped on page %i at x:%f,y:%f", page, point.x, point.y);
            
            /*_mgvData = [self getMGVPlatDataByViewport:111
                                           coordinate:point
                                                 file:_mgvData.pdfFile
                                              andPage:_mgvData.page];
            
            [webView zoomToPoint:_mgvData.ptUpper
                      withinPage:_mgvData.page
                       withScale:_mgvData.scaleUpper
                        rotation:_mgvData.rotUpper];
            
            if (_splitPlatView)
            {
                NVWebView *nvwv2 = [self webViewWithTag:222];
                
                if (nvwv2)
                {
                    [nvwv2 zoomToPoint:_mgvData.ptLower
                            withinPage:_mgvData.page
                             withScale:_mgvData.scaleLower
                              rotation:_mgvData.rotLower];
                }
            }*/
        }
           break;
            
        case 222://bottom PDF
            NSLog(@"Bottom PDF tapped on page %i at x:%f,y:%f", page, point.x, point.y);
            break;
    }
}

- (void)dismissReaderViewController:(ReaderViewController *)viewController
{
    [self dismissViewControllerAnimated:YES
                             completion:^{
                                 _readerVC = nil;
                             }];
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
            CGPoint target = [_mapView.projection pointForCoordinate:marker.position];
            
            _infoWindow = MarkerInfoWindow.new;
            _infoWindow.center = CGPointMake(target.x, (target.y - 42.0));
            _infoWindow.delegate = self;
            _infoWindow.marker = marker;
            _infoWindow.optionsTitle = marker.title;
             _noneSelected = NO;
            
            [self.view addSubview:_infoWindow];
        }
    }
}

- (void)mapView:(GMSMapView *)mapView
       willMove:(BOOL)gesture
{
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
    
    if (_firstMove)
        CRAPI.sharedInstance.selectBoundaryFromMapType = nil;
    
    _firstMove = NO;
    
    if (position.bearing != 0.0)
    {
        [self showCompass];
        _compass.transform = CGAffineTransformMakeRotation(-position.bearing * M_PI / 180);
    }
    
    [self updateMarkerPosition];
    
    for (NVPhotoView *nvpvs in _insetPixArray)
        [nvpvs updatePosition];
}

- (void)updateMarkerPosition
{
    CGFloat statusBarHeight = [self statusBarHeight:UIApplication.sharedApplication.statusBarOrientation];
    
    for (MarkerButton *markers in _markerArray)
    {
        CGPoint target = [self pointForCoordinate:markers.position];
        markers.center = CGPointMake(target.x, ((target.y + statusBarHeight) - (markers.frame.size.height / 2.0)));
    }
    
    MarkerButton *marker = _markerArray.lastObject;
    _infoWindow.center = CGPointMake(marker.center.x, (marker.center.y - 42.0));
    
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
    
    if (position.bearing == 0.0)
        [self hideCompass];
    
    if ([self.view.subviews containsObject:_nvdv])
        [_nvdv setNeedsDisplay];
    
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
    
    [_mapView constrainToView:self.view leading:0.0 trailing:0.0 top:statusBarHeight bottom:0.0];
    
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
            
        default:
            break;
    }
    
    [_mapToolbar didRotateWithTabBarHeight:_tabBarHeight
                           statusBarHeight:statusBarHeight];
    
    [self updateCompassPosition:NO];
    
    if (_mapView.camera.bearing != 0.0)
        _compass.alpha = 1.0;
    
    if (![self legendIsExpanded] && ![self alertVisible])
        [self updateLegendPositions];
    
    if (!_tableView.hidden)
        [_tableView reloadData];
    
    [self setMapType];
    
    if (_rotateZoom)
        [self moveCam:[GMSCameraUpdate zoomBy:0.000001]];
    
    else
        [self moveCam:[GMSCameraUpdate zoomBy:-0.000001]];
   
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
            
        default:
            break;
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
    _vectorView.translatesAutoresizingMaskIntoConstraints = NO;
    vectorViews[ivv] = _vectorView;
    _vectorView.ivv = ivv;
    _vectorView.userInteractionEnabled = NO;
    _vectorView.delegate = self;
    [self.view addSubview:_vectorView];
    [_vectorView constrainToView:_mapView leading:0.0 trailing:0.0 top:0.0 bottom:0.0];
}

- (void)clearVectorView
{
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
    [self allocateVectorView];
    _vectorView.displayDataOption = DISPLAY_DATA_OPTION_DISPLAY;
    
    [_vectorView setRegion:_mapView.projection.visibleRegion];
    CRAPI.sharedInstance.currentZoom = _vectorViewZoom;
    _vectorView.zoom = _vectorViewZoom;
    
    NSLog(@"Vector view start: zoom = %f", _vectorViewZoom);
    
    if ([ConfigurationControl.sharedInstance haveUserAerials] &&
        [ConfigurationControl.sharedInstance layer:HCLayerAerials
                                     visibleAtZoom:_vectorViewZoom
                                           andPass:AerialPass])
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

- (void)setMapType
{
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

- (void)vectorViewDidComplete:(VectorView *)vectorView
{
   _waitForVectorViewRefresh = NO;
    
    if (vectorView.displayID != CRAPI.sharedInstance.keepProcessing)
        vectorViews[vectorView.ivv] = nil;
    
    else dispatch_async(dispatch_get_main_queue(),
                   ^{
                       if (_fromLegends)
                       {
                           self.tabBarController.selectedIndex = _fromIndex;
                           self.tabBarController.tabBar.userInteractionEnabled = YES;
                           _fromLegends = NO;
                           return;
                       }
                       
                       [_vectorView removeFromSuperview];
                       
                       if (_screenSetting != MapViewScreenSettingPlatView)
                       {
                           [self.view addSubview:_vectorView];
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
                           
                           [self updateLegendPositions];
                           
                           if (!_tableView.hidden)
                               [self.view bringSubviewToFront:_tableView];
                           
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
                           
                           if (_displayRandomColorAlert)
                           {
                               self.tabBarController.tabBar.userInteractionEnabled = NO;
                               ThemeLegendMapOverlay *tlmo = (ThemeLegendMapOverlay *)[self.view viewWithTag:_currentLegendTag];
                               tlmo.currentColorPalette = _currentColorOption;
                               [tlmo displayRandomColorAlertInView:self.view];
                               _displayRandomColorAlert = NO;
                           }
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
                       
                       for (NVAlertView *alert in self.view.subviews)
                       {
                           if ([alert isKindOfClass:NVAlertView.class])
                           {
                               [self.view bringSubviewToFront:alert.overlayView];
                               [self.view bringSubviewToFront:alert];
                           }
                       }
                       
                       if (CRAPI.sharedInstance.becameActive &&
                           [UserDefaults.defaults boolForKey:@"AutoUpdate"] &&
                           ConfigurationControl.sharedInstance.currentApp == HCConfigCrimes)
                       {
                           _cd = [CrimeData new];
                           [_cd update:self.view];
                           CRAPI.sharedInstance.becameActive = NO;
                       }
                   });
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
    if (_legendMinimized)
        return;
    
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
                            [self.view bringSubviewToFront:[self.view viewWithTag:123456789]];
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
                        [self.view bringSubviewToFront:[self.view viewWithTag:123456789]];
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
        CGFloat headerHeight = ThemeLegendMapOverlay.headerHeight;
        
        CGFloat landscapeWidth = MAX(UIScreen.mainScreen.bounds.size.width, UIScreen.mainScreen.bounds.size.height);
        CGFloat portraitWidth = MIN(UIScreen.mainScreen.bounds.size.width, UIScreen.mainScreen.bounds.size.height);
        CGFloat xOriginLandscape = (landscapeWidth - tlmoWidth);
        CGFloat xOriginPortrait = (portraitWidth - tlmoWidth);
        
        CGFloat statusBarHeight = [self statusBarHeight:UIApplication.sharedApplication.statusBarOrientation];
        CGFloat yFactor = 2.0;
        
        if (ConfigurationControl.sharedInstance.currentApp == HCConfigMetroProp)
            yFactor += _mapToolbar.frame.size.height;
        
        CGFloat yOriginPortrait = (statusBarHeight + yFactor);
        CGFloat yOriginLandscape = yOriginPortrait;
        NSUInteger portraitColumnCount = 1, landscapeColumnCount = portraitColumnCount;
        UIView *inView = self.view;
        BOOL legendExistsToDraw = NO, legendsAreAlreadyDrawn = NO;
        
        for (ThemeLegend *tls in legends)
        {
            if (tls.drawOnMap || ConfigurationControl.sharedInstance.currentApp == HCConfigFromSpreadsheet)
                legendExistsToDraw = YES;
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
                
                if (!legendsAreAlreadyDrawn &&
                    ConfigurationControl.sharedInstance.currentApp == HCConfigCrimes)
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
                    CGFloat legendHeight = (((rowHeight * tl.numCells) + headerHeight) + yFactor);
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
                    if (!tl.isDraggedPortrait)
                        tl.portraitMapOrigin = CGPointMake(xOriginPortrait, yOriginPortrait);
                    
                    if (!tl.isDraggedLandscape)
                        tl.landscapeMapOrigin = CGPointMake(xOriginLandscape, yOriginLandscape);
                    
                    if (UIApplication.sharedApplication.statusBarOrientation == UIDeviceOrientationLandscapeLeft ||
                        UIApplication.sharedApplication.statusBarOrientation == UIDeviceOrientationLandscapeRight)
                    {
                        mapOrigin = tl.landscapeMapOrigin;
                    }
                    
                    else
                        mapOrigin = tl.portraitMapOrigin;
                }
                
                ThemeLegendMapOverlay *tlmo = [ThemeLegendMapOverlay drawLegend:tl
                                                                        withTag:((i + 1) * 111111)
                                                                       delegate:self
                                                                         inView:inView
                                                                       atOrigin:mapOrigin
                                                                    hideButtons:NO];
                
                    yOriginPortrait += (tlmo.frame.size.height + yFactor);
                    yOriginLandscape += (tlmo.frame.size.height + yFactor);
            }
        }
    }
}

- (void)themeLegendDidChangeStatus:(BOOL)refreshVectorView
{
    if (refreshVectorView)
    {
        [self refreshVectorView:_mapView.projection.visibleRegion
                         atZoom:_mapView.camera.zoom];
    }
    
    else
        [self updateLegendPositions];
}

- (void)themeLegendWasDraggedOffRightSide
{
    if (!_legendsAreOffMap && ConfigurationControl.sharedInstance.currentApp != HCConfigMetroProp)
    {
        CGFloat statusBarHeight = [self statusBarHeight:UIApplication.sharedApplication.statusBarOrientation];
        _legendScrollView.alpha = 1.0;
        _vectorView.hidden = _legendsAreOffMap = _mapToolbar.isOffset = YES;
        [self updateLegendPositions];
        
        [_mapView constrainToView:self.view leading:0.0 trailing:-_mapViewLegendOffset top:statusBarHeight bottom:0.0];
        [_mapToolbar adjustFrameToScrollView];
        [self updateCompassPosition:YES];
        
        [self refreshVectorView:_mapView.projection.visibleRegion
                                              atZoom:_mapView.camera.zoom];
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
        
        [self refreshVectorView:_mapView.projection.visibleRegion
                         atZoom:_mapView.camera.zoom];
    }
}

- (BOOL)themeLegendIsOffMap
{
    return _legendsAreOffMap;
}

- (void)themeLegendDidWantMinimize
{
    _legendMinimized = YES;
    
    for (ThemeLegendMapOverlay *tlmos in self.view.subviews)
    {
        if ([tlmos isKindOfClass:ThemeLegendMapOverlay.class])
            [tlmos removeFromSuperview];
    }
    
    CGFloat margin = 8.0;
    
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
        margin = 4.0;
    
    CGFloat statusBarHeight = [self statusBarHeight:UIApplication.sharedApplication.statusBarOrientation];
    
    UIButton *minimizeLegend = [UIButton buttonWithType:UIButtonTypeCustom];
    minimizeLegend.tag = 99999;
    minimizeLegend.backgroundColor = _mapToolbar.backgroundColor;
    minimizeLegend.layer.cornerRadius = 10.0;
    minimizeLegend.layer.borderColor = _mapToolbar.layer.borderColor;
    minimizeLegend.layer.borderWidth = _mapToolbar.layer.borderWidth;
    minimizeLegend.titleLabel.font = [UIFont boldSystemFontOfSize:24.0];
    minimizeLegend.titleLabel.adjustsFontSizeToFitWidth = YES;
    [minimizeLegend setTitle:@"L" forState:UIControlStateNormal];
    [minimizeLegend setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    [minimizeLegend setTitleColor:UIColor.darkGrayColor forState:UIControlStateHighlighted];
    
    minimizeLegend.frame = CGRectMake((self.view.frame.size.width - _compassSize - margin),
                                      statusBarHeight + margin, _compassSize, _compassSize);
    
    [minimizeLegend addTarget:self action:@selector(unminimizeLegend:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:minimizeLegend];
}

- (void)unminimizeLegend:(UIButton *)button
{
    [button removeFromSuperview];
    _legendMinimized = NO;
    [self updateLegendPositions];
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
    headerLabel.adjustsFontSizeToFitWidth = YES;
    
    switch (_tableViewSetting)
    {
        case PropertyTableViewSettingOptions:
            headerLabel.numberOfLines = 1;
            headerLabel.text = [NSString stringWithFormat:@"Options for %@", _infoWindow.optionsTitle];
            break;
            
        case PropertyTableViewSettingPropertyReport:
            headerLabel.numberOfLines = 2;
            headerLabel.text = @"Property Report for\nFirst Quarter 2016";
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
            
        default:
            break;
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
            
            [clearMarker addTarget:self action:@selector(prepareToRemoveMarker) forControlEvents:UIControlEventTouchUpInside];
            
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
    
    [self performSelector:@selector(removeMarker)
               withObject:nil
               afterDelay:0.3];
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
    NSString *text = [tableView cellForRowAtIndexPath:indexPath].textLabel.text;
    
    if ([text isEqualToString:@"Property Report"])
    {
        [self showPropReport];
        
        [UserDefaults.defaults saveNSInteger:PropertyTableViewSettingPropertyReport
                                    forKey:@"PIDOption"];
    }
    
    else if ([text isEqualToString:@"Property History"])
    {
        [self showPropHistory];
        [self deselectTableViewRow];
    }
    
    else if ([text isEqualToString:@"Zillow Property Record"])
    {
        [self showZillow];
        
        [UserDefaults.defaults saveNSInteger:PropertyTableViewSettingZillow
                                      forKey:@"PIDOption"];
    }
    
    else if ([text isEqualToString:@"County Property Record"])
    {
        [self showCountyRecord];
        
        [UserDefaults.defaults saveNSInteger:PropertyTableViewSettingCountyRecord
                                      forKey:@"PIDOption"];
    }
    
    else if ([text isEqualToString:@"Display Google Street View"])
    {
        [self showStreetView];
        
        switch (_infoWindow.marker.type)
        {
            case MarkerInfoWindowTypePID:
                [UserDefaults.defaults saveNSInteger:PropertyTableViewSettingStreetView
                                              forKey:@"PIDOption"];
                break;
                
            case MarkerInfoWindowTypeCrime:
                [UserDefaults.defaults saveNSInteger:CrimePointSettingDisplayStreetView
                                              forKey:@"CrimePointOption"];
                break;
                
            default:
                break;
        }
    }
    
    else if ([text isEqualToString:@"Display Bing Streetside"])
    {
        [self showStreetside];
        [self deselectTableViewRow];
    }
    
    else if ([text isEqualToString:@"Zoom to Census Area"])
    {
        [self showCensusArea];
        
        [UserDefaults.defaults saveNSInteger:PropertyTableViewSettingCensusArea
                                      forKey:@"PIDOption"];
    }
    
    else if ([text isEqualToString:@"Color Parcels"])
    {
        [self selectParcelColor];
        
        [UserDefaults.defaults saveNSInteger:PropertyTableViewSettingCensusArea
                                      forKey:@"PIDOption"];
    }
    else if ([text isEqualToString:@"Parcel Text"])
    {
        [self selectParcelText];
        
        [UserDefaults.defaults saveNSInteger:PropertyTableViewSettingCensusArea
                                      forKey:@"PIDOption"];
    }
    else if ([text isEqualToString:@"Add to Property List"])
    {
        [self addToPropList];
        
        [UserDefaults.defaults saveNSInteger:PropertyTableViewSettingPropList
                                      forKey:@"PIDOption"];
    }
    
    else if ([text isEqualToString:@"Add to Destinations"])
    {
        [self addToDestinations];
        
        [UserDefaults.defaults saveNSInteger:PropertyTableViewSettingDestinations
                                      forKey:@"PIDOption"];
    }
    
    else if ([text isEqualToString:@"Route From Current Location"])
    {
        [self dismissTableView];
        
        [self performSelector:@selector(traceRouteFromCurrentLocation)
                   withObject:nil
                   afterDelay:0.3];
    }
    
    else if ([text isEqualToString:@"Perform 3D Route Flyover"])
    {
        [SharedDefaults.defaults saveNSInteger:MarkerInfoWindowTypeStormSewer
                                        forKey:@"FlyOverType"];
        
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
            FILE *tracePolyFile = fopen(filePath, "wb");
            
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
                fclose(tracePolyFile);
                
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
            [SharedDefaults.defaults saveNSInteger:MarkerInfoWindowTypeCrime
                                            forKey:@"FlyOverType"];
            
            CLLocationCoordinate2D centerCoord = _selectedPIDCoords;
            int symbol = _infoWindow.marker.symbol;
            
            FILE *pidPolyFile = fopen(filePath, "wb");
            
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
                fclose(pidPolyFile);
                
                [self perform3DFlyAround];
            }
        }
        
        else
        {
            [SharedDefaults.defaults saveNSInteger:MarkerInfoWindowTypePID
                                            forKey:@"FlyOverType"];
            
            int numPoints = 0, numLoops = 0, *polyPartLen = 0;
            
            CLLocationCoordinate2D centerCoord = _selectedPIDCoords;
            PropertyData *propData = [[PropertyData alloc] init];
            MNMXCORD bounds = [propData getBoundsForPID:_selectedPID];
            
            LPDPOINT llpoints = [propData getParcelPolygonPointsForPID:_selectedPID
                                                             numPoints:&numPoints
                                                              numLoops:&numLoops
                                                           polyPartLen:&polyPartLen];
            
            FILE *pidPolyFile = fopen(filePath, "wb");
            
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
                fclose(pidPolyFile);
                
                [self perform3DFlyAround];
            }
            
            free (llpoints);
        }
    }
    
    else if ([[text substringToIndex:min(text.length,19)] isEqualToString:@"Display Plat"])
    {
        [self dismissTableView];
        _splitPlatView = NO;
        
        [self performSelector:@selector(loadPlat)
                   withObject:nil
                   afterDelay:0.3];
    }
    
    else if ([[text substringToIndex:min(text.length,33)] isEqualToString:@"Display Split Screen Profile to 1"])
    {
        [self dismissTableView];
        _splitPlatView = YES;
        _splitPlatDirection = 0;
        [self performSelector:@selector(loadPlat)
                   withObject:nil
                   afterDelay:0.3];
    }
    
    else if ([[text substringToIndex:min(text.length,33)] isEqualToString:@"Display Split Screen Profile to 2"])
    {
        [self dismissTableView];
        _splitPlatView = YES;
        _splitPlatDirection = 1;
        
        [self performSelector:@selector(loadPlat)
                   withObject:nil
                   afterDelay:0.3];
    }
    
    else if ([text isEqualToString:@"Display Pipe Attributes"])
    {
        [self showPipeAttributes];
        
        [UserDefaults.defaults saveNSInteger:SewerPipeSettingAttributes
                                      forKey:@"SewerOption"];
    }
    
    else if ([text isEqualToString:@"Trace Pipe Upstream"])
    {
        [self dismissTableView];
        
        [self performSelector:@selector(showPipeTraceUpstream)
                   withObject:nil
                   afterDelay:0.3];
        
        [UserDefaults.defaults saveNSInteger:SewerPipeSettingTraceUp
                                      forKey:@"SewerOption"];
    }
    
    else if ([text isEqualToString:@"Trace Pipe Downstream"])
    {
        [self dismissTableView];
        
        [self performSelector:@selector(showPipeTraceDownstream)
                   withObject:nil
                   afterDelay:0.3];
        
        [UserDefaults.defaults saveNSInteger:SewerPipeSettingTraceDown
                                      forKey:@"SewerOption"];
    }
    
    else if ([text isEqualToString:@"Perform Downstream\n3D Fly Over"])
    {
        [SharedDefaults.defaults saveNSInteger:MarkerInfoWindowTypeStormSewer
                                        forKey:@"FlyOverType"];
        
        [self dismissTableView];
        
        [self performSelector:@selector(performDownstreamFlyOver)
                   withObject:nil
                   afterDelay:0.3];
    }
    
    else if ([text isEqualToString:@"Remove Pipe Trace"])
    {
        [self dismissTableView];
        
        [self performSelector:@selector(removePipeTrace)
                   withObject:nil
                   afterDelay:0.3];
    }
    
    else if ([text isEqualToString:@"Update Cleaning Date"])
    {
        [self updateCleaningDate];
        
        [UserDefaults.defaults saveNSInteger:SewerPipeSettingUpdateCleanDate
                                      forKey:@"SewerOption"];
    }
    
    else if ([text isEqualToString:@"Update Inspection Notes"])
    {
        [self updateInspectionNotes];
        
        [UserDefaults.defaults saveNSInteger:SewerPipeSettingUpdateNotes
                                      forKey:@"SewerOption"];
    }
    
    else if ([text isEqualToString:@"Snap to Node"])
    {
        [self snapToNode];
        
        [UserDefaults.defaults saveNSInteger:CustomSettingSnapToNode
                                      forKey:@"CustomOption"];
    }
    
    else if ([text isEqualToString:@"Snap to Line"])
    {
        [self snapToLine];
        
        [UserDefaults.defaults saveNSInteger:CustomSettingSnapToLine
                                      forKey:@"CustomOption"];
    }
    
    else if ([text isEqualToString:@"Move Wall Point"])
    {
        [self dismissTableView];
        
        [self performSelector:@selector(moveWallPoint)
                   withObject:nil
                   afterDelay:0.3];
        
        [UserDefaults.defaults saveNSInteger:AlleyWallSettingMoveWallPoint
                                      forKey:@"AlleyWallOption"];
    }
    
    else if ([text isEqualToString:@"Delete Wall Point"])
    {
        [self deleteWallPoint];
        
        [UserDefaults.defaults saveNSInteger:AlleyWallSettingDeleteWallPoint
                                      forKey:@"AlleyWallOption"];
    }
    
    else if ([text isEqualToString:@"Edit Wall Attributes"])
    {
        [self editWallAttributes];
        
        [UserDefaults.defaults saveNSInteger:AlleyWallSettingEditWallAttributes
                                      forKey:@"AlleyWallOption"];
    }
    
    else if ([text isEqualToString:@"View Wall Photos"])
    {
        [self viewWallPhotos];
        
        [UserDefaults.defaults saveNSInteger:AlleyWallSettingViewWallPhotos
                                      forKey:@"AlleyWallOption"];
    }
    
    else if ([text isEqualToString:@"View Inset Wall Photos"])
    {
        [self dismissTableView];
        
        [self performSelector:@selector(viewInsetWallPhotos)
                   withObject:nil
                   afterDelay:0.3];
        
        [UserDefaults.defaults saveNSInteger:AlleyWallSettingViewInsetWallPhotos
                                      forKey:@"AlleyWallOption"];
    }
    
    else if ([text isEqualToString:@"Toggle Alley Line\nCompletion Status"])
    {
        [self dismissTableView];
        
        [self performSelector:@selector(toggleCompletionStatus)
                   withObject:nil
                   afterDelay:0.3];
        
        [UserDefaults.defaults saveNSInteger:AlleyWallSettingEditWallAttributes
                                      forKey:@"AlleyLineOption"];
    }
    
    else if ([text isEqualToString:@"Alley Centerline Status"])
    {
        [self dismissTableView];
        _alleyStatusSetting = AlleyStatusSettingCenterline;
        
        [self performSelector:@selector(alleyStatus)
                   withObject:nil
                   afterDelay:0.3];
    }
    
    else if ([text isEqualToString:@"Alley Wall Status"])
    {
        [self dismissTableView];
        _alleyStatusSetting = AlleyStatusSettingWall;
        
        [self performSelector:@selector(alleyStatus)
                   withObject:nil
                   afterDelay:0.3];
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
        [self displayCrimeReport];
        
        [UserDefaults.defaults saveNSInteger:CrimePointSettingDisplayReport
                                      forKey:@"CrimePointOption"];
    }
}

- (MGVPlatData *) loadMGVData:(NSString*)line
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

- (NSArray *) getMGVPlatDataByRefno:(int)refno
{
    NSMutableArray * array = NSMutableArray.new;
    NSString * imageFile;
    NSString * manholeID;
    NSString * dataFile = [NSBundle.mainBundle pathForResource:@"SANPTID"
                                        ofType:@"txt"];
    NSString * fileData = [NSString stringWithContentsOfFile:dataFile encoding:NSUTF8StringEncoding error:nil];
    
    NSArray * Lines = [fileData componentsSeparatedByString:@"\r\n"];
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
    dataFile = [NSBundle.mainBundle pathForResource:@"upperlower"
                                                        ofType:@"txt"];
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
                            prevData.rotUpper = 90 - LTWOPI (getaz (prevData.ptUpper,curData.ptUpper)-HALFPI) * RADtoDEG;
                        else
                            prevData.rotUpper = 90 - LTWOPI (getaz (curData.ptUpper,prevData.ptUpper)-HALFPI) * RADtoDEG;
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
                                nextData.rotUpper = 90 - LTWOPI (getaz (nextData.ptUpper,curData.ptUpper)-HALFPI) * RADtoDEG;
                            else
                                nextData.rotUpper = 90 - LTWOPI (getaz (curData.ptUpper,nextData.ptUpper)-HALFPI) * RADtoDEG;
                            nextData.ptUpper = PercentPoint (MidPointD (nextData.ptUpper,curData.ptUpper),curData.imageWidth,curData.imageHeight);
                            nextData.ptLower = PercentPoint (MidPointD (nextData.ptLower,curData.ptLower),curData.imageWidth,curData.imageHeight);
                            [array addObject:nextData];
                        }
                    }
                }
                /*else
                {
                    curData.ptUpper = PercentPoint (curData.ptUpper,curData.imageWidth,curData.imageHeight);
                    curData.ptLower = PercentPoint (curData.ptLower,curData.imageWidth,curData.imageHeight);
                    [array addObject:curData];
                }*/
            }
        }
        index++;
    }
    
    return array;
    
}
- (void)loadPlat
{
    
    NSArray * array = [self getMGVPlatDataByRefno:_selectedMGVSanMH];
//@"ENA_19_87-26_A0.pdf";
    SewerData *sd = [[SewerData alloc] init];
    
    if (array.count > _splitPlatDirection)
    {
        _mgvData = array[_splitPlatDirection];
        if (_mgvData)
        {
            
            [sd loadPlat:_mgvData.pdfFile
                  ofType:@"pdf"
            usingPopover:_popover
             andDelegate:self];
        }
    }
    else
       NSLog (@"Error in load plat"); 
}

- (void)displayCrimeReport
{
    NSString *reportText = [CrimeData reportForControlNumber:_selectedCrime];
    
    NVTextVC *textVC = [[NVTextVC alloc] initWithText:reportText
                                             fontSize:16.0];
    
    [self presentViewController:textVC
                       animated:YES
                     completion:nil];
}

- (void)showPropReport
{
    PropertyData *pd = PropertyData.new;
    _propertyReport = [pd getReport:PDSettingDefault forPID:_selectedPID];
    
    _tableViewSetting = PropertyTableViewSettingPropertyReport;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableView.allowsSelection = NO;
    _tableView.delaysContentTouches = YES;
    [_tableView reloadData];
    [_tableView scrollRectToVisible:CGRectMake(0.0, 0.0, 1.0, 1.0) animated:NO];
}

- (void)showPropHistory
{
    ChartsViewController *chartsVC = ChartsViewController.new;
    chartsVC.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    chartsVC.propHistoryArray = [PropertyData.new getParcelHistory:_selectedPID];
    [self presentViewController:chartsVC animated:YES completion:nil];
}

- (void)showZillow
{
    NSString *houseAndUnit, *streetName, *city, *cenblock, *usedesc;
    CGFloat totEMV;
    
    PropertyData *pd = PropertyData.new;
    
    if ([pd getAddressForPID:_selectedPID
             houseNumAndUnit:&houseAndUnit
                  streetName:&streetName
                        city:&city
                 censusBlock:&cenblock
                     useDesc:&usedesc
                      totEMV:&totEMV])
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
    [self deselectTableViewRow];
    
    [self refreshVectorView:_mapView.projection.visibleRegion
                     atZoom:_mapView.camera.zoom];
}

- (void)showStreetView
{
    _showsPanorama = YES;
    _panView = GMSPanoramaView.new;
    [_panView moveNearCoordinate:_selectedPIDCoords];
    _panView.translatesAutoresizingMaskIntoConstraints = NO;
    _panView.delegate = self;
    _panView.alpha = 0.0;
    
    [self.view addSubview:_panView];
    [_panView constrainToView:self.view leading:0.0 trailing:0.0 top:0.0 bottom:self.tabBarController.tabBar.frame.size.height];
    
    UIButton *dismissPan = [UIButton buttonWithType:UIButtonTypeCustom];
    dismissPan.translatesAutoresizingMaskIntoConstraints = NO;
    dismissPan.backgroundColor = UIColor.clearColor;
    dismissPan.titleLabel.textAlignment = NSTextAlignmentCenter;
    dismissPan.titleLabel.font = [UIFont boldSystemFontOfSize:40.0];
    dismissPan.titleLabel.layer.shadowColor = UIColor.blackColor.CGColor;
    dismissPan.titleLabel.layer.shadowOpacity = 1.0;
    dismissPan.titleLabel.layer.shadowRadius = 3.0;
    dismissPan.titleLabel.layer.shadowOffset = CGSizeZero;
    
    [dismissPan setTitle:@"< Return" forState:UIControlStateNormal];
    [dismissPan setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    [dismissPan setTitleColor:UIColor.lightGrayColor forState:UIControlStateHighlighted];
    
    [_panView addSubview:dismissPan];
    [dismissPan constrainLeadingToAnchor:_panView.leadingAnchor constant:20.0];
    [dismissPan constrainTopToAnchor:_panView.topAnchor constant:20.0];
    
    [dismissPan addTarget:self
                   action:@selector(dismissPanTapped:)
         forControlEvents:UIControlEventTouchUpInside];
    
    [UIView animateWithDuration:0.25 animations:^{
        _panView.alpha = 1.0;
        self.tabBarController.tabBar.alpha = 0.0;
    }];
}

- (void)panoramaView:(GMSPanoramaView *)view
   didMoveToPanorama:(GMSPanorama *)panorama
      nearCoordinate:(CLLocationCoordinate2D)coordinate
{
    CLLocationDirection heading = getHeading(panorama.coordinate, coordinate);
    
    view.camera = [GMSPanoramaCamera cameraWithHeading:heading
                                                 pitch:0.0
                                                  zoom:1.0
                                                   FOV:90.0];
}

- (void)panoramaView:(GMSPanoramaView *)view
               error:(NSError *)error
onMoveNearCoordinate:(CLLocationCoordinate2D)coordinate
{
    NVAlertView *alert = [NVAlertView showLargeAlertViewinView:self.view
                                                      delegate:self
                                                         title:@"Street View is not yet available for this address."
                                               buttonTextArray:@[@"OK"]
                                              destructiveIndex:0];
    
    alert.identifier = @"NoStreetViewAvailable";
}

- (void)dismissPanTapped:(UIButton *)button
{
    [UIView animateWithDuration:0.25 animations:^{
        _panView.alpha = 0.0;
        self.tabBarController.tabBar.alpha = 1.0;
    } completion:^(BOOL finished) {
        [_panView removeFromSuperview];
        [self deselectTableViewRow];
        _showsPanorama = NO;
        
        [self refreshVectorView:_mapView.projection.visibleRegion
                         atZoom:_mapView.camera.zoom];
    }];
}

- (void)showStreetside
{
    NVStreetSideController *nvssc = [NVStreetSideController presentStreetSideInController:self
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
                                              destructiveIndex:0];
    
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
                                              destructiveIndex:0];
    
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
                                              destructiveIndex:0];
    
    alert.identifier = @"ParcelColorAlert";
}

- (void)addToPropList
{
    [self dismissTableView];
    
    PropertyList *pl = [[PropertyList alloc] init];
    [pl addParcelToPropertyList:_selectedPID
                        popover:_popover];
}

- (void)addToDestinations
{
    [self dismissTableView];
    
    Destinations *pl = [[Destinations alloc] init];
    [pl addParcelToDestinations:_selectedPID];
}

- (void)traceRouteFromCurrentLocation
{
    _animateToLocation = NO;
    
    if (CLLocationManager.headingAvailable)
        [_locationManager startUpdatingLocation];
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
        
        data = [data stringByReplacingOccurrencesOfString:@">"
                                               withString:@">\n"];
        
        data = [data stringByReplacingOccurrencesOfString:@"</"
                                               withString:@"\n</"];
        
        data = [data stringByReplacingOccurrencesOfString:@" xsi:"
                                               withString:@"\nxsi:"];
        
        data = [data stringByReplacingOccurrencesOfString:@" https:"
                                               withString:@"\nhttps:"];
        
        data = [data stringByReplacingOccurrencesOfString:@" xmlns:"
                                               withString:@"\nxmlns:"];
        
        NVTextVC *textVC = [[NVTextVC alloc] initWithText:data
                                                 fontSize:16.0];
        
        textVC.clampTextViewToText = YES;
        textVC.zoomingEnabled = NO;
        
        [self presentViewController:textVC
                           animated:YES
                         completion:nil];
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
    NSString *flyOverURL = @"NVFlyover:";
    
    [SharedDefaults.defaults saveString:@"NVMobile:"
                                 forKey:@"FlyoverSourceApplication"];
    
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
    [self deselectTableViewRow];
}

- (void)editWallAttributes
{
    [SharedDefaults.defaults saveString:_selectedAlleyWall
                                 forKey:@"AlleyWallEditAttributes"];
    
    [self dismissTableView];
    
    [self performSelector:@selector(launchAlleyWallApp)
               withObject:nil
               afterDelay:0.3];
}

- (void)viewWallPhotos
{
    NSString *title = [NSString stringWithFormat:@"Photos for AlleyWall %@", _selectedAlleyWall];
    
    NVPhoto *photo1 = [NVPhoto photoWithIdentifier:@"Sample Photo 1"
                                               key:@"Key1"];
    
    NVPhoto *photo2 = [NVPhoto photoWithIdentifier:@"Sample Photo 2"
                                               key:@"Key2"];
    
    NVPhotoController *nvpc = [NVPhotoController photoControllerWithNVPhotosArray:@[(photo1), (photo2)]
                                                                         delegate:self
                                                                            title:title];
    
    [self presentViewController:nvpc
                       animated:YES
                     completion:nil];
}

- (NSString *)imageForKey:(NSString *)key
{
    NSString *rtn = @"";
    
    if ([key isEqualToString:@"Key1"])
    {
        rtn = [NSBundle.mainBundle pathForResource:@"SampleCurbRamp1"
                                            ofType:@"jpg"];
    }
    
    else if ([key isEqualToString:@"Key2"])
    {
        rtn = [NSBundle.mainBundle pathForResource:@"SampleCurbRamp2"
                                            ofType:@"jpg"];
    }
    
    return rtn;
}

- (NSString *)getImagePath:(NVPhotoController *)controller
                    forKey:(NSString *)key
{
    return [self imageForKey:key];
}

- (void)viewInsetWallPhotos
{
    NVPhoto *photo1 = [NVPhoto photoWithIdentifier:@"Sample Photo 1"
                                               key:@"Key1"];
    
    NVPhoto *photo2 = [NVPhoto photoWithIdentifier:@"Sample Photo 2"
                                               key:@"Key2"];
    
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
    
    [awd setAlleyLineStatus:_selectedAlleyLineRefno
                         to:!status];
    
    [self refreshVectorView:_mapView.projection.visibleRegion
                     atZoom:_mapView.camera.zoom];
}

- (void)editIntersectionAttributes
{
    NSString *CRISDetailURL = @"CRISDetail:";
    
    [SharedDefaults.defaults saveString:@"NVMobile"
                                 forKey:@"SourceApplication"];
    
    [SharedDefaults.defaults saveInteger:_selectedCRIntPt.intValue
                                  forKey:@"DetailCurrentIntersection"];
    
    if ([UIApplication.sharedApplication canOpenURL:[NSURL URLWithString:CRISDetailURL]])
        [UIApplication.sharedApplication openURL:[NSURL URLWithString:CRISDetailURL]];
    
    else
    {
        NVAlertView *alert = [NVAlertView showLargeAlertViewinView:self.view
                                                          delegate:self
                                                             title:@"NVMobile cannot launch CRIS Detail"
                                                   buttonTextArray:@[@"OK"]
                                                  destructiveIndex:0];
        
        alert.identifier = @"CannotLaunchCRISDetail";
    }
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
    [self deselectTableViewRow];
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
    [self deselectTableViewRow];
    
    if ([alertView.identifier isEqualToString:@"DeleteWallAlert"])
    {
        if (buttonIndex == 0)
        {
            AlleyWallData *awd = [[AlleyWallData alloc] init];
            
            [awd deleteAlleyWallPoint:_selectedAlleyWallRefno];
            [self dismissTableView];
            [self removePreviousInfoWindow];
            [self removeMarker];
            
            [self refreshVectorView:_mapView.projection.visibleRegion
                             atZoom:_mapView.camera.zoom];
        }
    }
    
    else if ([alertView.identifier isEqualToString:@"CensusZoomAlert"])
    {
        switch (buttonIndex)
        {
            case CensusZoomSettingCancel:
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
            case 5:
                [self dismissTableView];
                CRAPI.sharedInstance.parcelTextOption = (int)buttonIndex;
                
                [self refreshVectorView:_mapView.projection.visibleRegion
                                 atZoom:_mapView.camera.zoom];
                break;
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
                [self dismissTableView];
                CRAPI.sharedInstance.parcelColorOption = (int)buttonIndex;
                
                [self refreshVectorView:_mapView.projection.visibleRegion
                                 atZoom:_mapView.camera.zoom];
                break;
                
            case ParcelColorSettingHomestead:
                CRAPI.sharedInstance.parcelShadingOption = 1;
                break;
                
            case ParcelColorSettingResCom:
                CRAPI.sharedInstance.parcelShadingOption = 2;
                break;
                
            case ParcelColorSettingSpecialAssessment:
                CRAPI.sharedInstance.parcelShadingOption = 3;
                break;
                
            case ParcelColorSettingTaxExempt:
                CRAPI.sharedInstance.parcelShadingOption = 4;
                break;
            case ParcelColorSettingTaxForfeit:
                CRAPI.sharedInstance.parcelShadingOption = 5;
                break;
                
            case 10:
                CRAPI.sharedInstance.parcelShadingOption = 6;
                break;
                
            default:
                break;
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
            [self dismissTableView];
            [self removePreviousInfoWindow];
            [self removeMarker];
            
            [self refreshVectorView:_mapView.projection.visibleRegion
                             atZoom:_mapView.camera.zoom];
        }
    }
    
    else if ([alertView.identifier isEqualToString:@"NoStreetViewAvailable"])
        [self dismissPanTapped:nil];
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
    
    return 20.0;
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
    
    [self animateToCamPos:camera];
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
        [self stopTrackingUserLocation];
    
    else
    {
        if (enabled)
            [self startTrackingUserLocation];
        
        else
            [self stopTrackingUserLocation];
    }
}

- (void)startTrackingUserLocation
{
    if (CLLocationManager.locationServicesEnabled)
        [_locationManager startUpdatingLocation];
    
    [self.view bringSubviewToFront:_myLocationMarker];
}

- (void)stopTrackingUserLocation
{
    [_locationManager stopUpdatingLocation];
    [_mapToolbar deselectMyLocationButton];
    _myLocationMarker.hidden = YES;
}

- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray *)locations
{
    _currentLocation = [locations.firstObject coordinate];
    _locationCount++;
    
    if (_animateToLocation)
    {
        [_mapView animateToLocation:_currentLocation];
        CGPoint target = [_mapView.projection pointForCoordinate:_currentLocation];
        
        _myLocationMarker.center =
        CGPointMake(target.x, target.y + ([self statusBarHeight:UIApplication.sharedApplication.statusBarOrientation]));
        
        _myLocationMarker.hidden = NO;
    }
    
    else if (_locationCount > 2)
    {
        [_locationManager stopUpdatingLocation];
        _animateToLocation = YES;
        
        [self beginLocationRouteTrace];
        
        /*[self getPathDirections:_currentLocation
                withDestination:_selectedPIDCoords
                  transportType:MKDirectionsTransportTypeTransit
                     routeColor:UserDefaults.defaults.appleBlue];*/
    }
}

- (void)getPathDirections:(CLLocationCoordinate2D)source
          withDestination:(CLLocationCoordinate2D)destination
            transportType:(MKDirectionsTransportType)transportType
               routeColor:(UIColor *)routeColor
{
    
    MKPlacemark *placemarkSrc = [[MKPlacemark alloc] initWithCoordinate:source
                                                      addressDictionary:nil];
    
    MKMapItem *mapItemSrc = [[MKMapItem alloc] initWithPlacemark:placemarkSrc];
    
    MKPlacemark *placemarkDest = [[MKPlacemark alloc] initWithCoordinate:destination
                                                       addressDictionary:nil];
    
    MKMapItem *mapItemDest = [[MKMapItem alloc] initWithPlacemark:placemarkDest];
    
    MKDirectionsRequest *request = [[MKDirectionsRequest alloc] init];
    request.source = mapItemSrc;
    request.destination = mapItemDest;
    request.transportType = transportType;
    request.requestsAlternateRoutes = NO;
    
    MKDirections *directions = [[MKDirections alloc] initWithRequest:request];
    
    [directions calculateDirectionsWithCompletionHandler:
     ^(MKDirectionsResponse *response, NSError *error) {
         if (error && ![self.view viewWithTag:888])
         {
             NVAlertView *alert = [NVAlertView showLargeAlertViewinView:self.view
                                                               delegate:self
                                                                  title:error.localizedDescription
                                                        buttonTextArray:@[@"OK"]
                                                       destructiveIndex:0];
             alert.tag = 888;
         }
         
         else
         {
             MKRoute *theRoute = response.routes[0];
             NSUInteger pointCount = theRoute.polyline.pointCount;
             
             CLLocationCoordinate2D *routeCoordinates = malloc(pointCount * sizeof(CLLocationCoordinate2D) + 4);
             
             [theRoute.polyline getCoordinates:routeCoordinates
                                         range:NSMakeRange(0, pointCount)];
             
             GMSMutablePath *path = [[GMSMutablePath alloc] init];
             
             for (int i = 0; i < pointCount; i++)
                 [path addCoordinate:routeCoordinates[i]];
             
             free(routeCoordinates);
             
             _polyline = [GMSPolyline polylineWithPath:path];
             _polyline.strokeWidth = 10.0;
             _polyline.strokeColor = routeColor;
             _polyline.map = _mapView;
             
             GMSCoordinateBounds *bounds = [[GMSCoordinateBounds alloc] initWithPath:path];
             
             GMSCameraUpdate *update = [GMSCameraUpdate fitBounds:bounds
                                                      withPadding:40.0];
             
             [self setMapType];
             [self moveCam:update];
             [self updateMarkerPosition];
             
             _routeTraceExists = YES;
         }
     }];
}

- (void)beginLocationRouteTrace
{
    NSString *urlString =
    [NSString stringWithFormat:@"https://maps.google.com/maps/api/directions/json?origin=%f,%f&destination=%f,%f&sensor=true&mode=transit",
     _currentLocation.latitude, _currentLocation.longitude, _selectedPIDCoords.latitude, _selectedPIDCoords.longitude];
    
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
    
    if (error)
        NSLog(@"JSON error:%@", error.localizedDescription);
    
    else if (![status isEqualToString:@"OK"])
        NSLog(@"JSON error:%@", status);
    
    else
    {
        GMSPath *overviewPath = [GMSPath pathFromEncodedPath:json[@"routes"][0][@"overview_polyline"][@"points"]];
        
        for (GMSPolyline *polylines in _polylines)
            polylines.map = nil;
        
        [_polylines removeAllObjects];
        
        NSDictionary *legs = json[@"routes"][0][@"legs"][0];
        
        NSArray *steps = legs[@"steps"];
        
        for (int i = 0; i < steps.count; i++)
        {
            NSString *travelMode = legs[@"steps"][i][@"travel_mode"];
            
            GMSPath *path = [GMSPath pathFromEncodedPath:legs[@"steps"][i][@"polyline"][@"points"]];
            GMSPolyline *polyline = [GMSPolyline polylineWithPath:path];
            [_polylines addObject:polyline];
            polyline.strokeWidth = 10.0;
            
            if ([travelMode isEqualToString:@"TRANSIT"])
                polyline.strokeColor = UserDefaults.defaults.appleBlue;
            
            else
                polyline.strokeColor = UserDefaults.defaults.darkGreen;
            
            polyline.map = _mapView;
            
            GMSCoordinateBounds *bounds = [[GMSCoordinateBounds alloc] initWithPath:overviewPath];
            
            GMSCameraUpdate *update = [GMSCameraUpdate fitBounds:bounds
                                                     withPadding:40.0];
            
            [self setMapType];
            [self moveCam:update];
            [self updateMarkerPosition];
        }
    }
}

/*
- (void)connection:(nonnull NSURLConnection *)connection
    didReceiveData:(nonnull NSData *)data
{
    NSError *error = nil;
    
    NSDictionary *json =[NSJSONSerialization JSONObjectWithData:data
                                                        options:NSJSONReadingMutableContainers
                                                          error:&error];
    
    if (!error)
    {
        for (GMSPolyline *polylines in _polylines)
            polylines.map = nil;
 
        [_polylines removeAllObjects];
 
        GMSPath *path = [GMSPath pathFromEncodedPath:json[@"routes"][0][@"overview_polyline"][@"points"]];
        _polyline = [GMSPolyline polylineWithPath:path];
        _polyline.strokeWidth = 10.0;
        _polyline.strokeColor = UIColor.greenColor;
        _polyline.map = _mapView;
        
        GMSCoordinateBounds *bounds = [[GMSCoordinateBounds alloc] initWithPath:path];
        
        GMSCameraUpdate *update = [GMSCameraUpdate fitBounds:bounds
                                                 withPadding:40.0];
        
        [self moveCam:update];
        [self updateMarkerPosition];
        
        _routeTraceExists = YES;
    }

    else if (![self.view viewWithTag:888])
    {
        NVAlertView *alert = [NVAlertView showLargeAlertViewinView:self.view
                                                          delegate:self
                                                             title:error.localizedDescription
                                                   buttonTextArray:@[@"OK"]
                                                  destructiveIndex:0];
        alert.tag = 888;
        alert.tabBar = self.tabBarController.tabBar;
    }
}

- (void)connection:(nonnull NSURLConnection *)connection
  didFailWithError:(nonnull NSError *)error
{
    if (![self.view viewWithTag:999])
    {
        NVAlertView *alert = [NVAlertView showLargeAlertViewinView:self.view
                                                          delegate:self
                                                             title:error.localizedDescription
                                                   buttonTextArray:@[@"OK"]
                                                  destructiveIndex:0];
        alert.tag = 999;
        alert.tabBar = self.tabBarController.tabBar;
    }
}
*/

- (void)locationManager:(CLLocationManager *)manager
       didUpdateHeading:(CLHeading *)newHeading
{
    [_mapView animateToBearing:newHeading.trueHeading];
}

- (void)mapToolbarDidSelectClearMarkers
{
    [self dismissTableView];
    
    [self performSelector:@selector(clearMapItems)
               withObject:nil
               afterDelay:0.3];
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
    [self emailPDF];
}

- (void)mapToolbarDidSelectHelpButton
{
    NSString *filePath = [NSBundle.mainBundle pathForResource:@"DOES_NOT_EXIST"
                                                       ofType:@"pdf"];
    
    NVWebView *nvwv = [NVWebView showWebViewInView:self.view
                                    showFileAtPath:filePath];
#pragma unused(nvwv)
}

- (void)mapToolbarDidSelectDigitize
{
    switch (ConfigurationControl.sharedInstance.currentApp)
    {
        case HCConfigAlleyWalls:
            _digitizationMode = DigitizationModeAlleyWallNew;
            break;
            
        case HCConfigMetroProp:
        {
            _digitizationMode = DigitizationModeProperty;
            [self hideMarkersAndInfoWindows:YES];
            [_mapToolbar hide];
            
            _nvdv = [NVDigitizerView showDigitizerInView:self.view
                                       constrainedToView:_mapView
                                                delegate:self];
            return;
        }
        
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
    [self hideMarkersAndInfoWindows:YES];
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
                                 [self refreshVectorView:_mapView.projection.visibleRegion
                                                  atZoom:_mapView.camera.zoom];
                                 
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
                                 [self refreshVectorView:_mapView.projection.visibleRegion
                                                  atZoom:_mapView.camera.zoom];
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
                                 [self refreshVectorView:_mapView.projection.visibleRegion
                                                  atZoom:_mapView.camera.zoom];
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
    
    [self animateToCamPos:camera];
}

- (void)mapToolbarDidFinishDrag:(CGPoint)locationInSuperview
{
    CGFloat statusBarHeight = [self statusBarHeight:UIApplication.sharedApplication.statusBarOrientation];
    CGFloat margin = 8.0;
    NSTimeInterval duration = 0.25;
    
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
    
    else if (_mapToolbar.center.y < (self.view.frame.size.height * 0.25))
    {
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
        [UIView animateWithDuration:0.25
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
}

- (void)restoreMapToolbarPosition
{
    switch (_mapToolbar.orientation)
    {
        case MapToolbarOrientationTop:
        {
            [UIView animateWithDuration:0.25
                             animations:^{
                                 [_mapToolbar animateToHorizontalOrientation];
                                 
                                 _mapToolbar.center = CGPointMake((_mapView.frame.size.width / 2.0),
                                                                  (_mapToolbar.frame.size.height / 2.0) +
                                                                  [self statusBarHeight:UIApplication.sharedApplication.statusBarOrientation]);
                             }];
        }
            break;
            
        case MapToolbarOrientationBottom:
        {
            [UIView animateWithDuration:0.25
                             animations:^{
                                 [_mapToolbar animateToHorizontalOrientation];
                                 
                                 _mapToolbar.center = CGPointMake((_mapView.frame.size.width / 2.0),
                                                                  (self.view.frame.size.height -
                                                                   (_mapToolbar.frame.size.height / 2.0)));
                             }];
        }
            break;
            
        case MapToolbarOrientationLeft:
        {
            [UIView animateWithDuration:0.25
                             animations:^{
                                 [_mapToolbar animateToVerticalOrientation];
                                 
                                 _mapToolbar.center = CGPointMake((_mapToolbar.frame.size.width / 2.0),
                                                                  (self.view.frame.size.height / 2.0));
                             }];
        }
            break;
            
        case MapToolbarOrientationRight:
        {
            [UIView animateWithDuration:0.25
                             animations:^{
                                 [_mapToolbar animateToVerticalOrientation];
                                 
                                 _mapToolbar.center = CGPointMake(_mapView.frame.size.width -
                                                                  (_mapToolbar.frame.size.width / 2.0),
                                                                  (self.view.frame.size.height / 2.0));
                             }];
        }
            break;
            
        default:
            break;
    }
}

- (void)popoverTableViewDidCancel:(NVPopoverTableView *)popoverTableView
{
    [popoverTableView hide:YES];
}

- (void)popoverTableView:(NVPopoverTableView *)popoverTableView
    didSelectRowWithText:(NSString *)text
                 atIndex:(NSInteger)index
{
    [popoverTableView hide:YES];
    
    if ([text isEqualToString:@"View Overall Property Report"])
    {
        
    }
    
    else if ([text isEqualToString:@"Add All Units to Spreadsheet"])
    {
        
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
            if (_infoWindow.marker.nLinks && !_infoWindow.linkedPID)
            {
                PropertyData *pd = PropertyData.new;
                _linkedList = [pd getLinkedParcels:title];
                
                if (_linkedList.count)
                {
                    NSMutableArray *unitList = NSMutableArray.array;
                    [unitList addObject:@"View Overall Property Report"];
                    [unitList addObject:@"Add All Units to Spreadsheet"];
                    
                    for (PropertyDataExtract *ped in _linkedList)
                    {
                        NSString *unitName = ped.unit;
                        
                        if ([unitName isEqualToString:@""] || [unitName isEqualToString:@" "])
                        {
                            NSUInteger index = ([_linkedList indexOfObject:ped] + 1);
                            unitName = [NSString stringWithFormat:@"Select Unit %lu", (unsigned long)index];
                        }
                        
                        else
                            unitName = [NSString stringWithFormat:@"Select Unit %@", unitName];
                        
                        [unitList addObject:unitName];
                    }
                    
                    NVPopoverTableView *nvptv = [NVPopoverTableView showPopoverTableViewInView:self.view
                                                                                      delegate:self
                                                                                         title:@"Multi-Unit Property Options"
                                                                                     textArray:unitList
                                                                                 includeCancel:YES];
#pragma unused(nvptv)
                    return;
                }
            }
            
            _selectedPID = title;
            
            _options = @[@"", @"Property Report", @"Property History", @"Zillow Property Record", @"Display Google Street View",
                         @"Display Bing Streetside", @"Zoom to Census Area", @"Parcel Text", @"Color Parcels", @"Perform 3D Fly Around",
                         @"Add to Property List", @"Add to Destinations", @"Route From Current Location"];
            
            NSMutableArray *newArray = [NSMutableArray arrayWithArray:_options];
            
            if (_routeTraceExists)
            {
                [newArray insertObject:@"Perform 3D Route Flyover"
                               atIndex:8];
                
                _options = newArray;
            }
            
            if (countySupportsLookupForPID(_selectedPID))
            {
                [newArray insertObject:@"County Property Record"
                               atIndex:3];
                
                _options = newArray;
            }
        }
            break;
            
        case MarkerInfoWindowTypeStormSewer:
        {
            _selectedSewerPipe = title;
            
            _options = @[@"", @"Display Pipe Attributes", @"Trace Pipe Upstream",
                         @"Trace Pipe Downstream", @"Remove Pipe Trace", @"Update Cleaning Date",
                         @"Update Inspection Notes"];
           
            PipeTrace *pipeTrace = PipeTrace.new;
            
            if (pipeTrace.havePipeTrace)
            {
                NSMutableArray *newArray = [NSMutableArray arrayWithArray:_options];
                
                [newArray insertObject:@"Perform Downstream\n3D Fly Over"
                               atIndex:3];
                
                _options = newArray;
            }
        }
            break;
            
        case MarkerInfoWindowTypeAlleyWall:
            _selectedAlleyWall = title;
            _selectedAlleyWallRefno = refno;
            
            _options = @[@"", @"Move Wall Point", @"Delete Wall Point",
                         @"Edit Wall Attributes", @"View Wall Photos"];
            
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
                _options = newArray;
            }
            
            break;
            
        case MarkerInfoWindowTypeAlleyLine:
            _selectedAlleySeg = title;
            _selectedAlleyLineRefno = refno;
            _options = @[@"", @"Toggle Alley Line\nCompletion Status"];
            break;
            
        case MarkerInfoWindowTypeCRInt:
            _selectedCRIntPt = title;
            
            _options = @[@"", @"Edit Intersection Attributes",
                         @"Edit Intersection Status"];
            break;
            
        case MarkerInfoWindowTypeCustom:
            _options = @[@"", @"Snap to Node", @"Snap to Line"];
            break;
            
        case MarkerInfoWindowTypeCrime:
        {
            _selectedCrime = refno;
            _options = @[@"", @"Display Report", @"Display Google Street View"];
            
            NSMutableArray *newArray = [NSMutableArray arrayWithArray:_options];
            
            [newArray insertObject:@"Perform 3D Fly Around"
                           atIndex:2];
            
            _options = newArray;
        }
            break;
            
        case MarkerInfoWindowTypeMGVSanPoint:
        {
            _options = @[@""];
            NSMutableArray *newArray = [NSMutableArray arrayWithArray:_options];
            BOOL splitPlatViewSave = _splitPlatView;
            _splitPlatView = TRUE;
            NSArray * array = [self getMGVPlatDataByRefno:_selectedMGVSanMH];
            _splitPlatView = splitPlatViewSave;
            if (!array.count)
                break;
            [newArray addObject:@"Display Plat"];
            [newArray addObject:@"Display Split Screen Profile to 1"];
            if (array.count > 1)
                [newArray addObject:@"Display Split Screen Profile to 2"];
            
            _options = newArray;
        }
            break;
            
        case MarkerInfoWindowTypeMGVSanMain:
        {
            _options = @[@""];
            NSMutableArray *newArray = [NSMutableArray arrayWithArray:_options];
            BOOL splitPlatViewSave = _splitPlatView;
            _splitPlatView = TRUE;
            NSArray * manholes = [_selectedSanMain componentsSeparatedByString:@"-"];
            NSArray * array = [self getMGVPlatDataByRefno:_selectedMGVSanPipe];
            _splitPlatView = splitPlatViewSave;
            if (array.count)
            {
                
            }
            [newArray addObject:@"Display Plat"];
            [newArray addObject:@"Display Split Screen Profile Along Pipe"];
            
            _options = newArray;
        }
            break;
            
        default:
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
    _selectedPIDCoords = coords;
    
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
                    
                case PropertyTableViewSettingZillow:
                    [self showZillow];
                    break;
                    
                case PropertyTableViewSettingCountyRecord:
                    [self showCountyRecord];
                    break;
                    
                case PropertyTableViewSettingStreetView:
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
            
        case MarkerInfoWindowTypeCrime:
        {
            option = [UserDefaults.defaults integerForKey:@"CrimePointOption"];
            
            switch (option)
            {
                case CrimePointSettingDisplayReport:
                    [self displayCrimeReport];
                    break;
                    
                case CrimePointSettingDisplayStreetView:
                    [self showStreetView];
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
                             _mapToolbar.alpha = 0.0;
                         }];
    }
}

- (void)compassTapped:(UIButton *)button
{
    [_mapView animateToBearing:0.0];
}

- (void)hideCompass
{
    if (!_compass.hidden)
    {
        [UIView animateWithDuration:0.25
                         animations:^{
                             _compass.alpha = 0.0;
                         } completion:^(BOOL finished) {
                             _compass.hidden = YES;
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
    NSString *AlleyWallURL = @"NVAlleyWalls:";
    
    [SharedDefaults.defaults saveString:@"NVMobile"
                                 forKey:@"SourceApplication"];
    
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

BOOL CLLocationCoordinateEqual(CLLocationCoordinate2D coordinate1, CLLocationCoordinate2D coordinate2)
{
    return (fabs(coordinate1.latitude - coordinate2.latitude) < 0.00001) &&
           (fabs(coordinate1.longitude - coordinate2.longitude) < 0.00001);
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
    
    CRAPI.sharedInstance.organizationName = topText;
    CRAPI.sharedInstance.deviceNumber = (int)bottomText.integerValue;

    [twoTextAlert hideTwoTextAlert:YES];
}

- (void)NVDataLoaderFailed:(int)status
{
    _nvdl.popover = nil;
    _nvdl.delegate = nil;
    _nvdl = nil;
}

- (void)NVDataLoaderSuccess
{
    _nvdl.popover = nil;
    _nvdl.delegate = nil;
    _nvdl = nil;
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
    
    GMSCameraUpdate *update = [GMSCameraUpdate fitBounds:bounds
                                             withPadding:20.0];
    
    [_mapView animateWithCameraUpdate:update];
}

- (NVWebView *)webViewWithTag:(NSInteger)tag
{
    if ([[self.view viewWithTag:tag] isKindOfClass:NVWebView.class])
        return [self.view viewWithTag:tag];
    
    else
        return nil;
}

- (void)moveCam:(GMSCameraUpdate *)update
{
    [_mapView moveCamera:update];
}

- (void)animateToCamPos:(GMSCameraPosition *)camera
{
    [_mapView animateToCameraPosition:camera];
}

- (void)tabBarController:(UITabBarController *)tabBarController
 didSelectViewController:(UIViewController *)viewController
{
    if (viewController == self && ConfigurationControl.sharedInstance.currentApp == HCConfigMapleGrovePDF)
        [self mapToolbarDidSelectSplitScreenSetting:MapViewScreenSettingFullscreen];
}

@end
