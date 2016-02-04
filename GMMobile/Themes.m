//
//  Themes.m
//  GMMobile
//
//  Created by JEFFREY E SMITH on 11/17/15.
//  Copyright © 2015 GSSi. All rights reserved.
//
//extern int CRAPI.sharedInstance.keepProcessing;

#import "Themes.h"

@implementation Themes

- (void)setAppThemes
{
    Theme *thm;
    
    if (ConfigurationControl.sharedInstance.legendApp != ConfigurationControl.sharedInstance.currentApp)
        [self destroyCurrentThemes];
    ConfigurationControl.sharedInstance.legendApp = ConfigurationControl.sharedInstance.currentApp;
    
    self.themeList = [[NSMutableArray alloc]init];
    
    switch (ConfigurationControl.sharedInstance.currentApp)
    {
        case HCConfigCrimes:
            thm = [Theme createTheme:Part1Theme];
            [_themeList addObject:thm];
            thm = [Theme createTheme:DepartmentTheme];
            [_themeList addObject:thm];
            thm = [Theme createTheme:DayNightTheme];
            [_themeList addObject:thm];
            
            thm = [Theme createTheme:YearTheme];
            [_themeList addObject:thm];
            thm = [Theme createTheme:MonthTheme];
            [_themeList addObject:thm];
            thm = [Theme createTheme:DayofWeekTheme];
            [_themeList addObject:thm];
            thm = [Theme createTheme:HourTheme];
            [_themeList addObject:thm];
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
        default:
            break;
    }
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
                int j=0;
                
                for (ThemeLegendCell *tlc in thm.legend.cells)
                {
                    if (tl.cells.count > j)
                    {
                        ThemeLegendCell *cl = tl.cells[j++];
                        tlc.status = cl.status;
                        tlc.symbolColor = cl.symbolColor;
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
        
        if (ConfigurationControl.sharedInstance.legendList.count > i)
        {
            ThemeLegend *tleg = ConfigurationControl.sharedInstance.legendList[i];
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
{
    int rtn = DISPLAY_ITEM;
    
    //test pass
    for (Theme *thm in _themeList)
    {
        if (thm.displayID != displayID)
            return DO_NOT_DISPLAY_ITEM;
        rtn = [thm processTheme:dc
                      displayID:displayID
                       testPass:YES];
        if (rtn == DO_NOT_DISPLAY_ITEM)
            return rtn;
    }
    //display pass
    for (Theme *thm in _themeList)
    {
        if (thm.displayID != displayID)
            return DO_NOT_DISPLAY_ITEM;
        rtn = [thm processTheme:dc
                      displayID:displayID
                       testPass:NO];
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

- (int) getNumUCRRanges
{
    int nRange = 0;
    for (Theme *thm in _themeList)
    {
        switch (thm.type)
        {
            case Part1Theme:
            {
                int lastUCR = -1;
                for (int ucr = thm.minUCR; ucr <= thm.maxUCR; ucr++)
                {
                    int iclass = [thm classFromUCR:ucr];
                    if (![thm classIsSelected:iclass])
                        iclass = -1;
                    if (iclass > -1 && ucr - lastUCR > 1)
                    {
                        nRange++;
                    }
                    if (iclass > -1)
                        lastUCR = ucr;
                }
            }
                break;
            default:
                break;
        }
    }
    
    return nRange;
}
- (void) getMinMaxUCR:(int)range min:(int *)minUCR max:(int *)maxUCR
{
    int nRange = 0;
    *minUCR = 1;
    *maxUCR = 99;
    for (Theme *thm in _themeList)
    {
        switch (thm.type)
        {
            case Part1Theme:
            {
                int lastUCR = -1;
                for (int ucr = thm.minUCR; ucr <= thm.maxUCR; ucr++)
                {
                    int iclass = [thm classFromUCR:ucr];
                    if (![thm classIsSelected:iclass])
                        iclass = -1;
                    if (iclass > -1 && ucr - lastUCR > 1)
                    {
                        if (nRange == range)
                        {
                            *minUCR = ucr;
                            *maxUCR = ucr;
                        }
                        nRange++;
                    }
                    if (iclass > -1)
                    {
                        lastUCR = ucr;
                        if (nRange == range+1)
                            *maxUCR = ucr;
                    }
                }
            }
                break;
            default:
                break;
        }
    }
    
}


- (int) getNumTimeRanges
{
    int n = 1;
    
    return n;
}

@end
