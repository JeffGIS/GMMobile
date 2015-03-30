//  SpreadsheetView.h
//  GMMobile

#import <UIKit/UIKit.h>

@interface SpreadsheetView : UIScrollView <UITextFieldDelegate>

@property (nonatomic) NSUInteger rowHeight, columnWidth;
@property (nonatomic) UIView *overlayView;

+ (SpreadsheetView *)spreadsheetViewWithRows:(NSUInteger)rows
                                     columns:(NSUInteger)columns
                                       view:(UIView *)view;

- (void)willRotateWithDuration:(NSTimeInterval)duration
                  tabBarHeight:(CGFloat)tabBarHeight;

@end