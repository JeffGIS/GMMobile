//  PlatImageView.h
//  GMMobile

#import "CCodeLibrary/CCodeLibrary.h"
@import GoogleMaps;

@class PlatImageView;

@protocol PlatImageViewDelegate <NSObject>

- (void)platViewDidZoom:(CGFloat)pZoom
            withBearing:(CGFloat)pBearing
                 target:(CLLocationCoordinate2D)pTarget
                 minYpt:(DPOINT)minYpt
                 maxYpt:(DPOINT)maxYpt
           gestureState:(UIGestureRecognizerState)gestureState;

- (void)platViewDidLongPressAtFrameXPosition:(CGFloat)xFrame
                           andSuperviewPoint:(CGPoint)superpoint
                           andImageXPosition:(CGFloat)xImage
                                gestureState:(UIGestureRecognizerState)gestureState;

@end

@interface PlatImageView : UIImageView <UIGestureRecognizerDelegate>

@property (nonatomic, weak) id <PlatImageViewDelegate> delegate;
@property (nonatomic) CGSize mapViewSize, originalSize;
@property (nonatomic) CGFloat minY, maxY;

+ (PlatImageView *)platImageViewWithDelegate:(id)delegate
                                    andFrame:(CGRect)frame;

- (void)setPlatID:(int)refno
          andType:(int)platType;

- (BOOL)getYValueRangeForProfileAtX:(CGFloat)x
                               minY:(CGFloat *)pMinY
                               maxY:(CGFloat *)pMaxY;

- (CGFloat)zoomForMapBounds:(CGRect)imageRect
                    bearing:(CGFloat *)bearing
                     target:(CLLocationCoordinate2D *)target
                mapViewSize:(CGSize)size
                     minYpt:(DPOINT *)minYpt
                     maxYpt:(DPOINT *)maxYpt;

- (void)setAnchorPoint:(CGPoint)anchorPoint
               forView:(UIView *)view;

@end
