//
//  HuntingSeasonData.m
//  NVMobile
//
//  Created by Jeff Smith on 10/6/25.
//  Copyright © 2025 GSSi. All rights reserved.
//

#import "HuntingSeasonData.h"

@implementation HuntingSeasonData

- (id)init
{
    self = [super init];
    
    if (self)
    {
        _documentsDirectory = UserDefaults.defaults.nonBackedUpFilePath;
        _path = [NSBundle.mainBundle pathForResource:@"areapoly"
                                              ofType:@"slt"];
        int fileSize = (NSInteger)[NSFileManager.defaultManager attributesOfItemAtPath:_path
                                                                              error:nil].fileSize;
        NSLog(@"Season Database init");
    }
    
    return self;
}

- (void)dealloc
{
    [self close:TRUE];
    NSLog(@"Season Database dealloc");
}

- (BOOL)open
{
    BOOL rtn = FALSE;
    if (!_isOpen)
    {
        _isOpen = !SQLOK(__FILE__,__LINE__,SQLite_Open(_path.UTF8String, &_database), _database);
        NSLog(@"Season Database open");
        
        if (_isOpen)
            rtn = TRUE;
    }
    return rtn;
}

- (void)close:(BOOL)opened
{
    if (opened && _isOpen)
    {
        SQLOK(__FILE__,__LINE__,SQLite_Close(&_database),_database);
        NSLog(@"Boundary Database close");
        _isOpen = NO;
    }
}

- (void)clear
{
    [self close:TRUE];
    
}

- (int) datasetVersion
{
    int rtn = -1;
    BOOL opened = [self open];
    if (_isOpen && _fileSize > 0)
    {
        NSString *query = [NSString stringWithFormat:@"SELECT VersionNum FROM HUNTING_SEASONS"];
        
        sqlite3_stmt *statement = NULL;
        
        BOOL st = SQLOK(__FILE__,__LINE__,SQLitePrepare(_database, query.UTF8String, -1, &statement, 0), _database);;
        if (st)
        {
            
            if (sqlite3_step(statement) == SQLITE_ROW)
            {
                LPSTR version = (LPSTR)sqlite3_column_text(statement, 0);
                
                if (version)
                    rtn = atoi(version);
            }
            
            SQLOK(__FILE__,__LINE__,SQLiteFinalize(statement), _database);
        }
    }
    [self close:opened];
    return rtn;
}

- (BOOL)executeCmd:(char *)cmd
{
    BOOL rtn = !SQLOK(__FILE__,__LINE__,SQLiteExec(_database, cmd, 0, 0, 0), _database);
    return rtn;
}

- (void)startTransaction
{
    [self open];
    SQLOK(__FILE__,__LINE__,SQLiteExec(_database, "BEGIN", 0, 0, 0), _database);
}

- (void)commitTransaction
{
    SQLOK(__FILE__,__LINE__,SQLiteExec(_database, "COMMIT", 0, 0, 0),_database);
}

- (void)setLabel:(UILabel *)label
{
    
}

@end
