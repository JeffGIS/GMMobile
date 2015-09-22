//  PropertyList.m
//  GMMobile

#import "PropertyList.h"

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
- (void)open
{
    if (!_isOpen)
    {
        _isOpen = YES;
        _isOpen = !SQLOKpl(sqlite3_open(_path.UTF8String, &_database), _database);
        NSLog(@"PropertyList Database open");
        
        _fileSize = [NSFileManager.defaultManager attributesOfItemAtPath:_path
                                                                   error:nil].fileSize;
    }
}

- (void)close
{
    SQLOKpl(sqlite3_close(_database),_database);
    NSLog(@"PropertyList Database close");
    _isOpen = NO;
}

- (void)clear
{
    [self close];
    
    //BOOL st = [NSFileManager.defaultManager removeItemAtPath:_path
    //error:nil];
}
- (BOOL) createTables
{
    NSString *cmd =  @"CREATE TABLE IF NOT EXISTS PropertyList (id INTEGER PRIMARY KEY,PropID INTEGER,FieldType INTEGER,FieldValue BLOB(33554432))";
    NSString *cmd2 = @"CREATE TABLE IF NOT EXISTS DestinationList (id INTEGER PRIMARY KEY,FieldName CHAR(100),FieldValue BLOB(33554432))";
    
    [self open];
    BOOL rtn = !SQLOKpl(sqlite3_exec(_database, cmd.UTF8String, 0, 0, 0), _database);
    [self close];
    return rtn;
}
- (int)datasetVersion
{
    int rtn = -1;
    [self open];
    
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
    
    [self close];
    return rtn;
}

- (BOOL)executeCmd:(char *)cmd
      sendToServer:(BOOL)sendToServer
     useUniqueFile:(BOOL)uniqueFile
{
    BOOL rtn = !SQLOKpl(sqlite3_exec(_database, cmd, 0, 0, 0), _database);
/*    if (rtn && sendToServer)
    {
        if (uniqueFile || !_sendToServerFile)
        {
            int iTime = NSDate.timeIntervalSinceReferenceDate;
            _sendToServerFile = [NSString stringWithFormat:@"%@/AlleyWallInventory_%i-%i.sql",
                                 CRAPI.sharedInstance.sharedOutputDirectory,iTime,fileSequence++];
            rtn = [[NSString stringWithUTF8String:cmd] writeToFile:_sendToServerFile
                                                        atomically:YES
                                                          encoding:NSUTF8StringEncoding
                                                             error:nil];
        }
        else
        {
            [CRAPI.sharedInstance appendString:[NSString stringWithUTF8String:cmd] toFile:_sendToServerFile];
        }
    }*/
    return rtn;
}

- (void)startTransaction
{
    [self open];
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
    NSMutableArray * propNums = [[NSMutableArray alloc]init];;
    return propNums;
}
- (void) getPropertyFieldValueOfType:(PropFieldType)type
                   forPropertyNumber:(NSInteger)propNum;
{
    return;
}
- (BOOL)addParcelToPropertyList:(NSString *)PID
{
    return NO;
}

@end