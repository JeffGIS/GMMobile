//
//  DTMData.m
//  NVMobile
//
//  Created by Jeff Smith on 1/4/23.
//  Copyright © 2023 GSSi. All rights reserved.
//

#import "DTMData.h"

@interface DTMData ()

@property (nonatomic, copy) NSString *documentsDirectory;
@property (nonatomic, copy) NSString *backedUpDirectory;
@property (nonatomic, copy) NSString *fileName;
@property (nonatomic, copy) NSString *pathDTM;
@property (nonatomic, copy) NSString *pathDTM_BIN;
@property NSInteger fileSize;
@property NSInteger fileSizeDTM;
@property NSInteger fileSizeDTM_BIN;
@end

@implementation DTMData

- (id)init
{
    self = [super init];
    
    if (self)
    {
        _documentsDirectory = UserDefaults.defaults.nonBackedUpFilePath;
        _backedUpDirectory = UserDefaults.defaults.localFilePath;
        _pathDTM = [_documentsDirectory stringByAppendingString:@"/DTM/mndtm1.dts"];
        _pathDTM_BIN = [_documentsDirectory stringByAppendingString:@"/DTM/mndtm1.bin"];
        

        NSLog(@"DTM Database init");
    }
    
    return self;
}

- (void)dealloc
{
    [self close:TRUE];
    NSLog(@"DTM Database dealloc");
}

- (BOOL)open
{
    BOOL rtn = FALSE;
    if (!_isOpen)
    {
        BOOL delete = NO;
        if (delete)
            [NSFileManager.defaultManager removeItemAtPath:_pathDTM
                                                     error:nil];
        
        NSLog(@"DTM Database open");
        
        int fileSize = (NSInteger)[NSFileManager.defaultManager attributesOfItemAtPath:_pathDTM
                                                                                 error:nil].fileSize;
        int fileSizeBIN = (NSInteger)[NSFileManager.defaultManager attributesOfItemAtPath:_pathDTM_BIN
                                                                                    error:nil].fileSize;
        if (fileSize > 0 && fileSizeBIN > 0)
        {
//            _fidDTM = fopen (_pathDTM.UTF8String,"rb");
            _isOpen = !SQLOK(__FILE__,__LINE__,SQLite_Open(_pathDTM.UTF8String, &_database), _database);

            _fidDTM_BIN = fopen (_pathDTM_BIN.UTF8String,"rb");
            char file[MAX_PATH];
            strncpy (file,_pathDTM.UTF8String,MAX_PATH);
            file[_pathDTM.length]= 0;
            _NullElv = DBL_MAX;
            _hDTM = DTMOpen (file, _NullElv,_database,_fidDTM_BIN,&_surfType);
            
            _version = [self DTMVersion];
            rtn = YES;
            _isOpen = YES;
        }
    }
    return rtn;
}
- (void)close:(BOOL)opened
{
    if (opened && _isOpen)
    {
//        fclose(_fidDTM);
        SQLOK(__FILE__,__LINE__,SQLite_Close(&_database),_database);

        fclose(_fidDTM_BIN);
        DTMClose (&_hDTM);
        NSLog(@"DTM Database close");
        _isOpen = NO;
    }
}

- (int) DTMVersion
{
    int version = 0;
    NSString *query = [NSString stringWithFormat:@"SELECT Version FROM DTMINFO"];
    
    sqlite3_stmt *statement = NULL;
    
    int st = SQLOKpd(SQLitePrepare(_database, query.UTF8String, -1, &statement, 0), _database, 6);
    
    if (sqlite3_step(statement) == SQLITE_ROW)
    {
        version = (LPSTR)sqlite3_column_int(statement, 0);
    }
    SQLOKpd(SQLiteFinalize(statement), _database, 7);

    return version;
}

-(double)getElevation:(LLPOINT *)llpoint
{
    double elv = _NullElv;
    DPOINT dtmPoint;
    
    dtmPoint.x = 573180.1;
    dtmPoint.y = 5278670.7;
    
    elv = NGIELV (dtmPoint,_hDTM,0);
    return elv;
    
}
@end
