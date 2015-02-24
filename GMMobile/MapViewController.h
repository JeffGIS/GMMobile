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

@interface MapViewController : UIViewController <MKMapViewDelegate,GSSiOverlay,UIGestureRecognizerDelegate,UITableViewDataSource,UITableViewDelegate,PlatViewDelegate,GSSiAlertDelegate,VectorViewDelegate,MapToolbarDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic) MKMapRect cityInnerBounds;
@property (nonatomic) int currentZoom;
@property (weak, nonatomic) IBOutlet UIButton *exitStreetView;

@end