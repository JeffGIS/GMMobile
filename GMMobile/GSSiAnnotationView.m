//  GSSiAnnotationView.m
//  GMMobile

#import "GSSiAnnotationView.h"

@implementation GSSiAnnotationView

- (id)initWithAnnotation:(GSSiAnnotation *)annotation
                 mapView:(MKMapView *)mapView;
{
    CGPoint cPoint = [mapView convertCoordinate:annotation.coordinate
                                  toPointToView:mapView];
    
    CGFloat width = 160.0, height = 60.0;
    
    self = [super initWithFrame:CGRectMake((cPoint.x - width / 2.0), (cPoint.y - height), width, height)];
    
    if (self)
    {
        self.backgroundColor = UIColor.greenColor;
        _annotation = annotation;
        [CRAPI.sharedInstance.annotations addObject:_annotation];
    }
    
    return self;
}

@end