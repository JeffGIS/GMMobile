//
//  ThemeLegendCell.h
//  GMMobile
//
//  Created by JEFFREY E SMITH on 11/4/15.
//  Copyright © 2015 GSSi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CCodeLibrary/CCodelibrary.h"

@interface ThemeLegendCell : NSObject
@property int count;
@property PointSymbols symbol;
@property float symbolWidth;
@property UIColor *symbolColor;
@property NSString *label;
@property BOOL status;

+ (ThemeLegendCell*) createWithLabel:(NSString*)label;


@end
