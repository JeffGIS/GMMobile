//  Theme.h
//  GMMobile

@import UIKit;
#import "CCodeLibrary/CRAPI.h"
#import "ThemeClass.h"
#import "ThemeLegend.h"
#import "GetSlowValues.h"

#define DO_NOT_DISPLAY_ITEM     1
#define DISPLAY_ITEM            2
#define ITEM_HAS_BEEN_DISPLAYED 3

@interface Theme : NSObject

@property int displayID;
@property ThemeTypes type;
@property int subType;
@property NSMutableArray * titles;
@property int currentTitleIndex;
@property NSMutableArray * classes;
@property ThemeLegend* legend;
@property int numDesiredClasses;
@property int numClasses;
@property int numDecimals;
@property int totNumItems;
@property double totCount;
@property BOOL setSymbol;
@property BOOL setColor;
@property BOOL showSymbolAsBarChart;
@property int minUCR, maxUCR;
@property int minYear, maxYear;
@property MNMXCORD maxValBounds;
@property GetSlowValues * getSlowValues;

+ (Theme *)createTheme:(ThemeTypes)type;

- (BOOL) classIsSelected:(int)iclass;
- (int) classFromUCR:(int)ucr;
- (int) processTheme:(DisplayCharacteristics *)dc
           displayID:(int)displayID
            testPass:(BOOL)test
        compareClass:(int*) cclass;
- (void) beginDisplay:(int)displayID;
- (void) endDisplay:(int)displayID;
- (ThemeLegend *)copyLegend;
- (int) getFirstUCRGreaterThan:(int)ucr;
- (BOOL) incrementCount:(int)class
                     by:(double)val
                     dc:(DisplayCharacteristics *)dc
               testPass:(BOOL)test;
- (int) classFromTime:(int)time;


@end
