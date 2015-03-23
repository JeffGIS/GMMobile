//  PlatImageView.h
//  GMMobile

#import "../../CCodeLibrary/CCodeLibrary/CCodeLibrary.h"
#import <GoogleMaps/GoogleMaps.h>

@class PlatImageView;

@protocol PlatImageViewDelegate <NSObject>

- (void)platViewDidZoom:(CGFloat)pZoom
            withBearing:(CGFloat)pBearing
                 target:(CLLocationCoordinate2D)pTarget
                 minYpt:(DPOINT)minYpt
                 maxYpt:(DPOINT)maxYpt
           gestureState:(UIGestureRecognizerState)gestureState;

- (void)platViewDidLongPressAtXPosition:(CGFloat)xPosition
                           gestureState:(UIGestureRecognizerState)gestureState;

@end

@interface PlatImageView : UIImageView <UIGestureRecognizerDelegate>

@property (nonatomic, weak) id <PlatImageViewDelegate> delegate;
@property (nonatomic) CGSize mapViewSize, originalSize;
@property (nonatomic) CGFloat minY, maxY;

+ (PlatImageView *)platImageViewWithDelegate:(id)delegate andFrame:(CGRect)frame;

- (CGFloat)zoomForMapBounds:(CGRect)imageRect
                    bearing:(CGFloat *)bearing
                     target:(CLLocationCoordinate2D *)target
                mapViewSize:(CGSize)size
                     minYpt:(DPOINT *)minYpt
                     maxYpt:(DPOINT *)maxYpt;

- (void)setAnchorPoint:(CGPoint)anchorPoint
               forView:(UIView *)view;

@end