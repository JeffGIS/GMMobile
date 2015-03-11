//  SewerData.h
//  GMMobile

#define COORDINATE_FACTOR 10000000.0
#define GET_SANPLAT 11

#define LINE_PASS 1
#define TEXT_PASS 2
#define TRACE_PASS 2

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

- (void)setTrans:(CORNERPOINTS *)corners
      viewBounds:(MNMXCORD *)pvbounds;

- (void)displayPlats:(CGContextRef)context
                type:(NSString*)platType
           llCorners:(CORNERPOINTS *) latlonCornerPoints
              LLBounds:(MNMXCORD *)platlonBounds
            viewBounds:(MNMXCORD *)pvbounds;

-(void)displayStormLine:(CGContextRef)context
                   pass:(int)pass
              llCorners:(CORNERPOINTS *) latlonCornerPoints
              LLBounds:(MNMXCORD *)platlonBounds
            viewBounds:(MNMXCORD *)pvbounds;

- (void)drawStormLine:(CGContextRef)context
                 pass:(int)pass
              nPoints:(int)np
               points:(LPDPOINT)pPoints
            withColor:(CGColorRef)color
             andWidth:(CGFloat)width
              andText:(NSString *)text
          andPointers:(BOOL)addPointers;

-(void)displayStormPoint:(CGContextRef)context
               llCorners:(CORNERPOINTS *) latlonCornerPoints
               LLBounds:(MNMXCORD *)platlonBounds
             viewBounds:(MNMXCORD *)pvbounds;

- (int)pickSewer:(LLPOINT *)pt
   highlightList:(NSMutableArray *)hlist;

- (int)pickSanPlat:(LLPOINT *)pt;
- (NSString *)getSanPlatIDFromRefno:(int)refno;
- (NSMutableArray *)getAllSanPlats;


- (BOOL)loadPlat:(NSString *)platID
    usingPopover:(GSSiPopoverView *)popover
     andDelegate:(id)delegate;

@end