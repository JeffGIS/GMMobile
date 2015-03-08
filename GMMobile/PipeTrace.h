//  PipeTrace.h
//  GMMobile

#import <Foundation/Foundation.h>
#import "../../CCodeLibrary/CCodeLibrary/CCodeLibrary.h"

@class PipeTrace;

@protocol PipeTraceDelegate <NSObject>

- (void)zoomToPipeTraceBounds:(MNMXCORD)bounds;

@end

@interface PipeTrace : NSObject

@property (nonatomic, weak) id <PipeTraceDelegate> delegate;
@property int processingID;

- (void)tracePipeDownstream:(NSString *)fromFacilityID;
- (int) getPipeTraceBounds;
- (void)displayPipeTrace:(CGContextRef)context
               LLBounds:(MNMXCORD *)platlonBounds
             viewBounds:(MNMXCORD *)pvbounds;


@end