//  MapViewController.h
//  GMMobile

@import GoogleMaps;
@import MapKit;
#import "PropertyData.h"

@interface MapViewController : UIViewController

typedef NS_ENUM(NSInteger, NVMarkerStyle)
{
    NVMarkerStyleMarkerOnly,
    NVMarkerStyleMarkerPlusOptions,
    NVMarkerStyleOptionsOnly,
};

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property MKMapRect cityInnerBounds;
@property BOOL fromSpreadsheet, fromLegends;
@property CLLocationCoordinate2D spreadsheetCoords;
@property (nonatomic) GMSMapView *mapView;
@property NSUInteger fromIndex;
@property (nonatomic, copy) NSArray *propArray;
@property (nonatomic) GSSiPopoverView *popover;
@property CLLocationCoordinate2D northeast;
@property CLLocationCoordinate2D southwest;
@property UIEdgeInsets inset;

- (void)refreshVectorView:(GMSVisibleRegion)region
                   atZoom:(CGFloat)zoom;

@end
