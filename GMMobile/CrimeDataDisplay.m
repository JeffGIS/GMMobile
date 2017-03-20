//
//  CrimeDataDisplay.m
//  GMMobile
//
//  Created by JEFFREY E SMITH on 11/3/15.
//  Copyright © 2015 GSSi. All rights reserved.
//

#import "CrimeDataDisplay.h"
#import "BoundaryData.h"

@implementation CrimeDataDisplay
{
    CrimeData *_cd;
}

- (BOOL)continue
{
    if (self.processingID == CRAPI.sharedInstance.keepProcessing)
        return YES;
    
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
    CloseTRANS2(&_pTranLLtoView);
    CloseTRANS2(&_pTranViewtoLL);
    [_cd close:YES];
    NSLog(@"Crime Database dealloc");
}


- (void)setTrans:(CORNERPOINTS *)corners
      viewBounds:(MNMXCORD *)pvbounds
{
    
    CloseTRANS2(&_pTranLLtoView);
    CloseTRANS2(&_pTranViewtoLL);
    _pTranLLtoView = STRANCornersToBounds(corners, pvbounds);
    _pTranViewtoLL = STRANBoundsToCorners(corners, pvbounds);
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
    BOOL outOfOrder = FALSE;
    
    NSString *query = [NSString stringWithFormat:@"SELECT UCR FROM CNUMCHECK WHERE ControlNbr = %i",controlNbr];
    sqlite3_stmt *statement = NULL;
    
    SQLOK(0,sqlite3_prepare_v2(_cd.database, query.UTF8String, -1, &statement, 0), _cd.database);
    
    if (sqlite3_step(statement) == SQLITE_ROW)
    {
        int ucr = sqlite3_column_int(statement, 0);
        if (UCR < ucr)
            outOfOrder = TRUE;
        rtn = TRUE;
    }
    SQLOK(0,sqlite3_finalize(statement), _cd.database);
    if (!rtn)
    {
        query = [NSString stringWithFormat:@"INSERT INTO CNUMCHECK VALUES(%i,%i);",controlNbr,UCR];
        [_cd executeCmd:(LPSTR)query.UTF8String];
    }
    return rtn;
}

- (void)displayCrimePoints:(CGContextRef)context
    displayCharacteristics:(DisplayCharacteristics *)dc
                 llCorners:(CORNERPOINTS *) latlonCornerPoints
                  LLBounds:(MNMXCORD *)platlonBounds
                viewBounds:(MNMXCORD *)pvbounds
                    themes:(Themes*)themes
               pointInArea:(PointInArea *)pia
{
    NSString *query;
    sqlite3_stmt *statement = NULL;
    DPOINT BasePt[2];
    //int UCR;
    int controlNbr = 0;
    int fromTime=(int)CRAPI.sharedInstance.fromDate, toTime=(int)CRAPI.sharedInstance.toDate;
    int numUCRRanges, numTimeRanges;
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

    if (_zoom > 15)
        sizeFactor += (_zoom - 15)/2;
    sizeFactor *= scale;
    [self setTrans:latlonCornerPoints viewBounds:pvbounds];
    BOOL opened = [_cd startTransaction];
    
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
    else if (_mode == CHOROPLETH)
    {
        CRAPI.sharedInstance.mapToolbar.showIndicator = YES;

        pias = [[PointInAreas alloc]init];
        pias.areaType = _choroplethTarget;
        pias.adjustValue = nil;
        bd = [[BoundaryData alloc]init];
        bd.processingID = self.processingID;
        [bd   load:_choroplethTarget
    toPointInAreas:pias
boundsPointInAreas:nil
  usingPointInArea:pia
         llCorners:latlonCornerPoints
          LLBounds:platlonBounds
        viewBounds:pvbounds];
        CRAPI.sharedInstance.mapToolbar.showIndicator = NO;

    }
    
    if (![self continue])
        goto Exit;

NextPass:
    if (_mode == HOTSPOT)
    {
        hs = [HotSpot initWithWidth:MNMXCORDWidth(pvbounds)
                             Height:MNMXCORDHeight(pvbounds)
                           NumGrids:1
                          PointSize:max(MNMXCORDWidth(pvbounds),MNMXCORDHeight(pvbounds))/32
                               tran:_pTranLLtoView];
    }
   
    numUCRRanges  = [themes getNumUCRRanges];
    numTimeRanges = [themes getNumTimeRanges];
    int totRanges = numTimeRanges * numUCRRanges;
    int iRange = 0;
    for (int ucrRange = 0; ucrRange < numUCRRanges; ucrRange++)
    {
        if (![self continue]) break;
        [themes getMinMaxUCR:ucrRange min:&_minUCR max:&_maxUCR];
        for (int timeRange = 0; timeRange < numTimeRanges; timeRange++)
        {
            if (![self continue]) break;
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
            SQLOK(0,sqlite3_prepare_v2(_cd.database, query.UTF8String, -1, &statement, 0), _cd.database);
            
            while ([self continue] && sqlite3_step(statement) == SQLITE_ROW)
            {
                BOOL attempted = FALSE;;
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
                if ((!pia || [pia DPointInArea:BasePt]) &&
                    [themes setDisplayCharacteristics:dc
                                            displayID:_processingID] != DO_NOT_DISPLAY_ITEM)
                {
                    DPOINT llpoint = TranDPOINT(BasePt, _pTranLLtoView);
                    if (_mode == PINMAP)
                    {
                        [dp addPoint:&llpoint
                          controlNbr:controlNbr
                                time:dc.itemBeginTime
                             offense:dc.string1
                         usingSymbol:dc.pointSymbol
                           withColor:dc.fillColor.CGColor
                             andSize:(size * sizeFactor)];

                    }
                    else if (_mode == CHOROPLETH)
                    {
                        [pias DPointInArea:&llpoint];
                    }
                    else if (_mode == HOTSPOT)
                    {
                        [hs addPointAtX:llpoint.x andY:llpoint.y];
                    }
                    else
                    {
                    }
                }
            }
            iRange++;
            SQLOK(0,sqlite3_finalize(statement), _cd.database);
        }
    }
    if (_mode == HOTSPOT && iPass++ < _numPass)
        goto NextPass;
    
    [CRAPI.sharedInstance updateProgress:tot current:tot range:0 numRanges:1];
    if (![self continue])
        ;
    else if (_mode == PINMAP)
    {
        query = [NSString stringWithFormat:@"SELECT ControlNbr,X,Y,DispersedX,DispersedY,Sequence,Symbol,Size,Color FROM DISPERSE"];
        SQLOK(0,sqlite3_prepare_v2(dp.database, query.UTF8String, -1, &statement, 0), dp.database);
        
        while ([self continue] && sqlite3_step(statement) == SQLITE_ROW)
        {
            POINT Point, origPoint;
            static BOOL doDisperse = TRUE;
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
        if ([self continue])
            [dp commitTransaction];
        SQLOK(0,sqlite3_finalize(statement), dp.database);
    }
    else if (_mode == CHOROPLETH)
    {
        NSArray * textArray = [NSArray new];
        
        if (_choroplethAdjustValue)
        {
            PointInAreas *piasAdjust = [[PointInAreas alloc]init];
            piasAdjust.areaType = _choroplethAdjustArea;
            piasAdjust.adjustValue = [ConfigurationControl getAdjustValueString:_choroplethAdjustValue];
            bd = [[BoundaryData alloc]init];
            bd.processingID = self.processingID;
           [bd load:_choroplethAdjustArea
                  toPointInAreas:piasAdjust
              boundsPointInAreas:pias
                usingPointInArea:pia
                       llCorners:latlonCornerPoints
                        LLBounds:platlonBounds
                      viewBounds:pvbounds];
            [pias createDisplayColors:piasAdjust mask:pia];
        }
        else
            [pias createDisplayColors:nil mask:pia];

        CRAPI.sharedInstance.mapToolbar.showIndicator = YES;
        bd.totRecords = [bd display:context
           areaType:_choroplethTarget
            pointInAreas:pias
          llCorners:latlonCornerPoints
           LLBounds:platlonBounds
         viewBounds:pvbounds];

        CRAPI.sharedInstance.mapToolbar.showIndicator = NO;

        NVMetroTextOptions *to = [[NVMetroTextOptions alloc]init];
        
        to.numTextFields = 1;
        to.desc = @"Boundary Name";
        to.fields = @"NAME";
        if (_choroplethAdjustValue == HousingUnits)
        {
            to.formats = [NSArray arrayWithObjects:[NSNumber numberWithInt:TXTAdjustCountPerHundred], nil];
        }
        else if (_choroplethAdjustValue == Population)
        {
            to.formats = [NSArray arrayWithObjects:[NSNumber numberWithInt:TXTAdjustCountPerThousand], nil];
        }
        else
            to.formats = [NSArray arrayWithObjects:[NSNumber numberWithInt:TXTAdjustCount], nil];
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
    else if (_mode == HOTSPOT)
    {
        static BOOL dump=FALSE;
        [hs display:context];
        if (dump)
            [hs dump:@"hotspottest"];
    }
Exit:
    [_cd close:opened];
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


@end

/*CREATE TABLE OFFENSEXY (id INT PRIMARY KEY,'ControlNbr' INT,'OffenseOrder' INT,'Offense' CHAR(6),'CityCode' CHAR(2),'CaseYear' INT,'CaseNbr' CHAR(6),'ControlType' CHAR(1),'Attempt' CHAR(1),'BeginDate2' CHAR(19),'Precinct' CHAR(2),'UCRCode' CHAR(2),'NIBRSCode' CHAR(3),'CrimeCategory' CHAR(1),'CrimeClass' CHAR(1),'LastChangedID2' CHAR(11),'LastChanged2' CHAR(19),'OriginalCaseYear' INT,'OriginalCaseNbr' CHAR(6),'HouseNbr' CHAR(6),'HouseModifier' CHAR(1),'StreetName' CHAR(22),'StreetType' CHAR(2),'StreetDirection' CHAR(2),'IntersectionStreetName' CHAR(22),'IntersectionStreetType' CHAR(2),'IntersectionStreetDirection' CHAR(2),'Apartment' CHAR(5),'City2' CHAR(30),'State' CHAR(2),'VictimBusiness' CHAR(1),'Zipcode2' CHAR(9),'EndDate' CHAR(19),'ReportedDate' CHAR(19),'BeginDate' CHAR(19),'DispatchedTime' CHAR(4),'ArrivedTime' CHAR(4),'Location' CHAR(30),'ClearedTime' CHAR(4),'PrimaryOffense' CHAR(6),'SupervisorID' CHAR(11),'AssistingOfficerID' CHAR(11),'NotPublicInformation' CHAR(1),'UnitNbr' CHAR(4),'ReportingID' CHAR(11),'CallNbr' CHAR(11),'EnteredID' CHAR(11),'EnteredDate' CHAR(19),'LastChanged' CHAR(19),'AdultStatus' INT,'JuvenileStatus' INT,'Solvable' INT,'NotPublicAddressInformation' CHAR(1),'LastChangedID' CHAR(11),'ForceSupervisorReviewRequired' INT,'ForceSupervisorReviewCompeted' INT,'ForceIAUReviewCompleted' INT,'MatchCode' INT,'LocationCode' INT,'StreetNum' INT,'HouseNum' INT,'IntID' INT,'StreetNum1' INT,'StreetNum2' INT,'Street1MP' REAL,'Street2MP' REAL,'MunicNum' INT,'ZIP' INT,'X' REAL,'Y' REAL,'NumPartsRemoved' INT,'AddressTAGPrefix' CHAR(8),'AddressTAGUDI' CHAR(64),'Street' CHAR(80),'House' CHAR(12),'City' CHAR(32),'ZIPCODE' CHAR(12),'Symbol' CHAR(64),'FromDate' INT,'ToDate' INT,'Note' CHAR(100),'UCR' INT)
*/
