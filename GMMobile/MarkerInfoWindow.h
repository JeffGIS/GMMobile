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

@end

@interface MarkerInfoWindow : UIView

@property (nonatomic, weak) id <MarkerInfoWindowDelegate> delegate;
@property (nonatomic) MarkerButton *marker;
@property BOOL linkedPID;
@property (nonatomic, copy) NSString *optionsTitle;

+ (CGFloat)markerInfoWindowHeight;

@end
