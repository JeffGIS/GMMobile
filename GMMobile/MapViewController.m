//  MapViewController.m
//  GMMobile

#import "MapViewController.h"

@interface MapViewController ()

@property (nonatomic) MKTileOverlay *overlay;

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
    
    NSString *template = @"http://tile.openstreetmap.org/{z}/{x}/{y}.png";
    _overlay = [[MKTileOverlay alloc] initWithURLTemplate:template];
    _overlay.canReplaceMapContent = YES;
        
    [_mapView addOverlay:_overlay
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