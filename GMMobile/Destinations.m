//  Destinations.m
//  GMMobile

#import "Destinations.h"
#import "PropertyData.h"
#import "PropertyList.h"
@import GoogleMaps;
#import "CCodeLibrary/NVDestinationOptions.h"

//#define CURRENT_VERSION 22

@interface Destinations ()

@property NSString *documentsDirectory, *fileName, *path;
@property sqlite3nv *database;
@property BOOL isOpen;
@property (nonatomic) unsigned long long fileSize;
@property NSCondition *condition;

@end

@implementation Destination

- (id)init
{
    self = [super init];
    self.frequency = 1.0;
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

@implementation RouteStep

+ (RouteStep *)routeStepWithPolyline:(MKPolyline *)polyline
                       transportType:(MKDirectionsTransportType)transportType
{
    RouteStep *rs = [[RouteStep alloc] init];
    rs.polyline = polyline;
    rs.transportType = transportType;
    
    return rs;
}

- (id)init
{
    self = [super init];
    return self;
}

@end

@implementation Destinations

- (void)logError:(int)sqlReturn
          method:(sqlite3nv *)database
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
        
        //int version = [self datasetVersion];
        
        if (CRAPI.sharedInstance.resetDestinations)
        {
            NSError *error = nil;
            
            [NSFileManager.defaultManager removeItemAtPath:_path
                                                     error:&error];
            
            if (error)
                NSLog(@"%@ file removal error", _fileName);
            
            CRAPI.sharedInstance.resetDestinations = NO;
        }
        
        [self createTables];
        self.condition = [[NSCondition alloc] init];
    }
    
    return self;
}

- (void)dealloc
{
    SQLite_Close(&_database);
    //NSLog(@"Destinations Database dealloc");
}
- (BOOL)open
{
    BOOL rtn = NO;
    if (!_isOpen)
    {
        _isOpen = YES;
        _isOpen = !SQLOK(__FILE__,__LINE__,SQLite_Open(_path.UTF8String, &_database), _database);
        //NSLog(@"Destinations Database open");
        
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
        SQLOK(__FILE__,__LINE__,SQLite_Close(&_database),_database);
        //NSLog(@"Destinations Database close");
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
    
    BOOL rtn = !SQLOK(__FILE__,__LINE__,SQLiteExec(_database, cmd.UTF8String, 0, 0, 0), _database);
    
    /*cmd = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS Destinations_VERSION (id INT,Version INT);INSERT INTO Destinations_VERSION VALUES (1,%i);",CURRENT_VERSION];
    SQLOK(__FILE__,__LINE__,SQLiteExec(_database, cmd.UTF8String, 0, 0, 0), _database);*/
    
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
        NSString *query = [NSString stringWithFormat:@"SELECT Version FROM Destinations_VERSION"];
        
        sqlite3_stmt *statement = NULL;
        
        SQLOK(__FILE__,__LINE__,SQLitePrepare(_database, query.UTF8String, -1, &statement, 0), _database);
        
        if (sqlite3_step(statement) == SQLITE_ROW)
        {
            rtn = sqlite3_column_int(statement, 0);
        }
        
        SQLOK(__FILE__,__LINE__,SQLiteFinalize(statement), _database);
    }
    
    [self close:opened];
    return rtn;
}
*/

- (BOOL)executeCmd:(char *)cmd
{
    BOOL rtn = !SQLOK(__FILE__,__LINE__,SQLiteExec(_database, cmd, 0, 0, 0), _database);
    return rtn;
}

- (void)startTransaction
{
    SQLOK(__FILE__,__LINE__,SQLiteExec(_database, "BEGIN", 0, 0, 0), _database);
}

- (void)commitTransaction
{
    SQLOK(__FILE__,__LINE__,SQLiteExec(_database, "COMMIT", 0, 0, 0), _database);
}

- (int)next_id
{
    int rtn = 1;
    
    NSString *query = [NSString stringWithFormat:@"SELECT max(DestinationNumber) FROM Destinations"];
    
    sqlite3_stmt *statement = NULL;
    
    SQLOK(__FILE__,__LINE__,SQLitePrepare(_database, query.UTF8String, -1, &statement, 0), _database);
    
    if (sqlite3_step(statement) == SQLITE_ROW)
    {
        rtn = sqlite3_column_int(statement, 0) + 1;
    }
    
    SQLOK(__FILE__,__LINE__,SQLiteFinalize(statement), _database);
    
    return rtn;
}

- (int)nextRouteNum
{
    int rtn = 1;
    
    BOOL opened = [self open];
    NSString *query = [NSString stringWithFormat:@"SELECT max(RouteNum) FROM Routes"];
    
    sqlite3_stmt *statement = NULL;
    
    SQLOK(__FILE__,__LINE__,SQLitePrepare(_database, query.UTF8String, -1, &statement, 0), _database);
    
    if (sqlite3_step(statement) == SQLITE_ROW)
    {
        rtn = sqlite3_column_int(statement, 0) + 1;
    }
    
    SQLOK(__FILE__,__LINE__,SQLiteFinalize(statement), _database);
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

- (Destination *)getDestination:(NSInteger)destinationID
{
    Destination * dest = [[Destination alloc]init];
    BOOL opened = [self open];
    NSString *query = [NSString stringWithFormat:@"SELECT DestinationNumber,GroupNumber,DestinationName,LATITUDE,LONGITUDE,Frequency,TimeDepart,TimeReturn FROM Destinations WHERE DestinationNumber = %li",(long)destinationID];
    
    sqlite3_stmt *statement = NULL;
    
    SQLOK(__FILE__,__LINE__,SQLitePrepare(_database, query.UTF8String, -1, &statement, 0), _database);
    
    if (sqlite3_step(statement) == SQLITE_ROW)
    {
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
    }
    SQLOK(__FILE__,__LINE__,SQLiteFinalize(statement), _database);
    [self close:opened];
    return dest;
}

-(NSArray*)getDestinationsWithinGroup:(NSInteger)groupID
{
    NSMutableArray* dests = [[NSMutableArray alloc]init];

    BOOL opened = [self open];
    NSString *query = [NSString stringWithFormat:@"SELECT DestinationNumber,GroupNumber,DestinationName,LATITUDE,LONGITUDE,Frequency,TimeDepart,TimeReturn FROM Destinations WHERE GroupNumber = %li",(long)groupID];
    
    sqlite3_stmt *statement = NULL;
    
    SQLOK(__FILE__,__LINE__,SQLitePrepare(_database, query.UTF8String, -1, &statement, 0), _database);
    
    while (sqlite3_step(statement) == SQLITE_ROW)
    {
        Destination *dest = Destination.new;
        dest.destinationID = sqlite3_column_int(statement, 0);
        LPSTR name = (LPSTR)sqlite3_column_text(statement, 2);
        dest.destinationName = [NSString stringWithFormat:@"%s", name];
        LLPOINT pt = {0};
        pt.lat = sqlite3_column_double(statement, 3);
        pt.lon = sqlite3_column_double(statement, 4);
        dest.latlon = pt;
        dest.frequency = sqlite3_column_double(statement, 5);
        dest.timeDepart = sqlite3_column_int(statement, 6);
        dest.timeReturn = sqlite3_column_int(statement, 7);
        [dests addObject:dest];
    }
    
    SQLOK(__FILE__,__LINE__,SQLiteFinalize(statement), _database);
    [self close:opened];
    return dests.copy;
}

-(NSInteger)addIndividualDestination:(Destination*)dest
{
    NSInteger destNum = [self addDestination:dest toGroup:0];

    dest.destinationID = destNum;
    [self addRoutesForDestination:dest];
    return destNum;
}
-(NSInteger)addGroupDestination:(Destination*)dest
{
    BOOL opened = [self open];
    int destnum = [self next_id];
    
    NSString *cmd = [NSString stringWithFormat:@"INSERT INTO Destinations VALUES (%i,%i,'%@',%f,%f,%li,%li,%li);",
                     destnum,-1,dest.destinationName,dest.latlon.lat,dest.latlon.lon,(long)dest.frequency,
                     (long)dest.timeDepart,(long)dest.timeReturn];
    
    [self executeCmd:(LPSTR)cmd.UTF8String];
    
    [self close:opened];
    return destnum;
}
-(NSInteger)addDestination:(Destination*)dest toGroup:(NSInteger)groupID
{
    BOOL opened = [self open];
    
    int destnum = [self next_id];
    
    NSString *cmd = [NSString stringWithFormat:@"INSERT INTO Destinations VALUES (%i,%li,'%@',%f,%f,%li,%li,%li);",
                     destnum,(long)groupID,dest.destinationName,dest.latlon.lat,dest.latlon.lon,(long)dest.frequency,
                     (long)dest.timeDepart,(long)dest.timeReturn];
    
    [self executeCmd:(LPSTR)cmd.UTF8String];
    
    [self close:opened];
    return destnum;
}
-(void)removeDestination:(NSInteger)destinationID
{
    BOOL opened = [self open];
    
    NSString * cmd = [NSString stringWithFormat:@"DELETE FROM Destinations WHERE DestinationNumber = %li;",(long)destinationID];
    [self executeCmd:(LPSTR)cmd.UTF8String];
    cmd = [NSString stringWithFormat:@"DELETE FROM Routes WHERE DestinationNum = %li;",(long)destinationID];
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

- (int)getRoute:(NSInteger)routeNum
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
    request.departureDate = [NVDestinationOptions getDateForTime:time];
    
    MKDirections *directions = [[MKDirections alloc] initWithRequest:request];
    if (directions.calculating)
    {
        [directions cancel];
        return -1;
    }
    
    [directions calculateDirectionsWithCompletionHandler:
     ^(MKDirectionsResponse *response, NSError *error) {
         if (error)
         {
             NSLog(@"MKDIR ERROR(from %li to %li):%@", (long)propNum, (long)destinationID, error.localizedDescription);
             
             [self getRouteFromGoogle:routeNum
                             fromProp:propNum
                            fromPoint:fromPoint
                               toDest:destinationID
                              toPoint:toPoint
                               atTime:time
                        withFrequency:frequency
                          inDirection:direction
                         tranportType:transportType];
         }
         
         else
         {
             MKRoute *theRoute = response.routes[0];
             NSArray *routeSteps = theRoute.steps;
             NSMutableArray *routePoly = [[NSMutableArray alloc] init];
             
             for (int i = 0; i < routeSteps.count; i++)
             {
                 MKRouteStep *mkrs = routeSteps[i];
                 
                 RouteStep *rs = [RouteStep routeStepWithPolyline:mkrs.polyline
                                                    transportType:mkrs.transportType];
                 
                 [routePoly addObject:rs];
             }
             
             route.routePolyline = routePoly;
             route.distanceInMiles = frequency * (theRoute.distance / METERS_PER_MILE);
             route.timeInMinutes = frequency * (theRoute.expectedTravelTime / 60.0);
             
             [_condition lock];
             //[_condition wait];
             BOOL opened = [self open];
             
             NSString *cmd = [NSString stringWithFormat:@"INSERT INTO Routes VALUES (%li,%li,%li,%i,%f,%f);",
                              (long)routeNum, (long)propNum, (long)destinationID, direction, route.distanceInMiles, route.timeInMinutes];
             
             [self executeCmd:(LPSTR)cmd.UTF8String];
             [self close:opened];
             //[_condition signal];
             [_condition unlock];
         }
     }];
    return 1;
}

- (void)getRouteFromGoogle:(NSInteger)routeNum
                  fromProp:(NSInteger)propNum
                 fromPoint:(LLPOINT)fromPoint
                    toDest:(NSInteger)destinationID
                   toPoint:(LLPOINT)toPoint
                    atTime:(NSInteger)time
             withFrequency:(CGFloat)frequency
               inDirection:(int)direction
              tranportType:(MKDirectionsTransportType)transportType
{
    NSString *mode = @"";
    
    switch (transportType)
    {
        case MKDirectionsTransportTypeAny:
        case MKDirectionsTransportTypeAutomobile:
            mode = @"driving";
            break;
            
        case MKDirectionsTransportTypeTransit:
            mode = @"transit";
            break;
            
        case MKDirectionsTransportTypeWalking:
            mode = @"walking";
            break;
            
        default:
            mode = @"driving";
            break;
    }
    
    NSString *urlString =
    [NSString stringWithFormat:@"https://maps.google.com/maps/api/directions/json?origin=%f,%f&destination=%f,%f&sensor=true&mode=%@",
     fromPoint.lat, fromPoint.lon, toPoint.lat, toPoint.lon, mode];
    
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    urlRequest.timeoutInterval = 15;
    
    NSData *urlData = nil;
    NSURLResponse *response = nil;
    NSError *error = nil;
    
    urlData = [NSURLConnection sendSynchronousRequest:urlRequest
                                    returningResponse:&response
                                                error:&error];
    
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:urlData
                                                         options:NSJSONReadingMutableContainers
                                                           error:&error];
    
    NSString *status = json[@"status"];
    
    if (error)
        NSLog(@"JSON ERROR(from %li to %li):%@", (long)propNum, (long)destinationID, error.localizedDescription);
    
    else if (![status isEqualToString:@"OK"])
        NSLog(@"JSON ERROR(from %li to %li):%@", (long)propNum, (long)destinationID, status);
    
    else
    {
        NSDictionary *leg = json[@"routes"][0][@"legs"][0];
        NSArray *steps = leg[@"steps"];
        
        Route *route = [[Route alloc] init];
        
        NSMutableArray *routePoly = [[NSMutableArray alloc] init];
        
        for (int i = 0; i < steps.count; i++)
        {
            NSString *travelMode = steps[i][@"travel_mode"];
            MKDirectionsTransportType transType = MKDirectionsTransportTypeAutomobile;
            
            if ([travelMode isEqualToString:@"TRANSIT"])
                transType = MKDirectionsTransportTypeTransit;
            
            else if ([travelMode isEqualToString:@"WALKING"])
                transType = MKDirectionsTransportTypeWalking;
            
            GMSPath *path = [GMSPath pathFromEncodedPath:steps[i][@"polyline"][@"points"]];
            
            CLLocationCoordinate2D *coords = (CLLocationCoordinate2D *)malloc((sizeof(CLLocationCoordinate2D) * path.count) + 4);
           
            for (int i = 0; i < (int)path.count; i++)
                coords[i] = [path coordinateAtIndex:i];
            
            MKPolyline *polyline = [MKPolyline polylineWithCoordinates:coords
                                                                 count:path.count];
            
            free(coords);
            
            RouteStep *routeStep = [RouteStep routeStepWithPolyline:polyline
                                                      transportType:transType];
            
            [routePoly addObject:routeStep];
        }
        
        route.routePolyline = routePoly;
        
        NSString *distance = leg[@"distance"][@"value"];
        NSString *duration = leg[@"duration"][@"value"];
        
        route.distanceInMiles = frequency * (distance.integerValue / METERS_PER_MILE);
        route.timeInMinutes = frequency * (duration.integerValue / 60.0);
        
        [_condition lock];
        //[_condition wait];
        BOOL opened = [self open];
        
        NSString *cmd = [NSString stringWithFormat:@"INSERT INTO Routes VALUES (%li,%li,%li,%i,%f,%f);",
                         (long)routeNum, (long)propNum, (long)destinationID, direction, route.distanceInMiles, route.timeInMinutes];
        
        [self executeCmd:(LPSTR)cmd.UTF8String];
        [self close:opened];
        //[_condition signal];
        [_condition unlock];
    }
}

- (void)addRoutesForProperty:(NSInteger)propNum
{
    PropertyList *propList = [[PropertyList alloc]init];
    LLPOINT propPt = [propList getPropertyLatLon:propNum];
    
    NSArray *individDests = [self getIndividualDestinations];
    
    NSInteger routeNum = [self nextRouteNum];
    
    for (Destination *dest in individDests)
    {
        int n = 0;
        while (n++ < 100 &&
               [self getRoute:routeNum++
              fromProp:propNum
             fromPoint:propPt
                toDest:dest.destinationID
               toPoint:dest.latlon
                atTime:dest.timeDepart
         withFrequency:dest.frequency
           inDirection:1
          tranportType:MKDirectionsTransportTypeAny] == -1)
        {
            [NSThread sleepForTimeInterval:0.02];
        }
        if (n == 100)
            n = -1;
        n = 0;
        while (n++ < 100 &&
            [self getRoute:routeNum++
              fromProp:propNum
             fromPoint:dest.latlon
                toDest:dest.destinationID
               toPoint:propPt
                atTime:dest.timeReturn
         withFrequency:dest.frequency
           inDirection:2
          tranportType:MKDirectionsTransportTypeAny] == -1)
        {
            [NSThread sleepForTimeInterval:0.02];
        }
        if (n == 100)
            n = -1;
    }
}

- (void)addRoutesForDestination:(Destination *)dest
{
    PropertyList *propList = [[PropertyList alloc]init];
    NSArray *propNums = [propList getPropertyNumbers];
    
    NSInteger routeNum = [self nextRouteNum];
    
    for (NSNumber *pnum in propNums)
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

- (CGFloat)totalValueForProperty:(NSInteger)propNum
                          ofType:(PropFieldType)type
{
    CGFloat totval = 0;
    BOOL opened = [self open];
    NSString *query = [NSString stringWithFormat:@"SELECT Distance,Time FROM Routes WHERE PropertyNum = %li",(long)propNum];
    sqlite3_stmt *statement = NULL;
    
    SQLOK(__FILE__,__LINE__,SQLitePrepare(_database, query.UTF8String, -1, &statement, 0), _database);
    
    while (sqlite3_step(statement) == SQLITE_ROW)
    {
        CGFloat dist = sqlite3_column_double(statement, 0);
        CGFloat time = sqlite3_column_double(statement, 1);
        
        if (type == PFT_TimeToDestinations)
            totval += time;
        else
            totval += dist;
    }
    
    SQLOK(__FILE__,__LINE__,SQLiteFinalize(statement), _database);
    [self close:opened];
    
    return totval;
}

-(void)updateDestinationName:(NSInteger)destinationID
                     newName:(NSString*)name
{
    BOOL opened = [self open];
    
    NSString * cmd = [NSString stringWithFormat:@"UPDATE Destinations SET DestinationName = '%@' WHERE DestinationNumber = %li",name,(long)destinationID];
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
