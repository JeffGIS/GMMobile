//  MarkerButton.h
//  GMMobile

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <GoogleMaps/GoogleMaps.h>
#import "MarkerInfoWindow.h"

@class MarkerButton;

@protocol MarkerButtonDelegate <NSObject>

- (void)markerButtonWasTapped:(MarkerButton *)marker;

@end

@interface MarkerButton : UIButton

@property (nonatomic, weak) id <MarkerButtonDelegate> delegate;
@property (nonatomic) CLLocationCoordinate2D position;
@property MarkerInfoWindowType type;
@property (nonatomic) NSInteger refno;
@property (nonatomic) NSString *title;
@property (nonatomic) NSString *snippet;
@property int symbol;

+ (CGFloat)markerButtonSize;

+ (MarkerButton *)markerWithPosition:(CLLocationCoordinate2D)position
                                view:(UIView *)view
                                 map:(GMSMapView *)map
                     statusBarHeight:(CGFloat)statusBarHeight
                            delegate:(id)delegate;

@end