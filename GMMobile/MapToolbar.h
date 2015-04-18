//  MapToolbar.h
//  GMMobile

#import "../../CCodeLibrary/CCodeLibrary/CCodeLibrary.h"

typedef NS_ENUM(NSInteger, MapToolbarProperty)
{
    MapToolbarPropertyWantDefault,
    MapToolbarPropertyWantPlat,
    MapToolbarPropertyWantDigitize,
    MapToolbarPropertyWantMapType,
    MapToolbarPropertyWantGPS,
    MapToolbarPropertyWantExtents,
    MapToolbarPropertyWantLegends,
    MapToolbarPropertyWantMarkerSwitch,
};

@class MapToolbar;

@protocol MapToolbarDelegate <NSObject>

- (void)mapToolbarDidSelectUserLocation:(BOOL)enabled;
- (void)mapToolbarDidSelectZoomExtent;
- (void)mapToolbarDidSelectMapType:(NSInteger)mapType;
- (void)mapToolbarDidSelectSplitScreenSetting:(NSInteger)setting;
- (void)mapToolbarDidSelectAnnotationOption:(BOOL)option;
- (void)mapToolbarDidFinishDrag;

@end

@interface MapToolbar : UIView <UIGestureRecognizerDelegate>

@property (nonatomic, weak) id <MapToolbarDelegate> delegate;
@property (nonatomic) NSInteger orientation;

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