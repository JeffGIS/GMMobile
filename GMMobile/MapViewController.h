//  MapViewController.h
//  GMMobile

#import "CCodeLibrary/CCodeLibrary.h"
#import "FindViewController.h"
#import "PropertyData.h"
#import "SewerData.h"
#import "PlanimetricData.h"
#import "AlleyWallData.h" 
#import "PipeTrace.h"
#import "VectorView.h"
#import "PlatImageView.h"
#import "PlatProfileView.h"
#import "LayersViewController.h"
#import "MapToolbar.h"
#import <GoogleMaps/GoogleMaps.h>
#import "MarkerInfoWindow.h"
#import "MarkerButton.h"
#import "PropertyList.h"
#import "NVDataLoader.h"
#import <MessageUI/MessageUI.h>

typedef struct NVPolygonData {
    MNMXCORD bounds;
    DPOINT basePoint;
    int numPoints;
    int numLoops;
    LPDPOINT llpoints;
} NVPolygonData;

@interface MapViewController : UIViewController <GMSMapViewDelegate,UIGestureRecognizerDelegate,UITableViewDataSource,UITableViewDelegate,GSSiAlertDelegate, MapToolbarDelegate,VectorViewDelegate,CLLocationManagerDelegate,MarkerInfoWindowDelegate,PipeTraceDelegate,MarkerButtonDelegate,PlatImageViewDelegate,GSSiNotesViewDelegate,NVLargeAlertViewDelegate,NVLegendViewDelegate,NVTwoTextAlertDelegate, NVDataLoaderDelegate,MFMailComposeViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic) MKMapRect cityInnerBounds;
@property (nonatomic) int currentZoom;
@property (weak, nonatomic) IBOutlet UIButton *exitStreetView;

@end