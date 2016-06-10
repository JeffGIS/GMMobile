//  MarkerButton.h
//  GMMobile

@import UIKit;
@import CoreLocation;
#import <GoogleMaps/GoogleMaps.h>
#import "CCodeLibrary/NVPhotoController.h"
#import "CCodeLibrary/GSSiEnums.h"

@class MarkerButton;

@protocol MarkerButtonDelegate <NSObject>

- (void)markerButtonWasTapped:(MarkerButton *)marker;

@end

@interface MarkerButton : UIButton

@property (nonatomic, weak) id <MarkerButtonDelegate> delegate;
@property (nonatomic) CLLocationCoordinate2D position;
@property MarkerInfoWindowType type;
@property (nonatomic) NSInteger refno;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *snippet;
@property int symbol;
@property (nonatomic) NVPhotoView *photoView;

+ (CGFloat)markerButtonSize;

+ (MarkerButton *)markerWithPosition:(CLLocationCoordinate2D)position
                                view:(UIView *)view
                                 map:(GMSMapView *)map
                     statusBarHeight:(CGFloat)statusBarHeight
                            delegate:(id)delegate;

@end