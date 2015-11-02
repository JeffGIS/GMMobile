//
//  Theme.m
//  GMMobile
//
//  Created by JEFFREY E SMITH on 11/2/15.
//  Copyright © 2015 GSSi. All rights reserved.
//

#import "Theme.h"
#import "ThemeLegend.h"

@implementation Theme

+ (Theme *)createTheme:(ThemeTypes)type
{
    Theme * thm = [[Theme alloc]init];
    
    thm.type = type;
    thm.legend = [[ThemeLegend alloc]init];
    thm.legend.aspectRatio = 0.7;
    thm.legend.numColumns = 1;
    thm.legend.pctBorder = 1;
    thm.legend.pctInnerMargin = 2;
    thm.legend.pctSymbol = 30;
    thm.legend.pctTitle = 12;
    switch (type)
    {
        case YearTheme:
            thm.numClasses = 10;
            thm.legend.title = @"Year";
            break;
        case MonthTheme:
            thm.legend.title = @"Month";
            thm.numClasses = 12;
            break;
        case DayofWeekTheme:
            thm.legend.title = @"Day";
            thm.numClasses = 7;
            break;
        case HourTheme:
            thm.legend.title = @"Hour";
            thm.numClasses = 12;
            thm.legend.numColumns = 2;
            break;
    }
    thm.legend.numClasses = thm.numClasses;
    return thm;
}


@end
