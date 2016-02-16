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
    [_cd close];
    NSLog(@"Crime Database dealloc");
}


- (void)setTrans:(CORNERPOINTS *)corners
      viewBounds:(MNMXCORD *)pvbounds
{
    
    CloseTRANS2(&_pTranLLtoView);
    CloseTRANS2(&_pTranViewtoLL);
    _pTranLLtoView = STRANCornersToBounds(corners, pvbounds);
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

    if (_zoom > 14)
        sizeFactor += _zoom - 15;
    [self setTrans:latlonCornerPoints viewBounds:pvbounds];
    [_cd open];
    [_cd startTransaction];
    
    if (_mode == PINMAP)
    {
        dp = [DispersePoint initWithWidth:MNMXCORDWidth(pvbounds)
                                   Height:MNMXCORDHeight(pvbounds)
                              andDatabase:_cd];
    }
    else if (_mode == CHOROPLETH)
    {
        pias = [[PointInAreas alloc]init];
        bd = [[BoundaryData alloc]init];
        bd.processingID = self.processingID;
        [bd load:_choroplethTarget
  toPointInAreas:pias
usingPointInArea:pia
       llCorners:latlonCornerPoints
        LLBounds:platlonBounds
      viewBounds:pvbounds];
    }
    
    if (![self continue])
        goto Exit;

NextPass:
    if (_mode == HOTSPOT)
    {
        hs = [HotSpot initWithWidth:MNMXCORDWidth(pvbounds)
                             Height:MNMXCORDHeight(pvbounds)
                           NumGrids:1
                          PointSize:max(MNMXCORDWidth(pvbounds),MNMXCORDHeight(pvbounds))/32];
    }
   
    numUCRRanges  = [themes getNumUCRRanges];
    numTimeRanges = [themes getNumTimeRanges];
    int totRanges = numTimeRanges * numUCRRanges;
    int iRange = 0;
    for (int ucrRange = 0; ucrRange < numUCRRanges; ucrRange++)
    {
        [themes getMinMaxUCR:ucrRange min:&_minUCR max:&_maxUCR];
        for (int timeRange = 0; timeRange < numTimeRanges; timeRange++)
        {
            BOOL display = [themes getMinMaxTime:timeRange min:&fromTime max:&toTime];
            
            query = [NSString stringWithFormat:@"SELECT ControlNbr,X,Y,Offense,UCR,FromDate,ToDate, CityCode, SUNANGLE FROM OFFENSEXY,OFFENSEXY_index WHERE OFFENSEXY.id=OFFENSEXY_index.id AND\
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
            SQLOK(sqlite3_prepare_v2(_cd.database, query.UTF8String, -1, &statement, 0), _cd.database);
            
            while ([self continue] && sqlite3_step(statement) == SQLITE_ROW)
            {
                controlNbr = sqlite3_column_int(statement,0);
                BasePt[0].x = sqlite3_column_double(statement,1);
                BasePt[0].y = sqlite3_column_double(statement,2);
                offense = (LPSTR)sqlite3_column_text(statement,3);
                dc.dPoint = BasePt[0];
                dc.UCR = sqlite3_column_int(statement,4);
                dc.itemBeginTime = sqlite3_column_int(statement,5);
                [CRAPI.sharedInstance updateProgress:tot
                                             current:dc.itemBeginTime-fromTime
                                               range:iRange
                                           numRanges:totRanges];
                dc.itemEndTime = sqlite3_column_int(statement,6);
                dept = (LPSTR)sqlite3_column_text(statement,7);
                dc.sunAngle = sqlite3_column_int(statement,8);
                dc.string1 = [NSString stringWithUTF8String:offense];
                dc.string2 = [NSString stringWithUTF8String:dept];
                dc.color = [UIColor colorWithRed:1 green:0 blue:0 alpha:1];
                size = 25;
                if ((!pia || [pia DPointInArea:BasePt]) &&
                    [themes setDisplayCharacteristics:dc
                                            displayID:_processingID] != DO_NOT_DISPLAY_ITEM)
                {
                    DPOINT llpoint = TranDPOINT(BasePt, _pTranLLtoView);
                    if (_mode == PINMAP)
                    {
                        [dp addPoint:&llpoint
                          controlNbr:controlNbr
                         usingSymbol:dc.pointSymbol
                           withColor:dc.color.CGColor
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
            SQLOK(sqlite3_finalize(statement), _cd.database);
        }
    }
    if (_mode == HOTSPOT && iPass++ < _numPass)
        goto NextPass;
    
    [CRAPI.sharedInstance updateProgress:tot current:tot range:0 numRanges:1];
    if (![self continue])
        ;
    else if (_mode == PINMAP)
    {
        query = [NSString stringWithFormat:@"SELECT ControlNbr,X,Y,Sequence,Symbol,Size,Color FROM DISPERSE"];
        SQLOK(sqlite3_prepare_v2(_cd.database, query.UTF8String, -1, &statement, 0), _cd.database);
        
        while ([self continue] && sqlite3_step(statement) == SQLITE_ROW)
        {
            POINT Point, origPoint;
            static BOOL doDisperse = TRUE;
            controlNbr = sqlite3_column_int(statement,0);
            Point.x = sqlite3_column_int(statement,1);
            Point.y = sqlite3_column_int(statement,2);
            origPoint = Point;
            int seq = sqlite3_column_int(statement,3)+1;
            PointSymbols sym = sqlite3_column_int(statement,4);
            CGFloat size = sqlite3_column_double(statement,5);
            CGColorRef clr = (CGColorRef)sqlite3_column_int64(statement,6);
            if (doDisperse)
                Point = AddjustPointLoc (Point,size,seq);
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
        SQLOK(sqlite3_finalize(statement), _cd.database);
    }
    else if (_mode == CHOROPLETH)
    {
        NSArray * textArray = [NSArray new];
        
        [pias createDisplayColors];
        
        [bd display:context
           areaType:_choroplethTarget
       pointInAreas:pias
          llCorners:latlonCornerPoints
           LLBounds:platlonBounds
         viewBounds:pvbounds];
        
        [bd displayText:context
               areaType:_choroplethTarget
              textArray:textArray
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
    [_cd close];
}

/*- (int)pickCrimePoint:(LLPOINT *)pt
        highlightList:(NSMutableArray*)hlist
{
    if (![ConfigurationControl.sharedInstance layer:HCLayerCrimes
                                      visibleAtZoom:_zoom
                                            andPass:PickPass])
        return 0;
    
    NSString *minPID = [[NSString alloc] init];
    CGFloat d, mind = DBL_MAX;
    DPOINT p1, p2, minpt;
    int minref = 0;
    int npicked = 0;
    
    p1.x = pt->lon;
    p1.y = pt->lat;
    minpt = p1;
    dbounds bnds = [CRAPI.sharedInstance getPickApBoundsAtPoint:pt];
    BOOL opened = [_cd open];
    
    NSString *query = [NSString stringWithFormat:@"SELECT PROPINFO.id, PIN, LATITUDE, LONGITUDE FROM PROPINFO,PROPINFO_index WHERE PROPINFO.id=PROPINFO_index.id AND maxX>=%f AND minX<=%f AND maxY>=%f AND minY<=%f",
                       bnds.xmn, bnds.xmx, bnds.ymn, bnds.ymx];
    
    sqlite3_stmt *statement = NULL;
    
    SQLOKpd(sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement, 0), _database, 34);
    
    while (sqlite3_step(statement) == SQLITE_ROW)
    {
        int refno = sqlite3_column_int(statement, 0);
        LPSTR cpid = (LPSTR)sqlite3_column_text(statement, 1);
        CGFloat lat = sqlite3_column_double(statement, 2);
        CGFloat lon = sqlite3_column_double(statement, 3);
        p2.x = lon;
        p2.y = lat;
        d = ArcDistance(p1, p2);
        
        if (d < mind)
        {
            npicked++;
            minref = refno;
            mind = d;
            minpt = p2;
            minPID = [NSString stringWithUTF8String:cpid];
        }
    }
    
    SQLOKpd(sqlite3_finalize(statement), _database, 35);
    [self close:opened];
    pt->lon = minpt.x;
    pt->lat = minpt.y;
    if (npicked)
    {
        PickedItem *pi = [[PickedItem alloc]init];
        pi.itemType = PTPid;
        pi.distance = mind;
        pi.pickedPoint = minpt;
        pi.identifier = minPID;
        pi.symbolName = @"PARCEL";
        pi.refno = minref;
        [hlist addObject:pi];
    }
    return npicked;
}*/


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


POINT AddjustPointLoc (POINT Point,float Size,int Sequence)
#if ENABLETRACE
{GSSiEnterProg (1331);
#endif
    {
        short	xmove, ymove, shift=0;
        float	shiftdist;
        
        if (Sequence <= 1)
        {
#if ENABLETRACE
            GSSiExitProg (1331);
#endif
            return Point;
        }
    Top:
        if (Sequence == 1)
        {
            xmove = 0;
            ymove = 0;
        }
        else if (Sequence < 4)
        {
            xmove = -1;
            ymove = Sequence - 2;
        }
        else if (Sequence < 6)
        {
            ymove = 1;
            xmove = Sequence - 4;
        }
        else if (Sequence < 8)
        {
            xmove = 1;
            ymove = -(Sequence - 6);
        }
        else if (Sequence < 10)
        {
            ymove = -1;
            xmove = -(Sequence - 8);
        }
        else if (Sequence < 14)
        {
            xmove = -2;
            ymove = Sequence - 11;
        }
        else if (Sequence < 18)
        {
            ymove = 2;
            xmove = Sequence - 15;
        }
        else if (Sequence < 22)
        {
            xmove = 2;
            ymove = -(Sequence - 19);
        }
        else if (Sequence < 27)
        {
            ymove = -2;
            xmove = -(Sequence - 23);
        }
        else if (Sequence < 32)
        {
            xmove = -3;
            ymove = Sequence - 28;
        }
        else if (Sequence < 38)
        {
            ymove = 3;
            xmove = Sequence - 34;
        }
        else if (Sequence < 44)
        {
            xmove = 3;
            ymove = -(Sequence - 40);
        }
        else if (Sequence < 51)
        {
            ymove = -3;
            xmove = -(Sequence - 46);
        }
        else if (Sequence < 58)
        {
            xmove = -4;
            ymove = Sequence - 53;
        }
        else if (Sequence < 66)
        {
            ymove = 4;
            xmove = Sequence - 61;
        }
        else if (Sequence < 74)
        {
            xmove = 4;
            ymove = -(Sequence - 69);
        }	
        else if (Sequence < 83)
        {  
            ymove = -4;
            xmove = -(Sequence - 77);
        }	
        else if (Sequence < 92)
        {  
            xmove = -5;
            ymove = Sequence - 86;
        }	
        else if (Sequence < 102)
        {  
            ymove = 5;
            xmove = Sequence - 96;
        }	
        else if (Sequence < 112)
        {  
            xmove = 5;
            ymove = -(Sequence - 106);
        }	
        else if (Sequence < 122)
        {  
            ymove = -5;
            xmove = -(Sequence - 116);
        }	
        else 
        {  
            shift++;
            Sequence -= 121;
            goto Top;
        }
        shiftdist = shift * 0.25 * Size;	
        Point.x += IDNINT (xmove * Size + shiftdist);
        Point.y += IDNINT (ymove * Size + shiftdist);
        {
#if ENABLETRACE
            GSSiExitProg (1331);
#endif
            return Point;
        }
#if ENABLETRACE
    }
#endif
} 

@end

/*CREATE TABLE OFFENSEXY (id INT PRIMARY KEY,'ControlNbr' INT,'OffenseOrder' INT,'Offense' CHAR(6),'CityCode' CHAR(2),'CaseYear' INT,'CaseNbr' CHAR(6),'ControlType' CHAR(1),'Attempt' CHAR(1),'BeginDate2' CHAR(19),'Precinct' CHAR(2),'UCRCode' CHAR(2),'NIBRSCode' CHAR(3),'CrimeCategory' CHAR(1),'CrimeClass' CHAR(1),'LastChangedID2' CHAR(11),'LastChanged2' CHAR(19),'OriginalCaseYear' INT,'OriginalCaseNbr' CHAR(6),'HouseNbr' CHAR(6),'HouseModifier' CHAR(1),'StreetName' CHAR(22),'StreetType' CHAR(2),'StreetDirection' CHAR(2),'IntersectionStreetName' CHAR(22),'IntersectionStreetType' CHAR(2),'IntersectionStreetDirection' CHAR(2),'Apartment' CHAR(5),'City2' CHAR(30),'State' CHAR(2),'VictimBusiness' CHAR(1),'Zipcode2' CHAR(9),'EndDate' CHAR(19),'ReportedDate' CHAR(19),'BeginDate' CHAR(19),'DispatchedTime' CHAR(4),'ArrivedTime' CHAR(4),'Location' CHAR(30),'ClearedTime' CHAR(4),'PrimaryOffense' CHAR(6),'SupervisorID' CHAR(11),'AssistingOfficerID' CHAR(11),'NotPublicInformation' CHAR(1),'UnitNbr' CHAR(4),'ReportingID' CHAR(11),'CallNbr' CHAR(11),'EnteredID' CHAR(11),'EnteredDate' CHAR(19),'LastChanged' CHAR(19),'AdultStatus' INT,'JuvenileStatus' INT,'Solvable' INT,'NotPublicAddressInformation' CHAR(1),'LastChangedID' CHAR(11),'ForceSupervisorReviewRequired' INT,'ForceSupervisorReviewCompeted' INT,'ForceIAUReviewCompleted' INT,'MatchCode' INT,'LocationCode' INT,'StreetNum' INT,'HouseNum' INT,'IntID' INT,'StreetNum1' INT,'StreetNum2' INT,'Street1MP' REAL,'Street2MP' REAL,'MunicNum' INT,'ZIP' INT,'X' REAL,'Y' REAL,'NumPartsRemoved' INT,'AddressTAGPrefix' CHAR(8),'AddressTAGUDI' CHAR(64),'Street' CHAR(80),'House' CHAR(12),'City' CHAR(32),'ZIPCODE' CHAR(12),'Symbol' CHAR(64),'FromDate' INT,'ToDate' INT,'Note' CHAR(100),'UCR' INT)
*/