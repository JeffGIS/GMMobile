//  PipeTrace.h
//  GMMobile

#import <Foundation/Foundation.h>
#import "CCodeLibrary/CCodeLibrary.h"

@class PipeTrace;

@protocol PipeTraceDelegate <NSObject>

- (void)zoomToPipeTraceBounds:(MNMXCORD)bounds;
- (void)perform3DFlyAround;

@end

@interface PipeTrace : NSObject<GSSiPopoverViewDelegate>

@property (nonatomic, weak) id <PipeTraceDelegate> delegate;
@property int processingID;
@property GSSiPopoverView *popover;

+ (void)removeTrace;
- (void)tracePipeDownstream:(NSString *)fromFacilityID;
- (void)tracePipeUpstream:(NSString *)fromFacilityID;
- (int) getPipeTraceBounds;

- (void)displayPipeTrace:(CGContextRef)context
               llCorners:(CORNERPOINTS *)latlonCornerPoints
                LLBounds:(MNMXCORD *)platlonBounds
              viewBounds:(MNMXCORD *)pvbounds;

- (BOOL)outputPipeTrace:(NSString *)toPath;
- (BOOL)havePipeTrace;

@end