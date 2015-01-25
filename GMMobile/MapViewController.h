//  MapViewController.h
//  GMMobile

#import <UIKit/UIKit.h>
#import "GSSiTileOverlay.h"
#import "GSSiTileOverlayRenderer.h"
#import "../../CCodeLibrary/CCodeLibrary/CCodeLibrary.h"

@interface MapViewController : UIViewController <MKMapViewDelegate,GSSiOverlay,UIGestureRecognizerDelegate>

@property (weak, nonatomic) IBOutlet MKMapView *mapView;

@end