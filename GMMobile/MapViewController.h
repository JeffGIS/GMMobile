//  MapViewController.h
//  GMMobile

#import <UIKit/UIKit.h>
#import "GSSiTileOverlay.h"
#import "GSSiTileOverlayRenderer.h"
#import "../../CCodeLibrary/CCodeLibrary/CCodeLibrary.h"
#import "MKMapView+Zoom.h"

@interface MapViewController : UIViewController <MKMapViewDelegate, GSSiOverlay>

@property (weak, nonatomic) IBOutlet MKMapView *mapView;

@end