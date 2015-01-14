//  MapViewController.m
//  GMMobile

#import "MapViewController.h"

@interface MapViewController ()

@property (nonatomic) MKTileOverlay *osmOverlay;
@property (nonatomic) MKTileOverlay *gmmOverlay;

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
    NSString *gmm = @"http://www.thmgis.com/waypoint/CITYMPLS/MPLS/{z}/{y}/{x}.png";
    _osmOverlay = [[MKTileOverlay alloc] initWithURLTemplate:osm];
    _gmmOverlay = [[MKTileOverlay alloc] initWithURLTemplate:gmm];
    _osmOverlay.canReplaceMapContent = YES;
    _gmmOverlay.canReplaceMapContent = YES;
        
    [_mapView addOverlay:_osmOverlay
                   level:MKOverlayLevelAboveLabels];
    
    [_mapView addOverlay:_gmmOverlay
                   level:MKOverlayLevelAboveLabels];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView
            rendererForOverlay:(id <MKOverlay>)overlay
{
    if ([overlay isKindOfClass:MKTileOverlay.class])
        return [[MKTileOverlayRenderer alloc] initWithTileOverlay:overlay];
    
    return nil;
}

@end