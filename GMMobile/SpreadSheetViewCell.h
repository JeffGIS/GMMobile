//  SpreadSheetViewCell.h
//  GMMobile

#import <UIKit/UIKit.h>

@interface SpreadSheetViewCell : UILabel

@property (nonatomic) NSString *identifier;
@property (nonatomic) BOOL selected;
@property (nonatomic) int row, column;

@end