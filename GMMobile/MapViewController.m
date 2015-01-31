//  MapViewController.m
//  GMMobile

#import "MapViewController.h"

@interface MapViewController ()

@property (nonatomic) GSSiTileOverlay *osmOverlay;
@property (nonatomic) GSSiTileOverlay *gmmOverlay;
@property (nonatomic) MKMapCamera *camera;
@property (nonatomic) UITapGestureRecognizer *doubleTap;
@property (nonatomic) CLLocationManager *locationManager;
@property (nonatomic) CLLocationCoordinate2D target;
@property (nonatomic) PropertyData *propData;

@end

@implementation MapViewController

@synthesize coordinate;
@synthesize boundingMapRect;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setupButton:_zoomToExtentButton];
    [self setupButton:_userLocationButton];
    
    _cityInnerBounds.origin.x = 64631097;
    _cityInnerBounds.origin.y = 96565088;
    _cityInnerBounds.size.width = 83010;
    _cityInnerBounds.size.height = 103220;
    _propData = [[PropertyData alloc] init];
    _mapView.delegate = self;
    _mapView.showsUserLocation = YES;
    _target = CLLocationCoordinate2DMake(44.97, -93.27);
    
    [self extentZoom:NO];
    
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
    
    [self extentZoom:YES];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (CRAPI.sharedInstance.GMMSetting == GMMSettingPID)
    {
        [self extentZoom:NO];
        
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

- (void)extentZoom:(BOOL)animated
{
    _camera = [MKMapCamera cameraLookingAtCenterCoordinate:_target
                                         fromEyeCoordinate:_target
                                               eyeAltitude:36000.0];
    
    [_mapView setCamera:_camera
               animated:animated];
}

- (void)setupButton:(UIButton *)button
{
    button.layer.cornerRadius = 10.0;
    button.layer.borderColor = UIColor.blackColor.CGColor;
    button.layer.borderWidth = 2.0;
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

- (IBAction)userLocation:(id)sender
{
    [_mapView setUserTrackingMode:MKUserTrackingModeFollowWithHeading
                         animated:YES];

    _mapView.rotateEnabled = NO;
}

- (IBAction)zoomToExtent:(id)sender
{
    [_mapView setUserTrackingMode:MKUserTrackingModeNone
                         animated:NO];
    
    _mapView.rotateEnabled = YES;
    
    [self extentZoom:YES];
}

@end