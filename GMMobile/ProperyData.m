//
//  ProperyData.m
//  GMMobile
//
//  Created by JEFFREY E SMITH on 1/25/15.
//  Copyright (c) 2015 GSSi. All rights reserved.
//

#import "ProperyData.h"

@implementation ProperyData

static ProperyData *_database;

-(NSMutableArray*) getPIDsMatchingString:(NSString*)matchChar
{
    NSMutableArray* array=[[NSMutableArray alloc]init];
    
    return array;
}
- (void)open
{
    if (!self.isOpen)
    {
        self.isOpen = !SQLOK(sqlite3_open(self.path.UTF8String, &_database), "open(Property)");
        NSLog(@"Intersections Database open");
    }
}

- (void)close
{
    sqlite3_close(_database);
    NSLog(@"Property Database close");
    self.isOpen = NO;
}

- (void)dealloc
{
    sqlite3_close(_database);
    NSLog(@"Property Database dealloc");
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
        [_database logError:sqlReturn
                     method:method];
    }
    
    return sqlReturn;
}

@end
