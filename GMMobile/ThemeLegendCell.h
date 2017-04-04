//  ThemeLegendCell.h
//  GMMobile

@import UIKit;
#import "CCodeLibrary/DisplayCharacteristics.h"

@interface ThemeLegendCell : NSObject
@property PointSymbols symbol;
@property float symbolWidth;
@property (nonatomic) UIColor *symbolColor;
@property (nonatomic) NSString *label;
@property int count;
@property (nonatomic) int status;

+ (ThemeLegendCell *)createWithLabel:(NSString *)label;

@end
