//  MapToolbar.h
//  GMMobile

#import "../../CCodeLibrary/CCodeLibrary/CCodeLibrary.h"

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

+ (MapToolbar *)showMapToolbarWithCenter:(CGPoint)center
                                   view:(UIView *)view
                                delegate:(id)delegate
                             orientation:(MapToolbarOrientation)orientation;

- (void)deselectMyLocationButton;
- (void)animateToVerticalOrientation;
- (void)animateToHorizontalOrientation;
- (void)splitScreenSelectedSegmentIndex:(NSInteger)index;
- (void)platViewMode;
- (void)normalMode;
- (void)hide;
- (void)show;

- (void)setConfigurationProperty:(MapToolbarProperty)property
                           value:(BOOL)value;

- (void)configure;

- (void)willRotateWithDuration:(NSTimeInterval)duration
                  tabBarHeight:(CGFloat)tabBarHeight
               statusBarHeight:(CGFloat)statusBarHeight;

@end