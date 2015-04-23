//  MarkerButton.h
//  GMMobile

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <GoogleMaps/GoogleMaps.h>

@class MarkerButton;

@protocol MarkerButtonDelegate <NSObject>

- (void)markerButtonWasTapped:(MarkerButton *)marker;

@end

@interface MarkerButton : UIButton

@property (nonatomic, weak) id <MarkerButtonDelegate> delegate;
@property (nonatomic) CLLocationCoordinate2D position;
@property (nonatomic) NSInteger type;
@property (nonatomic) NSInteger refno;
@property (nonatomic) NSString *title;
@property (nonatomic) NSString *snippet;

+ (MarkerButton *)markerWithPosition:(CLLocationCoordinate2D)position
                                view:(UIView *)view
                                 map:(GMSMapView *)map
                     statusBarHeight:(CGFloat)statusBarHeight
                            delegate:(id)delegate;

@end