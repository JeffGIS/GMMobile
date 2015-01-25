//  MKMapView+Zoom.m
//  GMMobile

#import "MKMapView+Zoom.h"

@implementation MKMapView (Zoom)

- (void)setCenterCoordinate:(CLLocationCoordinate2D)centerCoordinate
                  zoomLevel:(NSUInteger)zoomLevel
                   animated:(BOOL)animated
{
    MKMapPoint center = MKMapPointForCoordinate(centerCoordinate);
    
    CGFloat width = (2.0 * self.bounds.size.width * pow(2, (20 - zoomLevel)));
    CGFloat height = (2.0 * self.bounds.size.height * pow(2, (20 - zoomLevel)));
    
    MKMapRect visibleRect = MKMapRectMake((center.x - width / 2.0), (center.y - height / 2.0), width, height);
    
    [self setVisibleMapRect:visibleRect
                   animated:animated];
}

@end