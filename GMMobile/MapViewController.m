//  MapViewController.m
//  GMMobile

#import "MapViewController.h"

@interface MapViewController ()

@property (nonatomic) GSSiTileOverlay *osmOverlay;
@property (nonatomic) GSSiTileOverlay *gmmOverlay;
@property (nonatomic) MKMapCamera *camera;
@property (nonatomic) UITapGestureRecognizer *doubleTap;
@property (nonatomic) CLLocationManager *locationManager;
@property (nonatomic) UISegmentedControl *segmentedControl;
@property (nonatomic) CLLocationCoordinate2D target;
@property (nonatomic) PropertyData *propData;

@end

@implementation MapViewController

@synthesize coordinate;
@synthesize boundingMapRect;

- (void)viewDidLoad
{
    [super viewDidLoad];
    _cityInnerBounds.origin.x = 64631097;
    _cityInnerBounds.origin.y = 96565088;
    _cityInnerBounds.size.width = 83010;
    _cityInnerBounds.size.height = 103220;
    _target = CLLocationCoordinate2DMake(44.97, -93.27);
    _propData = [[PropertyData alloc] init];
    
    _camera = [MKMapCamera cameraLookingAtCenterCoordinate:_target//camera target (center point)
                                         fromEyeCoordinate:_target//camera position (affects pitch)
                                               eyeAltitude:22000.0];//meters above ground (inversely affects zoom)
    
    _mapView.delegate = self;
    
    [_mapView setCamera:_camera
               animated:NO];
    
    NSString *osm = @"http://tile.openstreetmap.org/{z}/{x}/{y}.png";
    _osmOverlay = [[GSSiTileOverlay alloc] initWithURLTemplate:osm];
    _osmOverlay.canReplaceMapContent = YES;
    _osmOverlay.minimumZ = 0;
    _osmOverlay.maximumZ = 19;
    _osmOverlay.type = @"OSM";
    
    [_mapView addOverlay:_osmOverlay
                   level:MKOverlayLevelAboveLabels];
    
    NSString *gmm = @"http://www.gssidata.com/MPLS/{z}/{y}/{x}.png";
    //NSString *gmm = @"http://74.36.108.94/icons/MPLS/{z}/{y}/{x}.png";
    _gmmOverlay = [[GSSiTileOverlay alloc] initWithURLTemplate:gmm];
    _gmmOverlay.canReplaceMapContent = YES;
    _gmmOverlay.minimumZ = 12;
    _gmmOverlay.maximumZ = 19;
    _gmmOverlay.type = @"GMM";
    
    [_mapView addOverlay:_gmmOverlay
                   level:MKOverlayLevelAboveLabels];
    
    _doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                         action:@selector(didDoubleTapMap:)];
    _doubleTap.numberOfTapsRequired = 2;
    _doubleTap.numberOfTouchesRequired = 1;
    _doubleTap.delegate = self;
    [_mapView addGestureRecognizer:_doubleTap];
    
    _locationManager = [[CLLocationManager alloc] init];
    
    if ([_locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)])
        [_locationManager requestWhenInUseAuthorization];
    
    [self setupSegmentedControl];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (CRAPI.sharedInstance.GMMSetting == GMMSettingPID)
    {
        _camera = [MKMapCamera cameraLookingAtCenterCoordinate:_target
                                             fromEyeCoordinate:_target
                                                   eyeAltitude:36000.0];
        
        [_mapView setCamera:_camera
                   animated:NO];
        
        LLPOINT pidPoint = [_propData getPointForPID:CRAPI.sharedInstance.currentPID];
        CLLocationCoordinate2D pidCoord;
        pidCoord.latitude = pidPoint.lat;
        pidCoord.longitude = pidPoint.lon;
        
        _camera = [MKMapCamera cameraLookingAtCenterCoordinate:pidCoord
                                             fromEyeCoordinate:pidCoord
                                                   eyeAltitude:550.0];
        
        [_mapView setCamera:_camera
                   animated:YES];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (GSSiTileOverlayRenderer *)mapView:(MKMapView *)mapView
            rendererForOverlay:(id <GSSiOverlay>)overlay
{
    GSSiTileOverlayRenderer *renderer = [[GSSiTileOverlayRenderer alloc] initWithTileOverlay:overlay];
    return renderer;
}

- (void)mapView:(MKMapView *)mapView
regionDidChangeAnimated:(BOOL)animated
{
    if (mapView.camera.altitude < 549.9)
        {
            _camera = [MKMapCamera cameraLookingAtCenterCoordinate:mapView.centerCoordinate
                                                 fromEyeCoordinate:mapView.centerCoordinate
                                                       eyeAltitude:550.0];
        
            mapView.camera = _camera;
        }
    
    MKMapRect rect = mapView.visibleMapRect;
    MKMapRect intRect = MKMapRectUnion(rect,_cityInnerBounds);
    
    if (MKMapRectEqualToRect(intRect, _cityInnerBounds))
        _osmOverlay.maximumZ = 12;
    
    else
        _osmOverlay.maximumZ = 19;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

- (void)didDoubleTapMap:(UIGestureRecognizer *)gesture
{
    CGPoint pointPicked = [gesture locationInView:_mapView];
    
    CLLocationCoordinate2D coordPicked = [_mapView convertPoint:pointPicked
                                           toCoordinateFromView:_mapView];
    
    LLPOINT llp;
    llp.lat = coordPicked.latitude;
    llp.lon = coordPicked.longitude;
    
    NSString *PIDString = [_propData pickPID:llp];
    MKPointAnnotation *annotation = [[MKPointAnnotation alloc] init];
    annotation.coordinate = coordPicked;
    annotation.title = PIDString;
    [_mapView addAnnotation:annotation];
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView
            viewForAnnotation:(id <MKAnnotation>)annotation
{
    MKAnnotationView *annotationView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation
                                                                       reuseIdentifier:@"loc"];
    
    annotationView.canShowCallout = YES;
    annotationView.selected = YES;
    annotationView.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    return annotationView;
}

- (void)setupSegmentedControl
{
    CGFloat width = (self.view.frame.size.width / 3.8);
    _segmentedControl = [[UISegmentedControl alloc] initWithItems:@[@"My Location", @"Zoom to Extent"]];
    
    _segmentedControl.frame = CGRectMake(10.0, 26.0, width, (self.view.frame.size.height / 25.6));
    
    _segmentedControl.backgroundColor = UIColor.whiteColor;
    _segmentedControl.selectedSegmentIndex = 1;
    [self.view addSubview:_segmentedControl];
    
    [_segmentedControl addTarget:self
                          action:@selector(segmentedControlTapped:)
                forControlEvents:UIControlEventValueChanged];
}

- (void)segmentedControlTapped:(UISegmentedControl *)segmentedControl
{
    switch (segmentedControl.selectedSegmentIndex)
    {
        case 0:
            _mapView.userTrackingMode = MKUserTrackingModeFollowWithHeading;
            _mapView.rotateEnabled = NO;
            break;
            
        case 1:
            _mapView.userTrackingMode = MKUserTrackingModeNone;
            _mapView.rotateEnabled = YES;
            
            _camera = [MKMapCamera cameraLookingAtCenterCoordinate:_target
                                                 fromEyeCoordinate:_target
                                                       eyeAltitude:36000.0];
            
            [_mapView setCamera:_camera
                       animated:YES];
            break;
    }
}

@end