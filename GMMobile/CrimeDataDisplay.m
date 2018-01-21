//
//  CrimeDataDisplay.m
//  GMMobile
//
//  Created by JEFFREY E SMITH on 11/3/15.
//  Copyright © 2015 GSSi. All rights reserved.
//

#import "CrimeDataDisplay.h"
#import "BoundaryData.h"
#import "CrimeList.h"

@implementation CrimeDataDisplay
{
    CrimeData *_cd;
}

- (BOOL)continueProcessing
{
    if (!self.processingID)
        return YES;
    if (*self.processingID == 0)
        return YES;
    if (*self.processingID == CRAPI.sharedInstance.keepProcessing)
        return YES;
    if (_popoverDisplayed)
    {
        _popoverDisplayed = FALSE;
        dispatch_async(dispatch_get_main_queue(),
                       ^{
                           _mvc.popover.delegate = _savePOdelegate;
                           [_mvc.popover hide];
                       });
    }
    return NO;
}
- (id)init
{
    self = [super init];
    
    if (self)
    {
        _cd = [[CrimeData alloc]init];
    }
    
    return self;
}

- (void)dealloc
{
    CloseTRANS2P(&_pTranLLtoView);
    CloseTRANS2P(&_pTranViewtoLL);
    [_cd close:YES];
    if (_saveFromDate)
        CRAPI.sharedInstance.fromDate = _saveFromDate;
    NSLog(@"Crime Database dealloc");
}


- (void)setTrans:(CORNERPOINTS *)corners
      viewBounds:(MNMXCORD *)pvbounds
{
    
    CloseTRANS2P(&_pTranLLtoView);
    CloseTRANS2P(&_pTranViewtoLL);
    _pTranLLtoView = STRANCornersToBoundsP(corners, pvbounds);
    _pTranViewtoLL = STRANBoundsToCornersP(corners, pvbounds);
}

- (BOOL) createCNUMCheckTable
{
    BOOL rtn = FALSE;
    
    NSString * cmd = @"DROP TABLE IF EXISTS CNUMCHECK;CREATE TEMP TABLE CNUMCHECK (ControlNbr INTEGER PRIMARY KEY ASC,UCR INT);";
    [_cd executeCmd:(LPSTR)cmd.UTF8String];
    return rtn;
}

- (BOOL) alreadyHaveThisCNUM:(int)controlNbr
                         UCR:(int)UCR
{
    BOOL rtn = FALSE;
    int st = 0;
    BOOL outOfOrder = FALSE;
    
    NSString *query = [NSString stringWithFormat:@"SELECT UCR FROM CNUMCHECK WHERE ControlNbr = %i",controlNbr];
    sqlite3_stmt *statement = NULL;
    
    SQLOK(__FILE__,__LINE__,SQLitePrepare(_cd.database, query.UTF8String, -1, &statement, 0), _cd.database);
    
    if (sqlite3_step(statement) == SQLITE_ROW)
    {
        int ucr = sqlite3_column_int(statement, 0);
        if (UCR < ucr)
            outOfOrder = TRUE;
        else if (UCR > ucr)
            rtn = TRUE;
        st = 1;
    }
    SQLOK(__FILE__,__LINE__,SQLiteFinalize(statement), _cd.database);
    if (!st)
    {
        query = [NSString stringWithFormat:@"INSERT INTO CNUMCHECK VALUES(%i,%i);",controlNbr,UCR];
        [_cd executeCmd:(LPSTR)query.UTF8String];
    }
    return rtn;
}

-(void) checkMultipleCodes
{
    doesSQLiteFieldExist("OFFENSEXY", "OffenseOrder",_cd.database);
    sqlite3_stmt *statement = NULL;
    NSString * query = [NSString stringWithFormat:@"SELECT ControlNbr,Offense FROM OFFENSEXY ORDER BY ControlNbr,Offense"];
    SQLOK(__FILE__,__LINE__,SQLitePrepare(_cd.database, query.UTF8String, -1, &statement, 0), _cd.database);
    NSString * lastOffense = @"";
    NSString * firstOffense = @"";
    int lastControlNum = 0;
    int haveMults = 0;
    while (sqlite3_step(statement) == SQLITE_ROW)
    {
        int controlNbr = sqlite3_column_int(statement,0);
        NSString * offense = [NSString stringWithUTF8String:(LPSTR)sqlite3_column_text(statement,1)];
        if (controlNbr != lastControlNum)
            firstOffense = offense;
        else if ([offense isEqualToString:lastOffense] && [offense isEqualToString:firstOffense])
        {
            haveMults++;
        }
        lastControlNum = controlNbr;
        lastOffense = offense;
    }
    SQLOK(__FILE__,__LINE__,SQLiteFinalize(statement), _cd.database);
    
    
}
- (void)displayCrimePoints:(CGContextRef)context
           contextIsBitmap:(BOOL)isBitmapContext
    displayCharacteristics:(DisplayCharacteristics *)dc
                 llCorners:(CORNERPOINTS *) latlonCornerPoints
                  LLBounds:(MNMXCORD *)platlonBounds
                viewBounds:(MNMXCORD *)pvbounds
                    themes:(Themes*)themes
               pointInArea:(PointInArea *)pia
                      pass:(int)pass;
{
    NSString *query;
    NSString *crimeLegend = [UserDefaults.defaults stringForKey:@"SelectedLegend"];
    sqlite3_stmt *statement = NULL;
    DPOINT BasePt[2];
    //int UCR;
    int controlNbr = 0;
    NSArray *timeRanges = [CRAPI.sharedInstance getTimeRanges];
    int fromTime=(int)CRAPI.sharedInstance.fromDate, toTime=(int)CRAPI.sharedInstance.toDate;
    time_t iTime = fromTime;
    struct tm tmtime = *localtime (&iTime);
    int minYear = tmtime.tm_year + 1900;
    iTime = toTime;
    struct tm tmtime2 = *localtime (&iTime);    
    int maxYear = tmtime2.tm_year + 1900;
    int numYears = maxYear - minYear + 1;
    NSArray<NSNumber*> *hsTimes = nil;
    HSVideoTypes hotspotVideoType = HSTypeTime;
    int numHotspotGrids = 0;
    int numUCRRanges=1, numTimeRanges=1;
    LPSTR offense;
    LPSTR dept;
    CGFloat size;
    CGFloat sizeFactor = 1;
    NSInteger tot=0;
    [CRAPI.sharedInstance updateProgress:-1 current:0 range:0 numRanges:1];
    PointInAreas *pias = nil;
    BoundaryData *bd = nil;
    HotSpot * hs = nil;
    DispersePoint *dp = nil;
    int iPass = 1;
    BOOL wantAll = FALSE;
    int ii;
    CGFloat scale = [UIScreen mainScreen].nativeScale;
    double crimeCircleSizeMeters = 25;
    double groundRes1 = GroundResolution((platlonBounds->ymn + platlonBounds->ymx)/2,_zoom);
    double groundRes2 = GroundResolution((platlonBounds->ymn + platlonBounds->ymx)/2,_zoom+1);
    double groundRes = groundRes1 + (groundRes2 - groundRes1) * (_zoom - floor (_zoom));
    double crimeCirclePixelRadius =  crimeCircleSizeMeters / groundRes;
    if (_zoom > 15)
        sizeFactor += (_zoom - 15)/2;
    sizeFactor *= scale;
    [self setTrans:latlonCornerPoints viewBounds:pvbounds];
    BOOL opened = [_cd startTransaction];
    // [self checkMultipleCodes];
    if (!ConfigurationControl.sharedInstance.wantAllCrimes)
        [self createCNUMCheckTable];
    else
        wantAll = TRUE;
    
    if (_mode == PINMAP)
    {
        dp = [DispersePoint initWithWidth:MNMXCORDWidth(pvbounds)
                                   Height:MNMXCORDHeight(pvbounds)
                                    tran1:_pTranLLtoView
                                    tran2:_pTranViewtoLL];
    }
    else if (_mode == CHOROPLETH || _mode == LINEGRAPH)
    {
        [CRAPI.sharedInstance showMapToolbarIndicator:YES];
        
        pias = [[PointInAreas alloc]init];
        pias.processingID = *_processingID;
        pias.fullBounds = *pvbounds;
        pias.areaType = _choroplethTarget;
        pias.adjustValue = nil;
        pias.numYears = numYears;
        pias.compareFactor = [themes getCompareThemeFactor];
        int pointSize = ceil (crimeCirclePixelRadius);
        bd = [[BoundaryData alloc]init];
        bd.processingID = *self.processingID;
        
        MNMXCORD pvboundsPias = [pias bitmapBounds:pvbounds];
        [pias setPointSize:pointSize];
        
        [bd   load:_choroplethTarget
    toPointInAreas:pias
boundsPointInAreas:nil
  usingPointInArea:pia
         llCorners:latlonCornerPoints
          LLBounds:platlonBounds
        viewBounds:&pvboundsPias
  haveCompareTheme:[themes haveCompareTheme]];
        
        [CRAPI.sharedInstance showMapToolbarIndicator:NO];
        if (_mode == CHOROPLETH)
            [pias initTimeLine:_cd.database];
    }
    
    if (![self continueProcessing])
        goto Exit;
    
NextPass:
    if (_mode == HOTSPOT)
    {
        if ([CRAPI.sharedInstance.crimeCompare isEqualToString:@"Month With Yearly Compare"])
        {
            NSArray<NSNumber*> *times = [NVDateRange getArrayOfMonthsSpanningTime:(int)CRAPI.sharedInstance.fromDate
                                                                           toTime:(int)CRAPI.sharedInstance.toDate];
            _saveFromDate = (int)CRAPI.sharedInstance.fromDate;
            CRAPI.sharedInstance.fromDate = times[0].integerValue;
            hs = [HotSpot initWithWidth:MNMXCORDWidth(pvbounds)
                                 Height:MNMXCORDHeight(pvbounds)
                               NumGrids:[themes haveCompareTheme]+1
                              timeArray:times
                              PointSize:max(MNMXCORDWidth(pvbounds),MNMXCORDHeight(pvbounds))/32
                                   tran:_pTranLLtoView];
            
        }
        else
        {
            hs = [HotSpot initWithWidth:MNMXCORDWidth(pvbounds)
                                 Height:MNMXCORDHeight(pvbounds)
                               NumGrids:[themes haveCompareTheme]+1
                              timeArray:nil
                              PointSize:max(MNMXCORDWidth(pvbounds),MNMXCORDHeight(pvbounds))/32
                                   tran:_pTranLLtoView];
        }
    }
    else if (_mode == HOTSPOTVIDEO)
    {
        if ([CRAPI.sharedInstance.hotspotVideoMode containsString:@"Day of Week"])
        {
            hotspotVideoType = HSTypeDow;
            numHotspotGrids = -7;
        }
        else if ([CRAPI.sharedInstance.hotspotVideoMode containsString:@"Hour in Day"])
        {
            hotspotVideoType = HSTypeHour;
            numHotspotGrids = -24;
        }
        else
        {
            int maxTimeSlots = 50;
            hsTimes = [NVDateRange getArrayOfQuadWeeksSpanningTime:(int)CRAPI.sharedInstance.fromDate
                                                                          toTime:(int)CRAPI.sharedInstance.toDate
                                                                        maxTimes:maxTimeSlots];
            numHotspotGrids = (int)hsTimes.count;
        }
        hs = [HotSpot initWithWidth:MNMXCORDWidth(pvbounds)
                             Height:MNMXCORDHeight(pvbounds)
                           NumGrids:numHotspotGrids
                          timeArray:hsTimes
                          PointSize:max(MNMXCORDWidth(pvbounds),MNMXCORDHeight(pvbounds))/32
                               tran:_pTranLLtoView];
    }
    
    if (!CRAPI.sharedInstance.mapCrimeList)
    {
        numUCRRanges  = [themes getNumUCRRanges];
        numTimeRanges = (int)timeRanges.count;
    }
    int totRanges = numTimeRanges * numUCRRanges;
    int iRange = 0;
    for (int ucrRange = 0; ucrRange < numUCRRanges; ucrRange++)
    {
        if (![self continueProcessing]) break;
        if (!CRAPI.sharedInstance.mapCrimeList)
            [themes getMinMaxUCR:ucrRange min:&_minUCR max:&_maxUCR];
        if (!pass)
        {
            _minUCR = 999;
            _maxUCR = -999;
        }
        for (int timeRange = 0; timeRange < numTimeRanges; timeRange++)
        {
            if (![self continueProcessing]) break;
            if (!CRAPI.sharedInstance.mapCrimeList)
            {
                TimeRange * tr = timeRanges[timeRange];
                fromTime = tr.beginTime;
                toTime = tr.endTime;
                BOOL display = [themes getMinMaxTime:timeRange min:&fromTime max:&toTime];
                query = [NSString stringWithFormat:@"SELECT ControlNbr,X,Y,Offense,UCR,FromDate,ToDate, CityCode, SUNANGLE, Attempt FROM OFFENSEXY,OFFENSEXY_index WHERE OFFENSEXY.id=OFFENSEXY_index.id AND\
                         OFFENSEXY_index.minTime >=%f AND\
                         OFFENSEXY_index.maxTime <=%f AND\
                         OFFENSEXY_index.MinUCR  >=%f AND\
                         OFFENSEXY_index.MaxUCR  <=%f AND\
                         OFFENSEXY_index.maxX    >=%f AND\
                         OFFENSEXY_index.minX    <=%f AND\
                         OFFENSEXY_index.maxY    >=%f AND\
                         OFFENSEXY_index.minY    <=%f",
                         fromTime/1000.0-1,
                         toTime/1000.0+1,
                         _minUCR*10.0-1,
                         _maxUCR*10.0+1,
                         platlonBounds->xmn,
                         platlonBounds->xmx,
                         platlonBounds->ymn,
                         platlonBounds->ymx];
                tot = toTime - fromTime;
                [CRAPI.sharedInstance showMapToolbarIndicator:YES];
            }
            else
            {
                NSString * controlNumberList = [CrimeList getControlNumberList:CRAPI.sharedInstance.mapCrimeList];
                query = [NSString stringWithFormat:@"SELECT ControlNbr,X,Y,Offense,UCR,FromDate,ToDate, CityCode, SUNANGLE, Attempt FROM OFFENSEXY WHERE OFFENSEXY.ControlNbr IN (%@)",
                         controlNumberList];
                
            }
            SQLOK(__FILE__,__LINE__,SQLitePrepare(_cd.database, query.UTF8String, -1, &statement, 0), _cd.database);
            
            while ([self continueProcessing] && sqlite3_step(statement) == SQLITE_ROW)
            {
                BOOL attempted = FALSE;
                controlNbr = sqlite3_column_int(statement,0);
                dc.UCR =sqlite3_column_int(statement,4);
                if (!wantAll && [self alreadyHaveThisCNUM:controlNbr
                                                      UCR:dc.UCR])
                    continue;
                BasePt[0].x = sqlite3_column_double(statement,1);
                BasePt[0].y = sqlite3_column_double(statement,2);
                offense = (LPSTR)sqlite3_column_text(statement,3);
                dc.dPoint = BasePt[0];
                dc.itemBeginTime = sqlite3_column_int(statement,5);
                time_t iTime = dc.itemBeginTime;
                struct tm tmtime = *localtime (&iTime);

                dc.year = tmtime.tm_year + 1900;
                dc.yearIndex = dc.year - minYear;
                dc.dayNight = (dc.sunAngle < -6.0);
                dc.month = tmtime.tm_mon;
                dc.dow = tmtime.tm_wday;
                dc.hour = tmtime.tm_hour;
                

                [CRAPI.sharedInstance updateProgress:tot
                                             current:dc.itemBeginTime-fromTime
                                               range:iRange
                                           numRanges:totRanges];
                dc.itemEndTime = sqlite3_column_int(statement,6);
                dept = (LPSTR)sqlite3_column_text(statement,7);
                dc.sunAngle = sqlite3_column_int(statement,8);
                LPSTR attempt = (LPSTR)sqlite3_column_text(statement,9);
                if (*attempt == 'Y' || *attempt == 'y')
                    attempted = TRUE;
                dc.string1 = [NSString stringWithUTF8String:offense];
                dc.string2 = [NSString stringWithUTF8String:dept];
                dc.fillColor = [UIColor colorWithRed:1 green:0 blue:0 alpha:1];
                size = 15;
                
                /*                if (attempted && ConfigurationControl.sharedInstance.attemptedCrimeOption == IgnoreAttempts)
                 continue;
                 if (!attempted && ConfigurationControl.sharedInstance.attemptedCrimeOption == OnlyAttempts)
                 continue;
                 */
                int compareClass = 0;
                if ((!pia || [pia DPointInArea:BasePt]) &&
                    [themes setDisplayCharacteristics:dc
                                            displayID:*_processingID
                                         compareClass:&compareClass] != DO_NOT_DISPLAY_ITEM)
                {
                    DPOINT viewPoint = TranDPOINTP(BasePt, _pTranLLtoView);
                    if (_mode == PINMAP)
                    {
                        [dp addPoint:&viewPoint
                          controlNbr:controlNbr
                                time:dc.itemBeginTime
                             offense:dc.string1
                         usingSymbol:dc.pointSymbol
                           withColor:dc.fillColor.CGColor
                             andSize:(size * sizeFactor * dc.size)];
                        
                    }
                    else if (_mode == CHOROPLETH || _mode == LINEGRAPH)
                    {
                        [pias DPointInArea:&BasePt[0]
                    displayCharacteristics:(DisplayCharacteristics *)dc
                                  andRefno:controlNbr
                                whichCount:compareClass
                                     value:dc.incValue];
                    }
                    else if (_mode == HOTSPOT)
                    {
                        [hs addPointAtX:viewPoint.x andY:viewPoint.y
                                andTime:dc
                              whichGrid:compareClass];
                    }
                    else if (_mode == HOTSPOTVIDEO)
                    {
                        [hs addPointAtX:viewPoint.x andY:viewPoint.y
                                andTime:dc
                              whichGrid:-1];
                    }
                    else
                    {
                    }
                }
            }
            iRange++;
            SQLOK(__FILE__,__LINE__,SQLiteFinalize(statement), _cd.database);
            [CRAPI.sharedInstance showMapToolbarIndicator:NO];
        }
    }
    if ((_mode == HOTSPOT || _mode == HOTSPOTVIDEO) && iPass++ < _numPass)
        goto NextPass;
    
    [CRAPI.sharedInstance updateProgress:tot current:tot range:0 numRanges:1];
    if (![self continueProcessing])
        ;
    else if (_mode == PINMAP)
    {
        query = [NSString stringWithFormat:@"SELECT ControlNbr,X,Y,DispersedX,DispersedY,Sequence,Symbol,Size,Color FROM DISPERSE"];
        SQLOK(__FILE__,__LINE__,SQLitePrepare(dp.database, query.UTF8String, -1, &statement, 0), dp.database);
        [CRAPI.sharedInstance showMapToolbarIndicator:YES];
        
        while ([self continueProcessing] && sqlite3_step(statement) == SQLITE_ROW)
        {
            POINT Point, origPoint;
            //static BOOL doDisperse = YES;
            controlNbr = sqlite3_column_int(statement,0);
            origPoint.x = sqlite3_column_int(statement,1);
            origPoint.y = sqlite3_column_int(statement,2);
            Point.x = sqlite3_column_int(statement,3);
            Point.y = sqlite3_column_int(statement,4);
            int seq = sqlite3_column_int(statement,5)+1;
            PointSymbols sym = sqlite3_column_int(statement,6);
            CGFloat size = sqlite3_column_double(statement,7);
            CGColorRef clr = (CGColorRef)sqlite3_column_int64(statement,8);
            BasePt[0].x = Point.x;
            BasePt[0].y = Point.y;
            BasePt[1].x = origPoint.x;
            BasePt[1].y = origPoint.y;
            
            [self drawCrimePoint:context
                         atPoint:BasePt
                       origPoint:&origPoint
                     usingSymbol:sym
                       withColor:clr
                         andSize:size
                       dispersed:seq > 1];
        }
        
        [CRAPI.sharedInstance showMapToolbarIndicator:NO];
        if ([self continueProcessing])
            [dp commitTransaction];
        SQLOK(__FILE__,__LINE__,SQLiteFinalize(statement), dp.database);
    }
    
    else if (_mode == CHOROPLETH)
    {
        if (_choroplethAdjustValue && _choroplethAdjustValue < ACO_OverDueAverage)
        {
            PointInAreas *piasAdjust = [[PointInAreas alloc]init];
            piasAdjust.areaType = _choroplethAdjustArea;
            piasAdjust.adjustValue = [ConfigurationControl getAdjustValueString:_choroplethAdjustValue];
            bd = [[BoundaryData alloc]init];
            bd.processingID = *self.processingID;
            
            [bd load:_choroplethAdjustArea
      toPointInAreas:piasAdjust
  boundsPointInAreas:pias
    usingPointInArea:pia
           llCorners:latlonCornerPoints
            LLBounds:platlonBounds
          viewBounds:pvbounds
    haveCompareTheme:0];
            
            [pias createDisplayColors:piasAdjust
                                 mask:pia
                          wantOverdue:0];
        }
        
        else
        {
            AdjustCrimeOptions overDueOption = 0;
            if (_choroplethAdjustValue == ACO_OverDueAverage || _choroplethAdjustValue == ACO_OverDueSTDV)
                overDueOption = _choroplethAdjustValue;
            [pias createDisplayColors:nil
                                 mask:pia
                          wantOverdue:overDueOption];
        }
        
        [CRAPI.sharedInstance showMapToolbarIndicator:YES];
        bd.totRecords = [bd display:context
                           areaType:_choroplethTarget
                       pointInAreas:pias
                          llCorners:latlonCornerPoints
                           LLBounds:platlonBounds
                         viewBounds:pvbounds];
        
        [CRAPI.sharedInstance showMapToolbarIndicator:NO];
        
        NVMetroTextOptions *to = [[NVMetroTextOptions alloc]init];
        
        to.numTextFields = 1;
        to.desc = @"Boundary Name";
        to.fields = @"NAME";
        if (_choroplethAdjustValue == ACO_HousingUnits)
        {
            to.formats = [NSArray arrayWithObjects:[NSNumber numberWithInt:TXTAdjustCountPerHundred], nil];
        }
        else if (_choroplethAdjustValue == ACO_Population)
        {
            to.formats = [NSArray arrayWithObjects:[NSNumber numberWithInt:TXTAdjustCountPerThousand], nil];
        }
        else
            to.formats = [NSArray arrayWithObjects:[NSNumber numberWithInt:TXTAdjustNone], nil];
        [CRAPI.sharedInstance updateProgress:-1
                                     current:0
                                       range:1
                                   numRanges:1];
        
        [bd displayText:context
                   from:TFOSelectBoundary
               areaType:_choroplethTarget
            textOptions:to
           pointInAreas:pias
              llCorners:latlonCornerPoints
               LLBounds:platlonBounds
             viewBounds:pvbounds];
    }
    else if (_mode == LINEGRAPH)
    {
        if (pass)
        {
            if (!isBitmapContext)
            {
                CRAPI.sharedInstance.chartBitmaps = NSMutableArray.array;
                
                if (numYears > 1)
                {
                    ChartsBitmap *cb = ChartsBitmap.new;
                    cb.title = [NSString stringWithFormat:@"%@ for %@ By Year",crimeLegend, _choroplethTarget];
                    cb.format = ChartsBitmapDataFormatYears;
                    
                    for (AreaData *ai in pias.areaInfo)
                    {
                        ChartsBitmapDataSet *cbd = ChartsBitmapDataSet.new;
                        cbd.title = ai.areaID;
                        
                        for (int i = 0; i < numYears; i++)
                        {
                            DPoint *dp = [DPoint fromXY:i+minYear y:ai.yearCounts[i]];
                            [cbd.data addObject:dp];
                        }
                        [cb.dataSets addObject:cbd];
                    }
                    [CRAPI.sharedInstance.chartBitmaps addObject:cb];
                }
                
                ChartsBitmap *cbmon = ChartsBitmap.new;
                cbmon.title = [NSString stringWithFormat:@"%@ for %@ By Month",crimeLegend,_choroplethTarget];
                cbmon.format = ChartsBitmapDataFormatMonths;
                
                for (AreaData *ai in pias.areaInfo)
                {
                    ChartsBitmapDataSet *cbd = ChartsBitmapDataSet.new;
                    cbd.title = ai.areaID;
                    
                    for (int i = 0; i < 12; i++)
                    {
                        DPoint *dp = [DPoint fromXY:i y:ai.monthCounts[i]];
                        [cbd.data addObject:dp];
                    }
                    [cbmon.dataSets addObject:cbd];
                }
                [CRAPI.sharedInstance.chartBitmaps addObject:cbmon];
                
                ChartsBitmap *cbdow = ChartsBitmap.new;
                cbdow.title = [NSString stringWithFormat:@"%@ for %@ By Day of Week",crimeLegend,_choroplethTarget];
                cbdow.format = ChartsBitmapDataFormatDayOfWeek;
                
                for (AreaData *ai in pias.areaInfo)
                {
                    ChartsBitmapDataSet *cbd = ChartsBitmapDataSet.new;
                    cbd.title = ai.areaID;
                    
                    for (int i = 0; i < 7; i++)
                    {
                        DPoint *dp = [DPoint fromXY:i y:ai.dowCounts[i]];
                        [cbd.data addObject:dp];
                    }
                    [cbdow.dataSets addObject:cbd];
                }
                [CRAPI.sharedInstance.chartBitmaps addObject:cbdow];
                
                ChartsBitmap *cb = ChartsBitmap.new;
                cb.title = [NSString stringWithFormat:@"%@ for %@ By Hour",crimeLegend,_choroplethTarget];
                cb.format = ChartsBitmapDataFormatHourOfDay;
                
                for (AreaData *ai in pias.areaInfo)
                {
                    ChartsBitmapDataSet *cbd = ChartsBitmapDataSet.new;
                    cbd.title = ai.areaID;
                    
                    for (int i = 0; i < 24; i++)
                    {
                        DPoint *dp = [DPoint fromXY:i y:ai.hourCounts[i]];
                        [cbd.data addObject:dp];
                    }
                    [cb.dataSets addObject:cbd];
                }
                [CRAPI.sharedInstance.chartBitmaps addObject:cb];
                
                dispatch_async(dispatch_get_main_queue(),
                               ^{
                                   [NSTimer scheduledTimerWithTimeInterval:0.1
                                                                    target:CRAPI.sharedInstance
                                                                  selector:@selector(displayChartBitmaps:)
                                                                  userInfo:nil
                                                                   repeats:NO];
                               });
            }
            
            else
            {
                ChartsBitmap *cb = ChartsBitmap.new;
                cb.title = [NSString stringWithFormat:@"Violent Crime for Precincts By Hour"];
                cb.format = ChartsBitmapDataFormatHourOfDay;
                
                for (AreaData *ai in pias.areaInfo)
                {
                    ChartsBitmapDataSet *cbd = ChartsBitmapDataSet.new;
                    cbd.title = ai.areaID;
                    
                    for (int i = 0; i < 24; i++)
                    {
                        DPoint *dp = [DPoint fromXY:i y:ai.hourCounts[i]];
                        [cbd.data addObject:dp];
                    }
                    
                    [cb.dataSets addObject:cbd];
                }
                
                cb.chartWidth = MNMXCORDWidth(pvbounds);
                cb.chartHeight = MNMXCORDHeight(pvbounds);
                cb.format = ChartsBitmapDataFormatHourOfDay;
                cb.outputFile = CRAPI.sharedInstance.pdfImageFile;
                
                [cb createChartBitmap];
                /*
                 long long fileSize = [NSFileManager.defaultManager attributesOfItemAtPath:cb.outputFile
                 error:nil].fileSize;
                 UIImage *image = [UIImage imageWithContentsOfFile:cb.outputFile];
                 cb = nil;*/
            }
        }
    }
    
    else if (_mode == HOTSPOT)
    {
        static BOOL dump=FALSE;
        double compareFactor;
        double * pCompareFactor = &compareFactor;
        if (ConfigurationControl.sharedInstance.dataCompareOption == DCOptionRaw)
            compareFactor = 1;
        else if (ConfigurationControl.sharedInstance.dataCompareOption == DCOptionTime)
            compareFactor = [self getTimeFactor:themes];
        else
            pCompareFactor = nil;
        [hs display:context
         gridNumber:0
      compareFactor:pCompareFactor];
        if (dump)
            [hs dump:@"hotspottest"];
    }
    
    else if (_mode == HOTSPOTVIDEO)
    {
        if ([self continueProcessing])
        {
            if (!pass)
            {
 
            }
            else
            {
                dispatch_async(dispatch_get_main_queue(),
                               ^{
                                   _mvc.popover.progressView.hidden = NO;
                                   _mvc.popover.progressLabel.hidden = YES;
                                   _savePOdelegate = _mvc.popover.delegate;
                                   _mvc.popover.delegate = self;
                                   _mvc.popover.hideAtCancel = NO;
                                   _mvc.popover.title = @"Creating Hotspot Video Files";
                                   [_mvc.view bringSubviewToFront:_mvc.popover];
                                   [_mvc.popover updateProgress:0];
                                   [_mvc.popover show];
                                   _popoverDisplayed = TRUE;
                               });

                HotSpotVideo *hsv = HotSpotVideo.new;
                hsv.width = hs.width;
                hsv.height = hs.height;
                hsv.numImages = hs.nGrids;
                hsv.timeRanges = hsTimes.copy;
                hsv.type = hotspotVideoType;
                NSString *tempDirectory = [NSString stringWithFormat:@"%@HotspotImages", NSTemporaryDirectory()];
                
                tempDirectory = [NSString stringWithFormat:@"%@/HotspotImages", UserDefaults.defaults.sharedFilePath];
                
                [NSFileManager.defaultManager createDirectoryAtPath:tempDirectory
                                        withIntermediateDirectories:YES
                                                         attributes:nil
                                                              error:nil];
                NSString *file = [NSString stringWithFormat:@"%@/background.png", tempDirectory];
                
                if (_backgroundImage)
                {
                    [UIImagePNGRepresentation(_backgroundImage) writeToFile:file atomically:YES];
                    hsv.backgroundImageFile = file;
                }

                for (int iGrid = 0; iGrid < hs.nGrids; iGrid++)
                {
                    if (![self continueProcessing])
                        break;
                  @autoreleasepool {

                        NSString *file = [NSString stringWithFormat:@"%@/Image%i.png", tempDirectory, (iGrid + 1)];
                        [hs writeGrid:iGrid toFile:file];
                        [hsv.imageFiles addObject:file];
                                    }
                    if (![self continueProcessing])
                        break;
                    NSLog(@"Hotspot image added (%i of %i)", (iGrid + 1), hs.nGrids);
                    dispatch_async(dispatch_get_main_queue(),
                                   ^{
                                       [_mvc.popover updateProgress:(double)(iGrid+1)/hs.nGrids];
                                   });

                }
                if ([self continueProcessing])
                {
                    dispatch_async(dispatch_get_main_queue(),
                                   ^{
                                       [_mvc.popover hide];
                                       _popoverDisplayed = FALSE;
                                   });
                    
                    CRAPI.sharedInstance.hsv = hsv;
                    dispatch_async(dispatch_get_main_queue(),
                                   ^{
                                       [NSTimer scheduledTimerWithTimeInterval:0.1
                                                                        target:CRAPI.sharedInstance
                                                                      selector:@selector(displayHotSpotVideo:)
                                                                      userInfo:nil
                                                                       repeats:NO];
                                   });
                }
            }
        }
    }
Exit:
    [_cd close:opened];
    pias = nil;
}

- (double) getTimeFactor:(Themes *)themes
{
    int numSecondsInHour = 60 * 60;
    double factor = 1;
    int hours1 = 0;
    int hours2 = 0;
    NSArray *timeRanges = [CRAPI.sharedInstance getTimeRanges];
    time_t fromTime=(int)CRAPI.sharedInstance.fromDate, toTime=(int)CRAPI.sharedInstance.toDate;
    int numTimeRanges = (int)timeRanges.count;
    ThemeTypes themeWithCompare = [themes themeWithCompare];
    
    for (int timeRange = 0; timeRange < numTimeRanges; timeRange++)
    {
        TimeRange * tr = timeRanges[timeRange];
        fromTime = tr.beginTime;
        toTime = tr.endTime;
        double totHours = (double)(toTime - fromTime) / numSecondsInHour;
        time_t time = fromTime;
        while (time < toTime)
        {
            switch ([themes isHourSelected:time
                          themeWithCompare:themeWithCompare])
            {
                case 0:
                    break;
                case 1:
                    hours1++;
                    break;
                case 2:
                    hours2++;
                    break;
                case 3:
                    hours1++;
                    hours2++;
                    break;
            }
            time += numSecondsInHour;
        }
    }
    if (hours1 && hours2)
        factor = (double)hours1 /(double)hours2;
    return factor;
}
- (void)drawCrimePoint:(CGContextRef)context
               atPoint:(DPOINT *)pPoint
             origPoint:(POINT *)origPoint
           usingSymbol:(PointSymbols)sym
             withColor:(CGColorRef)color
               andSize:(CGFloat)size
             dispersed:(BOOL)dispersed

{
    
    [SymbolDictionary drawPointWithSymbol:context
                                       at:pPoint
                              usingSymbol:sym
                                     Size:size
                                fillColor:color
                                lineColor:0
                                lineWidth:dispersed ? -2 : 2];
    
}
- (void) GSSiPopoverViewdidCancel:(GSSiPopoverView *)popoverView
{
    *_processingID = -1;
}


@end
/*CREATE TABLE OFFENSEXY (id INT PRIMARY KEY,'ControlNbr' INT,'OffenseOrder' INT,'Offense' CHAR(6),'CityCode' CHAR(2),'CaseYear' INT,'CaseNbr' CHAR(6),'ControlType' CHAR(1),'Attempt' CHAR(1),'BeginDate2' CHAR(19),'Precinct' CHAR(2),'UCRCode' CHAR(2),'NIBRSCode' CHAR(3),'CrimeCategory' CHAR(1),'CrimeClass' CHAR(1),'LastChangedID2' CHAR(11),'LastChanged2' CHAR(19),'OriginalCaseYear' INT,'OriginalCaseNbr' CHAR(6),'HouseNbr' CHAR(6),'HouseModifier' CHAR(1),'StreetName' CHAR(22),'StreetType' CHAR(2),'StreetDirection' CHAR(2),'IntersectionStreetName' CHAR(22),'IntersectionStreetType' CHAR(2),'IntersectionStreetDirection' CHAR(2),'Apartment' CHAR(5),'City2' CHAR(30),'State' CHAR(2),'VictimBusiness' CHAR(1),'Zipcode2' CHAR(9),'EndDate' CHAR(19),'ReportedDate' CHAR(19),'BeginDate' CHAR(19),'DispatchedTime' CHAR(4),'ArrivedTime' CHAR(4),'Location' CHAR(30),'ClearedTime' CHAR(4),'PrimaryOffense' CHAR(6),'SupervisorID' CHAR(11),'AssistingOfficerID' CHAR(11),'NotPublicInformation' CHAR(1),'UnitNbr' CHAR(4),'ReportingID' CHAR(11),'CallNbr' CHAR(11),'EnteredID' CHAR(11),'EnteredDate' CHAR(19),'LastChanged' CHAR(19),'AdultStatus' INT,'JuvenileStatus' INT,'Solvable' INT,'NotPublicAddressInformation' CHAR(1),'LastChangedID' CHAR(11),'ForceSupervisorReviewRequired' INT,'ForceSupervisorReviewCompeted' INT,'ForceIAUReviewCompleted' INT,'MatchCode' INT,'LocationCode' INT,'StreetNum' INT,'HouseNum' INT,'IntID' INT,'StreetNum1' INT,'StreetNum2' INT,'Street1MP' REAL,'Street2MP' REAL,'MunicNum' INT,'ZIP' INT,'X' REAL,'Y' REAL,'NumPartsRemoved' INT,'AddressTAGPrefix' CHAR(8),'AddressTAGUDI' CHAR(64),'Street' CHAR(80),'House' CHAR(12),'City' CHAR(32),'ZIPCODE' CHAR(12),'Symbol' CHAR(64),'FromDate' INT,'ToDate' INT,'Note' CHAR(100),'UCR' INT)
 */
