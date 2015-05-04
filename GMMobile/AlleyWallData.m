//
//  AlleyWallData.m
//  GMMobile
//
//  Created by JEFFREY E SMITH on 4/26/15.
//  Copyright (c) 2015 GSSi. All rights reserved.
//
extern int keepProcessing;

#import "AlleyWallData.h"

@implementation AlleyWallData
static AlleyWallData *_wallData;

int SQLOKawd(int sqlReturn, char *method)
{
    if (sqlReturn != SQLITE_OK)
    {
        [_wallData logError:sqlReturn
                     method:method];
    }
    
    return sqlReturn;
}

- (void)logError:(int)sqlReturn
          method:(char *)method
{
    NSLog(@"%@", [NSString stringWithFormat:@"SQLite Error %i in %s = %i:%s",
                  sqlReturn, method, sqlite3_errcode(_database), sqlite3_errmsg(_database)]);
}

- (BOOL) continue
{
    if (self.processingID == keepProcessing)
        return YES;
    return NO;
}

- (id)init
{
    self = [super init];
    
    if (self)
    {
        _documentsDirectory = UserDefaults.defaults.sharedFilePath;
        _fileName = @"AlleyWalls.sqlite";
        _path = [NSString stringWithFormat:@"%@/%@", _documentsDirectory, _fileName];
        _wallData = (__bridge AlleyWallData *)((__bridge sqlite3 *)((AlleyWallData *)self));
        
    }
    
    return self;
}

- (void)dealloc
{
    sqlite3_close(_database);
    NSLog(@"AlleyWall Database dealloc");
}
- (void)open
{
    if (!_isOpen)
    {
        self.isOpen = YES;
        self.isOpen = !SQLOKawd(sqlite3_open(self.path.UTF8String, &_database), "open(AlleyWall)");
        NSLog(@"AlleyWall Database open");
        
        _fileSize = [NSFileManager.defaultManager attributesOfItemAtPath:_path
                                                                   error:nil].fileSize;
    }
}

- (void)close
{
    SQLOKawd(sqlite3_close(_database),"Close");
    NSLog(@"AlleyWall Database close");
    self.isOpen = NO;
}

- (void)clear
{
    [self close];
    
    //BOOL st = [NSFileManager.defaultManager removeItemAtPath:_path
    //error:nil];
}

- (BOOL)executeCmd:(char *)cmd
{
    BOOL rtn = !SQLOKawd(sqlite3_exec(_database, cmd, 0, 0, 0), "Execute cmd");
    return rtn;
}

- (void)startTransaction
{
    [self open];
    SQLOKawd(sqlite3_exec(_database, "BEGIN", 0, 0, 0), "Start transaction");
}

- (void)commitTransaction
{
    SQLOKawd(sqlite3_exec(_database, "COMMIT", 0, 0, 0), "End transaction");
}
-(int) getAlleyLineStatus:(NSInteger)refno
{
    int status = 0;
    [self open];
    
    NSString *query = [NSString stringWithFormat:@"SELECT ALLEY_LINE.CHECKED FROM ALLEY_LINE WHERE  ALLEY_LINE.id=%li",(long)refno];
    
    sqlite3_stmt *statement;
    
    SQLOK(sqlite3_prepare_v2(self.database, query.UTF8String, -1, &statement, 0), "preparePickPLAT");
    
    if (sqlite3_step(statement) == SQLITE_ROW)
    {
        int checked = sqlite3_column_int(statement, 0);
        status = checked;
    }
    
    SQLOK(sqlite3_finalize(statement), "pickAlley");
    [self close];
    
    return status;
}
-(void) setAlleyLineStatus:(NSInteger)refno to:(int)status
{
    [self open];
    NSString *cmd = [NSString stringWithFormat:@"UPDATE ALLEY_LINE SET CHECKED = %i WHERE id=%ld",status,refno];
    [self executeCmd:(LPSTR)cmd.UTF8String];
    [self close];
}
-(BOOL)deleteAlleyWallPoint:(NSInteger)refno
{
    BOOL rtn=FALSE;
    [self open];
    NSString *cmd = [NSString stringWithFormat:@"UPDATE ALLEYWALLS SET LATITUDE = 0,LONGITUDE = 0 WHERE id=%ld",refno];
    rtn = [self executeCmd:(LPSTR)cmd.UTF8String];
    [self close];
    return rtn;
}

-(BOOL)createNewWallPoint:(CLLocationCoordinate2D)position
{
/*    INSERT INTO ALLEYWALLS VALUES(1,'6119.1',3536,'10TH AVE S','Yes',100.000000,2.000000,6.500000,'',' $20,000.00 ','CONCBLOCK  POURED','1/27/1987','MB','7','GOOD.  MINOR CRACKS.  ',-93.260388,44.938210,1,0)
    INSERT INTO ALLEYWALLS_index VALUES(2,-93.260613,-93.260613,44.936725,44.936725);
SELECT max(_id) FROM MyTable*/
    BOOL rtn=FALSE;
    NSInteger refno=0;
    [self open];
    NSString *query = [NSString stringWithFormat:@"SELECT max(id) FROM ALLEYWALLS"];
    
    sqlite3_stmt *statement;
    
    SQLOK(sqlite3_prepare_v2(self.database, query.UTF8String, -1, &statement, 0), "");
    
    if (sqlite3_step(statement) == SQLITE_ROW)
    {
        int checked = sqlite3_column_int(statement, 0);
        refno = checked+1;
    }
    
    SQLOK(sqlite3_finalize(statement), "");
 //   NSString *cmd = [NSString stringWithFormat:@"INSERT INTO ALLEYWALLS VALUES(%ld,'6119.1',3536,'10TH AVE S','',,,,'','','','','','','',%f,%f,1,0);",refno,position.longitude,position.latitude];
    NSString *cmd = [NSString stringWithFormat:@"INSERT INTO ALLEYWALLS VALUES(%ld,'6119.1',3536,'10TH AVE S','Yes',100.000000,2.000000,6.500000,'',' $20,000.00 ','CONCBLOCK  POURED','1/27/1987','MB','7','GOOD.  MINOR CRACKS.  ',%f,%f,1,0);",refno,position.longitude,position.latitude];
    rtn = [self executeCmd:(LPSTR)cmd.UTF8String];
    cmd = [NSString stringWithFormat:@"INSERT INTO ALLEYWALLS_index VALUES(%ld,%f,%f,%f,%f)",refno,position.longitude,position.longitude,position.latitude,position.latitude];
    rtn = [self executeCmd:(LPSTR)cmd.UTF8String];
    [self close];
    return rtn;
}


@end
