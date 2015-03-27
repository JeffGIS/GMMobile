//  SpreadsheetView.h
//  GMMobile

#import <UIKit/UIKit.h>

@interface SpreadsheetView : UIScrollView <UITextFieldDelegate>

@property (nonatomic) NSUInteger rowHeight, columnWidth;

+ (SpreadsheetView *)spreadsheetViewWithRows:(NSUInteger)rows
                                     columns:(NSUInteger)columns
                                       view:(UIView *)view;

@end