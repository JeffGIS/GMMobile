//  SewerData.h
//  GMMobile

#define GET_SANPLAT 11

#define LINE_PASS   1
#define TEXT_PASS   2

#import <sqlite3.h>
#import "../../CCodeLibrary/CCodeLibrary/CCodeLibrary.h"
#import <CoreText/CoreText.h>

int SQLOKswr(int sqlReturn, char *method);

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
                   pass:(int)pass
              LLBounds:(MNMXCORD *)platlonBounds
            viewBounds:(MNMXCORD *)pvbounds;

-(void)displayStormPoint:(CGContextRef)context
               LLBounds:(MNMXCORD *)platlonBounds
             viewBounds:(MNMXCORD *)pvbounds;

- (int)pickSewer:(LLPOINT)pt
          highlightList:(NSMutableArray*)hlist;


- (int)pickSanPlat:(LLPOINT *)pt;
- (NSString *)getSanPlatIDFromRefno:(int)refno;
- (NSMutableArray *)getAllSanPlats;


- (BOOL)loadPlat:(NSString *)platID
    usingPopover:(GSSiPopoverView *)popover
     andDelegate:(id)delegate;

@end