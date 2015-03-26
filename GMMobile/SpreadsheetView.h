//  SpreadsheetView.h
//  GMMobile

#import <UIKit/UIKit.h>

@interface SpreadsheetView : UIScrollView

@property (nonatomic) NSUInteger rowHeight, columnWidth;

+ (SpreadsheetView *)spreadsheetViewWithRows:(NSUInteger)rows
                                     columns:(NSUInteger)columns
                                       frame:(CGRect)frame
                                        view:(UIView *)view;

@end