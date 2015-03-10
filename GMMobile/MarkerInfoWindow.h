//  MarkerInfoWindow.h
//  GMMobile

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@class MarkerInfoWindow;

@protocol MarkerInfoWindowDelegate <NSObject>

- (void)markerInfoWindowDidSelectOptions:(NSString *)title
                                  coords:(CLLocationCoordinate2D)coords
                                    type:(NSInteger)type;

- (void)markerInfoWindowDidSelectPropReport:(NSString *)title
                                       type:(NSInteger)type;

@end

@interface MarkerInfoWindow : UIView

@property (nonatomic, weak) id <MarkerInfoWindowDelegate> delegate;
@property (nonatomic, copy) NSString *title, *snippet;
@property (nonatomic) CLLocationCoordinate2D position;
@property (nonatomic) NSInteger type;

@end