//  MapViewController.h
//  GMMobile

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "GSSiTileOverlay.h"

@interface MapViewController : UIViewController <MKMapViewDelegate, GSSiOverlay>

@property (weak, nonatomic) IBOutlet MKMapView *mapView;

@end