//  PlatView.h
//  GMMobile

#import "CCodeLibrary/CCodeLibrary.h"
@import GoogleMaps;

@class PlatViewx;

@protocol PlatViewDelegate <NSObject>

- (void)platViewDidTranslate:(CGPoint)translation;
- (void)platViewDidTransformScale:(CGFloat)transformationScale;
- (void)platViewDidBeginTrans;
- (void)platViewDidEndTrans;
- (void)platViewDidZoom:(GMSCoordinateBounds*)bounds
            withBearing:(CGFloat)pBearing;

@end

@interface PlatViewx : UIView <UIGestureRecognizerDelegate>

@property (nonatomic, weak) id <PlatViewDelegate> delegate;

@end
