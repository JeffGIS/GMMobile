//
//  Destinations.m
//  GMMobile
//
//  Created by JEFFREY E SMITH on 10/4/15.
//  Copyright (c) 2015 GSSi. All rights reserved.
//

#import "Destinations.h"
#import "PropertyData.h"
#import "PropertyList.h"

#define CURRENT_VERSION 4

@implementation Destination
- (id)init
{
    self = [super init];
    return self;
}
@end

@implementation Route
- (id)init
{
    self = [super init];
    return self;
}
@end

@implementation Destinations
{
    NSString *_documentsDirectory;
    NSString *_fileName;
    NSString *_path;
    sqlite3 *_database;
    BOOL _isOpen;
    unsigned long long _fileSize;
}

int SQLOKdst(int sqlReturn, sqlite3 *database)
{
    if (sqlReturn != SQLITE_OK)
    {
        //[self logError:sqlReturn
        //             method:database];
        NSLog(@"%@", [NSString stringWithFormat:@"SQLite Error in Destinations %i = %i:%s",
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
        _fileName = @"DefaultDestinations.sqlite";
        _path = [NSString stringWithFormat:@"%@/%@", _documentsDirectory, _fileName];
        int version = [self datasetVersion];
        if (version != CURRENT_VERSION)
            [NSFileManager.defaultManager removeItemAtPath:_path error:nil];
        
        [self createTables];
    }
    
    return self;
}

- (void)dealloc
{
    sqlite3_close(_database);
    NSLog(@"Destinations Database dealloc");
}
- (BOOL)open
{
    BOOL rtn = NO;
    if (!_isOpen)
    {
        _isOpen = YES;
        _isOpen = !SQLOKdst(sqlite3_open(_path.UTF8String, &_database), _database);
        NSLog(@"Destinations Database open");
        
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
        SQLOKdst(sqlite3_close(_database),_database);
        NSLog(@"Destinations Database close");
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
    
    NSString *cmd =  @"CREATE TABLE IF NOT EXISTS Destinations (DestinationNumber INT PRIMARY KEY,GroupNumber INT,DestinationName CHAR(200),LATITUDE REAL,LONGITUDE REAL,Frequency REAL,TimeDepart INT,TimeReturn INT);\
    CREATE TABLE IF NOT EXISTS Routes (RouteNum INT,PropertyNum INT,DestinationNum INT,Direction INT,Distance REAL,Time REAL);\
                      CREATE INDEX IF NOT EXISTS PropNum_index ON Routes (PropertyNum ASC);";
    
    BOOL rtn = !SQLOKdst(sqlite3_exec(_database, cmd.UTF8String, 0, 0, 0), _database);
    cmd = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS Destinations_VERSION (id INT,Version INT);INSERT INTO Destinations_VERSION VALUES (1,%i);",CURRENT_VERSION];
    SQLOKdst(sqlite3_exec(_database, cmd.UTF8String, 0, 0, 0), _database);
    [self close:opened];
    return rtn;
}
- (int)datasetVersion
{
    int rtn = -1;
    BOOL opened = [self open];
    
    if (_isOpen && _fileSize > 0)
    {
        NSString *query = [NSString stringWithFormat:@"SELECT Version FROM Destinations_VERSION"];
        
        sqlite3_stmt *statement = NULL;
        
        SQLOKdst(sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement, 0), _database);
        
        if (sqlite3_step(statement) == SQLITE_ROW)
        {
            rtn = sqlite3_column_int(statement, 0);
        }
        
        SQLOKdst(sqlite3_finalize(statement), _database);
    }
    
    [self close:opened];
    return rtn;
}

- (BOOL)executeCmd:(char *)cmd
{
    BOOL rtn = !SQLOKdst(sqlite3_exec(_database, cmd, 0, 0, 0), _database);
    return rtn;
}

- (void)startTransaction
{
    SQLOKdst(sqlite3_exec(_database, "BEGIN", 0, 0, 0), _database);
}

- (void)commitTransaction
{
    SQLOKdst(sqlite3_exec(_database, "COMMIT", 0, 0, 0), _database);
}

- (int)next_id
{
    int rtn = 1;
    
    NSString *query = [NSString stringWithFormat:@"SELECT max(DestinationNumber) FROM Destinations"];
    
    sqlite3_stmt *statement = NULL;
    
    SQLOK(sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement, 0), _database);
    
    if (sqlite3_step(statement) == SQLITE_ROW)
    {
        rtn = sqlite3_column_int(statement, 0) + 1;
    }
    
    SQLOK(sqlite3_finalize(statement), _database);
    
    return rtn;
}

- (int)nextRouteNum
{
    int rtn = 1;
    
    NSString *query = [NSString stringWithFormat:@"SELECT max(RouteNum) FROM Routes"];
    
    sqlite3_stmt *statement = NULL;
    
    SQLOK(sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement, 0), _database);
    
    if (sqlite3_step(statement) == SQLITE_ROW)
    {
        rtn = sqlite3_column_int(statement, 0) + 1;
    }
    
    SQLOK(sqlite3_finalize(statement), _database);
    
    return rtn;
}

-(NSArray*)getIndividualDestinations
{
    NSArray* dests = [self getDestinationsWithinGroup:0];
    return dests;
}
-(NSArray*)getGroupDestinations
{
    NSArray* dests = [self getDestinationsWithinGroup:-1];
    return dests;
}
-(NSArray*)getDestinationsWithinGroup:(NSInteger)groupID
{
    NSMutableArray* dests = [[NSMutableArray alloc]init];

    BOOL opened = [self open];
    NSString *query = [NSString stringWithFormat:@"SELECT DestinationNumber,GroupNumber,DestinationName,LATITUDE,LONGITUDE,Frequency,TimeDepart,TimeReturn FROM Destinations WHERE GroupNumber = %li",groupID];
    
    sqlite3_stmt *statement = NULL;
    
    SQLOK(sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement, 0), _database);
    
    if (sqlite3_step(statement) == SQLITE_ROW)
    {
        Destination * dest = [[Destination alloc]init];
        
        dest.destinationID = sqlite3_column_int(statement, 0);
        LPSTR name = (LPSTR)sqlite3_column_text(statement, 2);
        dest.destinationName = [NSString stringWithUTF8String:name];
        LLPOINT pt;
        pt.lat = sqlite3_column_double(statement, 3);
        pt.lon = sqlite3_column_double(statement, 4);
        dest.latlon = pt;
        dest.frequency = sqlite3_column_double(statement, 5);
        dest.timeDepart = sqlite3_column_int(statement, 6);
        dest.timeReturn = sqlite3_column_int(statement, 7);
        [dests addObject:dest];
    }
    
    SQLOK(sqlite3_finalize(statement), _database);
    [self close:opened];
    return dests;
}

-(int)addIndividualDestination:(Destination*)dest
{
    int destNum = [self addDestination:dest toGroup:0];

    dest.destinationID = destNum;
    [self addRoutesForDestination:dest];
    return destNum;
}
-(int)addGroupDestination:(Destination*)dest
{
    BOOL opened = [self open];
    int destnum = [self next_id];
    NSString * cmd = [NSString stringWithFormat:@"INSERT INTO Destinations VALUES (%i,%i,'%@',%f,%f,%f,%li,%li);",destnum,-1,dest.destinationName,dest.latlon.lat,dest.latlon.lon,dest.frequency,dest.timeDepart,dest.timeReturn];
    [self executeCmd:(LPSTR)cmd.UTF8String];
    
    [self close:opened];
    return destnum;
}
-(int)addDestination:(Destination*)dest toGroup:(NSInteger)groupID
{
    BOOL opened = [self open];
    
    int destnum = [self next_id];
    NSString * cmd = [NSString stringWithFormat:@"INSERT INTO Destinations VALUES (%i,%li,'%@',%f,%f,1.0,0,0);",destnum,groupID,dest.destinationName,dest.latlon.lat,dest.latlon.lon];
    [self executeCmd:(LPSTR)cmd.UTF8String];
    
    [self close:opened];
    return destnum;
}
-(void)removeDestination:(NSInteger)destinationID
{
    BOOL opened = [self open];
    
    NSString * cmd = [NSString stringWithFormat:@"DELETE FROM Destinations WHERE DestinationNumber = %li;",destinationID];
    [self executeCmd:(LPSTR)cmd.UTF8String];
    
    [self close:opened];
    return;
}
- (BOOL)addParcelToDestinations:(NSString *)PID
{
    BOOL rtn = NO;
    PropertyData *propData = [[PropertyData alloc] init];
    LLPOINT pidPoint = [propData getPointForPID:PID];
    
    BOOL opened = [self open];
    Destination * dest = [[Destination alloc]init];
    int destnum = [self next_id];
    dest.latlon = pidPoint;
    dest.destinationName = PID;
    dest.destinationID = destnum;
    NSString * cmd = [NSString stringWithFormat:@"INSERT INTO Destinations VALUES (%i,%i,'%@',%f,%f,1.0,0,0);",destnum,0,PID,dest.latlon.lat,dest.latlon.lon];
    [self executeCmd:(LPSTR)cmd.UTF8String];
   
    rtn = YES;
    [self close:opened];
    return rtn;
}

-(Route*)getRouteFrom:(LLPOINT)fromPoint
                   to:(LLPOINT)toPoint
{
    Route * route = [[Route alloc]init];
    
    return route;
}

- (void)addRoutesForProperty:(NSInteger)propNum
{
    PropertyList *propList = [[PropertyList alloc]init];
    LLPOINT propPt = [propList getPropertyLatLon:propNum];
    
    NSArray * individDests = [self getIndividualDestinations];
    
    BOOL opened = [self open];

    for (Destination *dest in individDests)
    {
        Route * route = [self getRouteFrom:propPt to:dest.latlon];
        NSInteger routeNum = [self nextRouteNum];
        NSString *cmd = [NSString stringWithFormat:@"INSERT INTO Routes VALUES (%li,%li,%li,%f,%f);",routeNum,propNum,dest.destinationID,route.distanceInMiles,route.timeInMinutes];
        [self executeCmd:(LPSTR)cmd.UTF8String];
    }
    [self close:opened];
}

- (void)addRoutesForDestination:(Destination*)dest
{
    PropertyList *propList = [[PropertyList alloc]init];
    NSArray* propNums = [propList getPropertyNumbers];
    
    BOOL opened = [self open];
    for (NSNumber* pnum in propNums)
    {
        NSInteger propNum = [pnum integerValue];
        LLPOINT propPt = [propList getPropertyLatLon:propNum];
    
        Route * route = [self getRouteFrom:propPt to:dest.latlon];
        NSInteger routeNum = [self nextRouteNum];
        NSString *cmd = [NSString stringWithFormat:@"INSERT INTO Routes VALUES (%li,%li,%li,%f,%f);",routeNum,propNum,dest.destinationID,route.distanceInMiles,route.timeInMinutes];
        [self executeCmd:(LPSTR)cmd.UTF8String];
    }
    [self close:opened];
}
@end
