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

- (Theme *) createTheme:(ThemeTypes)type
{
    NSString * outFile = nil;
    if (_outDir)
        outFile = [NSString stringWithFormat:@"%@/%i.bmp",_outDir,(int)type];
    Theme * thm = [Theme createTheme:type
                              inFile:outFile
                             atScale:_outScale];
    return thm;
}

- (void)setAppThemes:(NSString *)outputDirectory
        outputFactor:(double)factor;
{
    Theme *thm;
    
    _outDir = outputDirectory;
    _outScale = factor;
    if (_outDir && ![_outDir isEqualToString:@""])
    {
        [NSFileManager.defaultManager createDirectoryAtPath:_outDir
                                withIntermediateDirectories:YES attributes:nil
                                                      error:nil];
    }
    else
        _outDir = nil;
    if (_outDir || ConfigurationControl.sharedInstance.legendApp != ConfigurationControl.sharedInstance.currentApp)
        [self destroyCurrentThemes];
    
    ConfigurationControl.sharedInstance.legendApp = ConfigurationControl.sharedInstance.currentApp;
    
    _themeList = NSMutableArray.array;
    
    switch (ConfigurationControl.sharedInstance.currentApp)
    {
        case HCConfigFromSpreadsheet:
        case HCConfigFromSlowValues:
        {
            if (ConfigurationControl.sharedInstance.currentMapitBaseLayer == MBL_LandUse)
                thm = [self createTheme:MetroLandUseTheme];
            else
                thm = [self createTheme:ColorByRefnoTheme];
            [_themeList addObject:thm];
        }
            break;
        case HCConfigCrimes:
        {
            NSString *crimeLegend = [UserDefaults.defaults stringForKey:@"SelectedLegend"];
            
            NSString *crimeCompare = [UserDefaults.defaults stringForKey:@"CrimeCompareValue"];
            
            thm = [self createTheme:Part1Theme];
            if ([crimeLegend isEqualToString:@"Part 2 Offenses"])
                thm = [self createTheme:Part2Theme];
            if ([crimeLegend isEqualToString:@"Crime Index"])
                thm = [self createTheme:CrimeIndexTheme];
            if ([crimeLegend isEqualToString:@"Violent Crimes"])
                thm = [self createTheme:ViolentTheme];
            if ([crimeLegend isEqualToString:@"Assault"])
                thm = [self createTheme:AssaultTheme];
            if ([crimeLegend isEqualToString:@"Burglary"])
                thm = [self createTheme:BurglaryTheme];
            if ([crimeLegend isEqualToString:@"Robbery"])
                thm = [self createTheme:RobberyTheme];
            if ([crimeLegend isEqualToString:@"Narcotics"])
                thm = [self createTheme:NarcoticsTheme];
            if ([crimeLegend isEqualToString:@"Motor Vehicle Theft"])
                thm = [self createTheme:MotorVehicleTheftTheme];
            if ([crimeLegend isEqualToString:@"Selected Theft"])
                thm = [self createTheme:SelectedTheftTheme];
            if ([crimeLegend isEqualToString:@"Theft From Auto"])
                thm = [self createTheme:TheftFromAutoTheme];
            if ([crimeLegend isEqualToString:@"Crime Index"])
                thm = [self createTheme:CrimeIndexTheme];
            //if (CRAPI.sharedInstance.crimeMode == CHOROPLETH)
            //    thm = [self createTheme:ChoroplethSummaryTheme];
            [_themeList addObject:thm];
            thm = [self createTheme:DepartmentTheme];
            [_themeList addObject:thm];
            thm = [self createTheme:DayNightTheme];
            [_themeList addObject:thm];
            
            thm = [self createTheme:YearTheme];
            [_themeList addObject:thm];
            if ([crimeCompare isEqualToString:@"Month With Monthly Compare"])
                thm = [self createTheme:ThirteenMonthTheme];
            else
                thm = [self createTheme:MonthTheme];
            [_themeList addObject:thm];
            thm = [self createTheme:DayofWeekTheme];
            [_themeList addObject:thm];
            thm = [self createTheme:HourTheme];
            [_themeList addObject:thm];
        }
            break;
        case HCConfigCurbRamps:
            thm = [self createTheme:CurbRampIntersectionTheme];
            [_themeList addObject:thm];
            thm = [self createTheme:CurbRampTheme];
            [_themeList addObject:thm];
            break;
        case HCConfigMapleGrove:
            thm = [self createTheme:MGVWaterLineTheme];
            [_themeList addObject:thm];
            thm = [self createTheme:MGVHydrantTheme];
            [_themeList addObject:thm];
            thm = [self createTheme:MGVFiberLineTheme];
            [_themeList addObject:thm];
            thm = [self createTheme:MGVFiberPointTheme];
            [_themeList addObject:thm];
            thm = [self createTheme:MGVWaterMeterTheme];
            [_themeList addObject:thm];
            break;
        case HCConfigHunting:
            thm = [self createTheme:PublicHuntingLandsTheme];
            [_themeList addObject:thm];
            break;
        case HCConfigMetroProp:
            if ([NVMetroSettings.sharedInstance currentValueFields].length < 1)
                break;
            if (NVMetroSettings.sharedInstance.currentFeature == CPFLandUse)
            {
                if (NVMetroSettings.sharedInstance.currentFeatureValue)
                {
                    thm = [self createTheme:MetroLandUseTheme];
                    [_themeList addObject:thm];
                }
            }
            else
            {
                thm = [self createTheme:MetroPropTheme];
                if (thm)
                    [_themeList addObject:thm];
                if (ConfigurationControl.sharedInstance.currentPropSheetFieldType2)
                {
                    thm = [self createTheme:MetroPropTheme2];
                    if (thm)
                        [_themeList addObject:thm];
                }
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
                thm.legend.hasOverlay = tleg.hasOverlay;
                thm.legend.selectionMode = tleg.selectionMode;
                
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
    if (!dc.size)
        dc.size = 1;
    return rtn;
}

- (ThemeTypes) themeWithCompare
{
    ThemeTypes rtn = NoTheme;
    for (Theme *thm in _themeList)
    {
        if ([thm hasCompare])
            return thm.type;
    }
    return rtn;
}

- (int) isHourSelected:(time_t)iTime
      themeWithCompare:(ThemeTypes)themeWithCompare
{
    DisplayCharacteristics *dc = DisplayCharacteristics.new;
    struct tm tmtime = *localtime (&iTime);
    int rtn = 3;
    
    for (Theme *thm in _themeList)
    {
        int val = -1;
        switch (thm.type)
        {
                
            case DayNightTheme:
            {
                val = -999;
                for (ThemeClass *cls in thm.classes)
                {
                    if (cls.status != 1)
                        val = 0;
                }
                if (val != -999)
                {
                    double Altitude=0, Az;
                    MNMXCORD mnmx = CRAPI.sharedInstance.lastDisplayBounds;
                    DPOINT pt = DBoundsMid(&mnmx);
                    GetAltitudeAndAzOfSun (pt,0,iTime,&Altitude,&Az);
                    if (Altitude < -6.0)
                        val = 1;
                    else
                        val = 0;
                }
            }
                break;
            case YearTheme:
                val = tmtime.tm_year + 1900;
                val -= thm.minYear;
                break;
            case MonthTheme:
                val = tmtime.tm_mon;
                break;
            case ThirteenMonthTheme:
                val = [thm classFromTime:dc.itemBeginTime];
                break;
            case DayofWeekTheme:
                val = tmtime.tm_wday;
                break;
            case HourTheme:
                val = tmtime.tm_hour/2;
                break;
            default:
                val = -999;
                break;
        }
        if (val != -999)
        {
            int ival = [thm compareStatus:val
                         themeWithCompare:themeWithCompare];
            if (!ival)
                return 0;
            rtn = min (rtn,ival);
        }
    }
    return rtn;
    
}

- (BOOL) getMinMaxTime:(int)range min:(int *)minTime max:(int *)maxTime
{
    BOOL display = TRUE;
    return display;
    
    /*
    int fromTime=(int)CRAPI.sharedInstance.fromDate, toTime=(int)CRAPI.sharedInstance.toDate;
    
    *minTime = fromTime;
    *maxTime = toTime;
    return display;*/
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
            case ViolentTheme:
            case CrimeIndexTheme:
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
                if (thm.type == CrimeIndexTheme && lastUCR == 0)
                    lastUCR = thm.maxUCR;
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

- (double) getCompareThemeFactor
{
    double rtn = 1;
    
    for (Theme *thm in _themeList)
    {
        double nNonCompare = 0;
        double nCompare = 0;
        for (ThemeClass *tc in thm.classes)
        {
            if (tc.status == 1)
                nNonCompare++;
            if (tc.status == 2)
                nCompare++;
        }
        if (nNonCompare > 0 && nCompare > 0)
        {
            rtn = nNonCompare / nCompare;
            return rtn;
        }
    }
    return rtn;
}

@end
