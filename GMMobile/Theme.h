//
//  Theme.h
//  GMMobile
//
//  Created by JEFFREY E SMITH on 11/2/15.
//  Copyright © 2015 GSSi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ThemeLegend.h"

typedef NS_ENUM(NSInteger, ThemeTypes)
{
    YearTheme,
    MonthTheme,
    DayofWeekTheme,
    HourTheme,
};
@interface Theme : NSObject

@property ThemeTypes type;
@property ThemeLegend* legend;
@property int numClasses;

+ (Theme *)createTheme:(ThemeTypes)type;

@end
