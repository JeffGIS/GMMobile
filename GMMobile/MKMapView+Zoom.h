//  MKMapView+Zoom.h
//  GMMobile

#import <MapKit/MapKit.h>

@interface MKMapView (Zoom)

- (void)setCenterCoordinate:(CLLocationCoordinate2D)centerCoordinate
                  zoomLevel:(NSUInteger)zoomLevel
                   animated:(BOOL)animated;

@end