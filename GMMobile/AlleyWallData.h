//  AlleyWallData.h
//  GMMobile

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
-(BOOL)createNewWall:(NSString*)wallID atPoint:(CLLocationCoordinate2D)position;
-(NSString *)nearestAlleyLine:(CLLocationCoordinate2D *)pt;
-(NSString *)getNextWallForAlley:(NSString*)nearestAlley;

@end