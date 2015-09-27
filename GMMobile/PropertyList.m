//  PropertyList.m
//  GMMobile

#import "PropertyList.h"
#import "PropertyData.h"

@implementation PropertyList
{
    NSString *_documentsDirectory;
    NSString *_fileName;
    NSString *_path;
    sqlite3 *_database;
    BOOL _isOpen;
    unsigned long long _fileSize;
}

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
    
    NSString *cmd =  @"CREATE TABLE IF NOT EXISTS PropertyList (id INTEGER PRIMARY KEY,PropID INTEGER,FieldType INTEGER,FieldValue BLOB(33554432));\
                        CREATE INDEX IF NOT EXISTS PropertyList_index ON PropertyList (PropID ASC);";
   // NSString *cmd2 = @"CREATE TABLE IF NOT EXISTS DestinationList (id INTEGER PRIMARY KEY,FieldName CHAR(100),FieldValue BLOB(33554432))";
    
    BOOL rtn = !SQLOKpl(sqlite3_exec(_database, cmd.UTF8String, 0, 0, 0), _database);
    [self close:opened];
    return rtn;
}
- (int)datasetVersion
{
    int rtn = -1;
    BOOL opened = [self open];
    
    if (_isOpen && _fileSize > 0)
    {
        NSString *query = [NSString stringWithFormat:@"SELECT max(Version) FROM PROPERTYLIST_VERSION"];
        
        sqlite3_stmt *statement = NULL;
        
        SQLOKpl(sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement, 0), _database);
        
        if (sqlite3_step(statement) == SQLITE_ROW)
        {
            LPSTR version = (LPSTR)sqlite3_column_text(statement, 0);
            
            if (version)
                rtn = atoi(version);
        }
        
        SQLOKpl(sqlite3_finalize(statement), _database);
    }
    
    [self close:opened];
    return rtn;
}

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
    return fields;
}

- (NSString*) propertyFieldName:(PropFieldType)fieldType
{
    NSString *name = @"";
    switch(fieldType)
    {
        case PFT_ID:
            name = @"Property ID";
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
        case PFT_Stability_block:
            name = @"Stability (5 year Block)";
            break;
        case PFT_Stability_blockgroup:
            name = @"Stability (5 year Block Group)";
            break;
        case PFT_Stability_halfMile:
            name = @"Stability (5 year Half Mile)";
            break;
        case PFT_TimeToDestinations:
            name = @"Time to Destinations";
            break;
        case PFT_PctHomestead_block:
            name = @"PCT Homestead (Block)";
            break;
        case PFT_MedianAge_block:
            name = @"Median Age (Block)";
            break;
        case PFT_MedianAge_blockgroup:
            name = @"Median Age (Block Group)";
            break;
        case PFT_Children_block:
            name = @"PCT Children (Block)";
            break;
        case PFT_MedianAgeChildren_block:
            name = @"Median Child Age (Block)";
            break;
        case PFT_MedianAgeAdults_block:
            name = @"Median Adult Age (Block)";
            break;
        case PFT_Seniors_block:
            name = @"PCT Seniors (Block)";
            break;
    }
    return name;
}
- (NSArray*) getPropertyNumbers
{
    NSMutableArray * propNums = [[NSMutableArray alloc]init];
    BOOL opened = [self open];
    NSString *query = [NSString stringWithFormat:@"SELECT DISTINCT PropID FROM PropertyList"];
    
    sqlite3_stmt *statement = NULL;
    
    SQLOK(sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement, 0), _database);
    
    while (sqlite3_step(statement) == SQLITE_ROW)
    {
        int propid = sqlite3_column_int(statement, 0) + 1;
        NSNumber * propNum = [NSNumber numberWithInt:propid];
        [propNums addObject:propNum];
    }
    
    SQLOK(sqlite3_finalize(statement), _database);
    [self close:opened];
    return propNums;
}
- (void) getPropertyFieldValueOfType:(PropFieldType)type
                   forPropertyNumber:(NSInteger)propNum;
{
    NSString * value = [self getFieldValue:propNum
                                      type:type];
    if (value)
    {
        [self.delegate PropertyList:self
                       returnsValue:value
                  forPropertyNumber:propNum
                       andFieldType:type
                         withStatus:0];
    }

    return;
}

- (NSString*) getFieldValue:(NSInteger)propNum
                       type:(NSInteger)fieldType
{
    NSString * value = nil;
    NSString *query = [NSString stringWithFormat:@"SELECT FieldValue FROM PropertyList WHERE PropID = %li AND FieldType = %li",propNum,fieldType];
    BOOL opened = [self open];
    
    sqlite3_stmt *statement = NULL;
    
    SQLOK(sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement, 0), _database);
    
    if (sqlite3_step(statement) == SQLITE_ROW)
    {
        LPSTR val = (LPSTR)sqlite3_column_blob(statement, 0);
        value = [NSString stringWithUTF8String:val];
    }
    
    SQLOK(sqlite3_finalize(statement), _database);
    [self close:opened];
    return value;
}

- (int)nextPropID
{
    int rtn = 1;
    
    NSString *query = [NSString stringWithFormat:@"SELECT max(PropID) FROM PropertyList"];
    
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
        LPSTR blb = malloc (sln*2);
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
    LPSTR pBlob = malloc(nPnts * 2 * sizeof(DPOINT)+4);
    for (NSInteger i = 0; i < nPnts; i++)
    {
        NSInteger  j;
        LPBYTE pInts = (LPBYTE)&pPoints[i];
        unsigned char c;
        for (j = 0; j < 8; j++, pInts++, lBlob += 2)
        {
            c = *pInts;
            sprintf(&pBlob[lBlob], "%2.2x", *pInts);
        }
    }
    pBlob[lBlob] = 0;
    blob = [NSString stringWithUTF8String:pBlob];
    free (pBlob);
    return blob;
}
- (BOOL)addParcelToPropertyList:(NSString *)PID
{
    BOOL rtn = NO;
    
    PropertyData *propData = [[PropertyData alloc] init];
    LLPOINT pidPoint = [propData getPointForPID:PID];
    
    BOOL opened = [self open];
    int dbid = [self next_id];
    int PropID = [self nextPropID];

    NSString *PIDBlob = [self stringToBlob:PID];
    NSString *pointBlob = [self llpointsToBlob:&pidPoint
                                    numPoints:1];
    NSString * cmd = [NSString stringWithFormat:@"INSERT INTO PropertyList VALUES (%i,%i,%i,X'%@');",dbid,PropID,(int)PFT_ID,PIDBlob];
    [self executeCmd:(LPSTR)cmd.UTF8String];
    cmd = [NSString stringWithFormat:@"INSERT INTO PropertyList VALUES (%i,%i,%i,X'%@');",dbid+1,PropID,(int)PFT_LatLon,pointBlob];
    [self executeCmd:(LPSTR)cmd.UTF8String];
    [self close:opened];
    return rtn;
}

@end