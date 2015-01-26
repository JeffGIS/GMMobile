//
//  ProperyData.h
//  GMMobile
//
//  Created by JEFFREY E SMITH on 1/25/15.
//  Copyright (c) 2015 GSSi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>
#import "../../CCodeLibrary/CCodeLibrary/CCodeLibrary.h"

@interface ProperyData : NSObject<FTPDataPullDelegate,GSSiPopoverViewDelegate>

{
    sqlite3 *_database;
}

-(void) clear;
-(void)startTransaction;
-(void)commitTransaction;
-(BOOL) executeCmd:(char*) cmd;
-(NSMutableArray*) getPIDsMatchingString:(NSString*)matchChar;
- (LLPOINT) getPointForPID:(NSString*)PID;

@property BOOL isOpen;
@property NSString *documentsDirectory;
@property NSString *fileName;
@property NSString *path;
@end
