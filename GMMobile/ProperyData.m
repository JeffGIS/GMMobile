//
//  ProperyData.m
//  GMMobile
//
//  Created by JEFFREY E SMITH on 1/25/15.
//  Copyright (c) 2015 GSSi. All rights reserved.
//

#import "ProperyData.h"

@implementation ProperyData
{
    GSSiPopoverView *_popover;
}

static ProperyData *_database;

- (id)init
{
    self = [super init];
    
    if (self)
    {
        NSString *documentsDirectory = UserDefaults.defaults.localFilePath;
        NSString *fileName = @"Property.sqlite";
        self.path = [NSString stringWithFormat:@"%@/%@",documentsDirectory,fileName];
        FTPDataPull *pull = FTPDataPull.pull;
        pull.delegate = self;
        pull.popover = _popover;
        pull.useOnlyPrimaryFTP = NO;
        
        [_popover showAfter:0.5
                  withTitle:@"Get Property File"];
        
        [pull getFile:fileName
        fromDirectory:@"GMMobile"
               toFile:fileName
          toDirectory:documentsDirectory
         forceRefresh:YES];
   }
    
    return self;
}

- (void)dealloc
{
    sqlite3_close(_database);
    NSLog(@"Property Database dealloc");
}

- (void)FTPdidComplete:(int)status
              filePath:(NSString *)path
{
    [_popover hide];
    if (status == FTPStatusOK)
    {
        
    }
}

-(NSMutableArray*) getPIDsMatchingString:(NSString*)matchChar
{
    NSMutableArray* array=[[NSMutableArray alloc]init];
    
    [self open];
 /*   NSString *query = [NSString stringWithFormat:@"SELECT PID FROM PARCELPOINT Where PID LIKE '%@%%'",matchChar];*/
    NSString *query = [NSString stringWithFormat:@"SELECT PIDx FROM PARCELPOINT"];
    sqlite3_stmt *statement;
    
    int st = sqlite3_prepare_v2(_database, query.UTF8String, -1, &statement,0);
    if (st != SQLITE_OK)
        [self logError:st method:"prepare"];
    while (sqlite3_step(statement) == SQLITE_ROW)
    {
        LPSTR cpid = (LPSTR)sqlite3_column_text(statement, 0);
        NSString * pid = [NSString stringWithUTF8String:cpid];
        [array addObject:pid];
    }
    
    SQLOK(sqlite3_finalize(statement), "getPIDsMatchingString");
    
    [self close];
    return array;
}
- (void)open
{
    if (!self.isOpen)
    {
        self.isOpen = !SQLOK(sqlite3_open(self.path.UTF8String, &_database), "open(Property)");
        NSLog(@"Property Database open");
    }
}

- (void)close
{
    sqlite3_close(_database);
    NSLog(@"Property Database close");
    self.isOpen = NO;
}


- (void)startTransaction
{
    [self open];
    SQLOK(sqlite3_exec(_database, "BEGIN", 0, 0, 0),"Start transaction");
}
- (void)commitTransaction
{
    SQLOK(sqlite3_exec(_database, "COMMIT", 0, 0, 0),"End transaction");
}
- (void)logError:(int)sqlReturn
          method:(char *)method
{
    NSLog(@"%@", [NSString stringWithFormat:@"SQLite Error %i in %s = %i:%s",
                  sqlReturn, method, sqlite3_errcode(_database), sqlite3_errmsg(_database)]);
}

int SQLOK(int sqlReturn, char *method)
{
    if (sqlReturn != SQLITE_OK)
    {
        NSLog(@"%@", [NSString stringWithFormat:@"SQLite Error %i in %s = %i:%s",
                      sqlReturn, method, sqlite3_errcode((__bridge sqlite3 *)(_database)), sqlite3_errmsg((__bridge sqlite3 *)(_database))]);
    }
    
    return sqlReturn;
}

@end
