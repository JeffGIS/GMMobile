//  MapViewController.h
//  GMMobile

#import "CCodeLibrary/CCodeLibrary.h"
#import "FindViewController.h"
#import "PropertyData.h"
#import "BoundaryData.h"
#import "PlanimetricData.h"
#import "PipeTrace.h"
#import "VectorView.h"
#import "PlatImageView.h"
#import "PlatProfileView.h"
#import "LayersViewController.h"
#import "CCodeLibrary/MapToolbar.h"
#import <GoogleMaps/GoogleMaps.h>
#import "MarkerInfoWindow.h"
#import "MarkerButton.h"
#import "PropertyList.h"
#import "CrimeList.h"
#import "Destinations.h"
#import "NVDataLoader.h"
#import "CCodeLibrary/NVAlertView.h"
#import "ThemeLegendMapOverlay.h"

@interface MapViewController : UIViewController <GMSMapViewDelegate,UIGestureRecognizerDelegate,UITableViewDataSource,UITableViewDelegate,NVAlertViewDelegate, MapToolbarDelegate,VectorViewDelegate,CLLocationManagerDelegate,MarkerInfoWindowDelegate,PipeTraceDelegate,MarkerButtonDelegate,PlatImageViewDelegate,GSSiNotesViewDelegate,NVLegendViewDelegate,NVTwoTextAlertDelegate,NVDataLoaderDelegate,NSURLConnectionDataDelegate,ThemeLegendMapOverlayDelegate,CrimeDataDelegate>

typedef NS_ENUM(NSInteger, NVMarkerStyle)
{
    NVMarkerStyleMarkerOnly,
    NVMarkerStyleMarkerPlusOptions,
    NVMarkerStyleOptionsOnly,
};

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic) MKMapRect cityInnerBounds;
@property BOOL fromSpreadsheet, fromLegends;
@property (nonatomic) CLLocationCoordinate2D spreadsheetCoords;
@property (nonatomic) GMSMapView *mapView;
@property NSUInteger fromIndex;
@property (nonatomic) NSArray <PropertyRecord *> *propArray;

- (void)refreshVectorView:(GMSVisibleRegion)region
                   atZoom:(CGFloat)zoom;

@end
