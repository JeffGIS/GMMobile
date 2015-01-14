//  GSSiTileOverlay.h
//  GMMobile

#import <MapKit/MapKit.h>

typedef NS_ENUM(NSInteger, OverlayType)
{
    OverlayTypeDefault,
    OverlayTypeOSM,
    OverlayTypeGMM,
};

@protocol GSSiOverlay <MKOverlay>

@end

@interface GSSiTileOverlay : MKTileOverlay

@property NSCache *cache;
@property NSOperationQueue *operationQueue;
@property NSInteger type;

@end