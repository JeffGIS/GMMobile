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

@end

@implementation MapViewController

@synthesize coordinate;
@synthesize boundingMapRect;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    CLLocationCoordinate2D target = CLLocationCoordinate2DMake(44.97, -93.27);
    
    _camera = [MKMapCamera cameraLookingAtCenterCoordinate:target//camera target (center point)
                                         fromEyeCoordinate:target//camera position (affects pitch)
                                               eyeAltitude:20000.0];//meters above ground (inversely affects zoom)
    
    _mapView.delegate = self;
    _mapView.camera = _camera;
    
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
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

- (void)didDoubleTapMap:(UIGestureRecognizer *)gesture
{
    NSLog(@"The map was double tapped");
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
    CLLocationCoordinate2D target;
    
    switch (segmentedControl.selectedSegmentIndex)
    {
        case 0:
            _mapView.userTrackingMode = MKUserTrackingModeFollowWithHeading;
            _mapView.rotateEnabled = NO;
            break;
            
        case 1:
            _mapView.userTrackingMode = MKUserTrackingModeNone;
            _mapView.rotateEnabled = YES;
            
            target = CLLocationCoordinate2DMake(44.97, -93.27);
            
            _camera = [MKMapCamera cameraLookingAtCenterCoordinate:target
                                                 fromEyeCoordinate:target
                                                       eyeAltitude:36000.0];
            
            [_mapView setCamera:_camera
                       animated:YES];
            break;
    }
}

@end