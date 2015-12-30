//  ThemeLegendCell.h
//  GMMobile

@import UIKit;
#import "CCodeLibrary/DisplayCharacteristics.h"

@interface ThemeLegendCell : NSObject
@property int count;
@property PointSymbols symbol;
@property float symbolWidth;
@property UIColor *symbolColor;
@property NSString *label;
@property BOOL status;

+ (ThemeLegendCell *)createWithLabel:(NSString *)label;

@end