//  PropertyData.h
//  GMMobile

#import <sqlite3.h>
#import "../../CCodeLibrary/CCodeLibrary/CCodeLibrary.h"

@interface PropertyData : NSObject <FTPDataPullDelegate,GSSiPopoverViewDelegate>

@property sqlite3 *database;
@property (nonatomic) BOOL isOpen;
@property (nonatomic, copy) NSString *path;

- (NSMutableArray *)getPIDsMatchingString:(NSString *)matchChar;

@end