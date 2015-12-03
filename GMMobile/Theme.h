//
//  Theme.h
//  GMMobile
//
//  Created by JEFFREY E SMITH on 11/2/15.
//  Copyright © 2015 GSSi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ThemeLegend.h"
#import "CCodeLibrary/CCodelibrary.h"

#define DO_NOT_DISPLAY_ITEM     1
#define DISPLAY_ITEM            2
#define ITEM_HAS_BEEN_DISPLAYED 3

typedef NS_ENUM(NSInteger, ThemeTypes)
{
    Part1Theme,
    DepartmentTheme,
    DayNightTheme,
    YearTheme,
    MonthTheme,
    DayofWeekTheme,
    HourTheme,
    CurbRampTheme,
};
@interface Theme : NSObject

@property int displayID;
@property ThemeTypes type;
@property NSMutableArray * classes;
@property ThemeLegend* legend;
@property int numDesiredClasses;
@property int numClasses;
@property int totNumItems;
@property double totCount;
@property BOOL setSymbol;
@property BOOL setColor;

+ (Theme *)createTheme:(ThemeTypes)type;

- (int) processTheme:(DisplayCharacteristics *)dc
           displayID:(int)displayID
            testPass:(BOOL)test;
- (void) beginDisplay:(int)displayID;
- (void) endDisplay:(int)displayID;
- (ThemeLegend *)copyLegend;

@end
