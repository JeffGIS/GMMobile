//  NVGeocoder.h
//  NVMobile

@import Foundation;
@import GoogleMaps;

@class NVGeocoder;

@protocol NVGeocoderDelegate <NSObject>

- (void)geocoderDidReturnAddresses:(nullable NSArray<GMSAddress *> *)addresses
                             error:(nullable NSError *)error;

@end

@interface NVGeocoder : NSObject

+ (nullable instancetype)geocoderForCoordinate:(CLLocationCoordinate2D)coordinate
                                      delegate:(nonnull id<NVGeocoderDelegate>)delegate;

@end
