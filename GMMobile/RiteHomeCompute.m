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

@implementation RiteHomeCompute

+(NSString *) parcelFieldList
{
    NSString * list = @"ACRES_POLY,USE1_DESC,SALE_DATE,EMV_TOTAL,TOTAL_TAX,HOMESTEAD,YEAR_BUILT,OPEN_SPACE";
    return list;
}

- (bool) computeParcelValues:(DATA_FROM_PARCELS *)values
                      totEMV:(int)totEMV
                     useDesc:(LPSTR) usedescIN
                   statement:(sqlite3_stmt*)statement
            PIDListStatement:(sqlite3_stmt*)statement_PidList;
{
    bool rtn = FALSE;
    int nHomestead=0;
    int totProp = 0;
    double sumEMV=0;
    double sumAcres=0;
    //double pctAveEMV;
    //double aveEMV;
    //double pctMedianEMV;
    int medianEMV=0;
    
    //double pctMedEMV;
    int myTotEMV = totEMV;
    int nAge = 0, nSales5yr = 0, nSales15yr = 0;
    int minSale = INT_MAX;
    CGFloat totYears = 0;
    //CGFloat medianAge = 0;
    CGFloat totAcres = 0, totOSAcres = 0;
    NSMutableArray * array=[[NSMutableArray alloc]init];
    NSMutableArray * ageArray=[[NSMutableArray alloc]init];

Top:
    while (sqlite3_step(statement) == SQLITE_ROW)
    {
        CGFloat acres = sqlite3_column_double(statement,0);
        LPSTR useDesc = (LPSTR)sqlite3_column_text(statement, 1);
        LPSTR saleDate = (LPSTR)sqlite3_column_text(statement, 2);
        int totEMV = (int)sqlite3_column_double(statement, 3);
        //double totTax = sqlite3_column_double(statement, 4);
        LPSTR homestead = (LPSTR)sqlite3_column_text(statement, 5);
        LPSTR yearBuilt = (LPSTR)sqlite3_column_text(statement, 6);
        LPSTR openSpace = (LPSTR)sqlite3_column_text(statement, 7);
        
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
            if (*saleDate)
            {
                int date = atoi (saleDate);
                minSale = min (minSale,date);
                date /= 10000;
                if (date >= 2010)
                    nSales5yr++;
                if (date >= 2005)
                    nSales15yr++;
            }
            if (yrBuilt > 1800)
            {
                totYears += yrBuilt;
                nAge++;
                NSNumber *age = [[NSNumber alloc]initWithInt:yrBuilt];
                [ageArray addObject:age];
            }
            if (totEMV > 0)
            {
                NSNumber * emv = [NSNumber numberWithInteger:totEMV];
                [array addObject:emv];
                sumAcres += acres;
                sumEMV += totEMV;
            }
        }
    }
    SQLOK(__FILE__,__LINE__,SQLiteFinalize(statement),_propData.database);
    if (statement_PidList)
    {
        if (sqlite3_step(statement_PidList) == SQLITE_ROW)
        {
            LPSTR pin = (LPSTR)sqlite3_column_text(statement_PidList,0);
            NSString *parcelFieldList = [RiteHomeCompute parcelFieldList];
            NSString *query = [NSString stringWithFormat:@"SELECT %@ FROM PROPINFO Where PIN = '%s'",parcelFieldList,pin];
            SQLOK(__FILE__,__LINE__,SQLitePrepare(_propData.database, query.UTF8String, -1, &statement, 0), _propData.database);
            goto Top;
        }
        else
            SQLOK(__FILE__,__LINE__,SQLiteFinalize(statement_PidList),_propData.database);
    }
    if (values.nMatchingProperties)
    {
        values.stability5yr  = IDNINT(100.0-(100.0 * nSales5yr) / values.nMatchingProperties);
        values.stability15yr = IDNINT(100.0-(100.0 * nSales15yr) / values.nMatchingProperties);
    }
    if (totProp)
    {
        values.pctHomestead  = IDNINT((100.0 * nHomestead) / totProp);
    }
    if (nAge)
    {
        //totYears /= nAge;
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
    
    [array sortUsingComparator: ^(id obj1, id obj2)
     {
         NSNumber *v1 = obj1;
         NSNumber *v2 = obj2;
         
         if (v1 > v2)
             return (NSComparisonResult)NSOrderedDescending;
         
         if (v1 < v2)
             return (NSComparisonResult)NSOrderedAscending;
         
         return (NSComparisonResult)NSOrderedSame;
     }];
    
    if ([array count])
    {
        int n=1;
        int myStartRank= -1;
        int myEndRank= -1;
        int medianN = (int)array.count / 2;
        int medianM = array.count % 2;
        //NSNumber *minEMV = array[0];
        //NSNumber *maxEMV = array[array.count - 1];
        for (NSNumber *EMVvalue in array)
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
        values.rankTotEMV = IDNINT((100.0 * (myStartRank + myEndRank)/2.0)/[array count]);
    }
    
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

