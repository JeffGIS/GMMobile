//
//  CrimeList.m
//  NVMobile
//
//  Created by Jeff Smith on 4/5/17.
//  Copyright © 2017 GSSi. All rights reserved.
//

#import "CrimeList.h"
#import "CCodeLibrary/SQLiteLib.h"
#import "CCodeLibrary/MathUtil.h"


//#define CURRENT_VERSION 28

@interface CrimeList ()

@property NSString *fileName, *path;
@property sqlite3 *database;
@property BOOL isOpen;
@property unsigned long long fileSize;
@property int dbIsOpen;
@end

@implementation CrimeList

- (void)logError:(int)sqlReturn
          method:(sqlite3*)database
{
    NSLog(@"%@", [NSString stringWithFormat:@"SQLite Error %i = %i:%s",
                  sqlReturn, sqlite3_errcode(database), sqlite3_errmsg(database)]);
}

NSString * GetCrimeListDirectory (void)
{
    NSString * documentsDirectory = CRAPI.sharedInstance.documentsDirectory;
    NSString * crimeListDir = [NSString stringWithFormat:@"%@/CrimeLists",documentsDirectory];
    [NSFileManager.defaultManager createDirectoryAtPath:crimeListDir
                            withIntermediateDirectories:YES
                                             attributes:nil
                                                  error:nil];
    
    return crimeListDir;
}

+ (NSArray *) getCrimeLists
{
    NSString *dir = GetCrimeListDirectory();
    NSMutableArray *array = [[NSMutableArray alloc]init];
    for (NSString *fileName in [NSFileManager.defaultManager contentsOfDirectoryAtPath:dir
                                                                                 error:nil])
    {
        NSString *leafName = textBefore (fileName.lastPathComponent,@".");
        [array addObject:leafName];
    }
    return array;
}

+ (NSString *) createNewCrimeList
{
    NSString *baseName = @"CrimeList";
    
    int n = 1;
    NSArray * lists = [CrimeList getCrimeLists];
    n = (int)lists.count + 1;
    NSString *newName = [NSString stringWithFormat:@"%@%i", baseName, n];
    
    while (nameInList (newName,lists))
    {
        n++;
        newName = [NSString stringWithFormat:@"%@%i", baseName, n];
    }
    
    [UserDefaults.defaults saveString:newName
                               forKey:@"CurrentCrimeList"];
    return newName;
}

+ (NSString*) getCurrentCrimeListName
{
    NSString *name = [UserDefaults.defaults stringForKey:@"CurrentCrimeList"];
    if (!name)
        name = [CrimeList createNewCrimeList];
    return name;
}

+ (BOOL) renameCurrentCrimeList:(NSString *)newName
{
    CrimeList *pl = [[CrimeList alloc]init];
    NSString *currentFile = pl.path;
    NSString *newFile = [NSString stringWithFormat:@"%@/%@.sqlite", pl.crimeListDir, newName];
    
    [pl close:YES];
    NSError * err = NULL;
    BOOL result = [NSFileManager.defaultManager  moveItemAtPath:currentFile
                                                         toPath:newFile
                                                          error:&err];
    if(!result)
    {
        NSLog(@"Error: %@", err);
        return FALSE;
    }
    [UserDefaults.defaults saveString:newName
                               forKey:@"CurrentCrimeList"];
    
    return TRUE;
}

+ (BOOL) deleteCurrentCrimeList
{
    
    CrimeList *pl = [[CrimeList alloc]init];
    NSString *currentFile = pl.path;
    NSError *error = nil;
    [pl close:YES];
    if (![NSFileManager.defaultManager removeItemAtPath:currentFile error:&error])
    {
        NSLog(@"%@ file removal error", currentFile);
        return FALSE;
    }
    NSArray *lists = [CrimeList getCrimeLists];
    if (lists.count)
        [UserDefaults.defaults saveString:lists[0]
                                   forKey:@"CurrentCrimeList"];
    else
        [UserDefaults.defaults saveString:@"CrimeList1"
                                   forKey:@"CurrentCrimeList"];
    
    return TRUE;
}

+ (BOOL) setCurrentCrimeList:(NSString *)crimeList
//returns false if crimelist does not exist
{
    BOOL rtn = NO;
    
    [UserDefaults.defaults saveString:crimeList
                               forKey:@"CurrentCrimeList"];
    
    return  rtn;
}
- (id)init
{
    self = [super init];
    
    if (self)
    {
        _crimeListDir = GetCrimeListDirectory ();
        _fileName = [CrimeList getCurrentCrimeListName];
        
        
        _path = [NSString stringWithFormat:@"%@/%@.sqlite", _crimeListDir, _fileName];
        
        //int version = [self datasetVersion];
        
        if (CRAPI.sharedInstance.resetCrimeList)
        {
            NSError *error = nil;
            
            [NSFileManager.defaultManager removeItemAtPath:_path
                                                     error:&error];
            
            if (error)
                NSLog(@"%@ file removal error", _fileName);
            
            CRAPI.sharedInstance.resetCrimeList = NO;
        }
        
        [self createTables];
        
    }
    NSLog(@"Init crimeerty list %@", _fileName);
    
    return self;
}

- (void)dealloc
{
    [self close:YES];
    NSLog(@"CrimeList Database dealloc");
}
- (BOOL)open
{
    BOOL rtn = NO;
    
    if (!_isOpen)
    {
        if (_dbIsOpen)
            NSLog(@"CrimeList already open");
        _dbIsOpen++;
        _fileName = [UserDefaults.defaults stringForKey:@"CurrentCrimeList"];
        _path = [NSString stringWithFormat:@"%@/%@.sqlite", _crimeListDir, _fileName];
        
        //        _isOpen = !SQLOK(0,sqlite3_open_v2(_path.UTF8String, &_database,SQLITE_OPEN_READWRITE|SQLITE_OPEN_CREATE|SQLITE_OPEN_NOMUTEX,NULL), _database);
        _isOpen = !SQLOK(0,sqlite3_open(_path.UTF8String, &_database), _database);
        NSLog(@"CrimeList Database open");
        _fileSize = [NSFileManager.defaultManager attributesOfItemAtPath:_path error:nil].fileSize;
        rtn = YES;
    }
    
    return rtn;
}

- (void)close:(BOOL)opened
{
    if (opened && _isOpen)
    {
        NSLog(@"CrimeList Database close");
        SQLOK(0,sqlite3_close(_database),_database);
        _isOpen = NO;
        _dbIsOpen--;
    }
}

- (BOOL) createTables
{
    BOOL opened = [self open];
    
    NSString *cmd =  @"CREATE TABLE IF NOT EXISTS CrimeList (id INTEGER PRIMARY KEY,ControlNum INTEGER,FieldType INTEGER,DataVersion INTEGER,FieldValue BLOB(33554432));\
    CREATE INDEX IF NOT EXISTS CrimeList_index ON CrimeList (ControlNum ASC);";
    BOOL rtn = !SQLOK(0,sqlite3_exec(_database, cmd.UTF8String, 0, 0, 0), _database);
    
    [self close:opened];
    return rtn;
}

- (BOOL)executeCmd:(char *)cmd
{
    BOOL rtn = !SQLOK(0,sqlite3_exec(_database, cmd, 0, 0, 0), _database);
    return rtn;
}

- (void)startTransaction
{
    SQLOK(0,sqlite3_exec(_database, "BEGIN", 0, 0, 0), _database);
}

- (void)commitTransaction
{
    SQLOK(0,sqlite3_exec(_database, "COMMIT", 0, 0, 0), _database);
}

- (NSArray*)availableCrimeFields
{
    NSMutableArray *fields = [[NSMutableArray alloc]init];
    for (int i = 1;i<CFT_END;i++)
    {
        NSNumber *field = [NSNumber numberWithInteger:i];
        [fields addObject:field];
    }
    return fields.copy;
}

- (NSString*) crimeFieldName:(CrimeFieldType)fieldType
{
    NSString *name = @"";
    
    switch(fieldType)
    {
        case CFT_LatLon:
        case CFT_END:
            break;
        case CFT_UCR:
            name = @"UCR";
            break;
        case CFT_CASENO:
            name = @"Case Number";
            break;
        case CFT_OFFENSECODE:
            name = @"Offense Code";
            break;
        default:
            break;
    }
    
    return name;
}

- (ValueTypes) getFieldValueType:(CrimeFieldType)type
{
    ValueTypes rtn = VTInteger;
    switch (type)
    {
        case CFT_LatLon:
            rtn = VTLLPoint;
            break;
        case CFT_CASENO:
        case CFT_OFFENSECODE:
        case CFT_Address:
            rtn = VTString;
            break;
        case CFT_HEIGHT:
            rtn = VTDouble;
            break;
        default:
            rtn = VTInteger;
            break;
    }
    return rtn;
}

- (NSArray*) getControlNumbers
{
    NSMutableArray * controlNums = [[NSMutableArray alloc]init];
    BOOL opened = [self open];
    NSString *query = [NSString stringWithFormat:@"SELECT DISTINCT ControlNum FROM CrimeList"];
    
    sqlite3_stmt *statement = NULL;
    
    SQLOK(0,sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement, 0), _database);
    
    while (sqlite3_step(statement) == SQLITE_ROW)
    {
        int controlid = sqlite3_column_int(statement, 0);
        NSNumber * controlNum = [NSNumber numberWithInt:controlid];
        [controlNums addObject:controlNum];
    }
    
    SQLOK(0,sqlite3_finalize(statement), _database);
    [self close:opened];
    return controlNums.copy;
}

+ (void) deleteControlNum:(NSInteger)controlNum
{
    
}

- (void) getCrimeFieldValueOfType:(CrimeFieldType)type
                   forControlNumber:(NSInteger)controlNum;
{
    NSString *value = @"";
    
    value = [self getFieldValue:controlNum type:type];
    
    if (value)
    {
        [self.delegate CrimeList:self
                       returnsValue:value
                  forControlNumber:controlNum
                       andFieldType:type
                         withStatus:0];
    }
    
    
    return;
}

- (NSString *) getFieldValue:(NSInteger)controlNum
                        type:(CrimeFieldType)fieldType
{
    NSString *value = @"";
    NSNumber *num;
    NSString *query = [NSString stringWithFormat:@"SELECT FieldValue FROM CrimeList WHERE ControlNum = %li AND FieldType = %li",
                       (long)controlNum, (long)fieldType];
    
    BOOL opened = [self open];
    
    sqlite3_stmt *statement = NULL;
    
    SQLOK(0,sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement, 0), _database);
    
    if (sqlite3_step(statement) == SQLITE_ROW)
    {
        LPSTR val;
        int ival;
        double dval;
        
        switch (fieldType)
        {
            case CFT_LatLon:
            {
                LLPOINT pt = *(LLPOINT*)sqlite3_column_blob(statement, 0);
                value = [NSString stringWithFormat:@"%f %f",pt.lat,pt.lon];
            }
                break;
            case CFT_Address:
                val = (LPSTR)sqlite3_column_blob(statement, 0);
                if (val)
                    value = [NSString stringWithFormat:@"%s",val];
                break;
            case CFT_HEIGHT:
                dval = *(double*)sqlite3_column_blob(statement, 0);
                num = [[NSNumber alloc] initWithDouble:dval];
                value = [CRAPI.sharedInstance.dollarFmt stringFromNumber:num];
                break;
            case CFT_SCORE:
                dval = *(double*)sqlite3_column_blob(statement, 0);
                num = [[NSNumber alloc] initWithDouble:dval];
                value = [CRAPI.sharedInstance.acreFmt stringFromNumber:num];
                break;
            default:
                ival = *(int*)sqlite3_column_blob(statement, 0);
                value = [NSString stringWithFormat:@"%i",ival];
                break;
        }
    }
    
    SQLOK(0,sqlite3_finalize(statement), _database);
    [self close:opened];
    
    return value;
}


- (int)nextCrimeNum
{
    int rtn = 1;
    
    NSString *query = [NSString stringWithFormat:@"SELECT max(CrimeNum) FROM CrimeList"];
    
    sqlite3_stmt *statement = NULL;
    
    SQLOK(0,sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement, 0), _database);
    
    if (sqlite3_step(statement) == SQLITE_ROW)
    {
        rtn = sqlite3_column_int(statement, 0) + 1;
    }
    
    SQLOK(0,sqlite3_finalize(statement), _database);
    
    return rtn;
}

- (int)next_id
{
    int rtn = 1;
    
    NSString *query = [NSString stringWithFormat:@"SELECT max(id) FROM CrimeList"];
    
    sqlite3_stmt *statement = NULL;
    
    SQLOK(0,sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement, 0), _database);
    
    if (sqlite3_step(statement) == SQLITE_ROW)
    {
        rtn = sqlite3_column_int(statement, 0) + 1;
    }
    
    SQLOK(0,sqlite3_finalize(statement), _database);
    
    return rtn;
}

-(NSString *) stringToBlob:(NSString*)str
{
    if (!str)
        str = @"";
    NSString * blob=@"";
    NSInteger sln = str.length;
    NSInteger lblb = 0;
    if (sln)
    {
        LPSTR blb = malloc (sln*2+4);
        LPSTR cstr = (LPSTR)str.UTF8String;
        for (NSInteger i = 0;i<sln;i++)
        {
            sprintf (&blb[lblb],"%2.2x",cstr[i]);
            lblb += 2;
        }
        blb[lblb] = 0;
        blob = [NSString stringWithUTF8String:blb];
        free (blb);
    }
    return blob;
}

-(NSString *) llpointsToBlob:(LLPOINT*)pPoints
                   numPoints:(NSInteger)nPnts
{
    NSString * blob=@"";
    NSInteger lBlob = 0;
    LPSTR pBlob = malloc(nPnts * sizeof(DPOINT)*2 +4);
    for (NSInteger i = 0; i < nPnts; i++)
    {
        NSInteger  j;
        LPBYTE pInts = (LPBYTE)&pPoints[i];
        //unsigned char c;
        for (j = 0; j < sizeof(DPOINT); j++, pInts++, lBlob += 2)
        {
            //c = *pInts;
            sprintf(&pBlob[lBlob], "%2.2x", *pInts);
        }
    }
    pBlob[lBlob] = 0;
    blob = [NSString stringWithUTF8String:pBlob];
    free (pBlob);
    return blob;
}
-(NSString *) doubleToBlob:(double)val
{
    NSString * blob=@"";
    NSInteger lBlob = 0;
    LPSTR pBlob = malloc(sizeof(double)*2+4);
    NSInteger  j;
    LPBYTE pInts = (LPBYTE)&val;
    //unsigned char c;
    for (j = 0; j < sizeof(double); j++, pInts++, lBlob += 2)
    {
        //c = *pInts;
        sprintf(&pBlob[lBlob], "%2.2x", *pInts);
    }
    pBlob[lBlob] = 0;
    blob = [NSString stringWithUTF8String:pBlob];
    free (pBlob);
    return blob;
}
-(NSString *) floatToBlob:(float)val
{
    NSString * blob=@"";
    NSInteger lBlob = 0;
    LPSTR pBlob = malloc(sizeof(float)*2+4);
    NSInteger  j;
    LPBYTE pInts = (LPBYTE)&val;
    //unsigned char c;
    for (j = 0; j < sizeof(float); j++, pInts++, lBlob += 2)
    {
        //c = *pInts;
        sprintf(&pBlob[lBlob], "%2.2x", *pInts);
    }
    pBlob[lBlob] = 0;
    blob = [NSString stringWithUTF8String:pBlob];
    free (pBlob);
    return blob;
}
-(NSString *) intToBlob:(int)val
{
    NSString * blob=@"";
    NSInteger lBlob = 0;
    LPSTR pBlob = malloc(sizeof(int)*2+4);
    NSInteger  j;
    LPBYTE pInts = (LPBYTE)&val;
    //unsigned char c;
    for (j = 0; j < sizeof(int); j++, pInts++, lBlob += 2)
    {
        //c = *pInts;
        sprintf(&pBlob[lBlob], "%2.2x", *pInts);
    }
    pBlob[lBlob] = 0;
    blob = [NSString stringWithUTF8String:pBlob];
    free (pBlob);
    return blob;
}

- (LLPOINT)getCrimeLatLon:(NSInteger)controlNum
{
    LLPOINT pt;
    BOOL opened = [self open];
    NSString * value = [self getFieldValue:controlNum
                                      type:CFT_LatLon];
    
    pt = LLPOINTFromString (value);
    [self close:opened];
    return pt;
}

- (void)setZoomValues:(NSInteger)controlNum forRow:(NSInteger)row
{
    BOOL opened = [self open];
/*    NSArray *fields = [self availablePropertyFields];
    NSNumber *field = fields[row];
    CrimeFieldType ifield = field.integerValue;
    NSString * PID = [self getFieldValue:propNum
                                    type:PFT_PIN];
    ConfigurationControl.sharedInstance.MapitPID = PID;
    ConfigurationControl.sharedInstance.currentPropSheetFieldType = ifield;
    ConfigurationControl.sharedInstance.MapitBoundaryOpt = [self getBoundaryTypeForField:ifield];
    NVMetroSettings.sharedInstance.currentFeatureSaved = [self setFeatureTypeForField:ifield];
    NVMetroSettings.sharedInstance.savedVisibleBounds = CRAPI.sharedInstance.lastViewBounds;
    if (ConfigurationControl.sharedInstance.MapitBoundaryOpt == MAPIT_CIRCULAR)
    {
        NSString * value = [self getFieldValue:propNum
                                          type:PFT_LatLon];
        ConfigurationControl.sharedInstance.MapitTargetCenterPoint = LLPOINTFromString (value);
        ConfigurationControl.sharedInstance.MapitCirularBoundaryRadiusInMiles = [CrimeList getRadiusForField:ifield];
    }
    else
    {
        NSString * cenBlock = [PropertyData getCensusBlockForPID:PID];
        NSString * type  = @"BLOCK";
        if (ConfigurationControl.sharedInstance.MapitBoundaryOpt == MAPIT_AREA_BLOCKGRP)
        {
            char blkGrp[20];
            strncpy (blkGrp,cenBlock.UTF8String,12);
            blkGrp[12] = 0;
            cenBlock = [NSString stringWithUTF8String:blkGrp];
            type = @"BLOCKGROUP";
        }
        ConfigurationControl.sharedInstance.MapitBoundaryRefno = [BoundaryData getBoundaryAreaRefnoForType:type andName:cenBlock];
        ConfigurationControl.sharedInstance.MapitBoundaryType = type;
    }
    */
    [self close:opened];
}

- (BOOL)addIncidentToCrimeList:(int)controlNum
{
    BOOL rtn = NO;
    BOOL opened = [self open];
    
    CrimeData *crimeData = [[CrimeData alloc] init];
/*    LLPOINT pidPoint = [propData getPointForPID:PID];
    
    //add address to Proplist
    NSString *houseAndUnit = @"";
    NSString *streetName = @"";
    NSString *city = @"";
    NSString *cenblock = @"";
    NSString *usedesc = @"";
    NSString *owner = @"";
    NSString *taxpayer = @"";
    double totEMV = 0;
    double landEMV = 0;
    double bldgEMV = 0;
    double totTax = 0;
    double specAssmt = 0;
    double acres = 0;
    
    [propData getAddressForPID:PID
               houseNumAndUnit:&houseAndUnit
                    streetName:&streetName
                          city:&city
                     ownerName:&owner
                  taxpayerName:&taxpayer
                   censusBlock:&cenblock
                       useDesc:&usedesc
                        totEMV:&totEMV
                       landEMV:&landEMV
                       bldgEMV:&bldgEMV
                        totTAX:&totTax
                       specAss:&specAssmt
                         acres:&acres];
    
    char cenBlock[20];
    strcpy (cenBlock, cenblock.UTF8String);
    cenBlock[12] = 0;
    DATA_FROM_TABLES values_blockgroup;
    
    [propData computeValuesFromTables:&values_blockgroup
                         inCensusArea:(LPSTR)cenBlock
                               totEMV:(int)totEMV
                              useDesc:(LPSTR)usedesc.UTF8String];
    
    DATA_FROM_TABLES values_block;
    
    [propData computeValuesFromTables:&values_block
                         inCensusArea:(LPSTR)cenblock.UTF8String
                               totEMV:(int)totEMV
                              useDesc:(LPSTR)usedesc.UTF8String];
    
    int dbid = [self next_id];
    int PropNum = [self nextPropNum];
    int propVersion = [propData propertyDatasetVersion];
    NSString *dataBlob;
    
    //add PID to Proplist
    NSString *PIDBlob = [self stringToBlob:PID];
    NSString *pointBlob = [self llpointsToBlob:&pidPoint
                                     numPoints:1];
    NSString * cmd = [NSString stringWithFormat:@"INSERT INTO CrimeList VALUES (%i,%i,%i,%i,X'%@');",dbid++,PropNum,(int)PFT_PIN,propVersion,PIDBlob];
    [self executeCmd:(LPSTR)cmd.UTF8String];
    cmd = [NSString stringWithFormat:@"INSERT INTO CrimeList VALUES (%i,%i,%i,%i,X'%@');",dbid++,PropNum,(int)PFT_UserID,propVersion,PIDBlob];
    [self executeCmd:(LPSTR)cmd.UTF8String];
    
    //add LatLon to Proplist
    cmd = [NSString stringWithFormat:@"INSERT INTO CrimeList VALUES (%i,%i,%i,%i,X'%@');",dbid++,PropNum,(int)PFT_LatLon,propVersion,pointBlob];
    [self executeCmd:(LPSTR)cmd.UTF8String];
    
    NSString *address = [NSString stringWithFormat:@"%@ %@\n%@",houseAndUnit,streetName,city];
    NSString *addressBlob = [self stringToBlob:address];
    cmd = [NSString stringWithFormat:@"INSERT INTO CrimeList VALUES (%i,%i,%i,%i,X'%@');",dbid++,PropNum,(int)PFT_Address,propVersion,addressBlob];
    [self executeCmd:(LPSTR)cmd.UTF8String];
    
    dataBlob = [self doubleToBlob:totEMV];
    cmd = [NSString stringWithFormat:@"INSERT INTO CrimeList VALUES (%i,%i,%i,%i,X'%@');",dbid++,PropNum,(int)PFT_EMV_TOTAL,propVersion,dataBlob];
    [self executeCmd:(LPSTR)cmd.UTF8String];
    dataBlob = [self doubleToBlob:landEMV];
    cmd = [NSString stringWithFormat:@"INSERT INTO CrimeList VALUES (%i,%i,%i,%i,X'%@');",dbid++,PropNum,(int)PFT_EMV_LAND,propVersion,dataBlob];
    [self executeCmd:(LPSTR)cmd.UTF8String];
    dataBlob = [self doubleToBlob:bldgEMV];
    cmd = [NSString stringWithFormat:@"INSERT INTO CrimeList VALUES (%i,%i,%i,%i,X'%@');",dbid++,PropNum,(int)PFT_EMV_BUILDING,propVersion,dataBlob];
    [self executeCmd:(LPSTR)cmd.UTF8String];
    dataBlob = [self doubleToBlob:totTax];
    cmd = [NSString stringWithFormat:@"INSERT INTO CrimeList VALUES (%i,%i,%i,%i,X'%@');",dbid++,PropNum,(int)PFT_TOTAL_TAX,propVersion,dataBlob];
    [self executeCmd:(LPSTR)cmd.UTF8String];
    dataBlob = [self doubleToBlob:specAssmt];
    cmd = [NSString stringWithFormat:@"INSERT INTO CrimeList VALUES (%i,%i,%i,%i,X'%@');",dbid++,PropNum,(int)PFT_SPEC_ASSESSMENT,propVersion,dataBlob];
    [self executeCmd:(LPSTR)cmd.UTF8String];
    dataBlob = [self doubleToBlob:acres];
    cmd = [NSString stringWithFormat:@"INSERT INTO CrimeList VALUES (%i,%i,%i,%i,X'%@');",dbid++,PropNum,(int)PFT_ACRES,propVersion,dataBlob];
    [self executeCmd:(LPSTR)cmd.UTF8String];
    if (acres > 0)
    {
        double landPerAcre = landEMV/acres;
        dataBlob = [self doubleToBlob:landPerAcre];
        cmd = [NSString stringWithFormat:@"INSERT INTO CrimeList VALUES (%i,%i,%i,%i,X'%@');",dbid++,PropNum,(int)PFT_EMV_LAND_PER_ACRE,propVersion,dataBlob];
        [self executeCmd:(LPSTR)cmd.UTF8String];
    }
    dataBlob = [self stringToBlob:owner];
    cmd = [NSString stringWithFormat:@"INSERT INTO CrimeList VALUES (%i,%i,%i,%i,X'%@');",dbid++,PropNum,(int)PFT_Owner,propVersion,dataBlob];
    [self executeCmd:(LPSTR)cmd.UTF8String];
    dataBlob = [self stringToBlob:taxpayer];
    cmd = [NSString stringWithFormat:@"INSERT INTO CrimeList VALUES (%i,%i,%i,%i,X'%@');",dbid++,PropNum,(int)PFT_TaxPayer,propVersion,dataBlob];
    [self executeCmd:(LPSTR)cmd.UTF8String];
    //add values from tables to Proplist
    dataBlob = [self intToBlob:values_block.rankTotEMV];
    cmd = [NSString stringWithFormat:@"INSERT INTO CrimeList VALUES (%i,%i,%i,%i,X'%@');",dbid++,PropNum,(int)PFT_RankEMV_block,propVersion,dataBlob];
    [self executeCmd:(LPSTR)cmd.UTF8String];
    dataBlob = [self intToBlob:values_block.pctHomestead];
    cmd = [NSString stringWithFormat:@"INSERT INTO CrimeList VALUES (%i,%i,%i,%i,X'%@');",dbid++,PropNum,(int)PFT_PctHomestead_block,propVersion,dataBlob];
    [self executeCmd:(LPSTR)cmd.UTF8String];
    dataBlob = [self intToBlob:values_block.homeOwnPct];
    cmd = [NSString stringWithFormat:@"INSERT INTO CrimeList VALUES (%i,%i,%i,%i,X'%@');",dbid++,PropNum,(int)PFT_PctHomeOwn_block,propVersion,dataBlob];
    [self executeCmd:(LPSTR)cmd.UTF8String];
    dataBlob = [self intToBlob:values_block.medianBuiltYear];
    cmd = [NSString stringWithFormat:@"INSERT INTO CrimeList VALUES (%i,%i,%i,%i,X'%@');",dbid++,PropNum,(int)PFT_MedianBuiltYear_block,propVersion,dataBlob];
    [self executeCmd:(LPSTR)cmd.UTF8String];
    dataBlob = [self intToBlob:values_block.medianAgePop];
    cmd = [NSString stringWithFormat:@"INSERT INTO CrimeList VALUES (%i,%i,%i,%i,X'%@');",dbid++,PropNum,(int)PFT_MedianAgePop_block,propVersion,dataBlob];
    [self executeCmd:(LPSTR)cmd.UTF8String];
    dataBlob = [self intToBlob:values_block.pctChildren];
    cmd = [NSString stringWithFormat:@"INSERT INTO CrimeList VALUES (%i,%i,%i,%i,X'%@');",dbid++,PropNum,(int)PFT_PctChildren_block,propVersion,dataBlob];
    [self executeCmd:(LPSTR)cmd.UTF8String];
    dataBlob = [self intToBlob:values_block.pctSenior];
    cmd = [NSString stringWithFormat:@"INSERT INTO CrimeList VALUES (%i,%i,%i,%i,X'%@');",dbid++,PropNum,(int)PFT_PctSenior_block,propVersion,dataBlob];
    [self executeCmd:(LPSTR)cmd.UTF8String];
    
    dataBlob = [self intToBlob:values_block.stability5yr];
    cmd = [NSString stringWithFormat:@"INSERT INTO CrimeList VALUES (%i,%i,%i,%i,X'%@');",dbid++,PropNum,(int)PFT_Stability5yr_block,propVersion,dataBlob];
    [self executeCmd:(LPSTR)cmd.UTF8String];
    dataBlob = [self intToBlob:values_block.stability15yr];
    cmd = [NSString stringWithFormat:@"INSERT INTO CrimeList VALUES (%i,%i,%i,%i,X'%@');",dbid++,PropNum,(int)PFT_Stability15yr_block,propVersion,dataBlob];
    [self executeCmd:(LPSTR)cmd.UTF8String];
    
    dataBlob = [self intToBlob:values_blockgroup.rankTotEMV];
    cmd = [NSString stringWithFormat:@"INSERT INTO CrimeList VALUES (%i,%i,%i,%i,X'%@');",dbid++,PropNum,(int)PFT_RankEMV_blockgroup,propVersion,dataBlob];
    [self executeCmd:(LPSTR)cmd.UTF8String];
    dataBlob = [self intToBlob:values_blockgroup.pctHomestead];
    cmd = [NSString stringWithFormat:@"INSERT INTO CrimeList VALUES (%i,%i,%i,%i,X'%@');",dbid++,PropNum,(int)PFT_PctHomestead_blockgroup,propVersion,dataBlob];
    [self executeCmd:(LPSTR)cmd.UTF8String];
    dataBlob = [self intToBlob:values_blockgroup.homeOwnPct];
    cmd = [NSString stringWithFormat:@"INSERT INTO CrimeList VALUES (%i,%i,%i,%i,X'%@');",dbid++,PropNum,(int)PFT_PctHomeOwn_blockgroup,propVersion,dataBlob];
    [self executeCmd:(LPSTR)cmd.UTF8String];
    dataBlob = [self intToBlob:values_blockgroup.medianBuiltYear];
    cmd = [NSString stringWithFormat:@"INSERT INTO CrimeList VALUES (%i,%i,%i,%i,X'%@');",dbid++,PropNum,(int)PFT_MedianBuiltYear_blockgroup,propVersion,dataBlob];
    [self executeCmd:(LPSTR)cmd.UTF8String];
    dataBlob = [self intToBlob:values_blockgroup.medianAgePop];
    cmd = [NSString stringWithFormat:@"INSERT INTO CrimeList VALUES (%i,%i,%i,%i,X'%@');",dbid++,PropNum,(int)PFT_MedianAgePop_blockgroup,propVersion,dataBlob];
    [self executeCmd:(LPSTR)cmd.UTF8String];
    dataBlob = [self intToBlob:values_blockgroup.pctChildren];
    cmd = [NSString stringWithFormat:@"INSERT INTO CrimeList VALUES (%i,%i,%i,%i,X'%@');",dbid++,PropNum,(int)PFT_PctChildren_blockgroup,propVersion,dataBlob];
    [self executeCmd:(LPSTR)cmd.UTF8String];
    dataBlob = [self intToBlob:values_blockgroup.pctSenior];
    cmd = [NSString stringWithFormat:@"INSERT INTO CrimeList VALUES (%i,%i,%i,%i,X'%@');",dbid++,PropNum,(int)PFT_PctSenior_blockgroup,propVersion,dataBlob];
    [self executeCmd:(LPSTR)cmd.UTF8String];
    dataBlob = [self intToBlob:values_blockgroup.stability5yr];
    cmd = [NSString stringWithFormat:@"INSERT INTO CrimeList VALUES (%i,%i,%i,%i,X'%@');",dbid++,PropNum,(int)PFT_Stability5yr_blockgroup,propVersion,dataBlob];
    [self executeCmd:(LPSTR)cmd.UTF8String];
    dataBlob = [self intToBlob:values_blockgroup.stability15yr];
    cmd = [NSString stringWithFormat:@"INSERT INTO CrimeList VALUES (%i,%i,%i,%i,X'%@');",dbid++,PropNum,(int)PFT_Stability15yr_blockgroup,propVersion,dataBlob];
    [self executeCmd:(LPSTR)cmd.UTF8String];
    rtn = YES;
    */
    [self close:opened];
    return rtn;
}

- (void) GSSiPopoverViewdidCancel:(GSSiPopoverView *)popoverView
{
    
}


@end

NSString* CrimeListFieldDescription (NSInteger fieldNumber)
{
    NSString *file;
    
    NSString *name = [NSString stringWithFormat:@"CrimeListField_%li",(long)fieldNumber];
    file = [NSBundle.mainBundle pathForResource:name ofType:@"pdf"];
    
    if (![NSFileManager.defaultManager fileExistsAtPath:file])
        file = [NSBundle.mainBundle pathForResource:@"CrimeListField_default" ofType:@"pdf"];
    return file;
}

