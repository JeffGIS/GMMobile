//  Destinations.m
//  GMMobile

#import "Destinations.h"
#import "PropertyData.h"
#import "PropertyList.h"

#define CURRENT_VERSION 8
#define METERS_PER_MILE 1609.344

@interface Destinations ()

@property (nonatomic, copy) NSString *documentsDirectory;
@property (nonatomic, copy) NSString *fileName;
@property (nonatomic, copy) NSString *path;
@property (nonatomic) sqlite3 *database;
@property BOOL isOpen;
@property (nonatomic) unsigned long long fileSize;

@end

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
    
    BOOL opened = [self open];
    NSString *query = [NSString stringWithFormat:@"SELECT max(RouteNum) FROM Routes"];
    
    sqlite3_stmt *statement = NULL;
    
    SQLOK(sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement, 0), _database);
    
    if (sqlite3_step(statement) == SQLITE_ROW)
    {
        rtn = sqlite3_column_int(statement, 0) + 1;
    }
    
    SQLOK(sqlite3_finalize(statement), _database);
    [self close:opened];
    
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
    
    while (sqlite3_step(statement) == SQLITE_ROW)
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

-(NSInteger)addIndividualDestination:(Destination*)dest
{
    int destNum = [self addDestination:dest toGroup:0];

    dest.destinationID = destNum;
    [self addRoutesForDestination:dest];
    return destNum;
}
-(NSInteger)addGroupDestination:(Destination*)dest
{
    BOOL opened = [self open];
    int destnum = [self next_id];
    NSString * cmd = [NSString stringWithFormat:@"INSERT INTO Destinations VALUES (%i,%i,'%@',%f,%f,%f,%li,%li);",destnum,-1,dest.destinationName,dest.latlon.lat,dest.latlon.lon,dest.frequency,dest.timeDepart,dest.timeReturn];
    [self executeCmd:(LPSTR)cmd.UTF8String];
    
    [self close:opened];
    return destnum;
}
-(NSInteger)addDestination:(Destination*)dest toGroup:(NSInteger)groupID
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
    cmd = [NSString stringWithFormat:@"DELETE FROM Routes WHERE DestinationNum = %li;",destinationID];
    [self executeCmd:(LPSTR)cmd.UTF8String];
    
    [self close:opened];
    return;
}
- (NSInteger)addParcelToDestinations:(NSString *)PID
{
    NSInteger rtn = NO;
    PropertyData *propData = [[PropertyData alloc] init];
    LLPOINT pidPoint = [propData getPointForPID:PID];
    
    Destination * dest = [[Destination alloc]init];
    dest.latlon = pidPoint;
    dest.destinationName = PID;
    rtn = [self addIndividualDestination:dest];
    return rtn;
}

- (void) getRoute:(NSInteger)routeNum
         fromProp:(NSInteger)propNum
        fromPoint:(LLPOINT)fromPoint
           toDest:(NSInteger)destinationID
          toPoint:(LLPOINT)toPoint
           atTime:(NSInteger)time
    withFrequency:(CGFloat)frequency
      inDirection:(int)direction
     tranportType:(MKDirectionsTransportType)transportType
{
    Route *route = [[Route alloc] init];
    
    CLLocationCoordinate2D fromCoord = CLLocationCoordinate2DMake(fromPoint.lat, fromPoint.lon);
    
    MKPlacemark *fpm = [[MKPlacemark alloc] initWithCoordinate:fromCoord
                                             addressDictionary:nil];
    
    MKMapItem *fmi = [[MKMapItem alloc] initWithPlacemark:fpm];
    
    CLLocationCoordinate2D toCoord = CLLocationCoordinate2DMake(toPoint.lat, toPoint.lon);
    
    MKPlacemark *tpm = [[MKPlacemark alloc] initWithCoordinate:toCoord
                                             addressDictionary:nil];
    
    MKMapItem *tmi = [[MKMapItem alloc] initWithPlacemark:tpm];
    
    MKDirectionsRequest *request = [[MKDirectionsRequest alloc] init];
    request.source = fmi;
    request.destination = tmi;
    request.transportType = transportType;
    request.requestsAlternateRoutes = NO;
    
    MKDirections *directions = [[MKDirections alloc] initWithRequest:request];
    
    [directions calculateDirectionsWithCompletionHandler:
     ^(MKDirectionsResponse *response, NSError *error) {
         if (error)
             NSLog(@"MKDIR ERROR:%@", error.localizedDescription);
         
         else
         {
             MKRoute *theRoute = response.routes[0];
             route.routePolyline = theRoute.steps;
             route.distanceInMiles = frequency * (theRoute.distance / METERS_PER_MILE);
             route.timeInMinutes = frequency * (theRoute.expectedTravelTime / 60.0);
             
             BOOL opened = [self open];
             NSString *cmd = [NSString stringWithFormat:@"INSERT INTO Routes VALUES (%li,%li,%li,%i,%f,%f);",routeNum,propNum,destinationID,direction,route.distanceInMiles,route.timeInMinutes];
             [self executeCmd:(LPSTR)cmd.UTF8String];
             [self close:opened];
         }
     }];
}

- (void)addRoutesForProperty:(NSInteger)propNum
{
    PropertyList *propList = [[PropertyList alloc]init];
    LLPOINT propPt = [propList getPropertyLatLon:propNum];
    
    NSArray * individDests = [self getIndividualDestinations];
    
    NSInteger routeNum = [self nextRouteNum];
    for (Destination *dest in individDests)
    {
        [self getRoute:routeNum++
              fromProp:propNum
             fromPoint:propPt
                toDest:dest.destinationID
               toPoint:dest.latlon
                atTime:dest.timeDepart
         withFrequency:dest.frequency
           inDirection:1
          tranportType:MKDirectionsTransportTypeAny];
        
        [self getRoute:routeNum++
              fromProp:propNum
             fromPoint:dest.latlon
                toDest:dest.destinationID
               toPoint:propPt
                atTime:dest.timeReturn
         withFrequency:dest.frequency
           inDirection:2
          tranportType:MKDirectionsTransportTypeAny];
    }
}

- (void)addRoutesForDestination:(Destination*)dest
{
    PropertyList *propList = [[PropertyList alloc]init];
    NSArray* propNums = [propList getPropertyNumbers];
    
    NSInteger routeNum = [self nextRouteNum];
    for (NSNumber* pnum in propNums)
    {
        NSInteger propNum = [pnum integerValue];
        LLPOINT propPt = [propList getPropertyLatLon:propNum];
    
        [self getRoute:routeNum++
              fromProp:propNum
             fromPoint:propPt
                toDest:dest.destinationID
               toPoint:dest.latlon
                atTime:dest.timeDepart
         withFrequency:dest.frequency
           inDirection:1
          tranportType:MKDirectionsTransportTypeAny];
        
        [self getRoute:routeNum++
              fromProp:propNum
             fromPoint:dest.latlon
                toDest:dest.destinationID
               toPoint:propPt
                atTime:dest.timeReturn
         withFrequency:dest.frequency
           inDirection:2
          tranportType:MKDirectionsTransportTypeAny];

    }
}

- (CGFloat)totalValueForProperty:(NSInteger)propNum ofType:(PropFieldType)type
{
    CGFloat totval = 0;
    BOOL opened = [self open];
    NSString *query = [NSString stringWithFormat:@"SELECT Distance,Time FROM Routes WHERE PropertyNum = %li",propNum];
    sqlite3_stmt *statement = NULL;
    
    SQLOK(sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement, 0), _database);
    
    while (sqlite3_step(statement) == SQLITE_ROW)
    {
        CGFloat dist = sqlite3_column_double(statement, 0);
        CGFloat time = sqlite3_column_double(statement, 1);
        if (type == PFT_TimeToDestinations)
            totval += time;
        else
            totval += dist;
    }
    
    SQLOK(sqlite3_finalize(statement), _database);
    [self close:opened];
    
    return totval;
}
-(void)updateDestinationName:(NSInteger)destinationID
                     newName:(NSString*)name
{
    BOOL opened = [self open];
    
    NSString * cmd = [NSString stringWithFormat:@"UPDATE Destinations SET DestinationName = '%@' WHERE DestinationNumber = %li",name,destinationID];
    [self executeCmd:(LPSTR)cmd.UTF8String];
    [self close:opened];
}

-(void)updateDestination:(Destination*)dest
{
    BOOL opened = [self open];
    
    [self startTransaction];
    [self removeDestination:dest.destinationID];
    dest.destinationID = [self addDestination:dest toGroup:dest.groupID];
    [self addRoutesForDestination:dest];
    [self commitTransaction];
    [self close:opened];
}

@end
