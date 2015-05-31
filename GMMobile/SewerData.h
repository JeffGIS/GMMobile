//  SewerData.h
//  GMMobile

#define COORDINATE_FACTOR 10000000.0
#define GET_SANPLATx 11
#define GET_STORMPLAT 12

#define PLAT_TYPE_SANITARY  1
#define PLAT_TYPE_STORM     2

#define LINE_PASS 1
#define TEXT_PASS 2
#define TRACE_PASS 2

#import <sqlite3.h>
#import "CCodeLibrary/CCodeLibrary.h"
#import <CoreText/CoreText.h>

int SQLOKswr(int sqlReturn, sqlite3 *database);


@interface SewerData : NSObject<FTPDataPullDelegate>

@property sqlite3 *database;
@property (nonatomic) int datasetVersion;
@property (nonatomic) BOOL isOpen;
@property (nonatomic, copy) NSString *documentsDirectory;
@property (nonatomic, copy) NSString *fileName;
@property (nonatomic, copy) NSString *path;
@property LPTRANDATA pTranLLtoView;
@property LPTRANDATA pTranViewtoLL;
@property long long fileSize;
@property int processingID;
@property int zoom;

+ (NSString *)getActualPlatFileName:(NSString *)platID;

- (void)open;
- (void)close;
- (void)clear;
- (BOOL)executeCmd:(char *)cmd;
- (void)startTransaction;
- (void)commitTransaction;

-(NSString *)platPathName:(NSString *)platName
                 platType:(int)type;

- (void)setTrans:(CORNERPOINTS *)corners
      viewBounds:(MNMXCORD *)pvbounds;

- (void)displayPlats:(CGContextRef)context
                type:(NSString *)platType
           llCorners:(CORNERPOINTS *) latlonCornerPoints
              LLBounds:(MNMXCORD *)platlonBounds
            viewBounds:(MNMXCORD *)pvbounds;

-(void)displayStormLine:(CGContextRef)context
                   pass:(int)pass
              llCorners:(CORNERPOINTS *) latlonCornerPoints
              LLBounds:(MNMXCORD *)platlonBounds
            viewBounds:(MNMXCORD *)pvbounds;

- (void)highlightStormLine:(CGContextRef)context
                     refno:(int)refno
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
          atZoom:(CGFloat)zoom
   highlightList:(NSMutableArray *)hlist;

- (int)pickSanPlat:(LLPOINT *)pt;
- (NSString *)getPlatIDofType:(NSString*)type fromRefno:(int)refno;
- (NSMutableArray *)getAllSanPlats;
- (NSMutableArray *)getAllStormPlats;


- (BOOL)loadPlat:(NSString *)platID
          ofType:(NSString *)type
    usingPopover:(GSSiPopoverView *)popover
     andDelegate:(id)delegate;

- (void)processDate:(NSString *)date
            forPipe:(NSString *)pipe;

- (void)processNotes:(NSString *)notes
           notesList:(NSArray *)notesList
             forPipe:(NSString *)pipe;

@end