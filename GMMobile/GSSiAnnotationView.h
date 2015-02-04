//  GSSiAnnotationView.h
//  GMMobile

#import "../../CCodeLibrary/CCodeLibrary/CCodeLibrary.h"

@interface GSSiAnnotationView : UIView

@property (nonatomic) CLLocationCoordinate2D coordinate;
@property (nonatomic) NSString *title;
@property (nonatomic) NSString *subtitle;

- (id)initWithCoord:(CLLocationCoordinate2D)coords
            mapView:(MKMapView *)mapView;

@end