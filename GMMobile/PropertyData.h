//  PropertyData.h
//  GMMobile

#import <sqlite3.h>
#import "../../CCodeLibrary/CCodeLibrary/CCodeLibrary.h"

typedef NS_ENUM(NSInteger, PropDataOption)
{
    PDSettingDefault,
    PDSettingRank,
    PDSettingComputed,
};

@interface BoundaryAreaData : NSObject
@property NSString* name;
@property int refno;
@end

@interface PropertyData : NSObject <FTPDataPullDelegate,GSSiPopoverViewDelegate>

@property sqlite3 *database;
@property (nonatomic) BOOL isOpen;
@property (nonatomic, copy) NSString *documentsDirectory;
@property (nonatomic, copy) NSString *fileName;
@property (nonatomic, copy) NSString *path;
@property LPTRANDATA pTranLLtoView;
@property LPTRANDATA pTranViewtoLL;
@property long long fileSize;

- (void)open;
- (void)close;
- (void)clear;
- (BOOL)executeCmd:(char *)cmd;
- (void)startTransaction;
- (void)commitTransaction;
- (NSMutableArray *)getPIDsMatchingString:(NSString *)matchChar;

- (NSMutableArray *)getPIDsWithOwnerMatchingString:(NSString *)matchChar
                                           limitOf:(int)lim;

- (NSMutableArray *)getPIDsMatchingAddress:(int)houseNumber
                                streetName:(NSString *)matchChar;

- (LLPOINT)getPointForPID:(NSString *)PID;
- (MNMXCORD) getBoundsForPID:(NSString*)PID;
- (NSString *)pickPID:(LLPOINT*)pt;

- (NSString *)getOwnerNameForPID:(NSString *)PID;

- (void)displayParcels:(CGContextRef)context
              LLBounds:(MNMXCORD *)platlonBounds
            viewBounds:(MNMXCORD *)pvbounds;

-(void)displayParcelText:(CGContextRef)context
                LLBounds:(MNMXCORD *)platlonBounds
              viewBounds:(MNMXCORD *)pvbounds;

- (NSMutableArray *)getReport:(PropDataOption)option
                       forPID:(NSString *)pid;

- (NSMutableArray *)getOwnersMatchingString:(NSString *)string;
- (BOOL)getDistinctUseCodes:(NSString *)outFile;

- (NSMutableArray *)getBoundaryAreaTypes;
- (NSMutableArray *)getBoundaryAreaDataForType:(NSString*)type;
- (MNMXCORD) getBoundaryAreaBounds:(int)refno;

@end