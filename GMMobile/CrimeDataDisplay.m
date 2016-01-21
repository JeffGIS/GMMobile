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
    if (self.processingID == keepProcessing)
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
    DPOINT BasePt;
    //int UCR;
    int controlNbr = 0;
    int fromTime=(int)CRAPI.sharedInstance.fromDate, toTime=(int)CRAPI.sharedInstance.toDate;
    int nFound=0;
    int numUCRRanges, numTimeRanges;
    LPSTR offense;
    LPSTR dept;
    CGFloat size;
    CGFloat sizeFactor = 5;
    NSInteger tot=0, current=0;
    [CRAPI.sharedInstance updateProgress:-1 current:0 range:0 numRanges:1];
    PointInAreas *pias = nil;
    BoundaryData *bd = nil;

    [self setTrans:latlonCornerPoints viewBounds:pvbounds];
    if (_mode == CHOROPLETH)
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
    /*if (_zoom > 18)
     sizeFactor *= (2.0 *(_zoom - 18.0));
     
     else if (_zoom < 18)
     sizeFactor /= (2.0 * (18.0 - _zoom));*/
    
    if (![self continue])
        return;
    
    sizeFactor = 1;
    
    [_cd open];
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
                BasePt.x = sqlite3_column_double(statement,1);
                BasePt.y = sqlite3_column_double(statement,2);
                offense = (LPSTR)sqlite3_column_text(statement,3);
                dc.dPoint = BasePt;
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
                if ((!pia || [pia DPointInArea:&BasePt]) &&
                    [themes setDisplayCharacteristics:dc
                                            displayID:_processingID] != DO_NOT_DISPLAY_ITEM)
                {
                    DPOINT llpoint = TranDPOINT(&BasePt, _pTranLLtoView);
                    if (_mode == CHOROPLETH)
                    {
                        [pias DPointInArea:&llpoint];
                    }
                    else
                    {
                        size = 25;
                        [self drawCrimePoint:context
                                     atPoint:&llpoint
                                 usingSymbol:dc.pointSymbol
                                   withColor:dc.color.CGColor
                                     andSize:(size * sizeFactor)];
                    }
                }
            }
            iRange++;
            SQLOK(sqlite3_finalize(statement), _cd.database);
        }
    }
    [_cd close];
    [CRAPI.sharedInstance updateProgress:tot current:tot range:0 numRanges:1];
    if (_mode == CHOROPLETH)
    {
        [pias createDisplayColors];

        [bd display:context
           areaType:_choroplethTarget
       pointInAreas:pias
          llCorners:latlonCornerPoints
           LLBounds:platlonBounds
         viewBounds:pvbounds];
    }
}

- (void)drawCrimePoint:(CGContextRef)context
               atPoint:(DPOINT *)pPoint
           usingSymbol:(PointSymbols)sym
             withColor:(CGColorRef)color
               andSize:(CGFloat)size

{
    
    [SymbolDictionary drawPointWithSymbol:context
                                       at:pPoint
                              usingSymbol:sym
                                     Size:size
                                fillColor:color
                                lineColor:0
                                lineWidth:2];

}

@end

/*CREATE TABLE OFFENSEXY (id INT PRIMARY KEY,'ControlNbr' INT,'OffenseOrder' INT,'Offense' CHAR(6),'CityCode' CHAR(2),'CaseYear' INT,'CaseNbr' CHAR(6),'ControlType' CHAR(1),'Attempt' CHAR(1),'BeginDate2' CHAR(19),'Precinct' CHAR(2),'UCRCode' CHAR(2),'NIBRSCode' CHAR(3),'CrimeCategory' CHAR(1),'CrimeClass' CHAR(1),'LastChangedID2' CHAR(11),'LastChanged2' CHAR(19),'OriginalCaseYear' INT,'OriginalCaseNbr' CHAR(6),'HouseNbr' CHAR(6),'HouseModifier' CHAR(1),'StreetName' CHAR(22),'StreetType' CHAR(2),'StreetDirection' CHAR(2),'IntersectionStreetName' CHAR(22),'IntersectionStreetType' CHAR(2),'IntersectionStreetDirection' CHAR(2),'Apartment' CHAR(5),'City2' CHAR(30),'State' CHAR(2),'VictimBusiness' CHAR(1),'Zipcode2' CHAR(9),'EndDate' CHAR(19),'ReportedDate' CHAR(19),'BeginDate' CHAR(19),'DispatchedTime' CHAR(4),'ArrivedTime' CHAR(4),'Location' CHAR(30),'ClearedTime' CHAR(4),'PrimaryOffense' CHAR(6),'SupervisorID' CHAR(11),'AssistingOfficerID' CHAR(11),'NotPublicInformation' CHAR(1),'UnitNbr' CHAR(4),'ReportingID' CHAR(11),'CallNbr' CHAR(11),'EnteredID' CHAR(11),'EnteredDate' CHAR(19),'LastChanged' CHAR(19),'AdultStatus' INT,'JuvenileStatus' INT,'Solvable' INT,'NotPublicAddressInformation' CHAR(1),'LastChangedID' CHAR(11),'ForceSupervisorReviewRequired' INT,'ForceSupervisorReviewCompeted' INT,'ForceIAUReviewCompleted' INT,'MatchCode' INT,'LocationCode' INT,'StreetNum' INT,'HouseNum' INT,'IntID' INT,'StreetNum1' INT,'StreetNum2' INT,'Street1MP' REAL,'Street2MP' REAL,'MunicNum' INT,'ZIP' INT,'X' REAL,'Y' REAL,'NumPartsRemoved' INT,'AddressTAGPrefix' CHAR(8),'AddressTAGUDI' CHAR(64),'Street' CHAR(80),'House' CHAR(12),'City' CHAR(32),'ZIPCODE' CHAR(12),'Symbol' CHAR(64),'FromDate' INT,'ToDate' INT,'Note' CHAR(100),'UCR' INT)
*/