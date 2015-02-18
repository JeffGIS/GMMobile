//  PlatView.h
//  GMMobile

#import "../../CCodeLibrary/CCodeLibrary/CCodeLibrary.h"

@class PlatView;

@protocol PlatViewDelegate <NSObject>

- (void)platViewDidTranslate:(CGPoint)translation;
- (void)platViewDidTransformScale:(CGFloat)transformationScale;
- (void)platViewDidDoubleTap;

@end

@interface PlatView : UIView <UIGestureRecognizerDelegate>

@property (nonatomic, weak) id <PlatViewDelegate> delegate;

@end