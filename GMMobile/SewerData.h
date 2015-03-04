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
@property int processingID;
@property int zoom;

- (void)open;
- (void)close;
- (void)clear;
- (BOOL)executeCmd:(char *)cmd;
- (void)startTransaction;
- (void)commitTransaction;

- (void)displayPlats:(CGContextRef)context
                type:(NSString*)platType
              LLBounds:(MNMXCORD *)platlonBounds
            viewBounds:(MNMXCORD *)pvbounds;

-(void)displayStormLine:(CGContextRef)context

              LLBounds:(MNMXCORD *)platlonBounds
            viewBounds:(MNMXCORD *)pvbounds;

-(void)displayStormPoint:(CGContextRef)context
               LLBounds:(MNMXCORD *)platlonBounds
             viewBounds:(MNMXCORD *)pvbounds;

- (int)pickSewer:(LLPOINT*)pt
          highlightList:(NSMutableArray*)hlist;


- (int)pickSanPlat:(LLPOINT *)pt;
- (NSString *)getSanPlatIDFromRefno:(int)refno;
- (NSMutableArray *)getAllSanPlats;

-(void)tracePipeDownstream:(NSString*)fromFacilityID;

- (BOOL)loadPlat:(NSString *)platID
    usingPopover:(GSSiPopoverView *)popover
     andDelegate:(id)delegate;

@end