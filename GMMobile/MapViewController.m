//  MapViewController.m
//  GMMobile

#import "MapViewController.h"

@interface MapViewController ()

@property (nonatomic) GSSiTileOverlay *osmOverlay;
@property (nonatomic) GSSiTileOverlay *gmmOverlay;

@end

@implementation MapViewController

@synthesize coordinate;
@synthesize boundingMapRect;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _mapView.delegate = self;
    MKCoordinateRegion region = {{44.97, -93.27}, {0.12, 0.12}};
    _mapView.region = region;
    
    NSString *osm = @"http://tile.openstreetmap.org/{z}/{x}/{y}.png";
    _osmOverlay = [[GSSiTileOverlay alloc] initWithURLTemplate:osm];
    _osmOverlay.canReplaceMapContent = YES;
    _osmOverlay.minimumZ = 0;
    _osmOverlay.maximumZ = 13;
    _osmOverlay.type = @"OSM";
    
    [_mapView addOverlay:_osmOverlay
                   level:MKOverlayLevelAboveLabels];
    
    //NSString *gmm = @"http://www.gssidata.com/MPLS/{z}/{y}/{x}.png";
    NSString *gmm = @"http://74.36.108.94/icons/MPLS/{z}/{y}/{x}.png";
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

@end