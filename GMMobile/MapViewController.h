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

@interface MapViewController : UIViewController <MKMapViewDelegate,GSSiOverlay,UIGestureRecognizerDelegate,UITableViewDataSource,UITableViewDelegate,PlatViewDelegate,GSSiAlertDelegate,VectorViewDelegate>

@property (weak, nonatomic) IBOutlet UIButton *userLocationButton;
@property (weak, nonatomic) IBOutlet UIButton *zoomToExtentButton;
@property (weak, nonatomic) IBOutlet UISwitch *annotationSwitch;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic) MKMapRect cityInnerBounds;
@property (nonatomic) int currentZoom;
@property (weak, nonatomic) IBOutlet UIButton *splitScreenButton;
@property (weak, nonatomic) IBOutlet UISegmentedControl *mapTypeSC;
@property (weak, nonatomic) IBOutlet UIButton *exitStreetView;

@end