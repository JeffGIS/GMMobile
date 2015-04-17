//  MapToolbar.h
//  GMMobile

#import "../../CCodeLibrary/CCodeLibrary/CCodeLibrary.h"

typedef NS_ENUM(NSInteger, MapToolbarProp)
{
    MTPwantPlat, MTPwantDigitize, MTPwantMapType, MTPwantGPS, MTPwantExtents, MTPwantLegends, 
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
@property (atomic) BOOL configChanged;
@property BOOL wantPlat, wantDigitize, wantMapType, wantGPS, wantExtents, wantLegends;

- (void)deselectMyLocationButton;
- (void)animateToVerticalOrientation;
- (void)animateToHorizontalOrientation;
- (void)splitScreenSelectedSegmentIndex:(NSInteger)index;
- (void)platViewMode;
- (void)normalMode;
- (void)hide;
- (void)show;
- (void)setConfiguration:(int)property value:(BOOL)value;
- (void)configure;

- (void)willRotateWithDuration:(NSTimeInterval)duration
                  tabBarHeight:(CGFloat)tabBarHeight
               statusBarHeight:(CGFloat)statusBarHeight;

@end