//  GSSiAnnotationView.h
//  GMMobile

#import "../../CCodeLibrary/CCodeLibrary/CCodeLibrary.h"
#import "GSSiAnnotation.h"

@interface GSSiAnnotationView : UIView

@property (nonatomic) GSSiAnnotation *annotation;

- (id)initWithAnnotation:(GSSiAnnotation *)annotation
                 mapView:(MKMapView *)mapView;

@end