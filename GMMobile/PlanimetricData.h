//  PlanimetricData.h
//  GMMobile

#import "CCodeLibrary/SQLiteLib.h"
#import "CCodeLibrary/CCodeLibrary.h"
#import "Themes.h"

@interface PlanimetricData : NSObject

@property int processingID;
@property CGFloat zoom;

-(void)displayPlanArea:(CGContextRef)context
             llCorners:(CORNERPOINTS *)latlonCornerPoints
              LLBounds:(MNMXCORD *)platlonBounds
            viewBounds:(MNMXCORD *)pvbounds;

-(void)displayPlanLine:(CGContextRef)context
             llCorners:(CORNERPOINTS *)latlonCornerPoints
              LLBounds:(MNMXCORD *)platlonBounds
            viewBounds:(MNMXCORD *)pvbounds;

-(void)displayPlanPoint:(CGContextRef)context
              llCorners:(CORNERPOINTS *)latlonCornerPoints
              LLBounds:(MNMXCORD *)platlonBounds
            viewBounds:(MNMXCORD *)pvbounds;

-(void)displayAlleyLine:(CGContextRef)context
              llCorners:(CORNERPOINTS *) latlonCornerPoints
               LLBounds:(MNMXCORD *)platlonBounds
             viewBounds:(MNMXCORD *)pvbounds;

-(void)displayWallPoint:(CGContextRef)context
              llCorners:(CORNERPOINTS *)latlonCornerPoints
               LLBounds:(MNMXCORD *)platlonBounds
             viewBounds:(MNMXCORD *)pvbounds;

- (int)pickAlleyWallPoint:(LLPOINT)pt
            highlightList:(NSMutableArray *)hlist;

- (int)pickAlleyLine:(LLPOINT)pt
              atZoom:(CGFloat)zoom
       highlightList:(NSMutableArray *)hlist;

- (int)pickCurbRampIntersectionPoint:(LLPOINT)point highlightList:(NSMutableArray*)hlist;

-(void)displayCurRampIntersectionPoint:(CGContextRef)context
                displayCharacteristics:(DisplayCharacteristics *)dc
                             llCorners:(CORNERPOINTS *) latlonCornerPoints
                              LLBounds:(MNMXCORD *)platlonBounds
                            viewBounds:(MNMXCORD *)pvbounds
                                themes:(Themes*)themes;

- (NSArray *)getDistinctSymbols:(NSString *)tableName;

- (void)drawCurbRampIntersection:(CGContextRef)context
                         atPoint:(DPOINT *)pPoint
                       withColor:(CGColorRef)color
                         andSize:(CGFloat)size;

@end