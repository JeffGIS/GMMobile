//  MapViewController.m
//  GMMobile

#import "MapViewController.h"

@interface MapViewController ()

@property (nonatomic) GSSiTileOverlay *osmOverlay;
@property (nonatomic) GSSiTileOverlay *gmmOverlay;
@property (nonatomic) MKMapCamera *camera;

@end

@implementation MapViewController

@synthesize coordinate;
@synthesize boundingMapRect;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _mapView.delegate = self;
    
    CLLocationCoordinate2D target = CLLocationCoordinate2DMake(44.97, -93.27);
    
    _camera = [MKMapCamera cameraLookingAtCenterCoordinate:target//camera target (center point)
                                         fromEyeCoordinate:target//camera position (affects pitch)
                                               eyeAltitude:20000.0];//meters above ground (inversely affects zoom)
    
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
    if (mapView.camera.altitude < 550.0)
    {
       _camera = [MKMapCamera cameraLookingAtCenterCoordinate:mapView.centerCoordinate
                                            fromEyeCoordinate:mapView.centerCoordinate
                                                  eyeAltitude:550.0];
        
        mapView.camera = _camera;
    }
}

@end