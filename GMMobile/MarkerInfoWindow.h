//  MarkerInfoWindow.h
//  GMMobile

@import UIKit;
@import CoreLocation;
#import "MarkerButton.h"

@class MarkerInfoWindow;

@protocol MarkerInfoWindowDelegate <NSObject>

- (void)markerInfoWindowDidSelectOptions:(NSString *)title
                                   refno:(NSInteger)refno
                                  coords:(CLLocationCoordinate2D)coords
                                    type:(NSInteger)type;

- (void)markerInfoWindowDidSelectPropReport:(NSString *)title
                                     coords:(CLLocationCoordinate2D)coords
                                       type:(NSInteger)type;

- (void)markerInfoWindowWasSwiped;

@end

@interface MarkerInfoWindow : UIView

@property (nonatomic, weak) id <MarkerInfoWindowDelegate> delegate;
@property (nonatomic) MarkerInfoWindowType type;
@property (nonatomic) MarkerButton *marker;

+ (CGFloat)markerInfoWindowHeight;

@end