//  MapViewController.h
//  GMMobile

#import "GSSiTileOverlay.h"
#import "GSSiTileOverlayRenderer.h"
#import "../../CCodeLibrary/CCodeLibrary/CCodeLibrary.h"
#import "FindViewController.h"
#import "PropertyData.h"

@interface MapViewController : UIViewController <MKMapViewDelegate,GSSiOverlay,UIGestureRecognizerDelegate>

@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (nonatomic) MKMapRect cityInnerBounds;
@property (weak, nonatomic) IBOutlet UIButton *userLocationButton;
@property (weak, nonatomic) IBOutlet UIButton *zoomToExtentButton;
@property (weak, nonatomic) IBOutlet UISwitch *annotationSwitch;
@property (weak, nonatomic) IBOutlet UIView *overlayView;

@end