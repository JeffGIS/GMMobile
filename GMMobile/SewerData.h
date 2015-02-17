//  SewerData.h
//  GMMobile

#define GET_SANPLAT 11

#import <sqlite3.h>
#import "../../CCodeLibrary/CCodeLibrary/CCodeLibrary.h"

@interface SewerData : NSObject<FTPDataPullDelegate>

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

- (int)pickSanPlat:(LLPOINT *)pt;
- (NSString*) getSanPlatIDFromRefno:(int)refno;
- (NSMutableArray*) getAllSanPlats;
- (BOOL)loadPlat:(NSString *)platID usingPopover:(GSSiPopoverView*)popover andDelegate:(id)delegate;

@end