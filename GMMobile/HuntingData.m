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
@property (nonatomic, copy) NSString *fileName;
@property (nonatomic, copy) NSString *path;
@property (nonatomic, copy) NSString *pathNWI;
@property (nonatomic, copy) NSString *pathNWIBin;
@property (nonatomic, copy) NSString *pathFOREST;
@property (nonatomic, copy) NSString *pathFORESTBin;
@property NSInteger fileSize;
@property NSInteger fileSizeNWI;
@property NSInteger fileSizeNWIBin;
@property NSInteger fileSizeFOREST;
@property NSInteger fileSizeFORESTBin;
@property double acres;
@property INT64 currentRec;
@property int iPass, ii;
@end


@implementation HuntingData
- (id)init
{
    self = [super init];
    
    if (self)
    {
        _huntingFactor = _NWIFactor = COORDINATE_FACTOR;
        _documentsDirectory = UserDefaults.defaults.nonBackedUpFilePath;
        _path = [_documentsDirectory stringByAppendingString:@"/Hunting/HuntingData.slt"];
        _pathNWI = [_documentsDirectory stringByAppendingString:@"/Hunting/NWI.slt"];
        _pathNWIBin = [_documentsDirectory stringByAppendingString:@"/Hunting/NWI.bin"];
        _pathFOREST = [_documentsDirectory stringByAppendingString:@"/Hunting/forest.slt"];
        _pathFORESTBin = [_documentsDirectory stringByAppendingString:@"/Hunting/forest.bin"];

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
            _datasetVersion = [self huntingVersion];
            NSString *attachCmd = [NSString stringWithFormat:@"ATTACH DATABASE '%@' AS NWIDATA",_pathNWI];
            rtn = [self executeCmd:(LPSTR)attachCmd.UTF8String];
            _NWIVersion = [self getNWIVersion];
            _fidNWIBin = fopen (_pathNWIBin.UTF8String,"rb");
            attachCmd = [NSString stringWithFormat:@"ATTACH DATABASE '%@' AS FORESTDATA",_pathFOREST];
            rtn = [self executeCmd:(LPSTR)attachCmd.UTF8String];
           _ForestVersion = [self getForestVersion];
            _fidForestBin = fopen (_pathFORESTBin.UTF8String,"rb");

        }
    }
    return rtn;
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

- (void)close:(BOOL)opened
{
    if (opened && _isOpen)
    {
        SQLOK(__FILE__,__LINE__,SQLite_Close(&_database),_database);
        fclose(_fidNWIBin);
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
