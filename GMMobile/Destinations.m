//  Destinations.m
//  GMMobile

#import "Destinations.h"

#define CURRENT_VERSION 1
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
    NSLog(@"PropertyList Database dealloc");
}
- (BOOL)open
{
    BOOL rtn = NO;
    if (!_isOpen)
    {
        _isOpen = YES;
        _isOpen = !SQLOKdst(sqlite3_open(_path.UTF8String, &_database), _database);
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
        SQLOKdst(sqlite3_close(_database),_database);
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
    
    NSString *cmd =  @"CREATE TABLE IF NOT EXISTS Destinations (DestinationNumber INT PRIMARY KEY,GroupNumber INT,DestinationName CHAR(200),LATITUDE REAL,LONGITUDE REAL);\
    CREATE INDEX IF NOT EXISTS Destinations_index ON Destinations (PropNum ASC);\
    CREATE TABLE IF NOT EXISTS RouteToDestination (RouteNum INT,PropertyNum INT,DestinationNum INT,Distance REAL,Time REAL);";
    // NSString *cmd2 = @"CREATE TABLE IF NOT EXISTS DestinationList (id INTEGER PRIMARY KEY,FieldName CHAR(100),FieldValue BLOB(33554432))";
    
    BOOL rtn = !SQLOKdst(sqlite3_exec(_database, cmd.UTF8String, 0, 0, 0), _database);
    cmd = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS PropertyList_VERSION (id INT,Version INT);INSERT INTO PropertyList_VERSION VALUES (1,%i);",CURRENT_VERSION];
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
        NSString *query = [NSString stringWithFormat:@"SELECT Version FROM PropertyList_VERSION"];
        
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

-(NSArray*)getIndividualDestinations
{
    NSMutableArray* dest = [[NSMutableArray alloc]init];
    return dest;
}
-(NSArray*)getGroupDestinations
{
    NSMutableArray* dest = [[NSMutableArray alloc]init];
    return dest;
}
-(NSArray*)getDestinationsWithinGroup:(NSInteger)groupID
{
    NSMutableArray* dest = [[NSMutableArray alloc]init];
    return dest;
}
-(void)addIndividualDestination:(Destination*)destination
{
    return;
}
-(void)addGroupDestination:(Destination*)destination
{
    return;
}
-(void)addDestination:(Destination*)destination toGroup:(NSInteger)groupID
{
    return;
}
-(void)removeDestination:(NSInteger)destinationID
{
    return;
}
- (BOOL)addParcelToDestinations:(NSString *)PID
{
    BOOL rtn = NO;
    
    return rtn;
}

- (void)getRouteFrom:(LLPOINT)fromPoint
                  to:(LLPOINT)toPoint
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
             route.distanceInMiles = (theRoute.distance / METERS_PER_MILE);
             route.timeInMinutes = (theRoute.expectedTravelTime / 60.0);
             
             if (_delegate)
                 [_delegate destinationsDidReturnRoute:route];
         }
     }];
}

@end