//  BoundaryData.h
//  GMMobile

#import <sqlite3.h>
#import "CCodeLibrary/CCodeLibrary.h"

@interface BoundaryAreaData : NSObject

@property NSString *name;
@property int refno;

@end

@interface BoundaryData : NSObject
@property int processingID;
@property sqlite3 *database;
@property (atomic) BOOL isOpen;
@property (nonatomic, copy) NSString *documentsDirectory;
@property (nonatomic, copy) NSString *fileName;
@property (nonatomic, copy) NSString *path;
@property NSInteger fileSize;
@property (nonatomic) int datasetVersion;

- (BOOL)open;
- (void)close:(BOOL)opened;
- (void)startTransaction;
- (void)commitTransaction;
- (BOOL)executeCmd:(char *)cmd;

- (NSMutableArray *)getBoundaryAreaTypes;
- (NSMutableArray *)getBoundaryAreaDataForType:(NSString *)type;
- (MNMXCORD) getBoundaryAreaBounds:(int)refno;

-(void)displayBoundary:(int)refno
             inContext:(CGContextRef)context
             llCorners:(CORNERPOINTS *) latlonCornerPoints
             LLBounds:(MNMXCORD *)platlonBounds
            viewBounds:(MNMXCORD *)pvbounds;

-(void)displayLandUse:(CGContextRef)context
            llCorners:(CORNERPOINTS *) latlonCornerPoints
             LLBounds:(MNMXCORD *)platlonBounds
           viewBounds:(MNMXCORD *)pvbounds;
- (LPDPOINT)getPolygonPointsForBoundary:(int)refno
                              numPoints:(int *)numPoints
                               numLoops:(int *)numLoops
                            polyPartLen:(int **)polyPartLen;

@end