//
//  Theme.m
//  GMMobile
//
//  Created by JEFFREY E SMITH on 11/2/15.
//  Copyright © 2015 GSSi. All rights reserved.
//

#import "Theme.h"
#import "ThemeLegend.h"
#import "ConfigurationControl.h"
#import "PropertyList.h"
#import "NVMetroSettings.h"

@implementation Theme

- (id)init
{
    self = [super init];
    
    if (self)
        _showSymbolAsBarChart = YES;
    
    return self;
}

+ (NSString *)formattedDate:(NSDate *)date
{
    NSString *formattedDate = @"";
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"MM/dd/yyyy";
    formattedDate = [dateFormatter stringFromDate:date];
    
    return formattedDate;
}
+ (int) yearFromDate:(NSInteger)date
{
    NSString *dateString = [self formattedDate:[NSDate dateWithTimeIntervalSince1970:date]];
    
    LPSTR pYear = strrchr (dateString.UTF8String,'/');
    int iyear = atoi (++pYear);
    return iyear;
}

- (void) adjustClassTitles
{
    int maxLen = 0;
    for (ThemeClass *cls in _classes)
    {
        maxLen = max (maxLen,(int)cls.title.length);
    }
    for (ThemeClass *cls in _classes)
    {
        cls.title = [cls.title stringByPaddingToLength:maxLen withString: @" " startingAtIndex:0];
    }

}

+ (Theme *)createTheme:(ThemeTypes)type
{
    Theme * thm = [[Theme alloc]init];
    ThemeClass *class;
    thm.type = type;
    thm.setColor = NO;
    thm.legend = [[ThemeLegend alloc]init];
    thm.titles = [[NSMutableArray alloc]init];
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
    thm.legend.symbolDefaultColor = [UIColor greenColor];
    thm.legend.hasColors = YES;

    CGFloat PropListAlpha = 1.0-NVMetroSettings.sharedInstance.themeTransparency;
    UIColor *selectedColor = [UIColor colorWithRed:1 green:0 blue:0 alpha:1];
    switch (type)
    {
        case MetroPropTheme:
        {
            thm.setColor = YES;
            thm.legend.appendClassCount = YES;
            thm.subType = ConfigurationControl.sharedInstance.currentPropSheetFieldType;
            thm.legend.title = [NVMetroSettings.sharedInstance currentValueText];
            NSString * adjustText = [NSString stringWithFormat:@" %@",[NVMetroSettings.sharedInstance currentAdjustmentText]];
            if (![adjustText containsString:@" None"])
                thm.legend.title = [thm.legend.title stringByAppendingString:adjustText];
            [thm.titles addObject:thm.legend.title];
            thm.numDesiredClasses = NVMetroSettings.sharedInstance.numThemeClasses;
            thm.numDecimals = NVMetroSettings.sharedInstance.roundTo;
            NSNumber * themeMin = NVMetroSettings.sharedInstance.themeClassMin[0];
            NSNumber * themeMax = NVMetroSettings.sharedInstance.themeClassMax[thm.numDesiredClasses-1];
            NSNumber * rangeAveTop = NVMetroSettings.sharedInstance.themeClassAve[thm.numDesiredClasses-1];
            NSNumber * rangeAveBot = NVMetroSettings.sharedInstance.themeClassAve[0];
            double range = rangeAveTop.doubleValue - rangeAveBot.doubleValue;
            if (range <= 0)
                range = themeMax.integerValue - themeMin.integerValue;
            int targetClass = -1;
            if (NVMetroSettings.sharedInstance.overUnder && CRAPI.sharedInstance.currentPID)
            {
                long long intVal = IDNINT64(NVMetroSettings.sharedInstance.targetValue);
                for (int iClass=0;iClass < thm.numDesiredClasses;iClass++)
                {
                    NSNumber * min = NVMetroSettings.sharedInstance.themeClassMin[iClass];
                    NSNumber * max = NVMetroSettings.sharedInstance.themeClassMax[iClass];
                    if (intVal >=  min.longLongValue && NVMetroSettings.sharedInstance.targetValue <=  max.longLongValue)
                        targetClass = iClass;
                }
            }

            for (int iClass=0;iClass < thm.numDesiredClasses;iClass++)
            {
                NSNumber * count = NVMetroSettings.sharedInstance.themeClassCounts[iClass];
                NSNumber * min = NVMetroSettings.sharedInstance.themeClassMin[iClass];
                NSNumber * max = NVMetroSettings.sharedInstance.themeClassMax[iClass];
                NSNumber * ave = NVMetroSettings.sharedInstance.themeClassAve[iClass];
                if (thm.numDecimals)
                {
                    NSString * fmt = [NSString stringWithFormat:@"%%.%if to %%.%if",thm.numDecimals,thm.numDecimals];
                    class = [ThemeClass createWithTitle:[NSString stringWithFormat:fmt,min.doubleValue/pow(10,thm.numDecimals),max.doubleValue/pow(10,thm.numDecimals)]];
                }
                else
                    class = [ThemeClass createWithTitle:[NSString stringWithFormat:@"%li to %li",(long)min.integerValue,(long)max.integerValue]];
                class.minValue = min.longLongValue;
                class.maxValue = max.longLongValue;
                class.aveValue = ave.doubleValue;
                class.numItems = count.longLongValue;
//                double intensity = 1.0-((double)iClass+1)/thm.numDesiredClasses;
                double intensity = 0;
                if (range > 0)
                    intensity = 1.0-(class.aveValue - rangeAveBot.doubleValue)/range;
                class.color = [UIColor colorWithRed:1 green:intensity blue:intensity alpha:PropListAlpha];
                if (iClass == targetClass)
                    class.color = [UIColor colorWithRed:0 green:1 blue:0 alpha:PropListAlpha];
                else if (iClass < targetClass)
                    class.color = [UIColor colorWithRed:intensity green:intensity blue:1 alpha:PropListAlpha];
                [thm.classes addObject:class];
            }
            [thm adjustClassTitles];
        }
            break;
        case MetroLandUseTheme:
            thm.setColor = YES;
            thm.showSymbolAsBarChart = NO;
            thm.legend.appendClassCount = YES;
            thm.subType = ConfigurationControl.sharedInstance.currentPropSheetFieldType;
            thm.legend.title = [NVMetroSettings.sharedInstance currentValueText];
            [thm.titles addObject:thm.legend.title];
            thm.numDesiredClasses = 0;
            class = [ThemeClass createWithTitle:@"Single Family Residential"];
            class.values = @[@"111",@"112",@"113",@"116"];
            class.color = [UIColor colorWithRed:1 green:1 blue:0 alpha:PropListAlpha];
            if (ConfigurationControl.sharedInstance.currentApp == HCConfigFromSpreadsheet &&
                [PropertyList getBaseTypeForField:thm.subType] == PBT_Residential)
                class.color = selectedColor;
            [thm.classes addObject:class];thm.numDesiredClasses++;
            
            class = [ThemeClass createWithTitle:@"Multi Family Residential "];
            class.values = @[@"114",@"115"];
            class.color = [UIColor colorWithRed:1 green:1 blue:0.5 alpha:PropListAlpha];
            if (ConfigurationControl.sharedInstance.currentApp == HCConfigFromSpreadsheet &&
                [PropertyList getBaseTypeForField:thm.subType] == PBT_Residential)
                class.color = selectedColor;
            [thm.classes addObject:class];thm.numDesiredClasses++;
            
            class = [ThemeClass createWithTitle:@"Mixed Use Residential    "];
            class.values = @[@"141"];
            class.color = [UIColor colorWithRed:1 green:1 blue:0.75 alpha:PropListAlpha];
            if (ConfigurationControl.sharedInstance.currentApp == HCConfigFromSpreadsheet &&
                [PropertyList getBaseTypeForField:thm.subType] == PBT_Residential)
                class.color = selectedColor;
            [thm.classes addObject:class];thm.numDesiredClasses++;
            
            class = [ThemeClass createWithTitle:@"Retail/Commercial        "];
            class.values = @[@"120",@"143"];
            class.color = [UIColor colorWithRed:0.6 green:0.4 blue:0.2 alpha:PropListAlpha];;
            if (ConfigurationControl.sharedInstance.currentApp == HCConfigFromSpreadsheet &&
                [PropertyList getBaseTypeForField:thm.subType] == PBT_Commercial)
                class.color = selectedColor;
            [thm.classes addObject:class];thm.numDesiredClasses++;
            
            class = [ThemeClass createWithTitle:@"Office                   "];
            class.values = @[@"130"];
            class.color = [UIColor colorWithRed:1 green:0.5 blue:1 alpha:PropListAlpha];
            [thm.classes addObject:class];thm.numDesiredClasses++;
            
            class = [ThemeClass createWithTitle:@"Industrial"               ];
            class.values = @[@"142",@"151",@"153"];
            class.color = [UIColor colorWithRed:1 green:0.5 blue:0 alpha:PropListAlpha];
            if (ConfigurationControl.sharedInstance.currentApp == HCConfigFromSpreadsheet &&
                [PropertyList getBaseTypeForField:thm.subType] == PBT_Industrial)
                class.color = selectedColor;
            [thm.classes addObject:class];thm.numDesiredClasses++;
            
            class = [ThemeClass createWithTitle:@"Institutional"            ];
            class.values = @[@"160"];
            class.color = [UIColor colorWithRed:1 green:0 blue:1 alpha:PropListAlpha];
            [thm.classes addObject:class];thm.numDesiredClasses++;
            
            class = [ThemeClass createWithTitle:@"Highway/Railway"          ];
            class.values = @[@"201",@"202"];
            class.color = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:PropListAlpha];
            [thm.classes addObject:class];thm.numDesiredClasses++;
            
            class = [ThemeClass createWithTitle:@"Airport"                  ];
            class.values = @[@"203"];
            class.color = [UIColor colorWithRed:1 green:0 blue:0 alpha:PropListAlpha];
            [thm.classes addObject:class];thm.numDesiredClasses++;
            
            class = [ThemeClass createWithTitle:@"Park/Rec/Preserve"        ];
            class.values = @[@"170",@"173"];
            class.color = [UIColor colorWithRed:0.5 green:1 blue:0.5 alpha:PropListAlpha];
            if (ConfigurationControl.sharedInstance.currentApp == HCConfigFromSpreadsheet &&
                [PropertyList getBaseTypeForField:thm.subType] == PBT_OpenSpace)
                class.color = selectedColor;
            [thm.classes addObject:class];thm.numDesiredClasses++;
            
            class = [ThemeClass createWithTitle:@"Agriculture"              ];
            class.values = @[@"100"];
            class.color = [UIColor colorWithRed:0 green:1 blue:0 alpha:PropListAlpha];
            if (ConfigurationControl.sharedInstance.currentApp == HCConfigFromSpreadsheet &&
                [PropertyList getBaseTypeForField:thm.subType] == PBT_OpenSpace)
                class.color = selectedColor;
            [thm.classes addObject:class];thm.numDesiredClasses++;
            
            class = [ThemeClass createWithTitle:@"Undeveloped"              ];
            class.values = @[@"210"];
            class.color = [UIColor colorWithRed:0.75 green:1 blue:0.75 alpha:PropListAlpha];
            if (ConfigurationControl.sharedInstance.currentApp == HCConfigFromSpreadsheet &&
                [PropertyList getBaseTypeForField:thm.subType] == PBT_OpenSpace)
                class.color = selectedColor;
            [thm.classes addObject:class];thm.numDesiredClasses++;
            
            class = [ThemeClass createWithTitle:@"Water"                    ];
            class.values = @[@"220"];
            class.color = [UIColor colorWithRed:0 green:0 blue:1 alpha:PropListAlpha];
            if (ConfigurationControl.sharedInstance.currentApp == HCConfigFromSpreadsheet &&
                [PropertyList getBaseTypeForField:thm.subType] == PBT_OpenSpace)
                class.color = selectedColor;
            [thm.classes addObject:class];thm.numDesiredClasses++;
            
            [thm adjustClassTitles];
            break;
        case PropertyListTheme:
            thm.setColor = YES;
            thm.legend.appendClassCount = YES;
            thm.subType = ConfigurationControl.sharedInstance.currentPropSheetFieldType;
            thm.legend.title = @"Land Use";
            [thm.titles addObject:thm.legend.title];
            thm.numDesiredClasses = 0;
            class = [ThemeClass createWithTitle:@"Single Family Residential"];
            class.values = @[@"111",@"112",@"113",@"116"];
            class.color = [UIColor colorWithRed:1 green:1 blue:0 alpha:PropListAlpha];
            if ([PropertyList getBaseTypeForField:thm.subType] == PBT_Residential)
                class.color = selectedColor;
            [thm.classes addObject:class];thm.numDesiredClasses++;
            
            class = [ThemeClass createWithTitle:@"Multi Family Residential "];
            class.values = @[@"114",@"115"];
            class.color = [UIColor colorWithRed:1 green:1 blue:0.5 alpha:PropListAlpha];
            if ([PropertyList getBaseTypeForField:thm.subType] == PBT_Residential)
                class.color = selectedColor;
            [thm.classes addObject:class];thm.numDesiredClasses++;
            
            class = [ThemeClass createWithTitle:@"Mixed Use Residential    "];
            class.values = @[@"141"];
            class.color = [UIColor colorWithRed:1 green:1 blue:0.75 alpha:PropListAlpha];
            if ([PropertyList getBaseTypeForField:thm.subType] == PBT_Residential)
                class.color = selectedColor;
            [thm.classes addObject:class];thm.numDesiredClasses++;
            
            class = [ThemeClass createWithTitle:@"Retail/Commercial        "];
            class.values = @[@"120",@"143"];
            class.color = [UIColor colorWithRed:0.6 green:0.4 blue:0.2 alpha:PropListAlpha];;
            if ([PropertyList getBaseTypeForField:thm.subType] == PBT_Commercial)
                class.color = selectedColor;
            [thm.classes addObject:class];thm.numDesiredClasses++;
            
            class = [ThemeClass createWithTitle:@"Office                   "];
            class.values = @[@"130"];
            class.color = [UIColor colorWithRed:1 green:0.5 blue:1 alpha:PropListAlpha];
            [thm.classes addObject:class];thm.numDesiredClasses++;
            
            class = [ThemeClass createWithTitle:@"Industrial"               ];
            class.values = @[@"142",@"151",@"153"];
            class.color = [UIColor colorWithRed:1 green:0.5 blue:0 alpha:PropListAlpha];
            if ([PropertyList getBaseTypeForField:thm.subType] == PBT_Industrial)
                class.color = selectedColor;
            [thm.classes addObject:class];thm.numDesiredClasses++;
            
            class = [ThemeClass createWithTitle:@"Institutional"            ];
            class.values = @[@"160"];
            class.color = [UIColor colorWithRed:1 green:0 blue:1 alpha:PropListAlpha];
            [thm.classes addObject:class];thm.numDesiredClasses++;
            
            class = [ThemeClass createWithTitle:@"Highway/Railway"          ];
            class.values = @[@"201",@"202"];
            class.color = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:PropListAlpha];
            [thm.classes addObject:class];thm.numDesiredClasses++;
            
            class = [ThemeClass createWithTitle:@"Airport"                  ];
            class.values = @[@"203"];
            class.color = [UIColor colorWithRed:1 green:0 blue:0 alpha:PropListAlpha];
            [thm.classes addObject:class];thm.numDesiredClasses++;
            
            class = [ThemeClass createWithTitle:@"Park/Rec/Preserve"        ];
            class.values = @[@"170",@"173"];
            class.color = [UIColor colorWithRed:0.5 green:1 blue:0.5 alpha:PropListAlpha];
            if ([PropertyList getBaseTypeForField:thm.subType] == PBT_OpenSpace)
                class.color = selectedColor;
            [thm.classes addObject:class];thm.numDesiredClasses++;
            
            class = [ThemeClass createWithTitle:@"Agriculture"              ];
            class.values = @[@"100"];
            class.color = [UIColor colorWithRed:0 green:1 blue:0 alpha:PropListAlpha];
            if ([PropertyList getBaseTypeForField:thm.subType] == PBT_OpenSpace)
                class.color = selectedColor;
            [thm.classes addObject:class];thm.numDesiredClasses++;
            
            class = [ThemeClass createWithTitle:@"Undeveloped"              ];
            class.values = @[@"210"];
            class.color = [UIColor colorWithRed:0.75 green:1 blue:0.75 alpha:PropListAlpha];
            if ([PropertyList getBaseTypeForField:thm.subType] == PBT_OpenSpace)
                class.color = selectedColor;
            [thm.classes addObject:class];thm.numDesiredClasses++;
            
            class = [ThemeClass createWithTitle:@"Water"                    ];
            class.values = @[@"220"];
            class.color = [UIColor colorWithRed:0 green:0 blue:1 alpha:PropListAlpha];
            if ([PropertyList getBaseTypeForField:thm.subType] == PBT_OpenSpace)
                class.color = selectedColor;
            [thm.classes addObject:class];thm.numDesiredClasses++;
            [thm adjustClassTitles];
            break;
        case Part1Theme:
            thm.minUCR = 1;
            thm.maxUCR = 10;
            thm.legend.title = @"Part 1 Crimes";
            [thm.titles addObject:thm.legend.title];
            thm.setSymbol = YES;
            thm.legend.usePointSymbols = YES;
            thm.numDesiredClasses = 8;
            class = [ThemeClass createWithTitle:@"UCR 01-02: Homicide"];
            class.color = [UIColor greenColor];
            class.symbol = CrossSym;
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"UCR 03: Rape       "];
            class.color = [UIColor greenColor];
            class.symbol = DiamondSym;
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"UCR 04: Robbery    "];
            class.color = [UIColor greenColor];
            class.symbol = TriangleSym;
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"UCR 05: Agg Assault"];
            class.color = [UIColor greenColor];
            class.symbol = SquareSym;
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"UCR 06: Burglary   "];
            class.color = [UIColor greenColor];
            class.symbol = Star1Sym;
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"UCR 07: Larceny    "];
            class.color = [UIColor greenColor];
            class.symbol = Star2Sym;
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"UCR 08: Auto Theft "];
            class.color = [UIColor greenColor];
            class.symbol = CircleSym;
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"UCR 10: Arson      "];
            class.color = [UIColor greenColor];
            class.symbol = ArsonSym;
            [thm.classes addObject:class];
            break;
        case Part2Theme:
            thm.minUCR = 1;
            thm.maxUCR = 10;
            thm.legend.title = @"Part 1 Crimes";
            [thm.titles addObject:thm.legend.title];
            thm.setSymbol = YES;
            thm.legend.usePointSymbols = YES;
            thm.numDesiredClasses = 8;
            class = [ThemeClass createWithTitle:@"UCR 01-02: Homicide"];
            class.color = [UIColor greenColor];
            class.symbol = CrossSym;
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"UCR 03: Rape       "];
            class.color = [UIColor greenColor];
            class.symbol = DiamondSym;
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"UCR 04: Robbery    "];
            class.color = [UIColor greenColor];
            class.symbol = TriangleSym;
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"UCR 05: Agg Assault"];
            class.color = [UIColor greenColor];
            class.symbol = SquareSym;
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"UCR 06: Burglary   "];
            class.color = [UIColor greenColor];
            class.symbol = Star1Sym;
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"UCR 07: Larceny    "];
            class.color = [UIColor greenColor];
            class.symbol = Star2Sym;
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"UCR 08: Auto Theft "];
            class.color = [UIColor greenColor];
            class.symbol = CircleSym;
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"UCR 10: Arson      "];
            class.color = [UIColor greenColor];
            class.symbol = ArsonSym;
            [thm.classes addObject:class];
            break;
        case AssaultTheme:
            thm.minUCR = 1;
            thm.maxUCR = 10;
            thm.legend.title = @"Part 1 Crimes";
            [thm.titles addObject:thm.legend.title];
            thm.setSymbol = YES;
            thm.legend.usePointSymbols = YES;
            thm.numDesiredClasses = 8;
            class = [ThemeClass createWithTitle:@"UCR 01-02: Homicide"];
            class.color = [UIColor greenColor];
            class.symbol = CrossSym;
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"UCR 03: Rape       "];
            class.color = [UIColor greenColor];
            class.symbol = DiamondSym;
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"UCR 04: Robbery    "];
            class.color = [UIColor greenColor];
            class.symbol = TriangleSym;
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"UCR 05: Agg Assault"];
            class.color = [UIColor greenColor];
            class.symbol = SquareSym;
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"UCR 06: Burglary   "];
            class.color = [UIColor greenColor];
            class.symbol = Star1Sym;
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"UCR 07: Larceny    "];
            class.color = [UIColor greenColor];
            class.symbol = Star2Sym;
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"UCR 08: Auto Theft "];
            class.color = [UIColor greenColor];
            class.symbol = CircleSym;
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"UCR 10: Arson      "];
            class.color = [UIColor greenColor];
            class.symbol = ArsonSym;
            [thm.classes addObject:class];
            break;
        case DepartmentTheme:
            thm.legend.title = @"Department";
            [thm.titles addObject:thm.legend.title];
            thm.numDesiredClasses = 4;
            class = [ThemeClass createWithTitle:@"MP"];
            class.color = [UIColor greenColor];
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"UM"];
            class.color = [UIColor greenColor];
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"CR"];
            class.color = [UIColor greenColor];
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"MT"];
            class.color = [UIColor greenColor];
            [thm.classes addObject:class];
            break;
        case DayNightTheme:
            thm.setColor = YES;
            thm.legend.title = @"Day - Night";
            [thm.titles addObject:thm.legend.title];
            thm.numDesiredClasses = 2;
            class = [ThemeClass createWithTitle:@"Day  "];
            class.color = [UIColor yellowColor];
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"Night"];
            class.color = [UIColor blueColor];
            [thm.classes addObject:class];
            break;
        case YearTheme:
        {
            int startYear = [self yearFromDate:CRAPI.sharedInstance.fromDate];
            int endYear = [self yearFromDate:CRAPI.sharedInstance.toDate];

            thm.legend.title = @"Year";
            thm.minYear = startYear;
            thm.maxYear = endYear;
            [thm.titles addObject:thm.legend.title];
            thm.numDesiredClasses = endYear - startYear + 1;
            
            for (int year = startYear;year <= endYear;year++)
            {
                class = [ThemeClass createWithTitle:[NSString stringWithFormat:@"%i",year]];
                class.color = [UIColor greenColor];
                [thm.classes addObject:class];
            }
        }
            break;
        case MonthTheme:
            thm.legend.title = @"Month";
            [thm.titles addObject:thm.legend.title];
            thm.numDesiredClasses = 12;
            class = [ThemeClass createWithTitle:@"Jan"];
            class.color = [UIColor greenColor];
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"Feb"];
            class.color = [UIColor greenColor];
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"Mar"];
            class.color = [UIColor greenColor];
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"Apr"];
            class.color = [UIColor greenColor];
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"May"];
            class.color = [UIColor greenColor];
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"Jun"];
            class.color = [UIColor greenColor];
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"Jul"];
            class.color = [UIColor greenColor];
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"Aug"];
            class.color = [UIColor greenColor];
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"Sep"];
            class.color = [UIColor greenColor];
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"Oct"];
            class.color = [UIColor greenColor];
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"Nov"];
            class.color = [UIColor greenColor];
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"Dec"];
            class.color = [UIColor greenColor];
            [thm.classes addObject:class];
            break;
        case DayofWeekTheme:
            thm.legend.title = @"Day";
            [thm.titles addObject:thm.legend.title];
            thm.numDesiredClasses = 7;
            class = [ThemeClass createWithTitle:@"Sun"];
            class.color = [UIColor greenColor];
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"Mon"];
            class.color = [UIColor greenColor];
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"Tue"];
            class.color = [UIColor greenColor];
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"Wed"];
            class.color = [UIColor greenColor];
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"Thu"];
            class.color = [UIColor greenColor];
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"Fri"];
            class.color = [UIColor greenColor];
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"Sat"];
            class.color = [UIColor greenColor];
            [thm.classes addObject:class];
            break;
        case HourTheme:
            thm.legend.title = @"Hour";
            [thm.titles addObject:thm.legend.title];
            thm.numDesiredClasses = 12;
            thm.legend.numColumns = 2;
            class = [ThemeClass createWithTitle:@"00-01"];
            class.color = [UIColor greenColor];
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"02-03"];
            class.color = [UIColor greenColor];
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"04-05"];
            class.color = [UIColor greenColor];
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"06-07"];
            class.color = [UIColor greenColor];
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"08-09"];
            class.color = [UIColor greenColor];
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"10-11"];
            class.color = [UIColor greenColor];
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"12-13"];
            class.color = [UIColor greenColor];
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"14-15"];
            class.color = [UIColor greenColor];
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"16-17"];
            class.color = [UIColor greenColor];
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"18-19"];
            class.color = [UIColor greenColor];
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"20-21"];
            class.color = [UIColor greenColor];
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"22-23"];
            class.color = [UIColor greenColor];
            [thm.classes addObject:class];
            break;
        case CurbRampIntersectionTheme:
            thm.legend.title = @"Intersections";
            [thm.titles addObject:thm.legend.title];
            thm.numDesiredClasses = 4;
            class = [ThemeClass createWithTitle:@"Original   "];
            class.color = [UIColor yellowColor];
            class.size = 1;
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"Scheduled  "];
            class.color = [UIColor greenColor];
            class.size = 2;
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"Built      "];
            class.color = [UIColor blueColor];
            class.size = 2;
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"Inventoried"];
            class.color = [UIColor redColor];
            class.size = 2;
            [thm.classes addObject:class];
            break;
        case CurbRampTheme:
        {
            int crtOpt = getThemeOpt(type);
            
            thm.currentTitleIndex = crtOpt-1;
            [thm.titles addObject:@"Ramp Types"];
            [thm.titles addObject:@"Material"];
            [thm.titles addObject:@"Year"];
            [thm.titles addObject:@"Excessive Slope"];
            thm.legend.usePointSymbols = YES;
            switch (crtOpt)
            {
                    
                default:
                    thm.legend.title = @"Ramp Types";
                    thm.numDesiredClasses = 10;
                    class = [ThemeClass createWithTitle:@"0-Unknown                      "];
                    class.color = [UIColor blackColor];
                    class.size = 1;
                    class.symbol = CircleSym;
                    [thm.classes addObject:class];
                    class = [ThemeClass createWithTitle:@"1-Perpendicular                "];
                    class.color = [UIColor yellowColor];
                    class.size = 1;
                    class.symbol = CircleSym;
                    [thm.classes addObject:class];
                    class = [ThemeClass createWithTitle:@"2-Perpendicular Non Walkable   "];
                    class.color = [UIColor greenColor];
                    class.size = 2;
                    class.symbol = CircleSym;
                    [thm.classes addObject:class];
                    class = [ThemeClass createWithTitle:@"3-Combined Perp. Walkable      "];
                    class.color = [UIColor blueColor];
                    class.size = 2;
                    class.symbol = CircleSym;
                    [thm.classes addObject:class];
                    class = [ThemeClass createWithTitle:@"4-Combined Perp. Non Walkable  "];
                    class.color = [UIColor grayColor];
                    class.size = 2;
                    class.symbol = CircleSym;
                    [thm.classes addObject:class];
                    class = [ThemeClass createWithTitle:@"5-One Way Dir. Adj. Curb/Gutter"];
                    class.color = [UIColor magentaColor];
                    class.size = 2;
                    class.symbol = CircleSym;
                    [thm.classes addObject:class];
                    class = [ThemeClass createWithTitle:@"6-One Way Dir. Blended Trans.  "];
                    class.color = [UIColor brownColor];
                    class.size = 2;
                    class.symbol = CircleSym;
                    [thm.classes addObject:class];
                    class = [ThemeClass createWithTitle:@"7-Parallel                     "];
                    class.color = [UIColor purpleColor];
                    class.size = 2;
                    class.symbol = CircleSym;
                    [thm.classes addObject:class];
                    class = [ThemeClass createWithTitle:@"8-Depressed Corner             "];
                    class.color = [UIColor redColor];
                    class.size = 2;
                    class.symbol = CircleSym;
                    [thm.classes addObject:class];
                    class = [ThemeClass createWithTitle:@"9-Fan                          "];
                    class.color = [UIColor orangeColor];
                    class.size = 2;
                    class.symbol = CircleSym;
                    [thm.classes addObject:class];
                    break;
                case 3:
                    
                    thm.legend.title = @"Year Rebuilt";
                    thm.numDesiredClasses = 4;
                    class = [ThemeClass createWithTitle:@"    "];
                    class.color = [UIColor blackColor];
                    class.size = 1;
                    class.symbol = CircleSym;
                    [thm.classes addObject:class];
                    class = [ThemeClass createWithTitle:@"2013"];
                    class.color = [UIColor yellowColor];
                    class.size = 1;
                    class.symbol = CircleSym;
                    [thm.classes addObject:class];
                    class = [ThemeClass createWithTitle:@"2014"];
                    class.color = [UIColor greenColor];
                    class.size = 2;
                    class.symbol = CircleSym;
                    [thm.classes addObject:class];
                    class = [ThemeClass createWithTitle:@"2015"];
                    class.color = [UIColor blueColor];
                    class.size = 2;
                    class.symbol = CircleSym;
                    [thm.classes addObject:class];
                    break;
            }
        }
            break;
        case MGVHydrantTheme:
            thm.setColor = YES;
            thm.legend.title = @"Hydrant Thread";
            [thm.titles addObject:thm.legend.title];
            thm.numDesiredClasses = 2;
            class = [ThemeClass createWithTitle:@"Minneapolis "];
            class.color = [UIColor yellowColor];
            class.size = 1;
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"National Std"];
            class.color = [UIColor greenColor];
            class.size = 2;
            [thm.classes addObject:class];
            break;
        case MGVWaterMeterTheme:
        case MGVWaterLineTheme:
            thm.setColor = YES;
            thm.legend.title = @"Pipe Material";
            [thm.titles addObject:thm.legend.title];
            thm.numDesiredClasses = 8;
            class = [ThemeClass createWithTitle:@"CIPP   "];
            class.color = [UIColor yellowColor];
            class.size = 1;
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"COP    "];
            class.color = [UIColor greenColor];
            class.size = 2;
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"DIP    "];
            class.color = [UIColor blueColor];
            class.size = 2;
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"HDPE   "];
            class.color = [UIColor cyanColor];
            class.size = 2;
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"Irrigat"];
            class.color = [UIColor blackColor];
            class.size = 2;
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"LockJnt"];
            class.color = [UIColor redColor];
            class.size = 2;
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"PVC    "];
            class.color = [UIColor brownColor];
            class.size = 2;
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"Other  "];
            class.color = [UIColor orangeColor];
            class.size = 2;
            [thm.classes addObject:class];
            break;
        case MGVFiberLineTheme:
            thm.setColor = YES;
            thm.legend.title = @"Fiber Strands";
            [thm.titles addObject:thm.legend.title];
            thm.numDesiredClasses = 9;
            class = [ThemeClass createWithTitle:@"0  "];
            class.color = [UIColor yellowColor];
            class.size = 1;
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"12 "];
            class.color = [UIColor greenColor];
            class.size = 1;
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"24 "];
            class.color = [UIColor greenColor];
            class.size = 1;
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"36 "];
            class.color = [UIColor greenColor];
            class.size = 1;
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"48 "];
            class.color = [UIColor greenColor];
            class.size = 1;
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"72 "];
            class.color = [UIColor greenColor];
            class.size = 1;
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"84 "];
            class.color = [UIColor greenColor];
            class.size = 1;
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"96 "];
            class.color = [UIColor greenColor];
            class.size = 1;
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"120"];
            class.color = [UIColor greenColor];
            class.size = 1;
            [thm.classes addObject:class];
            break;
        case MGVFiberPointTheme:
            thm.setColor = YES;
            thm.legend.title = @"Fiber Point";
            [thm.titles addObject:thm.legend.title];
            thm.numDesiredClasses = 9;
            class = [ThemeClass createWithTitle:@"Building        "];
            class.color = [UIColor yellowColor];
            class.size = 1;
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"Hand Hole       "];
            class.color = [UIColor greenColor];
            class.size = 1;
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"Lateral         "];
            class.color = [UIColor greenColor];
            class.size = 1;
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"Patch Panel     "];
            class.color = [UIColor greenColor];
            class.size = 1;
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"Splice-Vault    "];
            class.color = [UIColor greenColor];
            class.size = 1;
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"Valve Box       "];
            class.color = [UIColor greenColor];
            class.size = 1;
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"Vault           "];
            class.color = [UIColor greenColor];
            class.size = 1;
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"Water Tower Base"];
            class.color = [UIColor greenColor];
            class.size = 1;
            [thm.classes addObject:class];
            class = [ThemeClass createWithTitle:@"Other           "];
            class.color = [UIColor greenColor];
            class.size = 1;
            [thm.classes addObject:class];
            break;
    }
    
    thm.numClasses = (int)thm.classes.count;
    thm.legend.type = thm.type;
    thm.legend.titles = [NSMutableArray arrayWithArray:thm.titles];
    thm.legend.currentTitleIndex = thm.currentTitleIndex;
    thm.legend.numCells = thm.numClasses;
    thm.legend.useClassColors = thm.setColor;
    thm.legend.showSymbolAsBarChart = thm.showSymbolAsBarChart;
    thm.legend.cells = [[NSMutableArray alloc]init];
    
    for (ThemeClass *cls in thm.classes)
    {
        ThemeLegendCell * tlc = [ThemeLegendCell createWithLabel:cls.title];
        tlc.symbol = cls.symbol;
        tlc.symbolColor = cls.color;
        tlc.symbolWidth = cls.symbolWidth;
        tlc.count = (int)cls.numItems;
        tlc.status = cls.status;
        [thm.legend.cells addObject:tlc];
    }
    
    return thm;
}

int getThemeOpt(ThemeTypes type)
{
    int opt = 1;
    for (ThemeLegend *tleg in ConfigurationControl.sharedInstance.legendList)
    {
        if (tleg.type == type)
        {
            opt = tleg.currentTitleIndex + 1;
        }
    }

    return opt;
}

- (BOOL) incrementCount:(int)class
                     by:(double)val
                     dc:(DisplayCharacteristics *)dc
               testPass:(BOOL)test
{
    BOOL rtn = FALSE;
    
    if (class >= 0 && class < _numDesiredClasses)
    {
        ThemeClass *cls =  _classes[class];
        
        if (!cls.status)
        {
            if (!test)
            {
                if (_setSymbol)
                    dc.pointSymbol = cls.symbol;
                
                if (_setColor)
                {
                    dc.fillColor = cls.color;
                    dc.size = cls.size;
                }
                
                cls.count += val;
                cls.numItems++;
                _totCount += val;
                _totNumItems ++;
            }
            
            rtn = TRUE;
        }
    }
    return rtn;
}

- (BOOL) classIsSelected:(int)iclass
{
    BOOL rtn = FALSE;
    
    if (iclass >= 0 && iclass < self.numClasses)
    {
        ThemeClass * tc = self.classes[iclass];
        rtn = !tc.status;
    }
    return rtn;
}

- (int) classFromUCR:(int)ucr
{
    int iclass = -1;
    switch (self.type)
    {
        case Part1Theme:
            if (ucr < 1 || ucr > 10 || ucr == 9)
                break;
            if (ucr < 3)
                iclass = 0;
            else if (ucr == 10)
                iclass = 7;
            else
                iclass = ucr - 2;
            break;
        default:
            break;
    }
    return iclass;
}

- (BOOL) classValues:(NSArray*)values
      containInteger:(long long)ival
{
    for (NSNumber *num in values)
    {
        if (num.longLongValue == ival)
            return TRUE;
    }
    return FALSE;
}
- (int) processTheme:(DisplayCharacteristics *)dc
           displayID:(int)displayID
            testPass:(BOOL)test
{
    int rtn = DO_NOT_DISPLAY_ITEM;
    if (!displayID || displayID == _displayID)
    {
        time_t iTime = dc.itemBeginTime;
        //char* ctim = ctime (&iTime);
        struct tm tmtime = *localtime (&iTime);
        int val;
        switch (_type)
        {
            case ColorByRefnoTheme:
            {
                dc.fillColor = UIColorFromInt ((unsigned int)dc.refno);
                rtn = DISPLAY_ITEM;
            }
                break;
            case PropertyListTheme:
                switch (_subType)//propListValue
            {
                case PFT_PctIndustrial_Mile:
                case PFT_PctIndustrial_halfMile:
                case PFT_PctResidential_Mile:
                case PFT_PctResidential_halfMile:
                case PFT_PctCommercial_Mile:
                case PFT_PctCommercial_halfMile:
                case PFT_PctOpenSpace_Mile:
                case PFT_PctOpenSpace_halfMile:
                case PFT_Stability5yr_halfMile:
                case PFT_Stability5yr_Mile:
                case PFT_Stability15yr_halfMile:
                case PFT_Stability15yr_Mile:
                {
                    val = 0;
                    rtn = DO_NOT_DISPLAY_ITEM;
                    for (ThemeClass *cls in _classes)
                    {
                        if ([self classValues:cls.values containInteger:dc.iValue])
                        {
                            if ([self incrementCount:val
                                                  by:1
                                                  dc:dc
                                            testPass:test])
                                rtn = DISPLAY_ITEM;
                            break;
                        }
                        val++;
                    }
                    
                }
                    break;
            }
                break;
            case MetroLandUseTheme:
            {
                val = 0;
                rtn = DO_NOT_DISPLAY_ITEM;
                for (ThemeClass *cls in _classes)
                {
                    if ([self classValues:cls.values containInteger:dc.iValue])
                    {
                        if ([self incrementCount:val
                                              by:1
                                              dc:dc
                                        testPass:test])
                            rtn = DISPLAY_ITEM;
                        if (!val)
                            val = 0;
                        break;
                    }
                    val++;
                }
                
            }
                break;
            case MetroPropTheme:
                val = 0;
                rtn = DO_NOT_DISPLAY_ITEM;
                for (ThemeClass *cls in _classes)
                {
                    if (dc.iValue >= cls.minValue && dc.iValue <= cls.maxValue)
                    {
                        if ([self incrementCount:val
                                              by:1
                                              dc:dc
                                        testPass:test])
                            rtn = DISPLAY_ITEM;
                        if (val == _classes.count-1)//debug
                            rtn = DISPLAY_ITEM;

                        break;
                    }
                    val++;
                }
                
                
                break;
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
                                      dc:dc
                                testPass:test])
                {
                    rtn = DISPLAY_ITEM;
                }
                break;
            case DepartmentTheme:
                val = 0;
                rtn = DO_NOT_DISPLAY_ITEM;
                //int ii=0;
                for (ThemeClass *cls in _classes)
                {
                    if ([dc.string2 isEqualToString:cls.title])
                    {
                        //ii=1;
                        
                        if ([self incrementCount:val
                                              by:1
                                              dc:dc
                                        testPass:test])
                            rtn = DISPLAY_ITEM;
                        break;
                    }
                    val++;
                }
                //if (!ii)
                    //ii=1;
                break;
            case DayNightTheme:
            {
                double Altitude=dc.sunAngle, Az;
                //GetAltitudeAndAzOfSun (dc.dPoint,0,iTime,&Altitude,&Az);
                if (Altitude < -6.0)
                    val = 1;
                else
                    val = 0;
                if ([self incrementCount:val
                                      by:1
                                      dc:dc
                                testPass:test])
                rtn = DISPLAY_ITEM;
            }
                break;
            case YearTheme:
                val = tmtime.tm_year + 1900;
                val -= self.minYear;
                if ([self incrementCount:val
                                      by:1
                                      dc:dc
                                testPass:test])
                    rtn = DISPLAY_ITEM;
                break;
            case MonthTheme:
                val = tmtime.tm_mon;
                if ([self incrementCount:val
                                      by:1
                                      dc:dc
                                testPass:test])
                    rtn = DISPLAY_ITEM;
                
                break;
            case DayofWeekTheme:
                val = tmtime.tm_wday;
                if ([self incrementCount:val
                                      by:1
                                      dc:dc
                                testPass:test])
                    rtn = DISPLAY_ITEM;
                break;
            case HourTheme:
                val = tmtime.tm_hour/2;
                if ([self incrementCount:val
                                      by:1
                                      dc:dc
                                testPass:test])
                    rtn = DISPLAY_ITEM;
                break;
            case CurbRampIntersectionTheme:
                if (dc.elementType != StreetIntersection)
                    goto DisplayExit;
                val = (int)dc.string2.integerValue;
                if ([self incrementCount:val
                                      by:1
                                      dc:dc
                                testPass:test])
                    rtn = DISPLAY_ITEM;
                break;
            case CurbRampTheme:
                if (dc.elementType != CurbRamp)
                    goto DisplayExit;
                if (self.currentTitleIndex == 3)
                    val = dc.itemEndTime-2012;
                else
                    val = (int)dc.string2.integerValue;
                if ([self incrementCount:val
                                      by:1
                                      dc:dc
                                testPass:test])
                    rtn = DISPLAY_ITEM;
                break;
            case MGVWaterLineTheme:
                if (dc.elementType != WaterMain)
                    goto DisplayExit;
                val = 0;
                for (ThemeClass * cls in _classes)
                {
                    if ([cls.title isEqualToString:@"Other"] || [cls.title containsString:dc.string2])
                    {
                        if ([self incrementCount:val
                                              by:1
                                              dc:dc
                                        testPass:test])
                            rtn = DISPLAY_ITEM;
                        break;
                    }
                    val++;
                }
                break;
            case MGVWaterMeterTheme:
                if (dc.elementType != WaterMeter)
                    goto DisplayExit;
                val = 0;
                for (ThemeClass * cls in _classes)
                {
                    if (dc.string2 && [cls.title containsString:dc.string2])
                    {
                        if ([self incrementCount:val
                                              by:1
                                              dc:dc
                                        testPass:test])
                            rtn = DISPLAY_ITEM;
                        break;
                    }
                    val++;
                }
                break;
            case MGVHydrantTheme:
                if (dc.elementType != Hydrant)
                    goto DisplayExit;
                val = 0;
                for (ThemeClass * cls in _classes)
                {
                    NSString * classType = [[cls.title substringToIndex:5] uppercaseString];
                    NSString * recordType = [dc.string2 uppercaseString];
                    if ([recordType containsString:classType])
                    {
                        if ([self incrementCount:val
                                              by:1
                                              dc:dc
                                        testPass:test])
                            rtn = DISPLAY_ITEM;
                        break;
                    }
                    val++;
                }
                break;
            case MGVFiberLineTheme:
                if (dc.elementType != FiberLines)
                    goto DisplayExit;
                val = 0;
                for (ThemeClass * cls in _classes)
                {
                    int classVal = cls.title.intValue;
                    if (dc.UCR == classVal)
                    {
                        if ([self incrementCount:val
                                              by:1
                                              dc:dc
                                        testPass:test])
                            rtn = DISPLAY_ITEM;
                        break;
                    }
                    val++;
                }
            case MGVFiberPointTheme:
                if (dc.elementType != FiberPoints)
                    goto DisplayExit;
                val = 0;
                for (ThemeClass * cls in _classes)
                {
                    NSString * classType = [cls.title uppercaseString];
                    NSString * recordType = [dc.string2 uppercaseString];
                    if ([classType containsString:@"OTHER"] || [classType containsString:recordType])
                    {
                        if ([self incrementCount:val
                                              by:1
                                              dc:dc
                                        testPass:test])
                            rtn = DISPLAY_ITEM;
                        break;
                    }
                    val++;
                }
                break;
                
            default:
                break;
        }
    }
    return rtn;
DisplayExit:
    return DISPLAY_ITEM;
}

- (void) beginDisplay:(int)displayID
{
   
    if (displayID == _displayID)
    {
        _totCount = 0;
        _totNumItems = 0;
        for (ThemeClass *cls in _classes)
        {
            cls.count = 0;
            cls.numItems = 0;
        }
    }
}

- (void) endDisplay:(int)displayID
{
    double maxPct = 0;
    
    if (displayID == _displayID)
    {
        _legend.useClassColors = _setColor;
        _legend.maxValBounds = _maxValBounds;
        for (ThemeClass *cls in _classes)
        {
            if (_totCount > 0)
                cls.pctOfTotal = cls.count / _totCount;
            else
                cls.pctOfTotal = 0;
            maxPct = max (maxPct,cls.pctOfTotal);
        }
        
        for (ThemeClass *cls in _classes)
        {
            if (maxPct > 0)
                cls.symbolWidth = cls.pctOfTotal / maxPct;
            else
                cls.symbolWidth = 0;
        }
        int i=0;
        for (ThemeClass *cls in _classes)
        {
            ThemeLegendCell * tlc = _legend.cells[i++];
            tlc.symbolWidth = cls.symbolWidth;
            tlc.count = (int)cls.numItems;
            tlc.status = cls.status;
        }
    }
}

- (ThemeLegend *)copyLegend
{
    ThemeLegend * copy = [_legend copy];
    return copy;
}
@end
