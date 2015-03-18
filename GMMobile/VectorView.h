//  VectorView.h
//  GMMobile

#import "../../CCodeLibrary/CCodeLibrary/CCodeLibrary.h"
#import <GoogleMaps/GoogleMaps.h>

@class VectorView;

@protocol VectorViewDelegate <NSObject>

- (void)vectorViewDidComplete:(VectorView*)vectorView;

@end

@interface VectorView : UIView

@property (nonatomic, weak) id <VectorViewDelegate> delegate;

@property int displayData;
@property int displayID;
@property int ivv;
@property int zoom;
@property CORNERPOINTS latlonCornerPoints;
@property MNMXCORD latlonBounds;
@property MNMXCORD viewBounds;

- (void) setRegion:(GMSVisibleRegion)region;

@end