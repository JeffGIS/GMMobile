//  GSSiTileOverlay.h
//  GMMobile

#import <MapKit/MapKit.h>
#import "../../CCodeLibrary/CCodeLibrary/CCodeLibrary.h"

@protocol GSSiOverlay <MKOverlay>

@end

@interface GSSiTileOverlay : MKTileOverlay<GSSiPopoverViewDelegate>

@property (nonatomic, copy) NSString *type;

- (void)cacheTileAtPath:(MKTileOverlayPath)path condition:(NSCondition *)condition complete:(int *)pcomplete failed:(int *)pfailed;

@end