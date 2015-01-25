//  GSSiTileOverlay.h
//  GMMobile

#import <MapKit/MapKit.h>
#import "../../CCodeLibrary/CCodeLibrary/CCodeLibrary.h"

@protocol GSSiOverlay <MKOverlay>

@end

@interface GSSiTileOverlay : MKTileOverlay

@property (nonatomic, copy) NSString *type;

@end