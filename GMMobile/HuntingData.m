//
//  HuntingData.m
//  NVMobile
//
//  Created by Jeff Smith on 10/28/21.
//  Copyright © 2021 GSSi. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "HuntingData.h"
#import "ConfigurationControl.h"

@interface HuntingData ()

@property (nonatomic, copy) NSString *documentsDirectory;
@property (nonatomic, copy) NSString *backedUpDirectory;
@property (nonatomic, copy) NSString *fileName;
@property (nonatomic, copy) NSString *path;
@property (nonatomic, copy) NSString *pathNWI;
@property (nonatomic, copy) NSString *pathNWIBin;
@property (nonatomic, copy) NSString *pathFOREST;
@property (nonatomic, copy) NSString *pathFORESTBin;
@property (nonatomic, copy) NSString *pathFEESURF;
@property (nonatomic, copy) NSString *pathFEESURFBin;
@property (nonatomic, copy) NSString *usersHuntingData;
@property NSInteger fileSize;
@property NSInteger fileSizeNWI;
@property NSInteger fileSizeNWIBin;
@property NSInteger fileSizeFOREST;
@property NSInteger fileSizeFORESTBin;
@property NSInteger fileSizeFEESURF;
@property NSInteger fileSizeFEESURFBin;
@property double acres;
@property INT64 currentRec;
@property int iPass, ii;
@end

@implementation UserWaypoint
@synthesize refno;
@synthesize latlon;
@synthesize name;
@synthesize type;
@synthesize desc;
@synthesize time;
@synthesize displayOnCompass;
@end

@implementation TrackRoutePoint
@synthesize refno;
@synthesize latlon;
@synthesize time;
@end

@implementation HuntingData
- (id)init
{
    self = [super init];
    
    if (self)
    {
        _huntingFactor = _NWIFactor = COORDINATE_FACTOR;
        _documentsDirectory = UserDefaults.defaults.nonBackedUpFilePath;
        _backedUpDirectory = UserDefaults.defaults.localFilePath;
        _path = [_documentsDirectory stringByAppendingString:@"/Hunting/HuntingData.slt"];
        _pathNWI = [_documentsDirectory stringByAppendingString:@"/Hunting/NWI.slt"];
        _pathNWIBin = [_documentsDirectory stringByAppendingString:@"/Hunting/NWI.bin"];
        _pathFOREST = [_documentsDirectory stringByAppendingString:@"/Hunting/forest.slt"];
        _pathFORESTBin = [_documentsDirectory stringByAppendingString:@"/Hunting/forest.bin"];
        _pathFEESURF = [_documentsDirectory stringByAppendingString:@"/Hunting/feesurf.slt"];
        _pathFEESURFBin = [_documentsDirectory stringByAppendingString:@"/Hunting/feesurf.bin"];
        _usersHuntingData = [_backedUpDirectory stringByAppendingString:@"/UsersHuntingData.slt"];
        
        int fileSize = (NSInteger)[NSFileManager.defaultManager attributesOfItemAtPath:_path
                                                                                 error:nil].fileSize;
        int fileSizeNWI = (NSInteger)[NSFileManager.defaultManager attributesOfItemAtPath:_pathNWI
                                                                             error:nil].fileSize;
        int fileSizeNWIBin = (NSInteger)[NSFileManager.defaultManager attributesOfItemAtPath:_pathNWIBin
                                                                             error:nil].fileSize;
        int fileSizeFOREST = (NSInteger)[NSFileManager.defaultManager attributesOfItemAtPath:_pathFOREST
                                                                             error:nil].fileSize;
        int fileSizeFORESTBin = (NSInteger)[NSFileManager.defaultManager attributesOfItemAtPath:_pathFORESTBin
                                                                             error:nil].fileSize;
        int fileSizeFEESURF = (NSInteger)[NSFileManager.defaultManager attributesOfItemAtPath:_pathFEESURF
                                                                             error:nil].fileSize;
        int fileSizeFEESURFBin = (NSInteger)[NSFileManager.defaultManager attributesOfItemAtPath:_pathFEESURFBin
                                                                             error:nil].fileSize;

        _totRecords = -1;
        _currentRec = 0;
        if (fileSize > 0)
        {
            if ([self open])
            {
                [self close:TRUE];
            }
            
        }
        NSLog(@"Hunting Database init");
    }
    
    return self;
}

- (void)dealloc
{
    [self close:TRUE];
    NSLog(@"Hunting Database dealloc");
}

- (BOOL)open
{
    BOOL rtn = FALSE;
    if (!_isOpen)
    {
        BOOL delete = NO;
        if (delete)
            [NSFileManager.defaultManager removeItemAtPath:_usersHuntingData
                                                     error:nil];
        [self createUsersData];

        _isOpen = !SQLOK(__FILE__,__LINE__,SQLite_Open(_path.UTF8String, &_database), _database);
        NSLog(@"Hunting Database open");
        
        if (_isOpen)
        {
            _fileSize = (NSInteger)[NSFileManager.defaultManager attributesOfItemAtPath:_path
                                                                                  error:nil].fileSize;
            _fileSizeNWI = (NSInteger)[NSFileManager.defaultManager attributesOfItemAtPath:_pathNWI
                                                                                  error:nil].fileSize;
            _fileSizeNWIBin = (NSInteger)[NSFileManager.defaultManager attributesOfItemAtPath:_pathNWIBin
                                                                                  error:nil].fileSize;
            _fileSizeFOREST = (NSInteger)[NSFileManager.defaultManager attributesOfItemAtPath:_pathFOREST
                                                                                  error:nil].fileSize;
            _fileSizeFORESTBin = (NSInteger)[NSFileManager.defaultManager attributesOfItemAtPath:_pathFORESTBin
                                                                                  error:nil].fileSize;
            _fileSizeFEESURF = (NSInteger)[NSFileManager.defaultManager attributesOfItemAtPath:_pathFEESURF
                                                                                  error:nil].fileSize;
            _fileSizeFEESURFBin = (NSInteger)[NSFileManager.defaultManager attributesOfItemAtPath:_pathFEESURFBin
                                                                                  error:nil].fileSize;
            _datasetVersion = [self huntingVersion];
            NSString *attachCmd = [NSString stringWithFormat:@"ATTACH DATABASE '%@' AS NWIDATA",_pathNWI];
            rtn = [self executeCmd:(LPSTR)attachCmd.UTF8String];
            _NWIVersion = [self getNWIVersion];
            _fidNWIBin = fopen (_pathNWIBin.UTF8String,"rb");
            attachCmd = [NSString stringWithFormat:@"ATTACH DATABASE '%@' AS FORESTDATA",_pathFOREST];
            rtn = [self executeCmd:(LPSTR)attachCmd.UTF8String];
            _ForestVersion = [self getForestVersion];
            _fidForestBin = fopen (_pathFORESTBin.UTF8String,"rb");
            attachCmd = [NSString stringWithFormat:@"ATTACH DATABASE '%@' AS FEESURFDATA",_pathFEESURF];
            rtn = [self executeCmd:(LPSTR)attachCmd.UTF8String];
            _FEESURFVersion = [self getFEESURFVersion];
            _fidFEESURFBin = fopen (_pathFEESURFBin.UTF8String,"rb");
            attachCmd = [NSString stringWithFormat:@"ATTACH DATABASE '%@' AS USERDATA",_usersHuntingData];
            rtn = [self executeCmd:(LPSTR)attachCmd.UTF8String];
       }
    }
    return rtn;
}

-(BOOL) createUsersData
{
    BOOL rtn = TRUE;
    _isOpen = !SQLOK(__FILE__,__LINE__,SQLite_Open(_usersHuntingData.UTF8String, &_database), _database);
    NSString *cmd = @"CREATE TABLE IF NOT EXISTS UserWayPoints (id INTEGER PRIMARY KEY AUTOINCREMENT,Name CHAR(32), Type CHAR(32), LAT DOUBLE,LON DOUBLE, TimeCreated INT, Description CHAR(256), DisplayOnCompass INT)";
    rtn = !SQLOK(__FILE__,__LINE__, SQLiteExec(_database, cmd.UTF8String, 0, 0, 0), _database);
    cmd = @"CREATE TABLE IF NOT EXISTS TrackRoutes (id INTEGER PRIMARY KEY AUTOINCREMENT,TimeSaved INT, TimeCreated INT, LAT double, LON double)";
    rtn = !SQLOK(__FILE__,__LINE__, SQLiteExec(_database, cmd.UTF8String, 0, 0, 0), _database);
    SQLOK(__FILE__,__LINE__,SQLite_Close(&_database),_database);
    _isOpen = FALSE;
    return rtn;
}

-(int) deleteAllWaypoints
{
    BOOL opened = [self open];
    NSString *cmd;
    BOOL rtn;
    
    cmd = [NSString stringWithFormat:@"DELETE FROM USERDATA.UserWayPoints"];
    rtn = !SQLOK(__FILE__,__LINE__, SQLiteExec(_database, cmd.UTF8String, 0, 0, 0), _database);
    [self close:opened];
    return rtn;
}
-(int) deleteWaypointsOfType:(NSString*)type
{
    BOOL opened = [self open];
    NSString *cmd;
    BOOL rtn;
    
    cmd = [NSString stringWithFormat:@"DELETE FROM USERDATA.UserWayPoints WHERE type = '%@'",type];
    rtn = !SQLOK(__FILE__,__LINE__, SQLiteExec(_database, cmd.UTF8String, 0, 0, 0), _database);
    [self close:opened];
    return rtn;

}
-(int) deleteWaypointsWithName:(NSString*)name
{
    BOOL opened = [self open];
    NSString *cmd;
    BOOL rtn;
    
    cmd = [NSString stringWithFormat:@"DELETE FROM USERDATA.UserWayPoints WHERE name = '%@'",name];
    rtn = !SQLOK(__FILE__,__LINE__, SQLiteExec(_database, cmd.UTF8String, 0, 0, 0), _database);
    [self close:opened];
    return rtn;

}
-(int) deleteWaypointWithRefno:(int)refno
{
    BOOL opened = [self open];
    NSString *cmd;
    BOOL rtn;
    
    cmd = [NSString stringWithFormat:@"DELETE FROM USERDATA.UserWayPoints WHERE id = %i",refno];
    rtn = !SQLOK(__FILE__,__LINE__, SQLiteExec(_database, cmd.UTF8String, 0, 0, 0), _database);
    [self close:opened];
    return rtn;

}
-(void) saveTrackRoute:(NSArray*)trackRoutePoints
{
    BOOL opened = [self open];
    int saveTime = NSDate.timeIntervalSinceReferenceDate;
    NSString *cmd;
    BOOL rtn;
    for (TrackRoutePoint *tpt in CRAPI.sharedInstance.currentTrackRoute)
    {
        cmd = [NSString stringWithFormat:@"INSERT INTO USERDATA.TrackRoutes (TimeSaved,TimeCreated,LAT,LON) VALUES(%i,%i,%f,%f)",saveTime,tpt.time,tpt.latlon.lat,tpt.latlon.lon];
        rtn = !SQLOK(__FILE__,__LINE__, SQLiteExec(_database, cmd.UTF8String, 0, 0, 0), _database);
    }

    [self close:opened];

}

-(NSArray *) getTrackRoutes
{
    NSMutableArray *array = NSMutableArray.new;
    BOOL opened = [self open];
    NSString *query = [NSString stringWithFormat:@"SELECT DISTINCT TimeSaved FROM USERDATA.TrackRoutes"];
    
    sqlite3_stmt *statement = NULL;
    
    int st = SQLOKpd(SQLitePrepare(_database, query.UTF8String, -1, &statement, 0), _database, 6);
    while (sqlite3_step(statement) == SQLITE_ROW)
    {
        int i = 0;
        int refno = sqlite3_column_int(statement, i++);
        NSNumber *ref = [NSNumber  numberWithInt:refno];
        [array addObject:ref];
    }
    
    SQLOKpd(SQLiteFinalize(statement), _database, 7);

    [self close:opened];

    
    return array;
}

-(NSString *)getTrackInfo:(int)savedTime
{
    NSString *info = @"";
    BOOL opened = [self open];
    NSString *query = [NSString stringWithFormat:@"SELECT TimeCreated,LAT,LON FROM USERDATA.TrackRoutes WHERE TimeSaved = %i ORDER BY TimeCreated",savedTime];
    
    sqlite3_stmt *statement = NULL;
    int timeCreated = 0;
    int firstTime = 0;
    LLPOINT lastPoint;
    double totDist = 0;
    int st = SQLOKpd(SQLitePrepare(_database, query.UTF8String, -1, &statement, 0), _database, 6);
    while (sqlite3_step(statement) == SQLITE_ROW)
    {
        int i = 0;
        timeCreated = sqlite3_column_int(statement, i++);
        double lat = sqlite3_column_double(statement, i++);
        double lon = sqlite3_column_double(statement, i++);
        LLPOINT pt;
        pt.lat = lat;
        pt.lon = lon;
        if (!firstTime)
        {
            firstTime = timeCreated;
            lastPoint = pt;
        }
        else
        {
            double dist = ArcDistanceLL(lastPoint, pt);
            totDist += dist;
        }
    }
    SQLOKpd(SQLiteFinalize(statement), _database, 7);
    double totMiles = totDist / METERS_PER_MILE;
    int minutes = timeCreated - firstTime;
    info = [NSString stringWithFormat:@"%i Minutes (%.2f Miles)",minutes,totMiles];
    [self close:opened];
 
    return info;
}
-(BOOL)addWaypoint:(NSString*)name
              type:(NSString *)type
            latlon:(LLPOINT)ll
       description:(NSString *)desc
  displayOnCompass:(BOOL)displayOnCompass
{
    BOOL opened = [self open];
    int iTime = NSDate.timeIntervalSinceReferenceDate;
    NSString *cmd;
    BOOL rtn;
    
    if ([type isEqual:@"Vehicle"])
    {
        cmd = [NSString stringWithFormat:@"DELETE FROM USERDATA.UserWayPoints WHERE Type = 'Vehicle'"];
        rtn = !SQLOK(__FILE__,__LINE__, SQLiteExec(_database, cmd.UTF8String, 0, 0, 0), _database);
    }
    cmd = [NSString stringWithFormat:@"INSERT INTO USERDATA.UserWayPoints (Name,Type,LAT,LON,TimeCreated,Description,DisplayOnCompass) VALUES('%@','%@',%f,%f,%i,'%@',%i)",name,type,ll.lat,ll.lon,iTime,desc,displayOnCompass];
    rtn = !SQLOK(__FILE__,__LINE__, SQLiteExec(_database, cmd.UTF8String, 0, 0, 0), _database);
    [self close:opened];
    return rtn;
}
-(NSArray *)getWaypoints
{
    NSMutableArray *array = NSMutableArray.new;
    BOOL opened = [self open];
    NSString *query = [NSString stringWithFormat:@"SELECT * FROM USERDATA.UserWayPoints"];
    
    sqlite3_stmt *statement = NULL;
    
    int st = SQLOKpd(SQLitePrepare(_database, query.UTF8String, -1, &statement, 0), _database, 6);
    while (sqlite3_step(statement) == SQLITE_ROW)
    {
        int i = 0;
        int refno = sqlite3_column_int(statement, i++);
        LPSTR name = (LPSTR)sqlite3_column_text(statement, i++);
        LPSTR type = (LPSTR)sqlite3_column_text(statement, i++);
        double lat = sqlite3_column_double(statement, i++);
        double lon = sqlite3_column_double(statement, i++);
        int itime = sqlite3_column_int(statement, i++);
        LPSTR desc = (LPSTR)sqlite3_column_text(statement, i++);
        int displayOnCompass = sqlite3_column_int(statement, i++);
        LLPOINT latlon;
        latlon.lat = lat;
        latlon.lon = lon;
        UserWaypoint * wp = UserWaypoint.new;
        wp.refno = refno;
        wp.name = [NSString stringWithUTF8String:name];
        wp.name = [wp.name stringByReplacingOccurrencesOfString:@".id" withString:[NSString stringWithFormat:@"%i",refno]];
        wp.type = [NSString stringWithUTF8String:type];
        wp.desc = [NSString stringWithUTF8String:desc];
        wp.time = itime;
        wp.displayOnCompass = displayOnCompass;
        wp.latlon = latlon;
        [array addObject:wp];
    }
    
    SQLOKpd(SQLiteFinalize(statement), _database, 7);

    [self close:opened];
    return array;
}
-(NSArray *)getWaypointsOfType:(NSString *)wantType
{
    NSMutableArray *array = NSMutableArray.new;
    BOOL opened = [self open];
    NSString *query = [NSString stringWithFormat:@"SELECT * FROM USERDATA.UserWayPoints WHERE type = '%@' ORDER BY id",wantType];
    
    sqlite3_stmt *statement = NULL;
    
    int st = SQLOKpd(SQLitePrepare(_database, query.UTF8String, -1, &statement, 0), _database, 6);
    while (sqlite3_step(statement) == SQLITE_ROW)
    {
        int i = 0;
        int refno = sqlite3_column_int(statement, i++);
        LPSTR name = (LPSTR)sqlite3_column_text(statement, i++);
        LPSTR type = (LPSTR)sqlite3_column_text(statement, i++);
        double lat = sqlite3_column_double(statement, i++);
        double lon = sqlite3_column_double(statement, i++);
        int itime = sqlite3_column_int(statement, i++);
        LPSTR desc = (LPSTR)sqlite3_column_text(statement, i++);
        int displayOnCompass = sqlite3_column_int(statement, i++);
        LLPOINT latlon;
        latlon.lat = lat;
        latlon.lon = lon;
        UserWaypoint * wp = UserWaypoint.new;
        wp.refno = refno;
        wp.name = [NSString stringWithUTF8String:name];
        wp.name = [wp.name stringByReplacingOccurrencesOfString:@".id" withString:[NSString stringWithFormat:@"%i",refno]];
        wp.type = [NSString stringWithUTF8String:type];
        wp.desc = [NSString stringWithUTF8String:desc];
        wp.time = itime;
        wp.displayOnCompass = displayOnCompass;
        wp.latlon = latlon;
        [array addObject:wp];
    }
    
    SQLOKpd(SQLiteFinalize(statement), _database, 7);

    [self close:opened];
    return array;
}
- (BOOL)executeCmd:(LPCSTR)cmd
{
    BOOL rtn = !SQLOK(__FILE__,__LINE__,SQLiteExec(_database, cmd, 0, 0, 0), _database);
    return rtn;
}

- (NSString *) huntingVersion
{
    NSString *version = @"-1";
    NSString *query = [NSString stringWithFormat:@"SELECT VersionNum FROM VERSION"];
    
    sqlite3_stmt *statement = NULL;
    
    int st = SQLOKpd(SQLitePrepare(_database, query.UTF8String, -1, &statement, 0), _database, 6);
    
    if (sqlite3_step(statement) == SQLITE_ROW)
    {
        LPSTR ver = (LPSTR)sqlite3_column_text(statement, 0);
        version = [NSString stringWithUTF8String:ver];
    }
    
    SQLOKpd(SQLiteFinalize(statement), _database, 7);
    /*
    query = [NSString stringWithFormat:@"SELECT COORDFactor FROM VERSION"];
    
    st = SQLOKpd(SQLitePrepare(_database, query.UTF8String, -1, &statement, 0), _database, 6);
    
    if (sqlite3_step(statement) == SQLITE_ROW)
    {
        double factor = sqlite3_column_double(statement, 0);
        _huntingFactor = factor;
    }
    
    SQLOKpd(SQLiteFinalize(statement), _database, 7);
     */
    st = query_rtree_bbox(_database->db, "ROADS_LINE_index", &_RoadsBounds);
    return version;
}

- (NSString *) getNWIVersion
{
    NSString *version = @"-1";
    NSString *query = [NSString stringWithFormat:@"SELECT VersionNum FROM NWIDATA.NWI_Version"];
    
    sqlite3_stmt *statement = NULL;
    
    SQLOKpd(SQLitePrepare(_database, query.UTF8String, -1, &statement, 0), _database, 6);
    
    if (sqlite3_step(statement) == SQLITE_ROW)
    {
        LPSTR ver = (LPSTR)sqlite3_column_text(statement, 0);
        version = [NSString stringWithUTF8String:ver];
    }
    
        
    SQLOKpd(SQLiteFinalize(statement), _database, 7);
    query = [NSString stringWithFormat:@"SELECT COORDFactor FROM NWIDATA.NWI_VERSION"];
    
    int st = SQLOKpd(SQLitePrepare(_database, query.UTF8String, -1, &statement, 0), _database, 6);
    if (st == SQLITE_OK)
    {
        if (sqlite3_step(statement) == SQLITE_ROW)
        {
            double factor = sqlite3_column_double(statement, 0);
            _NWIFactor = factor;
        }
    }
    
    SQLOKpd(SQLiteFinalize(statement), _database, 7);

    st = query_rtree_bbox(_database->db, "NWI_index", &_NWIBounds);
    _NWIBounds.xmn /= _NWIFactor;
    _NWIBounds.xmx /= _NWIFactor;
    _NWIBounds.ymn /= _NWIFactor;
    _NWIBounds.ymx /= _NWIFactor;

    return version;
}
- (NSString *) getForestVersion
{
    NSString *version = @"-1";
    NSString *query = [NSString stringWithFormat:@"SELECT VersionNum FROM FORESTDATA.FOREST_Version"];
    
    sqlite3_stmt *statement = NULL;
    
    SQLOKpd(SQLitePrepare(_database, query.UTF8String, -1, &statement, 0), _database, 6);
    
    if (sqlite3_step(statement) == SQLITE_ROW)
    {
        LPSTR ver = (LPSTR)sqlite3_column_text(statement, 0);
        version = [NSString stringWithUTF8String:ver];
    }
    SQLOKpd(SQLiteFinalize(statement), _database, 7);
    query = [NSString stringWithFormat:@"SELECT COORDFactor FROM FORESTDATA.FOREST_VERSION"];
    
    int st = SQLOKpd(SQLitePrepare(_database, query.UTF8String, -1, &statement, 0), _database, 6);
    if (st == SQLITE_OK)
    {
        if (sqlite3_step(statement) == SQLITE_ROW)
        {
            double factor = sqlite3_column_double(statement, 0);
            _ForestFactor = factor;
        }
    }
    
    SQLOKpd(SQLiteFinalize(statement), _database, 7);

    st = query_rtree_bbox(_database->db, "FOREST_index", &_ForestBounds);
    _ForestBounds.xmn /= _NWIFactor;
    _ForestBounds.xmx /= _NWIFactor;
    _ForestBounds.ymn /= _NWIFactor;
    _ForestBounds.ymx /= _NWIFactor;

    return version;
}
- (NSString *) getFEESURFVersion
{
    NSString *version = @"-1";
    NSString *query = [NSString stringWithFormat:@"SELECT VersionNum FROM FEESURFDATA.FEESURF_Version"];
    
    sqlite3_stmt *statement = NULL;
    
    SQLOKpd(SQLitePrepare(_database, query.UTF8String, -1, &statement, 0), _database, 6);
    
    if (sqlite3_step(statement) == SQLITE_ROW)
    {
        LPSTR ver = (LPSTR)sqlite3_column_text(statement, 0);
        version = [NSString stringWithUTF8String:ver];
    }
    SQLOKpd(SQLiteFinalize(statement), _database, 7);
    query = [NSString stringWithFormat:@"SELECT COORDFactor FROM FEESURFDATA.FEESURF_VERSION"];
    
    int st = SQLOKpd(SQLitePrepare(_database, query.UTF8String, -1, &statement, 0), _database, 6);
    if (st == SQLITE_OK)
    {
        if (sqlite3_step(statement) == SQLITE_ROW)
        {
            double factor = sqlite3_column_double(statement, 0);
            _ForestFactor = factor;
        }
    }
    
    SQLOKpd(SQLiteFinalize(statement), _database, 7);

    st = query_rtree_bbox(_database->db, "FEESURF_index", &_ForestBounds);
    _FEESURFBounds.xmn /= _NWIFactor;
    _FEESURFBounds.xmx /= _NWIFactor;
    _FEESURFBounds.ymn /= _NWIFactor;
    _FEESURFBounds.ymx /= _NWIFactor;

    return version;
}

- (void)close:(BOOL)opened
{
    if (opened && _isOpen)
    {
        SQLOK(__FILE__,__LINE__,SQLite_Close(&_database),_database);
        fclose(_fidNWIBin);
        fclose(_fidForestBin);
        fclose(_fidFEESURFBin);
        NSLog(@"Hunting Database close");
        _isOpen = NO;
    }
}

- (void)clear
{
    [self close:TRUE];
    
    //BOOL st = [NSFileManager.defaultManager removeItemAtPath:_path
    //error:nil];
}

@end
