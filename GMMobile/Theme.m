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
    ThemeClass *class;
    thm.type = type;
    thm.legend = [[ThemeLegend alloc]init];
    thm.classes = [[NSMutableArray alloc]init];
    thm.legend.aspectRatio = 0.7;
    thm.legend.numColumns = 1;
    thm.legend.pctBorder = 1;
    thm.legend.pctInnerMargin = 2;
    thm.legend.pctSymbol = 30;
    thm.legend.pctTitle = 12;
    thm.legend.appendClassCount = YES;
    thm.legend.borderColor = [UIColor blackColor];
    thm.legend.labelBkColor = [UIColor yellowColor];
    thm.legend.titleTxColor = [UIColor blackColor];
    thm.legend.titleBkColor = [UIColor whiteColor];
    thm.legend.labelTxColor = [UIColor blueColor];
    thm.legend.symbolDefaultColor = [UIColor blueColor];
    switch (type)
    {
        case Part1Theme:
            thm.legend.title = @"Part 1 Crimes";
            thm.setSymbol = YES;
            thm.legend.usePointSymbols = YES;
            thm.numDesiredClasses = 8;
            class = [ThemeClass createWithTitle:@"UCR 01-02: Homicide"];
            class.symbol = CrossSym;
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"UCR 03: Rape"];
            class.symbol = DiamondSym;
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"UCR 04: Robbery"];
            class.symbol = TriangleSym;
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"UCR 05: Agg Assault"];
            class.symbol = SquareSym;
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"UCR 06: Burglary"];
            class.symbol = Star1Sym;
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"UCR 07: Larceny"];
            class.symbol = Star2Sym;
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"UCR 08: Auto Theft"];
            class.symbol = CircleSym;
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"UCR 10: Arson"];
            class.symbol = ArsonSym;
            [thm.classes addObject:class];
            break;
        case DepartmentTheme:
            thm.legend.title = @"Department";
            thm.numDesiredClasses = 4;
            class = [ThemeClass createWithTitle:@"MP"];
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"UM"];
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"CR"];
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"MT"];
            [thm.classes addObject:class];
            break;
        case DayNightTheme:
            thm.legend.title = @"Day - Night";
            thm.numDesiredClasses = 2;
            class = [ThemeClass createWithTitle:@"Day"];
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"Night"];
            [thm.classes addObject:class];
            break;
        case YearTheme:
            thm.legend.title = @"Year";
            thm.numDesiredClasses = 6;
            class = [ThemeClass createWithTitle:@"2010"];
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"2011"];
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"2012"];
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"2013"];
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"2014"];
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"2015"];
            [thm.classes addObject:class];
            break;
        case MonthTheme:
            thm.legend.title = @"Month";
            thm.numDesiredClasses = 12;
            class = [ThemeClass createWithTitle:@"Jan"];
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"Feb"];
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"Mar"];
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"Apr"];
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"May"];
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"Jun"];
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"Jul"];
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"Aug"];
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"Sep"];
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"Oct"];
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"Nov"];
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"Dec"];
            [thm.classes addObject:class];
            break;
        case DayofWeekTheme:
            thm.legend.title = @"Day";
            thm.numDesiredClasses = 7;
            class = [ThemeClass createWithTitle:@"Sun"];
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"Mon"];
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"Tue"];
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"Wed"];
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"Thu"];
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"Fri"];
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"Sat"];
            [thm.classes addObject:class];
            break;
        case HourTheme:
            thm.legend.title = @"Hour";
            thm.numDesiredClasses = 12;
            thm.legend.numColumns = 2;
            class = [ThemeClass createWithTitle:@"00-01"];
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"02-03"];
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"04-05"];
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"06-07"];
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"08-09"];
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"10-11"];
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"12-13"];
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"14-15"];
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"16-17"];
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"18-19"];
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"20-21"];
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"22-23"];
            [thm.classes addObject:class];
            break;
    }
    thm.numClasses = (int)[thm.classes count];
    thm.legend.numCells = thm.numClasses;
    return thm;
}

- (BOOL) incrementCount:(int)class
                     by:(double)val
                     dc:(DisplayCharacteristics *)dc
{
    BOOL rtn = FALSE;
    if (class >= 0 && class < _numDesiredClasses)
    {
        ThemeClass *cls =  _classes[class];
    
        if (_setSymbol)
            dc.pointSymbol = cls.symbol;

        cls.count += val;
        cls.numItems++;
        _totCount += val;
        _totNumItems ++;
        rtn = TRUE;
    }
    return rtn;
}

- (int) processTheme:(DisplayCharacteristics *)dc
                        displayID:(int)displayID
{
    int rtn = DO_NOT_DISPLAY_ITEM;
    if (displayID == _displayID)
    {
        time_t iTime = dc.itemBeginTime;
        //char* ctim = ctime (&iTime);
        struct tm tmtime = *localtime (&iTime);
        int val;
        switch (_type)
        {
            case Part1Theme:
                if (dc.UCR < 1 || dc.UCR > 10 || dc.UCR == 9)
                    break;
                if (dc.UCR < 3)
                    val = 0;
                else if (dc.UCR == 10)
                    val = 7;
                else
                    val = dc.UCR - 2;
                if ([self incrementCount:val
                                      by:1
                                      dc:dc])
                {
                    rtn = DISPLAY_ITEM;
                }
                break;
            case YearTheme:
                val = tmtime.tm_year + 1900;
                val -= 2010;
                if ([self incrementCount:val
                                      by:1
                                      dc:dc])
                    rtn = DISPLAY_ITEM;
                break;
            case MonthTheme:
                val = tmtime.tm_mon;
                if ([self incrementCount:val
                                      by:1
                                      dc:dc])
                    rtn = DISPLAY_ITEM;
                
                break;
            case DayofWeekTheme:
                val = tmtime.tm_wday;
                if ([self incrementCount:val
                                      by:1
                                      dc:dc])
                    rtn = DISPLAY_ITEM;
                break;
            case HourTheme:
                val = tmtime.tm_hour/2;
                if ([self incrementCount:val
                                      by:1
                                      dc:dc])
                    rtn = DISPLAY_ITEM;
                break;
        }
    }
    return rtn;
}

- (void) endDisplay:(int)displayID
{
    double maxPct = 0;
    
    if (displayID == _displayID)
    {
        if (_totCount > 0)
            for (ThemeClass *cls in _classes)
            {
                cls.pctOfTotal = cls.count / _totCount;
                maxPct = max (maxPct,cls.pctOfTotal);
            }
        
        if (maxPct > 0)
            for (ThemeClass *cls in _classes)
            {
                cls.symbolWidth = cls.pctOfTotal / maxPct;
            }
        _legend.cells = [[NSMutableArray alloc]init];
        for (ThemeClass *cls in _classes)
        {
            ThemeLegendCell * tlc = [ThemeLegendCell createWithLabel:cls.title];
            tlc.symbolColor = cls.color;
            tlc.symbolWidth = cls.symbolWidth;
            tlc.count = cls.numItems;
            [_legend.cells addObject:tlc];
        }
    }
}

- (ThemeLegend *)copyLegend
{
    ThemeLegend * copy = [_legend copy];
    return copy;
}
@end
