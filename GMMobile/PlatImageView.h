//  PlatImageView.h
//  GMMobile

#import "../../CCodeLibrary/CCodeLibrary/CCodeLibrary.h"
#import <GoogleMaps/GoogleMaps.h>

@class PlatImageView;

@protocol PlatImageViewDelegate <NSObject>

- (void)platViewDidBeginTrans;
- (void)platViewDidEndTrans;

- (void)platViewDidTransBounds:(GMSCoordinateBounds *)bounds
                   withBearing:(CGFloat)pBearing;

@end

@interface PlatImageView : UIImageView <UIGestureRecognizerDelegate>

@property (nonatomic, weak) id <PlatImageViewDelegate> delegate;

+ (PlatImageView *)platImageViewWithImagePath:(NSString *)imagePath
                                     delegate:(id)delegate;

- (GMSCoordinateBounds *)imageRectToMapBounds:(CGRect)imageRect
                                      bearing:(CGFloat *)bearing;

@end