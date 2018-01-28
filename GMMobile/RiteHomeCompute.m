//
//  RiteHomeCompute.m
//  NVMobile
//
//  Created by JEFFREY E SMITH on 1/25/18.
//  Copyright © 2018 GSSi. All rights reserved.
//

#import "RiteHomeCompute.h"

@implementation DATA_FROM_PARCELS
@end
@implementation DATA_FROM_BLOCKS
@end
@implementation DATA_FROM_LANDUSE
@end

@implementation RiteHomeCompute

/*
 CREATE TABLE PROPINFO ('id' INT,'PIN' CHAR(17),'BLDG_NUM' CHAR(10),'STREETNAME' CHAR(60),'UNIT_INFO' CHAR(12),'CITY' CHAR(30),'CITY_USPS' CHAR(30),'ZIP' CHAR(5),'ZIP4' CHAR(4),'PLAT_NAME' CHAR(50),'BLOCK' CHAR(5),'LOT' CHAR(5),'ACRES_POLY' REAL,'ACRES_DEED' REAL,'USE1_DESC' CHAR(100),'USE2_DESC' CHAR(100),'USE3_DESC' CHAR(100),'USE4_DESC' CHAR(100),'MULTI_USES' CHAR(1),'LANDMARK' CHAR(100),'OWNER_NAME' CHAR(50),'OWNER_MORE' CHAR(50),'OWN_ADD_L1' CHAR(40),'OWN_ADD_L2' CHAR(40),'OWN_ADD_L3' CHAR(40),'TAX_NAME' CHAR(40),'TAX_ADD_L1' CHAR(40),'TAX_ADD_L2' CHAR(40),'TAX_ADD_L3' CHAR(40),'HOMESTEAD' CHAR(1),'EMV_LAND' REAL,'EMV_BLDG' REAL,'EMV_TOTAL' REAL,'TAX_CAPAC' REAL,'TOTAL_TAX' REAL,'SPEC_ASSES' REAL,'TAX_EXEMPT' CHAR(1),'XUSE1_DESC' CHAR(100),'XUSE2_DESC' CHAR(100),'XUSE3_DESC' CHAR(100),'XUSE4_DESC' CHAR(100),'DWELL_TYPE' CHAR(30),'HOME_STYLE' CHAR(30),'FIN_SQ_FT' REAL,'GARAGE' CHAR(1),'GARAGESQFT' CHAR(11),'BASEMENT' CHAR(1),'HEATING' CHAR(30),'COOLING' CHAR(30),'YEAR_BUILT' CHAR(5),'NUM_UNITS' CHAR(6),'SALE_DATE' CHAR(8),'SALE_VALUE' REAL,'SCHOOL_DST' CHAR(6),'WSHD_DIST' CHAR(50),'GREEN_ACRE' CHAR(1),'OPEN_SPACE' CHAR(1),'AG_PRESERV' CHAR(1),'AGPRE_ENRD' CHAR(8),'AGPRE_EXPD' CHAR(8),'PARC_CODE' CHAR(5),'CENBLOCK' CHAR(15),'LONGITUDE' REAL,'LATITUDE' REAL,PRIMARY KEY('id' ASC))
 */

+(NSString *) parcelFieldList
{
    NSString * list = @"ACRES_POLY,USE1_DESC,SALE_DATE,EMV_TOTAL,TOTAL_TAX,HOMESTEAD,YEAR_BUILT,OPEN_SPACE, OWNER_NAME, TAX_NAME";
    return list;
}

- (bool) computeParcelValues:(DATA_FROM_PARCELS *)values
                      totEMV:(int)totEMV
                     useDesc:(LPSTR) usedescIN
                   statement:(sqlite3_stmt*)statement
            PIDListStatement:(sqlite3_stmt*)statement_PidList
{
    bool rtn = FALSE;
    int nHomestead=0;
    int totProp = 0;
    double sumEMV=0;
    double sumAcres=0;
    int medianEMV=0;
    int now = 2017;
    int nowMinus5 = now - 5,nowMinus10 = now - 10,nowMinus15 = now - 15,nowMinus25 = now - 25;
    int numNewerThan25 = 0;
    int numNewerThan10 = 0;
    int numNoTax = 0;

    int myTotEMV = totEMV;
    int nAge = 0, nSales5yr = 0, nSales15yr = 0;
    int minSale = INT_MAX;
    CGFloat totYears = 0;
    CGFloat totAcres = 0, totOSAcres = 0;
    NSMutableArray * EMVarray=[[NSMutableArray alloc]init];
    NSMutableArray * ageArray=[[NSMutableArray alloc]init];

Top:
    if (statement)
    {
    while (sqlite3_step(statement) == SQLITE_ROW)
    {
        int i=0;
        CGFloat acres = sqlite3_column_double(statement,i++);
        LPSTR useDesc = (LPSTR)sqlite3_column_text(statement, i++);
        LPSTR saleDate = (LPSTR)sqlite3_column_text(statement, i++);
        int totEMV = (int)sqlite3_column_double(statement, i++);
        double totTax = sqlite3_column_double(statement, i++);
        LPSTR homestead = (LPSTR)sqlite3_column_text(statement, i++);
        LPSTR yearBuilt = (LPSTR)sqlite3_column_text(statement, i++);
        LPSTR openSpace = (LPSTR)sqlite3_column_text(statement, i++);
        LPSTR ownName = (LPSTR)sqlite3_column_text(statement, i++);
        LPSTR taxName = (LPSTR)sqlite3_column_text(statement, i++);

        totProp++;
        int yrBuilt = atoi (yearBuilt);
        if (*homestead == 'y' || *homestead == 'Y')
            nHomestead++;
        totAcres += acres;
        if (*openSpace != 'N')
        {
            if (*openSpace == 'y' || *openSpace == 'Y')
                totOSAcres += acres;
        }
        if (!strcasecmp (useDesc,usedescIN))
        {
            values.nMatchingProperties++;
            if (!totTax)
                numNoTax++;
            if (*saleDate)
            {
                int date = atoi (saleDate);
                minSale = min (minSale,date);
                date /= 10000;
                if (date >= nowMinus5)
                    nSales5yr++;
                if (date >= nowMinus15)
                    nSales15yr++;
            }
            if (yrBuilt > 1800)
            {
                if (yrBuilt > nowMinus25)
                    numNewerThan25++;
                if (yrBuilt > nowMinus10)
                    numNewerThan10++;
                totYears += yrBuilt;
                nAge++;
                NSNumber *age = [[NSNumber alloc]initWithInt:yrBuilt];
                [ageArray addObject:age];
            }
            if (totEMV > 0)
            {
                NSNumber * emv = [NSNumber numberWithInteger:totEMV];
                [EMVarray addObject:emv];
                sumAcres += acres;
                sumEMV += totEMV;
            }
        }
    }
    SQLOK(__FILE__,__LINE__,SQLiteFinalize(statement),_propData.database);
    }
    if (statement_PidList)
    {
        if (sqlite3_step(statement_PidList) == SQLITE_ROW)
        {
            int polyID = sqlite3_column_int(statement_PidList,0);
            NSString *PIN = [_propData getPIDforPolyid:polyID];
            NSString *parcelFieldList = [RiteHomeCompute parcelFieldList];
            NSString *query = [NSString stringWithFormat:@"SELECT %@ FROM PROPINFO Where PIN = '%@'",parcelFieldList,PIN];
            SQLOK(__FILE__,__LINE__,SQLitePrepare(_propData.database, query.UTF8String, -1, &statement, 0), _propData.database);
            goto Top;
        }
        else
            SQLOK(__FILE__,__LINE__,SQLiteFinalize(statement_PidList),_propList.database);
    }
    if (values.nMatchingProperties)
    {
        values.stability_5yr  = IDNINT(100.0-(100.0 * nSales5yr) / values.nMatchingProperties);
        values.stability_15yr = IDNINT(100.0-(100.0 * nSales15yr) / values.nMatchingProperties);
        values.pctNoTax = IDNINT((100.0 * numNoTax) / values.nMatchingProperties);
        values.pctHomestead  = IDNINT((100.0 * nHomestead) / totProp);
    }
    if (totProp)
    {
    }
    if (nAge)
    {
        values.aveBuiltYear = totYears /= nAge;
        values.pctNew_10yr =  (100 * numNewerThan10)  / nAge;
        values.pctNew_25yr = (100 * numNewerThan25) / nAge;
        [ageArray sortUsingComparator: ^(id obj1, id obj2)
         {
             NSNumber *v1 = obj1;
             NSNumber *v2 = obj2;
             
             if (v1 > v2)
                 return (NSComparisonResult)NSOrderedDescending;
             
             if (v1 < v2)
                 return (NSComparisonResult)NSOrderedAscending;
             
             return (NSComparisonResult)NSOrderedSame;
         }];
        
        int median = (nAge / 2);
        NSNumber *age1 = (NSNumber *)ageArray[median];
        
        if (!(nAge %2))
        {
            NSNumber *age2 = (NSNumber *)ageArray[median - 1];
            values.medianBuiltYear = ((age1.floatValue + age2.floatValue) / 2.0);
        }
        else
            values.medianBuiltYear = age1.intValue;
    }
    
    [EMVarray sortUsingComparator: ^(id obj1, id obj2)
     {
         NSNumber *v1 = obj1;
         NSNumber *v2 = obj2;
         
         if (v1 > v2)
             return (NSComparisonResult)NSOrderedDescending;
         
         if (v1 < v2)
             return (NSComparisonResult)NSOrderedAscending;
         
         return (NSComparisonResult)NSOrderedSame;
     }];
    
    if ([EMVarray count])
    {
        int n=1;
        int myStartRank= -1;
        int myEndRank= -1;
        int medianN = (int)EMVarray.count / 2;
        int medianM = EMVarray.count % 2;
        //NSNumber *minEMV = array[0];
        //NSNumber *maxEMV = array[array.count - 1];
        for (NSNumber *EMVvalue in EMVarray)
        {
            if (n == medianN)
                medianEMV = EMVvalue.intValue;
            
            if (n == medianN + medianM)
                medianEMV = (medianEMV + EMVvalue.intValue) / 2;
            
            if (EMVvalue.integerValue == myTotEMV)
            {
                if (myStartRank < 0)
                    myStartRank = n;
                myEndRank = n;
            }
            n++;
        }
        
        //aveEMV = sumEMV / [array count];
        //pctAveEMV = ((double)myTotEMV / aveEMV) * 100;
        //pctMedianEMV = ((double)myTotEMV / medianEMV) * 100;
        values.rankTotEMV = IDNINT((100.0 * (myStartRank + myEndRank)/2.0)/[EMVarray count]);
    }
    
     return rtn;
}


+(NSString *) blockFieldList
{
    NSString * list = @"POPTOTAL,LIVEDALONE,MARRKIDS,UNMARRKIDS,FAMNOKIDS,NONFAMILY";
    return list;
}


- (bool) computeBlockValues:(DATA_FROM_BLOCKS *)values
                  statement:(sqlite3_stmt*)statement_BlockList
{
    bool rtn = FALSE;
    sqlite3_stmt *statement = NULL;
    double totPop = 0;
    double pctOfAreaInCircle = 1;
    
Top:
    if (statement)
    {
        while (sqlite3_step(statement) == SQLITE_ROW)
        {
            rtn = TRUE;
            int i=0;
            int popTotal = sqlite3_column_int(statement,i++);
            int livedAlone = sqlite3_column_int(statement,i++);
            int marrKids = sqlite3_column_int(statement,i++);
            int unMarrKids = sqlite3_column_int(statement,i++);
            int famNoKids = sqlite3_column_int(statement,i++);
            int nonFamily = sqlite3_column_int(statement,i++);
            
            totPop += popTotal * pctOfAreaInCircle;
        }
        SQLOK(__FILE__,__LINE__,SQLiteFinalize(statement),_propData.database);
    }
    if (statement_BlockList)
    {
        if (sqlite3_step(statement_BlockList) == SQLITE_ROW)
        {
            int polyID = sqlite3_column_int(statement_BlockList,0);
            double SQMetersInCircle = sqlite3_column_double(statement_BlockList,1);
            double polyArea;
            NSString *BLOCK = [BoundaryData getKeyforPolyid:polyID
                                                     ofType:@"BLOCK"
                                               areaInMeters:&polyArea];
            pctOfAreaInCircle = SQMetersInCircle /polyArea;
            //            if (pctOfAreaInCircle > 1)
            //                pctOfAreaInCircle = 1;
            NSString *blockFieldList = [RiteHomeCompute blockFieldList];
            NSString *query = [NSString stringWithFormat:@"SELECT %@ FROM CENSUSBLOCKDATA Where GEOG_UNIT = '%@'",blockFieldList,BLOCK];
            SQLOK(__FILE__,__LINE__,SQLitePrepare(_propData.database, query.UTF8String, -1, &statement, 0), _propData.database);
            goto Top;
        }
        else
            SQLOK(__FILE__,__LINE__,SQLiteFinalize(statement_BlockList),_propList.database);
    }
    values.totPop = IDNINT (totPop);
    values.totPopPerSqMile = IDNINT (totPop / _circleAreaInSqMiles);
    return rtn;
}

+(NSString *) landUseFieldList
{
    NSString * list = @"USECODE,Area";
    return list;
}

- (bool) computeLandUseValues:(DATA_FROM_LANDUSE *)values
                  statement:(sqlite3_stmt*)statement
{
    bool rtn = FALSE;
    int numPoly = 0;
    double totalPct = 0;
    double totPct[LUC_Count]={0};
    
    while (sqlite3_step(statement) == SQLITE_ROW)
    {
        rtn = TRUE;
        numPoly++;
        int i=0;
        int polyID = sqlite3_column_int(statement,i++);
        double SQMetersInCircle = sqlite3_column_double(statement,i++);
        double PercentOfCircle = sqlite3_column_double(statement,i++);
        if (polyID < 0 || polyID >= LUC_Count)
            rtn = FALSE;
        else
            totPct[polyID] += PercentOfCircle;
        totalPct += PercentOfCircle;
    }
    SQLOK(__FILE__,__LINE__,SQLiteFinalize(statement),_propData.database);
    return rtn;
}

- (bool)computeValuesFromParcelsInCensus:(DATA_FROM_PARCELS *)values
                            inCensusArea:(LPSTR)cenBlockIN
                                  totEMV:(int)totEMV
                                 useDesc:(LPSTR) usedescIN
{
    bool rtn;
    sqlite3_stmt *statement = NULL;
    NSString *query;
    NSString *parcelFieldList = [RiteHomeCompute parcelFieldList];

    if (strlen (cenBlockIN) == 12)
        query = [NSString stringWithFormat:@"SELECT %@ FROM PROPINFO WHERE CENBLOCK>='%s000' AND CENBLOCK<='%s999'",parcelFieldList,cenBlockIN,cenBlockIN];
    else if (strlen (cenBlockIN) > 12)
        query = [NSString stringWithFormat:@"SELECT %@ FROM PROPINFO WHERE CENBLOCK='%s'",parcelFieldList,cenBlockIN];
    else
        return FALSE;
    
    BOOL opened = [_propData open];
    SQLOK(__FILE__,__LINE__,SQLitePrepare(_propData.database, query.UTF8String, -1, &statement, 0), _propData.database);
    rtn = [self computeParcelValues:values
                              totEMV:totEMV
                             useDesc:usedescIN
                           statement:statement
                    PIDListStatement:nil];
    [_propData close:opened];
    return rtn;
}

- (bool)computeValuesFromParcelsInCircle:(DATA_FROM_PARCELS *)values
                             forProperty:(int)propNum
                                inCircle:(int)circleID
                                  totEMV:(int)totEMV
                                 useDesc:(LPSTR) usedescIN
{
    bool rtn;
    sqlite3_stmt *statement = NULL;
    sqlite3_stmt *statement_PID = NULL;
    NSString *query;
    int circleId = circleID - 1;
    _circleAreaInSqMiles = circleRadiusInMiles[circleId] * circleRadiusInMiles[circleId] * PY;

    
    query = [NSString stringWithFormat:@"SELECT AreaID,SQMetersInCircle,PercentOfCircle FROM AreasWithinDistance WHERE PropNum = %i AND AreaType = %i AND Distance = %i",propNum,MBL_Parcels,circleID];
    SQLOK(__FILE__,__LINE__,SQLitePrepare(_propList.database, query.UTF8String, -1, &statement_PID, 0), _propList.database);
    BOOL opened = [_propData open];
    rtn = [self computeParcelValues:values
                             totEMV:totEMV
                            useDesc:usedescIN
                          statement:statement
                   PIDListStatement:statement_PID];
    
    [_propData close:opened];
    
    return rtn;
}
- (bool)computeValuesFromBlocksInCircle:(DATA_FROM_BLOCKS *)values
                            forProperty:(int)propNum
                               inCircle:(int)circleID
{
    bool rtn;
    sqlite3_stmt *statement = NULL;
    NSString *query;
    int circleId = circleID - 1;
    _circleAreaInSqMiles = circleRadiusInMiles[circleId] * circleRadiusInMiles[circleId] * PY;
    
    query = [NSString stringWithFormat:@"SELECT AreaID,SQMetersInCircle,PercentOfCircle FROM AreasWithinDistance WHERE PropNum = %i AND AreaType = %i AND Distance = %i",propNum,MBL_CensusBlocks,circleID];
    SQLOK(__FILE__,__LINE__,SQLitePrepare(_propList.database, query.UTF8String, -1, &statement, 0), _propList.database);
    BOOL opened = [_propData open];
    rtn = [self computeBlockValues:values
                         statement:statement];
    
    [_propData close:opened];
    
    return rtn;
}
- (bool)computeValuesFromLandUseInCircle:(DATA_FROM_LANDUSE *)values
                            forProperty:(int)propNum
                               inCircle:(int)circleID
{
    bool rtn;
    sqlite3_stmt *statement = NULL;
    NSString *query;
    int circleId = circleID - 1;
    _circleAreaInSqMiles = circleRadiusInMiles[circleId] * circleRadiusInMiles[circleId] * PY;
    
    query = [NSString stringWithFormat:@"SELECT AreaID,SQMetersInCircle,PercentOfCircle FROM AreasWithinDistance WHERE PropNum = %i AND AreaType = %i AND Distance = %i",propNum,MBL_LandUse,circleID];
    SQLOK(__FILE__,__LINE__,SQLitePrepare(_propList.database, query.UTF8String, -1, &statement, 0), _propList.database);
    BOOL opened = [_propData open];
    rtn = [self computeLandUseValues:values
                         statement:statement];
    
    [_propData close:opened];
    
    return rtn;
}
/*
- (bool)computeValuesFromCensus:(DATA_FROM_PARCELS *)values
                   inCensusArea:(LPSTR)cenBlockIN
                         totEMV:(int)totEMV
                        useDesc:(LPSTR) usedescIN
{
    bool rtn = FALSE;

if (strlen (cenBlockIN) > 12)
query = [NSString stringWithFormat:@"SELECT MEDIANAGE,HOMEOWNPCT,HHTOTAL,HH_UNDER18,HH_65OVER FROM CENSUSBLOCKDATA WHERE GEOG_UNIT ='%s'",cenBlockIN];
else
query = [NSString stringWithFormat:@"SELECT MEDIANAGE,HOMEOWNPCT,HHTOTAL,HH_UNDER18,HH_65OVER FROM CENSUSBLOCKGROUPDATA WHERE GEOG_UNIT ='%s'",cenBlockIN];
SQLOK(__FILE__,__LINE__,SQLitePrepare(_propData.database, query.UTF8String, -1, &statement, 0), _propData.database);

if (sqlite3_step(statement) == SQLITE_ROW)
{
    values.medianAgePop = sqlite3_column_double(statement,0);
    values.homeOwnPct = 100.0 * sqlite3_column_double(statement,1);
    int hhTot = sqlite3_column_int(statement,2);
    int hh18 = sqlite3_column_int(statement,3);
    int hh65 = sqlite3_column_int(statement,4);
    if (hhTot > 0)
    {
        values.pctChildren = (100.0 * hh18)/hhTot;
        values.pctSenior   = (100.0 * hh65)/hhTot;
    }
}

SQLOK(__FILE__,__LINE__,SQLiteFinalize(statement), _propData.database);

    return rtn;
}
*/
@end

