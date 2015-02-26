//  MarkerInfoWindow.h
//  GMMobile

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@class MarkerInfoWindow;

@protocol MarkerInfoWindowDelegate <NSObject>

- (void)markerInfoWindowDidSelectOptions:(NSString *)PID
                                  coords:(CLLocationCoordinate2D)coords;

- (void)markerInfoWindowDidSelectPropReport:(NSString *)PID;

@end

@interface MarkerInfoWindow : UIView

@property (nonatomic, weak) id <MarkerInfoWindowDelegate> delegate;
@property (nonatomic) NSString *title;
@property (nonatomic) NSString *snippet;
@property (nonatomic) CLLocationCoordinate2D position;

@end