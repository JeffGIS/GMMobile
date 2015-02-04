//  GSSiAnnotationView.m
//  GMMobile

#import "GSSiAnnotationView.h"

@implementation GSSiAnnotationView

- (id)initWithCoord:(CLLocationCoordinate2D)coord
            mapView:(MKMapView *)mapView
{
    CGPoint cPoint = [mapView convertCoordinate:coord
                                  toPointToView:mapView];
    
    self = [super initWithFrame:CGRectMake(cPoint.x, cPoint.y, 160.0, 60.0)];
    
    if (self)
    {
        self.backgroundColor = UIColor.greenColor;
        _coordinate = coord;
    }
    
    return self;
}

@end