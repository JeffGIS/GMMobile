//
//  AlleyWallData.h
//  GMMobile
//
//  Created by JEFFREY E SMITH on 4/26/15.
//  Copyright (c) 2015 GSSi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>
#import "CCodeLibrary/CCodeLibrary.h"

@interface AlleyWallData : NSObject
@property sqlite3 *database;
@property (atomic) BOOL isOpen;
@property (atomic) int processingID;
@property (nonatomic, copy) NSString *documentsDirectory;
@property (nonatomic, copy) NSString *fileName;
@property (nonatomic, copy) NSString *path;
@property NSInteger fileSize;
- (void)open;
- (void)close;
- (void)clear;
- (BOOL)executeCmd:(char *)cmd;
- (void)startTransaction;
- (void)commitTransaction;
-(int) getAlleyLineStatus:(NSInteger)refno;
-(void) setAlleyLineStatus:(NSInteger)refno to:(int)status;
-(BOOL)deleteAlleyWallPoint:(NSInteger)refno;
-(BOOL)createNewWallPoint:(CLLocationCoordinate2D)position;

@end
