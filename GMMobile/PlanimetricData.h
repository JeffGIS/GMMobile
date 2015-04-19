//  PlanimetricData.h
//  GMMobile

#import <sqlite3.h>
#import "../../CCodeLibrary/CCodeLibrary/CCodeLibrary.h"

@interface PlanimetricData : NSObject

@property int processingID;

-(void)displayPlanArea:(CGContextRef)context
             llCorners:(CORNERPOINTS *) latlonCornerPoints
              LLBounds:(MNMXCORD *)platlonBounds
            viewBounds:(MNMXCORD *)pvbounds;

-(void)displayPlanLine:(CGContextRef)context
             llCorners:(CORNERPOINTS *) latlonCornerPoints
              LLBounds:(MNMXCORD *)platlonBounds
            viewBounds:(MNMXCORD *)pvbounds;

-(void)displayPlanPoint:(CGContextRef)context
              llCorners:(CORNERPOINTS *) latlonCornerPoints
              LLBounds:(MNMXCORD *)platlonBounds
            viewBounds:(MNMXCORD *)pvbounds;

-(void)displayAlleyLine:(CGContextRef)context
              llCorners:(CORNERPOINTS *) latlonCornerPoints
               LLBounds:(MNMXCORD *)platlonBounds
             viewBounds:(MNMXCORD *)pvbounds;

-(void)displayWallPoint:(CGContextRef)context
              llCorners:(CORNERPOINTS *) latlonCornerPoints
               LLBounds:(MNMXCORD *)platlonBounds
             viewBounds:(MNMXCORD *)pvbounds;

- (int)pickAlleyWallPoint:(LLPOINT)pt
            highlightList:(NSMutableArray*)hlist;

- (BOOL)moveAlleyWallPoint:(NSInteger)refno
                        to:(CLLocationCoordinate2D)point;

- (NSArray*)getDistinctSymbols:(NSString *)tableName;

- (void)userSavedAlleyWallPointMove:(BOOL)saved;

@end