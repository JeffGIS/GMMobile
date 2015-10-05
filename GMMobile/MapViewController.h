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
#import "MapToolbar.h"
#import <GoogleMaps/GoogleMaps.h>
#import "MarkerInfoWindow.h"
#import "MarkerButton.h"
#import "PropertyList.h"
#import "Destinations.h"
#import "NVDataLoader.h"
#import <MessageUI/MessageUI.h>
#import "CCodeLibrary/NVAlertView.h"
//#import "CCodeLibrary/FTPDirectoryList.h"
//#import "CCodeLibrary/FTPDirectoryCreate.h"
//#import "CCodeLibrary/NVRoutes.h"

@interface MapViewController : UIViewController <GMSMapViewDelegate,UIGestureRecognizerDelegate,UITableViewDataSource,UITableViewDelegate,NVAlertViewDelegate, MapToolbarDelegate,VectorViewDelegate,CLLocationManagerDelegate,MarkerInfoWindowDelegate,PipeTraceDelegate,MarkerButtonDelegate,PlatImageViewDelegate,GSSiNotesViewDelegate,NVLegendViewDelegate,NVTwoTextAlertDelegate,NVDataLoaderDelegate,MFMailComposeViewControllerDelegate,NSURLConnectionDataDelegate/*,NVRoutesDelegate,FTPDirectoryListDelegate,FTPDirectoryCreateDelegate*/>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic) MKMapRect cityInnerBounds;
@property (nonatomic) int currentZoom;
@property (weak, nonatomic) IBOutlet UIButton *exitStreetView;

@end