//  MapViewController.h
//  GMMobile

#import "GSSiTileOverlay.h"
#import "../../CCodeLibrary/CCodeLibrary/CCodeLibrary.h"
#import "FindViewController.h"
#import "PropertyData.h"
#import "VectorView.h"
#import "GSSiTileOverlayRenderer.h"

@interface MapViewController : UIViewController <MKMapViewDelegate,GSSiOverlay,UIGestureRecognizerDelegate>

@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (nonatomic) MKMapRect cityInnerBounds;
@property (weak, nonatomic) IBOutlet UIButton *userLocationButton;
@property (weak, nonatomic) IBOutlet UIButton *zoomToExtentButton;
@property (weak, nonatomic) IBOutlet UISwitch *annotationSwitch;
@property (weak, nonatomic) IBOutlet VectorView *vectorView;

@end