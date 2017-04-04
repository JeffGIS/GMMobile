//
//  Themes.m
//  GMMobile
//
//  Created by JEFFREY E SMITH on 11/17/15.
//  Copyright © 2015 GSSi. All rights reserved.
//
//extern int CRAPI.sharedInstance.keepProcessing;

#import "Themes.h"
#import "NVMetroSettings.h"

@implementation UCRRange
@end

@implementation Themes

- (void)setAppThemes
{
    Theme *thm;
    
    if (ConfigurationControl.sharedInstance.legendApp != ConfigurationControl.sharedInstance.currentApp)
        [self destroyCurrentThemes];
    
    ConfigurationControl.sharedInstance.legendApp = ConfigurationControl.sharedInstance.currentApp;
    
    _themeList = NSMutableArray.array;
    
    switch (ConfigurationControl.sharedInstance.currentApp)
    {
        case HCConfigFromSpreadsheet:
        case HCConfigFromSlowValues:
        {
            if (ConfigurationControl.sharedInstance.currentMapitBaseLayer == MBL_LandUse)
                thm = [Theme createTheme:MetroLandUseTheme];
            else
                thm = [Theme createTheme:ColorByRefnoTheme];
            [_themeList addObject:thm];
        }
            break;
        case HCConfigCrimes:
        {
            NSString *crimeLegend = [UserDefaults.defaults stringForKey:@"SelectedLegend"];
            
            NSString *crimeCompare = [UserDefaults.defaults stringForKey:@"CrimeCompareValue"];
            
            thm = [Theme createTheme:Part1Theme];
            if ([crimeLegend isEqualToString:@"Part 2 Offenses"])
                thm = [Theme createTheme:Part2Theme];
            if ([crimeLegend isEqualToString:@"Assault"])
                thm = [Theme createTheme:AssaultTheme];
            if ([crimeLegend isEqualToString:@"Burglary"])
                thm = [Theme createTheme:BurglaryTheme];
            if ([crimeLegend isEqualToString:@"Robbery"])
                thm = [Theme createTheme:RobberyTheme];
            if ([crimeLegend isEqualToString:@"Narcotics"])
                thm = [Theme createTheme:NarcoticsTheme];
            if ([crimeLegend isEqualToString:@"Motor Vehicle Theft"])
                thm = [Theme createTheme:MotorVehicleTheftTheme];
            if ([crimeLegend isEqualToString:@"Selected Theft"])
                thm = [Theme createTheme:SelectedTheftTheme];
            if ([crimeLegend isEqualToString:@"Theft From Auto"])
                thm = [Theme createTheme:TheftFromAutoTheme];
            [_themeList addObject:thm];
            thm = [Theme createTheme:DepartmentTheme];
            [_themeList addObject:thm];
            thm = [Theme createTheme:DayNightTheme];
            [_themeList addObject:thm];
            
            thm = [Theme createTheme:YearTheme];
            [_themeList addObject:thm];
            if ([crimeCompare isEqualToString:@"Month With Monthly Compare"])
                thm = [Theme createTheme:ThirteenMonthTheme];
            else
                thm = [Theme createTheme:MonthTheme];
            [_themeList addObject:thm];
            thm = [Theme createTheme:DayofWeekTheme];
            [_themeList addObject:thm];
            thm = [Theme createTheme:HourTheme];
            [_themeList addObject:thm];
        }
            break;
        case HCConfigCurbRamps:
            thm = [Theme createTheme:CurbRampIntersectionTheme];
            [_themeList addObject:thm];
            thm = [Theme createTheme:CurbRampTheme];
            [_themeList addObject:thm];
            break;
        case HCConfigMapleGrove:
            thm = [Theme createTheme:MGVWaterLineTheme];
            [_themeList addObject:thm];
            thm = [Theme createTheme:MGVHydrantTheme];
            [_themeList addObject:thm];
            thm = [Theme createTheme:MGVFiberLineTheme];
            [_themeList addObject:thm];
            thm = [Theme createTheme:MGVFiberPointTheme];
            [_themeList addObject:thm];
            thm = [Theme createTheme:MGVWaterMeterTheme];
            [_themeList addObject:thm];
            break;
        case HCConfigMetroProp:
            if ([NVMetroSettings.sharedInstance currentValueFields].length < 1)
                break;
            if (NVMetroSettings.sharedInstance.currentFeature == CPFLandUse)
            {
                if (NVMetroSettings.sharedInstance.currentFeatureValue)
                {
                    thm = [Theme createTheme:MetroLandUseTheme];
                    [_themeList addObject:thm];
                }
            }
            else
            {
                thm = [Theme createTheme:MetroPropTheme];
                if (thm)
                    [_themeList addObject:thm];
            }
            break;
        default:
            break;
    }
    thm.displayID = _displayID;

    if (!ConfigurationControl.sharedInstance.legendList)
    {
        ConfigurationControl.sharedInstance.legendList = [[NSMutableArray alloc]init];
        for (Theme *thm in _themeList)
        {
            ThemeLegend * lgnd = [thm copyLegend];
            [ConfigurationControl.sharedInstance.legendList addObject:lgnd];
        }
    }
    
    else
    {
        int i=0;
        
        for (Theme *thm in _themeList)
        {
            if (ConfigurationControl.sharedInstance.legendList.count > i)
            {
                ThemeLegend *tl = ConfigurationControl.sharedInstance.legendList[i++];
                if (tl.type == thm.type)
                {
                    int j=0;
                    thm.legend.scrollYPosition = tl.scrollYPosition;
                    thm.legend.portraitMapOrigin = tl.portraitMapOrigin;
                    thm.legend.landscapeMapOrigin = tl.landscapeMapOrigin;
                    thm.legend.isDraggedPortrait = tl.isDraggedPortrait;
                    thm.legend.isDraggedLandscape = tl.isDraggedLandscape;
                    for (ThemeLegendCell *tlc in thm.legend.cells)
                    {
                        if (tl.cells.count > j)
                        {
                            ThemeLegendCell *cl = tl.cells[j++];
                            tlc.status = cl.status;
                            cl.symbolColor = tlc.symbolColor;
                        }
                    }
                }
            }
        }
    }
}

- (BOOL) addTheme:(Theme *)theme
{
    BOOL rtn = FALSE;
    
    return rtn;
}

- (void) destroyCurrentThemes
{
    ConfigurationControl.sharedInstance.legendList = nil;
    _themeList = nil;
}

- (ItemProcessingPassTypes)themesNeedDataPass:(int)displayID
{
    ItemProcessingPassTypes rtn = DisplayPass;
    int i = 0;
    
    for (Theme *thm in _themeList)
    {
        thm.displayID = displayID;
        if (thm.type == MetroPropTheme)
            rtn = DataPass;
        if (ConfigurationControl.sharedInstance.currentApp == HCConfigFromSpreadsheet ||
            ConfigurationControl.sharedInstance.currentApp == HCConfigFromSlowValues)
            rtn = DataPass;
        if (ConfigurationControl.sharedInstance.legendList.count > i)
        {
            ThemeLegend *tleg = ConfigurationControl.sharedInstance.legendList[i];
            if (tleg.type == thm.type)
            {
                int j = 0;
                thm.legend.portraitMapOrigin = tleg.portraitMapOrigin;
                thm.legend.landscapeMapOrigin = tleg.landscapeMapOrigin;
                thm.legend.isDraggedLandscape = tleg.isDraggedLandscape;
                thm.legend.isDraggedPortrait = tleg.isDraggedPortrait;
                thm.legend.title = tleg.title;
                thm.legend.currentTitleIndex = tleg.currentTitleIndex;
                thm.legend.type = tleg.type;
                
                for (ThemeClass * cls in thm.classes)
                {
                    if (tleg.cells.count > j)
                    {
                        ThemeLegendCell *tlc = tleg.cells[j++];
                        cls.status = tlc.status;
                        cls.color = tlc.symbolColor;
                    }
                }
            }
        }
        
        i++;
    }
    
    return rtn;
}

- (void) themesBeginDataPass:(int)displayID
{
}

- (void) themesEndDataPass:(int)displayID
{
}

- (void) themesBeginDisplayPass:(int)displayID
{
    for (Theme *thm in _themeList)
    {
        [thm beginDisplay:displayID];
    }
    
}

- (void) themesEndDisplayPass:(int)displayID
{
    for (Theme *thm in _themeList)
    {
        [thm endDisplay:displayID];
    }
    if (displayID == _displayID)
    {
        ConfigurationControl.sharedInstance.legendList = [[NSMutableArray alloc]init];
        for (Theme *thm in _themeList)
        {
            ThemeLegend * lgnd = [thm copyLegend];
            [ConfigurationControl.sharedInstance.legendList addObject:lgnd];
        }
    }
}

- (int) setDisplayCharacteristics:(DisplayCharacteristics *)dc
                        displayID:(int)displayID
                     compareClass:(int*)cclass;
{
    int rtn = DISPLAY_ITEM;
    
    if (cclass)
        *cclass = 0;
    //test pass
    for (Theme *thm in _themeList)
    {
        if (displayID && thm.displayID != displayID)
            return DO_NOT_DISPLAY_ITEM;
        rtn = [thm processTheme:dc
                      displayID:displayID
                       testPass:YES
                   compareClass:nil];
        if (rtn == DO_NOT_DISPLAY_ITEM)
            return rtn;
    }
    //display pass
    for (Theme *thm in _themeList)
    {
        if (displayID && thm.displayID != displayID)
            return DO_NOT_DISPLAY_ITEM;
        rtn = [thm processTheme:dc
                      displayID:displayID
                       testPass:NO
               compareClass:cclass];
        if (rtn == DO_NOT_DISPLAY_ITEM)
            return rtn;
    }
    
    return rtn;
}

- (BOOL) getMinMaxTime:(int)range min:(int *)minTime max:(int *)maxTime
{
    BOOL display = TRUE;
    int fromTime=(int)CRAPI.sharedInstance.fromDate, toTime=(int)CRAPI.sharedInstance.toDate;
    
    *minTime = fromTime;
    *maxTime = toTime;
    return display;
}

- (NSArray *) getUCRRanges
{
    NSMutableArray * array = NSMutableArray.new;
    
    for (Theme *thm in _themeList)
    {
        switch (thm.type)
        {
            case Part1Theme:
            case Part2Theme:
            case AssaultTheme:
            case RobberyTheme:
            case BurglaryTheme:
            case SelectedTheftTheme:
            case MotorVehicleTheftTheme:
            case TheftFromAutoTheme:
            {
                int minUCR = [thm getFirstUCRGreaterThan:-1];
                int lastUCR = minUCR;
                if (thm.type == Part1Theme && lastUCR == 1)
                    lastUCR = 2;
                int nextUCR = [thm getFirstUCRGreaterThan:lastUCR];
                
                while (nextUCR > -1)
                {
                    if (nextUCR - lastUCR > 1)
                    {
                        UCRRange *range = UCRRange.new;
                        range.rangeBegin = [NSNumber numberWithInteger:minUCR];
                        range.rangeEnd = [NSNumber numberWithInteger:lastUCR];
                        [array addObject:range];
                        minUCR = nextUCR;
                        lastUCR = minUCR;
                    }
                    else
                        lastUCR = nextUCR;
                    nextUCR = [thm getFirstUCRGreaterThan:lastUCR];
                }
                UCRRange *range = UCRRange.new;
                range.rangeBegin = [NSNumber numberWithInteger:minUCR];
                range.rangeEnd = [NSNumber numberWithInteger:lastUCR];
                [array addObject:range];
                goto Exit;
            }
            default:
                break;
        }
    }
Exit:
    return array;
}

- (int) getNumUCRRanges
{
    _UCRRanges = [self getUCRRanges];
    return (int)_UCRRanges.count;
}

- (void) getMinMaxUCR:(int)irange min:(int *)minUCR max:(int *)maxUCR
{
    *minUCR = 1;
    *maxUCR = 99;
    if (irange <= _UCRRanges.count)
    {
        UCRRange *range = _UCRRanges[irange];
        *minUCR = (int)range.rangeBegin.integerValue;
        *maxUCR = (int)range.rangeEnd.integerValue;
    }
    
}


- (int) getNumTimeRanges
{
    int n = 1;
    
    return n;
}
- (BOOL) containsColorByRefTheme
{
    BOOL rtn = FALSE;
    for (Theme *thm in _themeList)
    {
        if (thm.type == ColorByRefnoTheme)
            rtn = TRUE;
    }
    return rtn;

}
- (int) haveCompareTheme
{
    int rtn = 0;
    
    for (Theme *thm in _themeList)
    {
        for (ThemeClass *tc in thm.classes)
        {
            if (tc.status == 2)
                rtn = 1;
        }
    }
    return rtn;
}

@end
