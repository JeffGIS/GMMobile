//  PropertyList.m
//  GMMobile

#import "PropertyList.h"
#import "PropertyData.h"
#import "Destinations.h"
#import "ConfigurationControl.h"

//#define CURRENT_VERSION 28

@interface PropertyList ()

@property NSString *documentsDirectory, *fileName, *path;
@property sqlite3 *database;
@property BOOL isOpen;
@property unsigned long long fileSize;

@end

@implementation PropertyList

int SQLOKpl(int sqlReturn, sqlite3 *database)
{
    if (sqlReturn != SQLITE_OK)
    {
        //[self logError:sqlReturn
        //             method:database];
        NSLog(@"%@", [NSString stringWithFormat:@"SQLite Error in PropertyList %i = %i:%s",
                      sqlReturn, sqlite3_errcode(database), sqlite3_errmsg(database)]);
    }
    
    return sqlReturn;
}

- (void)logError:(int)sqlReturn
          method:(sqlite3*)database
{
    NSLog(@"%@", [NSString stringWithFormat:@"SQLite Error %i = %i:%s",
                  sqlReturn, sqlite3_errcode(database), sqlite3_errmsg(database)]);
}

- (id)init
{
    self = [super init];
    
    if (self)
    {
        _documentsDirectory = UserDefaults.defaults.sharedFilePath;
        _fileName = @"DefaultPropList.sqlite";
        _path = [NSString stringWithFormat:@"%@/%@", _documentsDirectory, _fileName];
        
        //int version = [self datasetVersion];
        
        if (CRAPI.sharedInstance.resetPropList)
        {
            NSError *error = nil;
            
            [NSFileManager.defaultManager removeItemAtPath:_path
                                                     error:&error];
            
            if (error)
                NSLog(@"%@ file removal error", _fileName);
            
            CRAPI.sharedInstance.resetPropList = NO;
        }

        [self createTables];
    }
    
    return self;
}

- (void)dealloc
{
    sqlite3_close(_database);
    NSLog(@"PropertyList Database dealloc");
}
- (BOOL)open
{
    BOOL rtn = NO;
    if (!_isOpen)
    {
        _isOpen = YES;
        _isOpen = !SQLOKpl(sqlite3_open(_path.UTF8String, &_database), _database);
        NSLog(@"PropertyList Database open");
        
        _fileSize = [NSFileManager.defaultManager attributesOfItemAtPath:_path
                                                                   error:nil].fileSize;
        rtn = YES;
    }
    return rtn;
}

- (void)close:(BOOL)opened
{
    if (opened)
    {
        SQLOKpl(sqlite3_close(_database),_database);
        NSLog(@"PropertyList Database close");
        _isOpen = NO;
    }
}

- (void)clear
{
    //[self close];
    
    //BOOL st = [NSFileManager.defaultManager removeItemAtPath:_path
    //error:nil];
}
- (BOOL) createTables
{
    BOOL opened = [self open];
    
    NSString *cmd =  @"CREATE TABLE IF NOT EXISTS PropertyList (id INTEGER PRIMARY KEY,PropNum INTEGER,FieldType INTEGER,FieldValue BLOB(33554432));\
                        CREATE INDEX IF NOT EXISTS PropertyList_index ON PropertyList (PropNum ASC);";
   // NSString *cmd2 = @"CREATE TABLE IF NOT EXISTS DestinationList (id INTEGER PRIMARY KEY,FieldName CHAR(100),FieldValue BLOB(33554432))";
    
    BOOL rtn = !SQLOKpl(sqlite3_exec(_database, cmd.UTF8String, 0, 0, 0), _database);
    
    /*cmd = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS PropertyList_VERSION (id INT,Version INT);INSERT INTO PropertyList_VERSION VALUES (1,%i);",CURRENT_VERSION];
    SQLOKpl(sqlite3_exec(_database, cmd.UTF8String, 0, 0, 0), _database);*/
    
    [self close:opened];
    return rtn;
}

/*
- (int)datasetVersion
{
    int rtn = -1;
    BOOL opened = [self open];
    
    if (_isOpen && _fileSize > 0)
    {
        NSString *query = [NSString stringWithFormat:@"SELECT Version FROM PropertyList_VERSION"];
        
        sqlite3_stmt *statement = NULL;
        
        SQLOKpl(sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement, 0), _database);
        
        if (sqlite3_step(statement) == SQLITE_ROW)
        {
            rtn = sqlite3_column_int(statement, 0);
        }
        
        SQLOKpl(sqlite3_finalize(statement), _database);
    }
    
    [self close:opened];
    return rtn;
}
*/

- (BOOL)executeCmd:(char *)cmd
{
    BOOL rtn = !SQLOKpl(sqlite3_exec(_database, cmd, 0, 0, 0), _database);
    return rtn;
}

- (void)startTransaction
{
    SQLOKpl(sqlite3_exec(_database, "BEGIN", 0, 0, 0), _database);
}

- (void)commitTransaction
{
    SQLOKpl(sqlite3_exec(_database, "COMMIT", 0, 0, 0), _database);
}

- (NSArray*)availablePropertyFields
{
    NSMutableArray *fields = [[NSMutableArray alloc]init];
    for (int i = 1;i<PFT_END;i++)
    {
        NSNumber *field = [NSNumber numberWithInteger:i];
        [fields addObject:field];
    }
    return fields.copy;
}

- (NSString*) propertyFieldName:(PropFieldType)fieldType
{
    NSString *name = @"";
    
    switch(fieldType)
    {
        case PFT_LatLon:
        case PFT_END:
            break;
        case PFT_UserID:
            name = @"Name";
            break;
        case PFT_PIN:
            name = @"Unique Parcel ID (PIN)";
            break;
        case PFT_Address:
            name = @"Address";
            break;
        case PFT_RankEMV_block:
            name = @"EMV Rank (Block)";
            break;
        case PFT_RankEMV_blockgroup:
            name = @"EMV Rank (Block Group)";
            break;
        case PFT_PctOpenSpace_halfMile:
            name = @"PCT Open space (Half Mile)";
            break;
        case PFT_PctOpenSpace_Mile:
            name = @"PCT Open space (Mile)";
            break;
        case PFT_PctIndustrial_halfMile:
            name = @"PCT Industrial (Half Mile)";
            break;
        case PFT_PctIndustrial_Mile:
            name = @"PCT Industrial (Mile)";
            break;
        case PFT_Stability5yr_block:
            name = @"Stability (5 year Block)";
            break;
        case PFT_Stability5yr_blockgroup:
            name = @"Stability (5 year Block Group)";
            break;
        case PFT_Stability15yr_block:
            name = @"Stability (15 year Block)";
            break;
        case PFT_Stability15yr_blockgroup:
            name = @"Stability (15 year Block Group)";
            break;
        case PFT_Stability_halfMile:
            name = @"Stability (5 year Half Mile)";
            break;
        case PFT_DistanceToDestinations:
            name = @"Distance to Destinations (Miles per Month)";
            break;
        case PFT_TimeToDestinations:
            name = @"Time to Destinations (Hours per Month)";
            break;
        case PFT_PctHomestead_block:
            name = @"PCT Homestead (Block)";
            break;
        case PFT_PctHomestead_blockgroup:
            name = @"PCT Homestead (Block Group)";
            break;
        case PFT_PctHomeOwn_block:
            name = @"PCT Home Ownership (Block)";
            break;
        case PFT_PctHomeOwn_blockgroup:
            name = @"PCT Home Ownership (Block Group)";
            break;
        case PFT_MedianAgePop_block:
            name = @"Median Age Population (Block)";
            break;
        case PFT_MedianAgePop_blockgroup:
            name = @"Median Age Population (Block Group)";
            break;
        case PFT_MedianBuiltYear_block:
            name = @"Median Year Built (Block)";
            break;
        case PFT_MedianBuiltYear_blockgroup:
            name = @"Median Year Built (Block Group)";
            break;
        case PFT_PctChildren_block:
            name = @"PCT Children (Block)";
            break;
        case PFT_PctChildren_blockgroup:
            name = @"PCT Children (Block Group)";
            break;
        case PFT_MedianAgeChildren_block:
            name = @"Median Child Age (Block)";
            break;
        case PFT_MedianAgeChildren_blockgroup:
            name = @"Median Child Age (Block Group)";
            break;
        case PFT_MedianAgeAdults_block:
            name = @"Median Adult Age (Block)";
            break;
        case PFT_MedianAgeAdults_blockgroup:
            name = @"Median Adult Age (Block Group)";
            break;
        case PFT_PctSenior_block:
            name = @"PCT Seniors (Block)";
            break;
        case PFT_PctSenior_blockgroup:
            name = @"PCT Seniors (Block Group)";
            break;
        
            
    }
    
    return name;
}

- (int)getBoundaryTypeForField:(PropFieldType) field
{
    int type = MAPIT_CIRCULAR;
    
    return type;
}

- (NSArray*) getPropertyNumbers
{
    NSMutableArray * propNums = [[NSMutableArray alloc]init];
    BOOL opened = [self open];
    NSString *query = [NSString stringWithFormat:@"SELECT DISTINCT PropNum FROM PropertyList"];
    
    sqlite3_stmt *statement = NULL;
    
    SQLOK(sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement, 0), _database);
    
    while (sqlite3_step(statement) == SQLITE_ROW)
    {
        int propid = sqlite3_column_int(statement, 0);
        NSNumber * propNum = [NSNumber numberWithInt:propid];
        [propNums addObject:propNum];
    }
    
    SQLOK(sqlite3_finalize(statement), _database);
    [self close:opened];
    return propNums.copy;
}
- (void) getPropertyFieldValueOfType:(PropFieldType)type
                   forPropertyNumber:(NSInteger)propNum;
{
    NSString * value = nil;
    
    if (type == PFT_TimeToDestinations)
    {
        Destinations *dest = [[Destinations alloc]init];
        
        CGFloat val = [dest totalValueForProperty:propNum ofType:type];
        value = [NSString stringWithFormat:@"%.1f",val/60.0];
    }
    else if (type == PFT_DistanceToDestinations)
    {
        Destinations *dest = [[Destinations alloc]init];
        
        CGFloat val = [dest totalValueForProperty:propNum ofType:type];
        value = [NSString stringWithFormat:@"%.1f",val];
    }
    else
        value = [self getFieldValue:propNum
                                      type:type];
    
    if (value)
    {
        [self.delegate PropertyList:self
                       returnsValue:value
                  forPropertyNumber:propNum
                       andFieldType:type
                         withStatus:0];
    }
    else
    {
        switch (type)
        {
            case PFT_PctOpenSpace_halfMile:
                break;
            default:
                break;
        }
    }
    return;
}

- (NSString *) getFieldValue:(NSInteger)propNum
                        type:(PropFieldType)fieldType
{
    NSString *value = nil;
    
    NSString *query = [NSString stringWithFormat:@"SELECT FieldValue FROM PropertyList WHERE PropNum = %li AND FieldType = %li",
                       (long)propNum, (long)fieldType];
    
    BOOL opened = [self open];
    
    sqlite3_stmt *statement = NULL;
    
    SQLOK(sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement, 0), _database);
    
    if (sqlite3_step(statement) == SQLITE_ROW)
    {
        LPSTR val;
        int ival;
        
        switch (fieldType)
        {
            case PFT_LatLon:
            {
                LLPOINT pt = *(LLPOINT*)sqlite3_column_blob(statement, 0);
                value = [NSString stringWithFormat:@"%f %f",pt.lat,pt.lon];
            }
                break;
            case PFT_UserID:
            case PFT_PIN:
            case PFT_Address:
                val = (LPSTR)sqlite3_column_blob(statement, 0);
                value = [NSString stringWithUTF8String:val];
                break;
            default:
                ival = *(int*)sqlite3_column_blob(statement, 0);
                value = [NSString stringWithFormat:@"%i",ival];
                break;
        }
    }
    
    SQLOK(sqlite3_finalize(statement), _database);
    [self close:opened];
    
    return value;
}

- (int)nextPropNum
{
    int rtn = 1;
    
    NSString *query = [NSString stringWithFormat:@"SELECT max(PropNum) FROM PropertyList"];
    
    sqlite3_stmt *statement = NULL;
    
    SQLOK(sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement, 0), _database);
    
    if (sqlite3_step(statement) == SQLITE_ROW)
    {
        rtn = sqlite3_column_int(statement, 0) + 1;
    }
    
    SQLOK(sqlite3_finalize(statement), _database);
    
    return rtn;
}

- (int)next_id
{
    int rtn = 1;
    
    NSString *query = [NSString stringWithFormat:@"SELECT max(id) FROM PropertyList"];
    
    sqlite3_stmt *statement = NULL;
    
    SQLOK(sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement, 0), _database);
    
    if (sqlite3_step(statement) == SQLITE_ROW)
    {
        rtn = sqlite3_column_int(statement, 0) + 1;
    }
    
    SQLOK(sqlite3_finalize(statement), _database);
    
    return rtn;
}

-(NSString *) stringToBlob:(NSString*)str
{
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

- (void)updatePropertyUserID:(NSInteger)propNum
                      userID:(NSString*)userID
{
    NSLog(@"%li, %@", (long)propNum, userID);
    
    BOOL opened = [self open];
    
    NSString *PIDBlob = [self stringToBlob:userID];
    NSString * cmd = [NSString stringWithFormat:@"UPDATE PropertyList SET FieldValue = X'%@' WHERE PropNum = %li AND FieldType = %li",
                      PIDBlob,(long)propNum, (long)PFT_UserID];
    [self executeCmd:(LPSTR)cmd.UTF8String];
    [self close:opened];
}
LLPOINT LLPOINTFromString (NSString* string)
{
    if (!string)
        string = @"";
    
    LLPOINT pt;
    LPSTR str = malloc (string.length+4);
    strcpy (str,string.UTF8String);
    LPSTR space = strchr (str,' ');
    if (space)
        *space++ = 0;
    else
        space = str;
    pt.lat = atof (str);
    pt.lon = atof (space);
    free (str);
    return pt;
}
- (LLPOINT)getPropertyLatLon:(NSInteger)propNum
{
    LLPOINT pt;
    BOOL opened = [self open];
    NSString * value = [self getFieldValue:propNum
                                      type:PFT_LatLon];
    
    pt = LLPOINTFromString (value);
    [self close:opened];
    return pt;
}

- (void)setZoomValues:(NSInteger)propNum forRow:(NSInteger)row
{
    LLPOINT pt;
    BOOL opened = [self open];
    NSArray *fields = [self availablePropertyFields];
    NSNumber *field = fields[row];
    PropFieldType ifield = field.integerValue;
    NSString * PID = [self getFieldValue:propNum
                                      type:PFT_PIN];

    ConfigurationControl.sharedInstance.MapitBoundaryOpt = [self getBoundaryTypeForField:ifield];
    if (ConfigurationControl.sharedInstance.MapitBoundaryOpt == MAPIT_CIRCULAR)
    {
        NSString * value = [self getFieldValue:propNum
                                          type:PFT_LatLon];
        pt = LLPOINTFromString (value);
       
    }
    else
    {
        NSString * cenBlock = [PropertyData getCensusBlockForPID:PID];
        ConfigurationControl.sharedInstance.MapitBoundaryRefno = 0;
    }

     [self close:opened];
}

- (BOOL)addParcelToPropertyList:(NSString *)PID
{
    BOOL rtn = NO;
    
    PropertyData *propData = [[PropertyData alloc] init];
    LLPOINT pidPoint = [propData getPointForPID:PID];
    
    //add address to Proplist
    NSString * houseAndUnit=@"";
    NSString * streetName=@"";
    NSString * city=@"";
    NSString * cenblock=@"";
    NSString * usedesc=@"";
    CGFloat totEMV=0;
    [propData getAddressForPID:PID
               houseNumAndUnit:&houseAndUnit
                    streetName:&streetName
                          city:&city
                   censusBlock:&cenblock
                       useDesc:&usedesc
                        totEMV:&totEMV];
    
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
    
    BOOL opened = [self open];
    int dbid = [self next_id];
    int PropNum = [self nextPropNum];

    //add PID to Proplist
    NSString *PIDBlob = [self stringToBlob:PID];
    NSString *pointBlob = [self llpointsToBlob:&pidPoint
                                    numPoints:1];
    NSString * cmd = [NSString stringWithFormat:@"INSERT INTO PropertyList VALUES (%i,%i,%i,X'%@');",dbid++,PropNum,(int)PFT_PIN,PIDBlob];
    [self executeCmd:(LPSTR)cmd.UTF8String];
    cmd = [NSString stringWithFormat:@"INSERT INTO PropertyList VALUES (%i,%i,%i,X'%@');",dbid++,PropNum,(int)PFT_UserID,PIDBlob];
    [self executeCmd:(LPSTR)cmd.UTF8String];

    //add LatLon to Proplist
    cmd = [NSString stringWithFormat:@"INSERT INTO PropertyList VALUES (%i,%i,%i,X'%@');",dbid++,PropNum,(int)PFT_LatLon,pointBlob];
    [self executeCmd:(LPSTR)cmd.UTF8String];

    NSString *address = [NSString stringWithFormat:@"%@ %@\n%@",houseAndUnit,streetName,city];
    NSString *addressBlob = [self stringToBlob:address];
    cmd = [NSString stringWithFormat:@"INSERT INTO PropertyList VALUES (%i,%i,%i,X'%@');",dbid++,PropNum,(int)PFT_Address,addressBlob];
    [self executeCmd:(LPSTR)cmd.UTF8String];

    //add values from tables to Proplist
    NSString *dataBlob = [self intToBlob:values_block.rankTotEMV];
    cmd = [NSString stringWithFormat:@"INSERT INTO PropertyList VALUES (%i,%i,%i,X'%@');",dbid++,PropNum,(int)PFT_RankEMV_block,dataBlob];
    [self executeCmd:(LPSTR)cmd.UTF8String];
    dataBlob = [self intToBlob:values_block.pctHomestead];
    cmd = [NSString stringWithFormat:@"INSERT INTO PropertyList VALUES (%i,%i,%i,X'%@');",dbid++,PropNum,(int)PFT_PctHomestead_block,dataBlob];
    [self executeCmd:(LPSTR)cmd.UTF8String];
    dataBlob = [self intToBlob:values_block.homeOwnPct];
    cmd = [NSString stringWithFormat:@"INSERT INTO PropertyList VALUES (%i,%i,%i,X'%@');",dbid++,PropNum,(int)PFT_PctHomeOwn_block,dataBlob];
    [self executeCmd:(LPSTR)cmd.UTF8String];
    dataBlob = [self intToBlob:values_block.medianBuiltYear];
    cmd = [NSString stringWithFormat:@"INSERT INTO PropertyList VALUES (%i,%i,%i,X'%@');",dbid++,PropNum,(int)PFT_MedianBuiltYear_block,dataBlob];
    [self executeCmd:(LPSTR)cmd.UTF8String];
    dataBlob = [self intToBlob:values_block.medianAgePop];
    cmd = [NSString stringWithFormat:@"INSERT INTO PropertyList VALUES (%i,%i,%i,X'%@');",dbid++,PropNum,(int)PFT_MedianAgePop_block,dataBlob];
    [self executeCmd:(LPSTR)cmd.UTF8String];
    dataBlob = [self intToBlob:values_block.pctChildren];
    cmd = [NSString stringWithFormat:@"INSERT INTO PropertyList VALUES (%i,%i,%i,X'%@');",dbid++,PropNum,(int)PFT_PctChildren_block,dataBlob];
    [self executeCmd:(LPSTR)cmd.UTF8String];
    dataBlob = [self intToBlob:values_block.pctSenior];
    cmd = [NSString stringWithFormat:@"INSERT INTO PropertyList VALUES (%i,%i,%i,X'%@');",dbid++,PropNum,(int)PFT_PctSenior_block,dataBlob];
    [self executeCmd:(LPSTR)cmd.UTF8String];

    dataBlob = [self intToBlob:values_block.stability5yr];
    cmd = [NSString stringWithFormat:@"INSERT INTO PropertyList VALUES (%i,%i,%i,X'%@');",dbid++,PropNum,(int)PFT_Stability5yr_block,dataBlob];
    [self executeCmd:(LPSTR)cmd.UTF8String];
    dataBlob = [self intToBlob:values_block.stability15yr];
    cmd = [NSString stringWithFormat:@"INSERT INTO PropertyList VALUES (%i,%i,%i,X'%@');",dbid++,PropNum,(int)PFT_Stability15yr_block,dataBlob];
    [self executeCmd:(LPSTR)cmd.UTF8String];
    
    dataBlob = [self intToBlob:values_blockgroup.rankTotEMV];
    cmd = [NSString stringWithFormat:@"INSERT INTO PropertyList VALUES (%i,%i,%i,X'%@');",dbid++,PropNum,(int)PFT_RankEMV_blockgroup,dataBlob];
    [self executeCmd:(LPSTR)cmd.UTF8String];
    dataBlob = [self intToBlob:values_blockgroup.pctHomestead];
    cmd = [NSString stringWithFormat:@"INSERT INTO PropertyList VALUES (%i,%i,%i,X'%@');",dbid++,PropNum,(int)PFT_PctHomestead_blockgroup,dataBlob];
    [self executeCmd:(LPSTR)cmd.UTF8String];
    dataBlob = [self intToBlob:values_blockgroup.homeOwnPct];
    cmd = [NSString stringWithFormat:@"INSERT INTO PropertyList VALUES (%i,%i,%i,X'%@');",dbid++,PropNum,(int)PFT_PctHomeOwn_blockgroup,dataBlob];
    [self executeCmd:(LPSTR)cmd.UTF8String];
    dataBlob = [self intToBlob:values_blockgroup.medianBuiltYear];
    cmd = [NSString stringWithFormat:@"INSERT INTO PropertyList VALUES (%i,%i,%i,X'%@');",dbid++,PropNum,(int)PFT_MedianBuiltYear_blockgroup,dataBlob];
    [self executeCmd:(LPSTR)cmd.UTF8String];
    dataBlob = [self intToBlob:values_blockgroup.medianAgePop];
    cmd = [NSString stringWithFormat:@"INSERT INTO PropertyList VALUES (%i,%i,%i,X'%@');",dbid++,PropNum,(int)PFT_MedianAgePop_blockgroup,dataBlob];
    [self executeCmd:(LPSTR)cmd.UTF8String];
    dataBlob = [self intToBlob:values_blockgroup.pctChildren];
    cmd = [NSString stringWithFormat:@"INSERT INTO PropertyList VALUES (%i,%i,%i,X'%@');",dbid++,PropNum,(int)PFT_PctChildren_blockgroup,dataBlob];
    [self executeCmd:(LPSTR)cmd.UTF8String];
    dataBlob = [self intToBlob:values_blockgroup.pctSenior];
    cmd = [NSString stringWithFormat:@"INSERT INTO PropertyList VALUES (%i,%i,%i,X'%@');",dbid++,PropNum,(int)PFT_PctSenior_blockgroup,dataBlob];
    [self executeCmd:(LPSTR)cmd.UTF8String];
    dataBlob = [self intToBlob:values_blockgroup.stability5yr];
    cmd = [NSString stringWithFormat:@"INSERT INTO PropertyList VALUES (%i,%i,%i,X'%@');",dbid++,PropNum,(int)PFT_Stability5yr_blockgroup,dataBlob];
    [self executeCmd:(LPSTR)cmd.UTF8String];
    dataBlob = [self intToBlob:values_blockgroup.stability15yr];
    cmd = [NSString stringWithFormat:@"INSERT INTO PropertyList VALUES (%i,%i,%i,X'%@');",dbid++,PropNum,(int)PFT_Stability15yr_blockgroup,dataBlob];
    [self executeCmd:(LPSTR)cmd.UTF8String];
    rtn = YES;
    [self close:opened];
    //add routes from property to destinations
    Destinations *dests = [[Destinations alloc]init];
    [dests addRoutesForProperty:PropNum];
    
    
    return rtn;
}

@end