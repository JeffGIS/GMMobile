//  MapToolbar.h
//  GMMobile

#import "CCodeLibrary/CCodeLibrary.h"

#define NUMMapToolbarProperty 10

typedef NS_ENUM(NSInteger, MapToolbarProperty)
{
    MapToolbarPropertyWantPlat,
    MapToolbarPropertyWantDigitize,
    MapToolbarPropertyWantMapType,
    MapToolbarPropertyWantUserLocation,
    MapToolbarPropertyWantExtents,
    MapToolbarPropertyWantLegends,
    MapToolbarPropertyWantGrayscale,
    MapToolbarPropertyWantClearMarkers,
    MapToolbarPropertyWantEmailPDF,
    MapToolbarPropertyWantProgressBar,
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
- (void)mapToolbarDidSelectGrayscale;
- (void)mapToolbarDidSelectClearMarkers;
- (void)mapToolbarDidSelectEmailPDF;
- (void)mapToolbarDidSelectDigitize;
- (void)mapToolbarDidSelectLegends;
- (void)mapToolbarDidFinishDrag;

@end

@interface MapToolbar : UIView <UIGestureRecognizerDelegate>

@property (nonatomic, weak) id <MapToolbarDelegate> delegate;
@property (nonatomic) MapToolbarOrientation orientation;
@property (readonly) BOOL wantPlat, wantDigitize, wantMapType, wantUserLocation;
@property (readonly) BOOL wantExtents, wantLegends, wantGrayscale, wantClearMarkers;
@property (readonly) BOOL wantEmailPDF, wantProgressBar;

+ (MapToolbar *)showMapToolbarWithCenter:(CGPoint)center
                                   view:(UIView *)view
                                delegate:(id)delegate;

- (void)deselectMyLocationButton;
- (void)animateToVerticalOrientation;
- (void)animateToHorizontalOrientation;
- (void)splitScreenSelectedSegmentIndex:(NSInteger)index;
- (void)normalMode:(MapViewScreenSetting)screenSetting;
- (void)platViewMode:(MapViewScreenSetting)screenSetting;
- (void)hide;
- (void)show;

- (void)setConfigurationProperty:(MapToolbarProperty)property
                           value:(BOOL)value;

- (void)configure:(MapViewScreenSetting)screenSetting;

- (void)willRotateWithDuration:(NSTimeInterval)duration
                  tabBarHeight:(CGFloat)tabBarHeight
               statusBarHeight:(CGFloat)statusBarHeight;

@end