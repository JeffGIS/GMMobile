//  MapViewController.h
//  GMMobile

#import "GSSiTileOverlay.h"
#import "GSSiTileOverlayRenderer.h"
#import "../../CCodeLibrary/CCodeLibrary/CCodeLibrary.h"

@interface MapViewController : UIViewController <MKMapViewDelegate,GSSiOverlay,UIGestureRecognizerDelegate>

@property (weak, nonatomic) IBOutlet MKMapView *mapView;

@property MKMapRect cityInnerBounds;

@end