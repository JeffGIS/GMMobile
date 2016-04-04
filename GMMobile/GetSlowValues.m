//
//  GetSlowValues.m
//  GMMobile
//
//  Created by JEFFREY E SMITH on 4/3/16.
//  Copyright © 2016 GSSi. All rights reserved.
//

#import "GetSlowValues.h"
#import "Destinations.h"

@implementation SlowValues
@end

@implementation GetSlowValues
- (void)computeSlowValues:(int)propNum
                     dbid:(int)dbid
                aroundLatLon:(LLPOINT)latlon
                      totEMV:(int)totEMV
                     useDesc:(LPSTR) usedescIN
{
    SlowValues * slowVals = [[SlowValues alloc]init];
    
//add routes from property to destinations
    Destinations *dests = [[Destinations alloc]init];
    [dests addRoutesForProperty:propNum];

}
- (void)computeValuesFromMap:(SlowValues *)values
                        dbid:(int)dbid
                     popover:(GSSiPopoverView*)popover
                aroundLatLon:(LLPOINT)latlon
                      totEMV:(int)totEMV
                     useDesc:(LPSTR) usedescIN
{
    _popover.title = @"Computing Values From Map";
    dispatch_queue_t valuesFromMapQueue = dispatch_queue_create("valuesFromMapQueue",NULL);
    
    dispatch_async(valuesFromMapQueue,
                   ^{
                       PercentInArea * pctInA = [[PercentInArea alloc]init];
                   });
}

@end
