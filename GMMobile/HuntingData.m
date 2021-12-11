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
@property NSInteger fileSize;
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
        _documentsDirectory = UserDefaults.defaults.nonBackedUpFilePath;
        _path = [_documentsDirectory stringByAppendingString:@"/Hunting/HuntingData.slt"];
        _pathNWI = [_documentsDirectory stringByAppendingString:@"/Hunting/NWI.slt"];
        
        int fileSize = (NSInteger)[NSFileManager.defaultManager attributesOfItemAtPath:_path
                                                                                 error:nil].fileSize;
        int fileSizeNWI = (NSInteger)[NSFileManager.defaultManager attributesOfItemAtPath:_pathNWI
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
            _datasetVersion = [self huntingVersion];
            NSString *attachCmd = [NSString stringWithFormat:@"ATTACH DATABASE '%@' AS NWIDATA",_pathNWI];
            rtn = [self executeCmd:(LPSTR)attachCmd.UTF8String];
            _NWIVersion = [self getNWIVersion];
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
    
    SQLOKpd(SQLitePrepare(_database, query.UTF8String, -1, &statement, 0), _database, 6);
    
    if (sqlite3_step(statement) == SQLITE_ROW)
    {
        LPSTR ver = (LPSTR)sqlite3_column_text(statement, 0);
        version = [NSString stringWithUTF8String:ver];
    }
    
    SQLOKpd(SQLiteFinalize(statement), _database, 7);
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
    return version;
}

- (void)close:(BOOL)opened
{
    if (opened && _isOpen)
    {
        SQLOK(__FILE__,__LINE__,SQLite_Close(&_database),_database);
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
