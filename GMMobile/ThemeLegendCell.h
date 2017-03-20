//  ThemeLegendCell.h
//  GMMobile

@import UIKit;
#import "CCodeLibrary/DisplayCharacteristics.h"

@interface ThemeLegendCell : NSObject
@property int count;
@property PointSymbols symbol;
@property float symbolWidth;
@property (nonatomic) UIColor *symbolColor;
@property NSString *label;
@property (nonatomic) BOOL status;

+ (ThemeLegendCell *)createWithLabel:(NSString *)label;

@end
