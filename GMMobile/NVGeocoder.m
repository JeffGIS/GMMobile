//  NVGeocoder.m
//  NVMobile

#import "NVGeocoder.h"

@implementation NVGeocoder

+ (instancetype)geocoderForCoordinate:(CLLocationCoordinate2D)coordinate
                             delegate:(id<NVGeocoderDelegate>)delegate
{
    if (!delegate)
    {
        NSLog(@"NVGeocoder ERROR:Cannot set delegate to nil");
        return nil;
    }
    
    NVGeocoder *nvgeo = NVGeocoder.new;
    GMSGeocoder *gmsgeo = GMSGeocoder.geocoder;
    
    [gmsgeo reverseGeocodeCoordinate:coordinate
                   completionHandler:^(GMSReverseGeocodeResponse * _Nullable response, NSError * _Nullable error) {
                       [delegate geocoderDidReturnAddresses:response.results error:error];
                   }];
    
    return nvgeo;
}

@end
