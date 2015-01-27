//  PropertyData.h
//  GMMobile

#import <sqlite3.h>
#import "../../CCodeLibrary/CCodeLibrary/CCodeLibrary.h"

@interface PropertyData : NSObject <FTPDataPullDelegate,GSSiPopoverViewDelegate>

@property sqlite3 *database;
@property (nonatomic) BOOL isOpen;
@property NSString *documentsDirectory;
@property NSString *fileName;
@property (nonatomic, copy) NSString *path;

- (void)            clear;
- (BOOL)            executeCmd:(char*) cmd;
- (void)            startTransaction;
- (void)            commitTransaction;
- (NSMutableArray *)getPIDsMatchingString:(NSString *)matchChar;
- (NSMutableArray *)getPIDsMatchingAddress:(int)houseNumber streetName:(NSString *)matchChar;
- (LLPOINT)         getPointForPID:(NSString*)PID;
- (NSString*)       pickPID:(LLPOINT)pt;

@end