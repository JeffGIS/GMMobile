//  MapViewController.m
//  GMMobile

#import "MapViewController.h"

@interface MapViewController ()

@property (nonatomic) GSSiTileOverlay *osmOverlay;
@property (nonatomic) GSSiTileOverlay *gmmOverlay;
@property (nonatomic) MKMapCamera *camera;
@property (nonatomic) UITapGestureRecognizer *doubleTap;
@property (nonatomic) CLLocationCoordinate2D target;
@property (nonatomic) BOOL clearAnnotations;
@property (nonatomic) PropertyData *propData;
@property BOOL firstTime;

@end

@implementation MapViewController

@synthesize coordinate;
@synthesize boundingMapRect;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _firstTime = YES;
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
    //NSString *gmm = @"http://74.42.137.128/icons/MPLS/{z}/{y}/{x}.png";
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
    
    _firstTime = NO;
    [self extentZoom:YES];
    [self.view bringSubviewToFront:_vectorView];
    
    [self setupButton:_zoomToExtentButton];
    [self setupButton:_userLocationButton];
    [self.view bringSubviewToFront:_annotationSwitch];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (CRAPI.sharedInstance.GMMSetting == GMMSettingPID ||
        CRAPI.sharedInstance.GMMSetting == GMMSettingAddress)
    {
        NSString *currentPID = CRAPI.sharedInstance.currentPID;
        LLPOINT pidPoint = [_propData getPointForPID:currentPID];
        CLLocationCoordinate2D pidCoord;
        pidCoord.latitude = pidPoint.lat;
        pidCoord.longitude = pidPoint.lon;
        
        _camera = [MKMapCamera cameraLookingAtCenterCoordinate:pidCoord
                                             fromEyeCoordinate:pidCoord
                                                   eyeAltitude:550.0];
        
        [_mapView setCamera:_camera
                   animated:YES];
        
        MKPointAnnotation *annotation = [[MKPointAnnotation alloc] init];
        annotation.coordinate = pidCoord;
        
        if (CRAPI.sharedInstance.GMMSetting == GMMSettingPID)
            annotation.title = currentPID;
        
        else
            annotation.title = CRAPI.sharedInstance.currentAddress;
        
        annotation.subtitle = [_propData getOwnerNameForPID:currentPID];
        [self addAnnotation:annotation];
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
    [self.view bringSubviewToFront:button];
}

- (MKTileOverlayRenderer *)mapView:(MKMapView *)mapView
            rendererForOverlay:(id <GSSiOverlay>)overlay
{
    MKTileOverlayRenderer *renderer = [[MKTileOverlayRenderer alloc] initWithTileOverlay:overlay];
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
    MKMapRect visRect = mapView.visibleMapRect;
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
    CGFloat wantScale = GroundResolution(latlon1.latitude, 19);
    
 /*   if (mapView.camera.altitude < 299.0)
        {
            _camera = [MKMapCamera cameraLookingAtCenterCoordinate:mapView.centerCoordinate
                                                 fromEyeCoordinate:mapView.centerCoordinate
                                                       eyeAltitude:300.0];
        
            mapView.camera = _camera;
        }*/
    
    _camera = mapView.camera;
    _camera = mapView.camera;
    MKMapRect intRect = MKMapRectUnion(visRect,_cityInnerBounds);
    
    if (MKMapRectEqualToRect(intRect, _cityInnerBounds))
        _osmOverlay.maximumZ = 12;
    
    else
        _osmOverlay.maximumZ = 19;

    if (!_firstTime)
        [self refreshVectorView:region];
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
    annotation.subtitle = [_propData getOwnerNameForPID:PIDString];
    [self addAnnotation:annotation];
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
        NSLog(@"right callout tapped");
    
    else if (control == view.leftCalloutAccessoryView)
        NSLog(@"left callout tapped");
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

- (void)clearVectorView
{
    _vectorView.displayData = 0;
    [_vectorView setNeedsDisplay];
}

- (void)refreshVectorView:(MKCoordinateRegion) region
{
    MNMXCORD llBounds;
    _vectorView.displayData = 1;
    llBounds.xmn = (region.center.longitude - region.span.longitudeDelta / 2.0);
    llBounds.xmx = (region.center.longitude + region.span.longitudeDelta / 2.0);
    llBounds.ymn = (region.center.latitude - region.span.latitudeDelta / 2.0);
    llBounds.ymx = (region.center.latitude + region.span.latitudeDelta / 2.0);
    _vectorView.latlonBounds = llBounds;
    [_vectorView setNeedsDisplay];
}

- (IBAction)toggleAnnotationState:(id)sender
{
    if (_annotationSwitch.on)
        _clearAnnotations = NO;
    
    else
        _clearAnnotations = YES;
}

- (void)addAnnotation:(id<MKAnnotation>)annotation
{
    if (_clearAnnotations)
    {
        for (id<MKAnnotation> annotation in _mapView.annotations)
        {
            if (![annotation isKindOfClass:MKUserLocation.class])
                [_mapView removeAnnotation:annotation];
        }
    }
    
    [_mapView addAnnotation:annotation];
    
    [_mapView selectAnnotation:annotation
                      animated:NO];
}

@end