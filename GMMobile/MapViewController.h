//  MapViewController.h
//  GMMobile

#import "CCodeLibrary/CCodeLibrary.h"
#import "FindViewController.h"
#import "PropertyData.h"
#import "PlanimetricData.h"
#import "AlleyWallData.h" 
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
#import "Destinations.h"
#import "NVDataLoader.h"
#import <MessageUI/MessageUI.h>
#import "CCodeLibrary/NVAlertView.h"
#import "ThemeLegendMapOverlay.h"

@interface MapViewController : UIViewController <GMSMapViewDelegate,UIGestureRecognizerDelegate,UITableViewDataSource,UITableViewDelegate,NVAlertViewDelegate, MapToolbarDelegate,VectorViewDelegate,CLLocationManagerDelegate,MarkerInfoWindowDelegate,PipeTraceDelegate,MarkerButtonDelegate,PlatImageViewDelegate,GSSiNotesViewDelegate,NVLegendViewDelegate,NVTwoTextAlertDelegate,NVDataLoaderDelegate,MFMailComposeViewControllerDelegate,NSURLConnectionDataDelegate,ThemeLegendMapOverlayDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic) MKMapRect cityInnerBounds;
@property (nonatomic) int currentZoom;
@property (weak, nonatomic) IBOutlet UIButton *exitStreetView;
@property BOOL fromSpreadsheet;
@property (nonatomic) CLLocationCoordinate2D spreadsheetCoords;

@end