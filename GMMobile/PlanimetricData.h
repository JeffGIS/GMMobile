//  PlanimetricData.h
//  GMMobile

#import <sqlite3.h>
#import "../../CCodeLibrary/CCodeLibrary/CCodeLibrary.h"

@interface PlanimetricData : NSObject

@property int processingID;

-(void)displayPlanArea:(CGContextRef)context
              LLBounds:(MNMXCORD *)platlonBounds
            viewBounds:(MNMXCORD *)pvbounds;

-(void)displayPlanLine:(CGContextRef)context

              LLBounds:(MNMXCORD *)platlonBounds
            viewBounds:(MNMXCORD *)pvbounds;

-(void)displayPlanPoint:(CGContextRef)context
              LLBounds:(MNMXCORD *)platlonBounds
            viewBounds:(MNMXCORD *)pvbounds;

-(void)displayWallPoint:(CGContextRef)context
               LLBounds:(MNMXCORD *)platlonBounds
             viewBounds:(MNMXCORD *)pvbounds;

@end