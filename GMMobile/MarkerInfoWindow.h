//  MarkerInfoWindow.h
//  GMMobile

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@class MarkerInfoWindow;

@protocol MarkerInfoWindowDelegate <NSObject>

- (void)markerInfoWindowDidSelectOptions:(NSString *)title
                                   refno:(NSInteger) refno
                                  coords:(CLLocationCoordinate2D)coords
                                    type:(NSInteger)type;

- (void)markerInfoWindowDidSelectPropReport:(NSString *)title
                                     coords:(CLLocationCoordinate2D)coords
                                       type:(NSInteger)type;

- (void)markerInfoWindowWasSwiped;

@end

@interface MarkerInfoWindow : UIView

@property (nonatomic, weak) id <MarkerInfoWindowDelegate> delegate;
@property (nonatomic, copy) NSString *title, *snippet;
@property (nonatomic) NSInteger refno;
@property (nonatomic) CLLocationCoordinate2D position;
@property (nonatomic) NSInteger type;

@end