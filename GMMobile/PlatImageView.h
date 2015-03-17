//  PlatImageView.h
//  GMMobile

#import "../../CCodeLibrary/CCodeLibrary/CCodeLibrary.h"
#import <GoogleMaps/GoogleMaps.h>

@class PlatImageView;

@protocol PlatImageViewDelegate <NSObject>

- (void)platViewDidBeginTrans;
- (void)platViewDidEndTrans;

- (void)platViewDidZoom:(CGFloat)pZoom
            withBearing:(CGFloat)pBearing
                 target:(CLLocationCoordinate2D)pTarget;

@end

@interface PlatImageView : UIImageView <UIGestureRecognizerDelegate>

@property (nonatomic, weak) id <PlatImageViewDelegate> delegate;
@property (nonatomic) CGSize mapViewSize, originalSize;

+ (PlatImageView *)platImageViewWithDelegate:(id)delegate;

- (CGFloat)zoomForMapBounds:(CGRect)imageRect
                    bearing:(CGFloat *)bearing
                     target:(CLLocationCoordinate2D *)target
                mapViewSize:(CGSize)size;

@end