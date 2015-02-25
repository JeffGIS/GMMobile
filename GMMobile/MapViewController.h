//  MapViewController.h
//  GMMobile

#import "GSSiTileOverlay.h"
#import "../../CCodeLibrary/CCodeLibrary/CCodeLibrary.h"
#import "FindViewController.h"
#import "PropertyData.h"
#import "SewerData.h"
#import "VectorView.h"
#import "PlatView.h"
#import "GSSiTileOverlayRenderer.h"
#import "LayersViewController.h"
#import "MapToolbar.h"
#import <GoogleMaps/GoogleMaps.h>

@interface MapViewController : UIViewController <GMSMapViewDelegate,GSSiOverlay,UIGestureRecognizerDelegate,UITableViewDataSource,UITableViewDelegate,PlatViewDelegate,GSSiAlertDelegate, MapToolbarDelegate,VectorViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic) MKMapRect cityInnerBounds;
@property (nonatomic) int currentZoom;
@property (weak, nonatomic) IBOutlet UIButton *exitStreetView;

@end