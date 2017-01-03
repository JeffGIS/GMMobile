//  ThemeClass.h
//  GMMobile

@import UIKit;
#import "CCodeLibrary/DisplayCharacteristics.h"

@interface ThemeClass : NSObject

@property NSString *title;
@property double count;
@property int numItems;
@property int status;
@property NSArray * values;
@property float pctOfTotal;
@property float symbolWidth;
@property UIColor *color;
@property float size;
@property PointSymbols symbol;
@property double minValue, maxValue, aveValue;

+ (ThemeClass *) createWithTitle:(NSString *)title;

@end
