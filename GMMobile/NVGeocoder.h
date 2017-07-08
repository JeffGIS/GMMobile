//  NVGeocoder.h
//  NVMobile

@import Foundation;
@import GoogleMaps;

@class NVGeocoder;

@protocol NVGeocoderDelegate <NSObject>

- (void)geocoderDidReturnAddresses:(nullable NSArray<GMSAddress *> *)addresses;

@end

@interface NVGeocoder : NSObject

@end
