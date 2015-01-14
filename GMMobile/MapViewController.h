//  MapViewController.h
//  GMMobile

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "GSSiTileOverlay.h"

@interface MapViewController : UIViewController <MKMapViewDelegate, MKOverlay>

@property (weak, nonatomic) IBOutlet MKMapView *mapView;

@end