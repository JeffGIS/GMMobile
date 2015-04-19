//  MapToolbar.h
//  GMMobile

#import "../../CCodeLibrary/CCodeLibrary/CCodeLibrary.h"

#define NUMMapToolbarProperty 8
typedef NS_ENUM(NSInteger, MapToolbarProperty)
{
    MapToolbarPropertyWantDefault,
    MapToolbarPropertyWantPlat,
    MapToolbarPropertyWantDigitize,
    MapToolbarPropertyWantMapType,
    MapToolbarPropertyWantUserLocation,
    MapToolbarPropertyWantExtents,
    MapToolbarPropertyWantLegends,
    MapToolbarPropertyWantMarkerSwitch,
};

typedef NS_ENUM(NSInteger, MapToolbarOrientation)
{
    MapToolbarOrientationDefault,
    MapToolbarOrientationTop,
    MapToolbarOrientationBottom,
    MapToolbarOrientationLeft,
    MapToolbarOrientationRight,
};

@class MapToolbar;

@protocol MapToolbarDelegate <NSObject>

- (void)mapToolbarDidSelectUserLocation:(BOOL)enabled;
- (void)mapToolbarDidSelectZoomExtent;
- (void)mapToolbarDidSelectMapType:(NSInteger)mapType;
- (void)mapToolbarDidSelectSplitScreenSetting:(NSInteger)setting;
- (void)mapToolbarDidSelectMarkerSwitch:(BOOL)option;
- (void)mapToolbarDidSelectDigitize;
- (void)mapToolbarDidSelectLegends;
- (void)mapToolbarDidFinishDrag;

@end

@interface MapToolbar : UIView <UIGestureRecognizerDelegate>

@property (nonatomic, weak) id <MapToolbarDelegate> delegate;
@property (nonatomic) MapToolbarOrientation orientation;
@property (readonly) BOOL wantPlat, wantDigitize, wantMapType, wantUserLocation, wantExtents, wantLegends, wantMarkerSwitch;

+ (MapToolbar *)showMapToolbarWithCenter:(CGPoint)center
                                   view:(UIView *)view
                                delegate:(id)delegate;

- (void)deselectMyLocationButton;
- (void)animateToVerticalOrientation;
- (void)animateToHorizontalOrientation;
- (void)splitScreenSelectedSegmentIndex:(NSInteger)index;
- (void)normalMode;
- (void)hide;
- (void)show;
- (void)platViewMode;

- (void)setConfigurationProperty:(MapToolbarProperty)property
                           value:(BOOL)value;

- (void)configure;

- (void)willRotateWithDuration:(NSTimeInterval)duration
                  tabBarHeight:(CGFloat)tabBarHeight
               statusBarHeight:(CGFloat)statusBarHeight;

@end